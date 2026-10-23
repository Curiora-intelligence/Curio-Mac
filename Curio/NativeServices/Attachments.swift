import AppKit
import UniformTypeIdentifiers

/// Scope belongs to this in-memory selection, never a model message or a bookmark.
final class LocalAttachment: Identifiable {
    let id = UUID()
    let url: URL
    let byteCount: Int
    private let scoped: Bool
    init(url: URL, byteCount: Int, scoped: Bool) { self.url = url; self.byteCount = byteCount; self.scoped = scoped }
    deinit { if scoped { url.stopAccessingSecurityScopedResource() } }
}

enum AttachmentPolicy {
    static let maximumBytes = 15 * 1024 * 1024
    static let maximumCount = 5
    static let extensions: Set<String> = ["jpg","jpeg","png","webp","gif","pdf","txt","md","csv","json"]
    static var contentTypes: [UTType] { extensions.sorted().compactMap { UTType(filenameExtension:$0) } }
    static func validate(name: String, bytes: Int, regular: Bool, symbolicLink: Bool) throws {
        guard regular && !symbolicLink else { throw AttachmentError.invalid("Choose a regular file, not a folder, package, or symbolic link.") }
        guard extensions.contains(URL(fileURLWithPath:name).pathExtension.lowercased()) else { throw AttachmentError.invalid("Choose an image, PDF, text, Markdown, CSV, or JSON file.") }
        guard bytes > 0 && bytes <= maximumBytes else { throw AttachmentError.invalid("Choose a nonempty file up to 15 MB.") }
    }
    static func select(_ url: URL) throws -> LocalAttachment {
        let scoped = url.startAccessingSecurityScopedResource()
        do {
            let values = try url.resourceValues(forKeys:[.isRegularFileKey,.isSymbolicLinkKey,.fileSizeKey,.isPackageKey])
            try validate(name:url.lastPathComponent,bytes:values.fileSize ?? 0,regular:values.isRegularFile == true && values.isPackage != true,symbolicLink:values.isSymbolicLink == true)
            return LocalAttachment(url:url,byteCount:values.fileSize ?? 0,scoped:scoped)
        } catch {
            if scoped { url.stopAccessingSecurityScopedResource() }
            throw error
        }
    }
}
enum AttachmentError: LocalizedError {
    case invalid(String)
    var errorDescription: String? { if case let .invalid(message) = self { return message }; return nil }
}

@MainActor enum AttachmentPicker {
    static func choose(for window: NSWindow?) async -> [URL] {
        let panel = NSOpenPanel()
        panel.title = "Add files to this draft"
        panel.message = "Images, PDF, text, Markdown, CSV or JSON. Up to 5 files, 15 MB each. Files stay local and are not uploaded."
        panel.allowedContentTypes = AttachmentPolicy.contentTypes
        panel.allowsMultipleSelection = true; panel.canChooseDirectories = false
        panel.resolvesAliases = false
        let response: NSApplication.ModalResponse = await withCheckedContinuation { continuation in
            if let window { panel.beginSheetModal(for:window) { continuation.resume(returning:$0) } }
            else { panel.begin { continuation.resume(returning:$0) } }
        }
        return response == .OK ? panel.urls : []
    }
}
