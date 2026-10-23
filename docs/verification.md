# Phase 1 verification — 23 October 2026

## Outcome

Curio builds and runs as an independent native macOS application. Debug was built and launched through Xcode's Product → Run workflow. Release was built with Xcode's `xcodebuild` and launched separately from its `.app` bundle. No web renderer or external dependency is used for the UI.

- Xcode 27.1 (27A9275), Swift 6, macOS deployment target 14.0.
- Debug: **BUILD SUCCEEDED** — [log](build-debug.log).
- Release: **BUILD SUCCEEDED**, arm64 and x86_64 binary — [log](build-release.log).
- XCTest: **7 tests passed, 0 failures** — [log](tests-final.log); result bundle in ignored `build/FinalTests.xcresult`.
- The final Escape shortcut change was compiled in Release and manually verified after the seven-test run. The tests cover state/boundaries rather than UI keyboard dispatch.
- Xcode emitted an App Intents metadata-skipped warning because no AppIntents framework is linked. The initial restricted compiler invocation failed in the tool sandbox; the authorized Xcode build completed successfully.

## Local source of truth

The actual local files were read, including templates, token stylesheets, product CSS, SVG icons, composer/menu structures, sidebar resizing, Chat/Work state and motion, and backend route use. The local working copies were clean when inspected; no uncommitted reference changes were replaced.

| Reference | Local revision |
| --- | --- |
| `../Curio-Web` | `c04996bed9df5a928aec3ccb77c11ded34863e7b` |
| `../Curiora-Design-System` | `43e87e9b15da5b1686bcc105a4bc0264b81f9151` |

Curio-Web product overrides take precedence over broader design-system defaults. Both reference repositories remain clean on `main`. The user-approved existing Curio-Mac directory was initialized on `main`; there are no commits, staged files, branches beyond main, clones, or worktrees.

## Checks performed

| Area | Result and scope |
| --- | --- |
| Launch/window | Xcode Run and independent Release launch succeeded. Native title bar, traffic lights, menus, window resize/tiling and restoration used. |
| Appearance | Actual macOS Light and Dark settings changed while app ran; colors and controls followed. Dark restored afterward. |
| Chat/Work | Pointer and ⌘1/⌘2 switching worked. Separate draft text survived switching. Distinct single-row Chat and taller Work composers retained. |
| Composer | ⌘L focus, typing, effort menu, capability menu and unavailable send notice checked. Draft retained; no assistant message or backend request generated. Work execution button disabled. |
| Sidebar | Collapse/expand and narrow overlay checked. Accessible increment/decrement and keyboard reset changed width; persisted width and bounds covered by tests. Automated pointer dragging could not be verified because the computer-use tool returned no-window errors. |
| Navigation | Scheduled and Library displayed explicit unavailable sheets; Recents remains empty. No placeholder history, jobs or saved content generated. |
| Narrow window | Native 736 × 826 outer window (736 × 794 content) checked in Chat/Work; overlay hides main controls from accessibility; Escape dismisses it even without an editor focused. |
| Keyboard | Tab reached menus with macOS Keyboard navigation enabled; Space opened menus; arrow keys switched workspace. System preference restored to off. Focus evidence saved. |
| Reduced motion | OS Reduce Motion enabled and workspace/sidebar interactions exercised. SwiftUI environment disables layout/selection animations. Preference restored to off. No frame-by-frame timing measurement. |
| Accessibility | Labels, selected workspace, disabled execution, resize adjustable actions, heading and navigation grouping checked in accessibility tree. Full VoiceOver speech traversal remains untested. |

The seven automated checks cover draft preservation, sidebar bounds/persistence/viewport recovery, unavailable-action draft retention, disconnected backend failure, unavailable native capabilities, opaque colors in both appearances, and finite/contained liquid-selection geometry across 101 progress samples.

## Screenshot comparison

[Open the comparison gallery](parity.html). Actual Curio Web templates and production assets were served locally through the repository's existing browser test harness, without modifying source or sending prompts. Browser appearance routes selected the reference palette.

Desktop Web captures use a **1200 × 728 content viewport**. Native screenshots use a **1200 × 760 outer window**, including its **32-point native title bar**, at 2× display scale. The gallery aligns the content regions while linking original untouched images. Narrow captures compare 736 × 794 content regions. Earlier 1200 × 760 web viewport captures are retained as supplementary evidence, not used for matched-content comparison.

Observed parity: 270-point sidebar, 72-point header, centered switch, 770-point content width, source heading text, distinct Chat/Work composition, rounded surfaces, blue primary control, icon silhouettes, palette, Scheduled and Library labels. Work heading/composer positions are close at matched content size. Chat's native minimum editor height makes its composer roughly 8 points taller than the empty Web capture; its explicit disconnected note adds vertical content.

## Remaining limitations and parity gaps

- Backend/authentication, chat transcript/history, scheduled tasks, library data, upload, dictation, Speak, temporary chat and execution are not implemented. Their UI says so. No fake inference, account, or running task exists.
- Drafts are memory-only and per-window; there is no restoration after closing/quitting.
- Native title bar, native menu popovers, system font rendering/weight, scrollbar behavior and focus rings differ from the browser. The source wordmark is recreated with system text and a custom mark.
- The Chat placeholder is static; Web's rotating placeholder and voice hover choreography are not ported. Liquid selection is a new SwiftUI shape animation, not a frame-exact reproduction of the JavaScript animation.
- Narrow layout retains a 200 × 40 desktop switch and desktop-sized controls; Web uses some larger touch targets and a 176 × 44 switch. Native minimum window width is 560 points.
- Glass surfaces use semantic translucent fills, border and shadow; there is no exact browser backdrop-filter equivalent.
- Work omits the Web button that opens the desktop app, because this is already that app. Context copy accurately describes local drafts.
- Physical drag/double-click resize verification, full VoiceOver speech audit, Intel runtime, minimum macOS 14 runtime, and frame-level motion comparison remain outstanding. Keyboard/accessibility resizing and its bounds were verified.
- Distribution signing/notarization and a distributable installer are outside this milestone.

## Changed files

All files below are new, untracked local work; nothing was staged or committed. Existing user additions to `.gitignore` were preserved.

| Files | Change |
| --- | --- |
| `.gitignore`, `README.md` | Local build exclusions and run/architecture documentation |
| `Curio.xcodeproj/project.pbxproj`, `Curio.xcodeproj/xcshareddata/xcschemes/Curio.xcscheme` | Native app and XCTest targets; shared scheme |
| `Curio/App/CurioApp.swift` | AppKit lifecycle integration, windows and native commands |
| `Curio/DesignSystem/CurioraTokens.swift`, `CurioIcon.swift`, `Controls.swift` | Product tokens, custom drawing, accessible reusable controls and native selection animation |
| `Curio/UI/SidebarView.swift`, `ComposerView.swift`, `WorkspaceView.swift` | Shell, layouts, draft controls and explicit availability screens |
| `Curio/State/WorkspaceState.swift` | Window state, separate drafts, persisted width/effort |
| `Curio/Networking/CurioraBackend.swift` | Future shared-backend protocol and disconnected implementation |
| `Curio/NativeServices/NativeServiceBoundary.swift` | Separate native capability availability boundary |
| `Curio/Curio.entitlements` | App sandbox |
| `Curio/Resources/Assets.xcassets/**` | Semantic light/dark colors and app icon sizes |
| `CurioTests/WorkspaceTests.swift` | Seven meaningful foundation checks |
| `scripts/generate-icon.swift` | Dependency-free AppKit icon generation |
| `docs/verification.md`, `docs/parity.html`, `docs/*.log`, `docs/evidence/*.jpg` | Verification record and visual evidence |

Generated build products and Xcode user state are ignored.
