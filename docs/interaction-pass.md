# Native/Web interaction pass

## Diagnosis before editing

- **Selector defect:** Mac animates a single progress value with a cubic timing curve, symmetric 24% expansion and quadratic waist. Approved Web uses eight cubic curves, independently timed leading/trailing edges, a tapered trailing radius, and carries the last painted contour on reversal over 360ms. These are different geometry and interruption models, not a platform rendering quirk.
- **Resize defect:** reproduced the full-height blue rectangle by focusing/resizing the native handle; evidence `evidence/resize-focus-before.jpg`. The handle calls `.focusable()` and gets SwiftUI's default focus effect in addition to its custom neutral fill. The source never paints a blue drag line. Pointer automation itself currently reports no window; keyboard reproduction confirms the decoration's focus origin.
- **Temporary Chat defect:** both headers render the control unconditionally. Chat already identifies it as unavailable; preserve that behavior and exclude the entire utility in Work.
- **Search feature:** Web currently filters Recents by title only. Its per-user browser cache includes message text; authenticated existing history route supplies titles, with content fetched only when a conversation opens. Mac has no authenticated history adapter or cached conversations. Do not invent results or fetch every remote transcript without user action.
- **Composer features:** Mac has an editable TextField but no attachment or speech service; its only entitlement is sandbox. Add explicit user-initiated services with narrowly scoped permission configuration, separate from backend/model data.
- **Motion feature:** original voice geometry is five strokes, with coordinated one-shot hover ratios 2.1/.56/.62 and stagger 0/35/70ms. Shared motion docs forbid idle or fake level animation. Existing navigation icons are static; new interaction-triggered motion is a product addition, not a shared-system rewrite.
- **Brand review:** keep the recognized C/return-arrow mark and blue tile. Current system-text wordmark differs from Web metrics; future optical sizing of the 16/32px icon and a designer-approved vector wordmark would improve small-scale consistency. No rebrand or icon replacement is included.

Preserved concurrent Web change: `app/routers/home.py` has a pre-existing TemplateResponse call edit. Design System is read-only. All work remains in original checkouts on main.

## Implemented behavior

- **Liquid selection:** native eight-curve contour, separately timed edges, 360 ms travel, tapered tail and retained contour on reversal. Reduced Motion settles directly. No JavaScript renderer or runtime dependency is used. New middle-gradient token matches the shared surface.
- **Sidebar:** removed SwiftUI's automatic full-height blue focus effect from the resize handle. A neutral 40-point marker preserves keyboard focus; the existing neutral resize material, width limits, reset, persistence and collapse behavior remain. New Chat, Scheduled and Library respond subtly to hover/focus on both platforms, with reduced-motion overrides.
- **Temporary Chat:** excluded from Work on both platforms. Chat still describes its unavailable privacy behavior honestly.
- **Search:** centered dialogs with automatic query focus, Escape dismissal, outside-click handling, empty/loading/error states and result navigation. Queries search titles and available message content. Web uses the existing authorized per-identity catalog and history endpoints; transcript content becomes searchable after it is loaded. Mac has an injectable asynchronous catalog protocol and an empty disconnected implementation. No fabricated production conversations or backend search endpoint. The first Escape closes a populated WebKit search field and the focused native field.
- **Dictation:** explicit microphone/Speech permission requests, on-device recognition only, visible listening state, Stop, Cancel, editable transcript and Insert text. Insertion changes the draft without sending. Session tokens prevent late callbacks from reviving cancelled sessions; recording stops when leaving the workspace or when the app becomes inactive. A 60-second limit releases the microphone. Unavailable language/device or denied permission produces an explanation.
- **Attachments:** native NSOpenPanel, regular-file/type/size validation, five-file limit, removable filename/icon/size previews, separate selections per workspace, balanced security-scoped access. Supported extensions: jpg/jpeg/png/webp/gif/pdf/txt/md/csv/json; nonempty files up to 15 MiB each. No uploads, bookmarks or file-content persistence.
- **Voice artwork:** the approved five-stroke geometry and one-shot staggered waveform response use SwiftUI keyframes. Speak/Live remain unavailable; this is interaction feedback, not an audio-level visualization.

## Microphone crash: confirmed cause and fix

The user's microphone click produced `Curio-2026-10-23-171837.ips`. Its faulting TCC callback queue hit `dispatch_assert_queue` / `swift_task_checkIsolated` inside the Speech authorization callback. The callback inherited MainActor isolation even though Speech invoked it on a background queue.

Authorization now crosses a nonisolated async bridge with an explicitly Sendable completion closure. Audio and recognition callbacks are also explicitly Sendable; observable UI state returns to MainActor. Permission prompts no longer cancel an authorizing session simply because the app becomes inactive.

A regression test invokes the authorization completion on `DispatchQueue.global()`. It passes. The running app subsequently entered “Listening on this Mac…”, recognized “Permission”, stopped into an editable transcript, and inserted that text into the Chat draft without submitting or quitting. The temporary verification draft was cleared when the test app was restarted.

Apple references: [authorization callback](https://developer.apple.com/documentation/speech/sfspeechrecognizer/requestauthorization(_:)), [on-device availability](https://developer.apple.com/documentation/speech/sfspeechrecognizer/supportsondevicerecognition), [requiring on-device recognition](https://developer.apple.com/documentation/speech/sfspeechrecognitionrequest/requiresondevicerecognition), [sandbox resource access](https://developer.apple.com/documentation/security/accessing-files-from-the-macos-app-sandbox).

## Verification results

Verification performed October 23, 2026; report completed October 24, 2026.

| Check | Result |
| --- | --- |
| Xcode Debug build | Passed; `interaction-build-debug.log` |
| Xcode Release build | Passed; `interaction-build-release.log`; arm64 + x86_64 binary |
| Native regression suite | 13 passed, 0 failures; `interaction-tests.log` |
| Native launch | Built/run through Xcode during crash diagnosis; rebuilt Debug app independently launched and interacted with afterward |
| JavaScript module suites, including shared liquid tests | 20 passed, 0 failures |
| Safari functional browser suite | 111 passed; final run includes search content/navigation, nonempty-query Escape and Work utility visibility |
| Python web suite | 12 passed, 1 failed: existing `test_history_navigation_label_matches_its_existing_destination` requires History and forbids Scheduled. Approved Scheduled label retained; assertion not suppressed |
| Git whitespace checks | Passed for both modified checkouts |
| Design System | Clean on main; unchanged |

Native checks confirmed automatic search focus, query typing, Escape, no invented search results, keyboard sidebar resizing/reset, persistent width, neutral focus marker, Chat/Work commands and rapid reversals, Temporary Chat hidden in Work/restored in Chat, native file selection/preview/removal, and the live dictation flow above. Unit tests additionally cover cancellation state, contour carry on reversal, search navigation without consuming drafts, invalid file selections, deduplication and selection lifecycle.

Safari's longer visual suites did **not** finish green:

- Dark surface run failed “hover changes only the target row, never current navigation” (`surface-safari-dark-d2f0ce2ee515.json`).
- A full theme run reached light 1024px but lost foreground visibility and failed the fluid-geometry observation (`surface-safari-light-6a3136a81156.json`). A separate attempt stayed hidden and correctly failed rather than bypassing foreground checks.
- After the user brought Safari forward, the light 390px run passed layout, contrast, composer, drawer and several navigation checks, then failed “segment hover changes only text emphasis over 150ms” (`surface-safari-light-e49513792d17.json`). This assertion's cause remains unresolved; it must not be described as a clean visual pass. Shared segment CSS/JS were not modified.
- The final functional result is `Curio-Web/test-results/surface-safari-light-f426e007860a.json` (111 passed). Tests use their existing controlled backend/media fixtures; no production mock inference was added.

The actual WebKit search dialog was also checked at 390px: query input, honest no-match state and first-Escape dismissal worked. Captures and native accessibility trees were inspected. Full VoiceOver speech/rotor traversal, fresh deny/revoke permission scenarios, unplugged microphone behavior, real mouse dragging, native narrow-window resizing, a fresh native light-mode sweep and system Reduce Motion toggling were **not fully reverified in this pass**. Coordinate/drag automation returned `noWindowsAvailable`; keyboard resizing and numerical/state tests passed. Earlier foundation light/narrow captures remain in `parity.html`, clearly separate from the new dark captures. x86_64 compilation is not an Intel hardware runtime test.

## Visual comparison and remaining gaps

[Interaction comparison gallery](interaction-parity.html) uses actual native and Web screenshots. The new Chat and Work comparisons match 1200 × 728 content points: native screenshots are 2400 × 1520 at 2×, including a 32-point title bar; the gallery clips that title bar only for comparison. Web captures are 1200 × 728. Both use a 270-point sidebar. Original full screenshots remain intact.

The overall sidebar, centered switch, heading and composer placement are recognizable. Remaining differences include system-font wordmark metrics, native menu arrows and control rendering, a roughly 54-point native Chat composer versus Web's 48-point capsule, native availability text below the composer, static native placeholder versus Web's rotating placeholder, and different native/Web Work availability footers. The native minimum width is 560 points; Web supports mobile layouts. Pixel-identical motion rendering is not claimed: numeric geometry/reversal is tested, but a frame-by-frame screen-recording comparison remains outstanding.

Mac authenticated history, inference, scheduling, library data, attachment processing, temporary conversations, Speak/Live and Work execution remain disconnected. A future authenticated adapter must supply only authorized conversations. Local file and microphone services have no path from model output to permission requests or execution. Distribution signing/notarization is not configured; Release is a locally signed development artifact (including get-task-allow), not a shipping package.

## Exact changed files

Paths below are relative to their original checkout. No staging, commits, pushes, branches, worktrees or clones were created in this pass. The native bundle identifier `curio.curiora.com` and concurrent repository configuration were preserved.

### Curio-Mac

- `Curio.xcodeproj/project.pbxproj`
- `Curio/App/CurioApp.swift`
- `Curio/Curio.entitlements`
- `Curio/DesignSystem/Controls.swift`
- `Curio/DesignSystem/CurioraTokens.swift`
- `Curio/DesignSystem/InteractionIcon.swift` (new)
- `Curio/DesignSystem/LiquidMotion.swift` (new)
- `Curio/NativeServices/NativeServiceBoundary.swift`
- `Curio/NativeServices/Attachments.swift` (new)
- `Curio/NativeServices/DictationService.swift` (new)
- `Curio/Networking/ConversationSearch.swift` (new)
- `Curio/Resources/Assets.xcassets/waterMiddle.colorset/Contents.json` (new)
- `Curio/State/WorkspaceState.swift`
- `Curio/UI/ComposerView.swift`
- `Curio/UI/SidebarView.swift`
- `Curio/UI/WorkspaceView.swift`
- `Curio/UI/ConversationSearchView.swift` (new)
- `CurioTests/WorkspaceTests.swift`
- `README.md`
- `docs/interaction-pass.md`, `docs/interaction-parity.html` (new)
- `docs/interaction-build-debug.log`, `docs/interaction-build-release.log`, `docs/interaction-tests.log`, `docs/interaction-web-tests.log` (verification artifacts)

Local screenshots live under the repository's already-ignored `docs/evidence/`: `resize-focus-before.jpg`, `resize-focus-after.jpg`, `interaction-attachment.jpg`, `interaction-native-search-dark.jpg`, `interaction-native-chat-dark.jpg`, `interaction-native-work-dark.jpg`, `interaction-web-chat-dark.png`, `interaction-web-work-dark.png`, `interaction-web-search-dark.png`, `interaction-web-search-narrow.png`. Build products and the disposable `build/attachment-check.txt` are ignored.

### Curio-Web

- `static/css/app.css`
- `static/js/app.js`
- `static/js/chat.js`
- `static/js/shell.js`
- `static/js/conversation-search.js` (new)
- `templates/components/sidebar.html`
- `templates/index.html`
- `tests/browser_checks.js`
- `tests/conversation-search.test.mjs` (new)

`app/routers/home.py` remains a pre-existing concurrent change, not part of this implementation. Append-only browser evidence remains in the existing ignored `test-results/` folder. No backend contracts were changed.
