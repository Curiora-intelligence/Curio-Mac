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
    var destination: Destination?
    var notice: String?
    var focusComposer = 0
    var toggleSidebarRequest = 0
    var preferredSidebarWidth: Double { didSet { preferences.set(preferredSidebarWidth, forKey: "sidebarWidth") } }
    var effort: Effort { didSet { preferences.set(effort.rawValue, forKey: "thinkingEffort") } }
    private let preferences: UserDefaults

    init(preferences: UserDefaults = .standard) {
        self.preferences = preferences
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
        destination = nil
        narrowSidebarOpen = false
        focusComposer += 1
    }
    func select(_ mode: Mode) { self.mode = mode; notice = nil }
    func explainUnavailable(_ feature: String) {
        notice = "\(feature) isn't connected yet. Your draft stays here."
    }
}
