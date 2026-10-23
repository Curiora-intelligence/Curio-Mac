import SwiftUI

@MainActor @Observable final class WorkspaceState {
    enum Mode: String, CaseIterable, Identifiable { case chat = "Chat", work = "Work"; var id: Self { self } }
    enum Destination: String, Identifiable { case scheduled = "Scheduled", library = "Library", settings = "Settings"; var id: Self { self } }
    enum Effort: String, CaseIterable { case low = "Low", medium = "Medium", high = "High" }
    var mode: Mode = .chat
    var chatDraft = ""
    var workDraft = ""
    var sidebarVisible = true
    var narrowSidebarOpen = false
    var searchVisible = false
    var search = ""
    let conversationSource: any ConversationSearchSource
    var selectedConversation: SearchConversation?
    var chatAttachments: [LocalAttachment] = []
    var workAttachments: [LocalAttachment] = []
    func openConversation(_ conversation: SearchConversation) {
        selectedConversation = conversation; mode = .chat; narrowSidebarOpen = false
    }
    func addAttachments(_ urls: [URL], mode: Mode) {
        var current = mode == .chat ? chatAttachments : workAttachments
        var errors: [String] = []
        for url in urls {
            if current.contains(where:{ $0.url == url }) { continue }
            guard current.count < AttachmentPolicy.maximumCount else { errors.append("You can attach up to 5 files per draft."); break }
            do { current.append(try AttachmentPolicy.select(url)) }
            catch { errors.append("\(url.lastPathComponent): \(error.localizedDescription)") }
        }
        if mode == .chat { chatAttachments = current } else { workAttachments = current }
        if !errors.isEmpty { notice = errors.joined(separator:"\n") }
    }
    func removeAttachment(_ id: UUID, mode: Mode) {
        if mode == .chat { chatAttachments.removeAll { $0.id == id } }
        else { workAttachments.removeAll { $0.id == id } }
    }
    var destination: Destination?
    var notice: String?
    var focusComposer = 0
    var toggleSidebarRequest = 0
    var preferredSidebarWidth: Double { didSet { preferences.set(preferredSidebarWidth, forKey: "sidebarWidth") } }
    var effort: Effort { didSet { preferences.set(effort.rawValue, forKey: "thinkingEffort") } }
    private let preferences: UserDefaults

    init(preferences: UserDefaults = .standard, conversationSource: any ConversationSearchSource = DisconnectedConversationSource()) {
        self.preferences = preferences
        self.conversationSource = conversationSource
        let width = preferences.double(forKey: "sidebarWidth")
        preferredSidebarWidth = width.isFinite && width >= 252 ? min(420, width) : 270
        effort = Effort(rawValue: preferences.string(forKey: "thinkingEffort") ?? "") ?? .medium
    }
    func sidebarWidth(for windowWidth: CGFloat) -> CGFloat {
        min(max(Curiora.sidebarMinimum, preferredSidebarWidth), max(Curiora.sidebarMinimum, min(Curiora.sidebarMaximum, windowWidth - 480)))
    }
    func resizeSidebar(to width: CGFloat, windowWidth: CGFloat) {
        guard width.isFinite else { return }
        preferredSidebarWidth = min(max(252, width), max(252, min(420, windowWidth - 480)))
    }
    func newChat() {
        // New Chat navigates to an unsent draft; it never silently discards it.
        mode = .chat
        selectedConversation = nil
        destination = nil
        narrowSidebarOpen = false
        focusComposer += 1
    }
    func select(_ mode: Mode) { self.mode = mode; notice = nil }
    func explainUnavailable(_ feature: String) {
        notice = "\(feature) isn't connected yet. Your draft stays here."
    }
}
