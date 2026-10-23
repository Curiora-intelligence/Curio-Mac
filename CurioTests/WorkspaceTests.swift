import XCTest
import SwiftUI
import AppKit
@testable import Curio

@MainActor final class WorkspaceTests: XCTestCase {
    func isolatedState() -> (WorkspaceState, UserDefaults, String) {
        let name = "CurioTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName:name)!
        return (WorkspaceState(preferences:defaults),defaults,name)
    }
    func testDraftsSurviveModeSwitchAndNewChat() {
        let (state,defaults,name) = isolatedState(); defer { defaults.removePersistentDomain(forName:name) }
        state.chatDraft = "Unsent question"; state.workDraft = "Unsent task"
        state.select(.work); state.newChat()
        XCTAssertEqual(state.mode,.chat)
        XCTAssertEqual(state.chatDraft,"Unsent question")
        XCTAssertEqual(state.workDraft,"Unsent task")
    }
    func testSidebarBoundsPersistenceAndViewportRecovery() {
        let (state,defaults,name) = isolatedState(); defer { defaults.removePersistentDomain(forName:name) }
        state.resizeSidebar(to:999,windowWidth:1200)
        XCTAssertEqual(state.sidebarWidth(for:1200),420)
        XCTAssertEqual(state.sidebarWidth(for:800),320)
        XCTAssertEqual(state.sidebarWidth(for:1200),420)
        XCTAssertEqual(WorkspaceState(preferences:defaults).preferredSidebarWidth,420)
        state.resizeSidebar(to:-5,windowWidth:1200)
        XCTAssertEqual(state.preferredSidebarWidth,252)
        state.resizeSidebar(to:.infinity,windowWidth:1200)
        XCTAssertEqual(state.preferredSidebarWidth,252)
    }
    func testUnavailableActionDoesNotConsumeDraft() {
        let (state,defaults,name) = isolatedState(); defer { defaults.removePersistentDomain(forName:name) }
        state.chatDraft = "Keep this"
        state.explainUnavailable("Chat inference")
        XCTAssertEqual(state.chatDraft,"Keep this")
        XCTAssertTrue(state.notice?.contains("isn't connected") == true)
        state.effort = .high
        XCTAssertEqual(WorkspaceState(preferences:defaults).effort,.high)
    }
    func testBackendFailsClosed() async {
        let backend = DisconnectedBackend()
        do { _ = try await backend.submit(ChatRequest(requestID:UUID(),message:"Hello",conversationID:nil)); XCTFail("Disconnected backend accepted a request") }
        catch { XCTAssertTrue(error is BackendUnavailable) }
        do { for try await _ in backend.events(for:AcceptedRun(requestID:"test")) { XCTFail("Produced a model event") }; XCTFail("Stream succeeded") }
        catch { XCTAssertTrue(error is BackendUnavailable) }
        do { _ = try await backend.conversations(); XCTFail("Invented history") }
        catch { XCTAssertTrue(error is BackendUnavailable) }
    }
    func testNativeExecutionUnavailable() {
        let services = UnconnectedNativeServices()
        XCTAssertFalse(services.executionAvailable)
        XCTAssertFalse(services.dictationAvailable)
        XCTAssertFalse(services.attachmentsAvailable)
    }
    func testBrandAssetsRemainOpaqueInBothAppearances() {
        for name in ["background", "text", "primary", "sidebar"] {
            let color = NSColor(named:name, bundle:Bundle.main)
            XCTAssertNotNil(color, "Missing token: \(name)")
            for appearance in [NSAppearance.Name.aqua, .darkAqua] {
                NSAppearance(named:appearance)!.performAsCurrentDrawingAppearance {
                    XCTAssertEqual(color?.usingColorSpace(.sRGB)?.alphaComponent ?? 0, 1, accuracy:0.001)
                }
            }
        }
    }
    func testLiquidSelectionRemainsContainedDuringTravel() {
        let bounds = CGRect(x:0,y:0,width:192,height:32)
        for progress in stride(from:0.0,through:1.0,by:0.01) {
            let box = LiquidSelection(progress:progress).path(in:bounds).boundingRect
            XCTAssertTrue(box.minX.isFinite && box.maxX.isFinite)
            XCTAssertGreaterThanOrEqual(box.minX,-0.001)
            XCTAssertLessThanOrEqual(box.maxX,bounds.maxX+0.001)
            XCTAssertGreaterThanOrEqual(box.minY,-0.001)
            XCTAssertLessThanOrEqual(box.maxY,bounds.maxY+0.001)
        }
    }

}
