# Curio for macOS

Native SwiftUI + AppKit foundation for **Curio by Curiora**. macOS 14 or later; Swift 6; no external dependencies, embedded browser, or backend required to launch.

## Run

Open `Curio.xcodeproj` in Xcode, select **Curio → My Mac**, then **Product → Run** (⌘R). The project uses local ad hoc signing. Distribution signing and notarization are not configured.

From this directory:

```sh
xcodebuild -project Curio.xcodeproj -scheme Curio -configuration Debug -derivedDataPath build build
xcodebuild -project Curio.xcodeproj -scheme Curio -configuration Debug -destination 'platform=macOS' -derivedDataPath build test
xcodebuild -project Curio.xcodeproj -scheme Curio -configuration Release -derivedDataPath build build
```

The independently launchable Release application is `build/Build/Products/Release/Curio.app`.

## Foundation

- Curio branding, semantic light/dark asset colors, product spacing, custom SwiftUI icons, and a native liquid selection animation.
- Native windows and menus; Chat and Work empty states with separate composers and in-memory drafts.
- New chat, Scheduled, Library, Recents, search empty state, and profile/settings entry points.
- Collapsible sidebar, bounded resizing, and an overlay sidebar below 760 points.
- System appearance, reduced motion, selected-state accessibility, focus rings, native menus, and keyboard commands.

| Command | Action |
| --- | --- |
| ⌘1 / ⌘2 | Chat / Work |
| ⌘L | Focus composer |
| ⇧⌘N | Return to Chat and focus its existing draft |
| ⌃⌘S | Toggle navigation |
| Escape | Close narrow navigation overlay |
| Left / Right on Chat/Work | Select workspace |
| Left / Right on resize handle | Resize by 10 points (Shift: 40) |
| Return on resize handle | Reset to 270 points |
| Shift–Return in composer | Insert a newline |

Tab access to all controls follows macOS **Keyboard → Keyboard navigation**. Drafts live only in their window and disappear when it closes or the app quits. New Chat preserves unsent text while no conversation service exists. Only sidebar width and thinking effort persist on this Mac.

## Boundaries

This is an application shell. Chat inference, authentication, history, scheduling, library data, attachments, dictation, Speak, temporary conversations, and Work execution are explicitly unavailable. Sending a draft explains the missing connection without consuming it or generating a response. Thinking effort is a local preference only.

`Networking/CurioraBackend.swift` defines an asynchronous interface and a disconnected adapter. It documents existing web routes without inventing an authentication or Work wire contract. `NativeServices/NativeServiceBoundary.swift` is separate, unavailable, and has no execution entry point. Model event data cannot trigger native permissions or execution.

## Structure

| Location | Responsibility |
| --- | --- |
| `Curio/App` | App lifecycle, windows, scene-scoped commands |
| `Curio/DesignSystem` | Semantic tokens, icons, reusable controls and motion |
| `Curio/UI` | Sidebar, composer, workspace, availability sheets |
| `Curio/State` | Per-window drafts and navigation; local preferences |
| `Curio/Networking` | Future backend boundary; disconnected adapter |
| `Curio/NativeServices` | Future native capability boundary |
| `Curio/Resources` | Adaptive colors and application icon |
| `CurioTests` | State, boundary, color and geometry checks |

See [verification](docs/verification.md) for build results, checks, limitations and changed files, and [visual comparison](docs/parity.html) for actual Web/native screenshots.
