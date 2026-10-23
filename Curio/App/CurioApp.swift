import SwiftUI
import AppKit

@main struct CurioApp: App {
    @NSApplicationDelegateAdaptor(CurioAppDelegate.self) private var delegate
    var body: some Scene {
        WindowGroup("Curio") { CurioWindow() }
            .defaultSize(width:1200,height:760)
            .windowResizability(.contentMinSize)
            .commands { CurioCommands() }
        Settings { AvailabilitySheet(destination:.settings) }
    }
}

private struct CurioWindow: View {
    @State private var state = WorkspaceState()
    var body: some View {
        RootView(state:state)
            .focusedSceneValue(\.workspaceState,state)
    }
}
private struct WorkspaceStateKey: FocusedValueKey { typealias Value = WorkspaceState }
extension FocusedValues {
    var workspaceState: WorkspaceState? {
        get { self[WorkspaceStateKey.self] }
        set { self[WorkspaceStateKey.self] = newValue }
    }
}
struct CurioCommands: Commands {
    @FocusedValue(\.workspaceState) private var state
    var body: some Commands {
        CommandGroup(after:.newItem) {
            Button("New Chat") { state?.newChat() }.keyboardShortcut("n",modifiers:[.command,.shift])
            Button("Focus Composer") { state?.focusComposer += 1 }.keyboardShortcut("l",modifiers:.command)
        }
        CommandGroup(before:.sidebar) {
            Button("Toggle Sidebar") { state?.toggleSidebarRequest += 1 }
                .keyboardShortcut("s",modifiers:[.command,.control])
        }
        CommandMenu("Workspace") {
            Button("Chat") { state?.select(.chat) }.keyboardShortcut("1",modifiers:.command)
            Button("Work") { state?.select(.work) }.keyboardShortcut("2",modifiers:.command)
            Divider()
            Button("Scheduled") { state?.destination = .scheduled }
            Button("Library") { state?.destination = .library }
        }
    }
}

final class CurioAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // No appearance override in normal use: SwiftUI and AppKit track macOS.
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("--ui-testing") {
            // Deterministic test launch only; never mutates system appearance.
            if arguments.contains("--dark") { NSApp.appearance = NSAppearance(named:.darkAqua) }
            if arguments.contains("--light") { NSApp.appearance = NSAppearance(named:.aqua) }
        }
        #endif
    }
}
