import XCTest
import SwiftUI
import AppKit
import Speech
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
        let services = LocalNativeServices()
        XCTAssertFalse(services.executionAvailable)
        XCTAssertTrue(services.dictationAvailable)
        XCTAssertTrue(services.attachmentsAvailable)
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
            let box = LiquidFrame.travel(from:.rest(x:0),to:.rest(x:96),progress:progress).path.boundingRect
            XCTAssertTrue(box.minX.isFinite && box.maxX.isFinite)
            XCTAssertGreaterThanOrEqual(box.minX,-0.001)
            XCTAssertLessThanOrEqual(box.maxX,bounds.maxX+0.001)
            XCTAssertGreaterThanOrEqual(box.minY,-0.001)
            XCTAssertLessThanOrEqual(box.maxY,bounds.maxY+0.001)
        }
    }

    func testLiquidReversalInheritsEntireContourAndSettlesExactly() {
        let left = LiquidFrame.rest(x:0), right = LiquidFrame.rest(x:96)
        for t in [0.05,0.25,0.5,0.8,0.95] {
            let painted = LiquidFrame.travel(from:left,to:right,progress:t)
            XCTAssertEqual(LiquidFrame.travel(from:painted,to:left,progress:0),painted)
            XCTAssertEqual(LiquidFrame.travel(from:painted,to:left,progress:1),left)
            let next = LiquidFrame.travel(from:painted,to:left,progress:0.00001)
            XCTAssertEqual(next.x,painted.x,accuracy:0.001)
            XCTAssertEqual(next.width,painted.width,accuracy:0.001)
            for i in painted.points.indices { XCTAssertEqual(next.points[i],painted.points[i],accuracy:0.002) }
        }
        let mid = LiquidFrame.travel(from:left,to:right,progress:0.5)
        XCTAssertGreaterThan(mid.width,96*1.18)
        XCTAssertLessThan(mid.width,96*1.4)
        XCTAssertEqual(LiquidFrame.travel(from:right,to:left,progress:1),left)
    }
    func testSearchFindsAvailableMessagesAndNavigatesWithoutConsumingDraft() {
        let entries = [SearchConversation(id:"a",title:"Planning",messages:["The launch is on Thursday"]),SearchConversation(id:"b",title:"Research",messages:[],contentAvailable:false)]
        XCTAssertEqual(ConversationSearch.matches(entries,query:"thursday").map(\.id),["a"])
        XCTAssertEqual(ConversationSearch.matches(entries,query:" RESEARCH ").map(\.id),["b"])
        XCTAssertTrue(ConversationSearch.matches(entries,query:"absent").isEmpty)
        let (state,defaults,name) = isolatedState(); defer { defaults.removePersistentDomain(forName:name) }
        state.chatDraft = "Keep unsent text"; state.select(.work); state.openConversation(entries[0])
        XCTAssertEqual(state.mode,.chat); XCTAssertEqual(state.selectedConversation?.id,"a")
        XCTAssertEqual(state.chatDraft,"Keep unsent text")
    }
    func testDisconnectedSearchHasNoInventedResults() async throws {
        let catalog = try await DisconnectedConversationSource().catalog()
        XCTAssertTrue(catalog.conversations.isEmpty); XCTAssertTrue(catalog.status.contains("No account"))
    }
    func testAttachmentValidationAndRemovalLifecycle() throws {
        for invalid in [("secret.exe",10,true,false),("empty.txt",0,true,false),("large.pdf",AttachmentPolicy.maximumBytes+1,true,false),("link.txt",10,true,true),("folder.txt",10,false,false)] {
            XCTAssertThrowsError(try AttachmentPolicy.validate(name:invalid.0,bytes:invalid.1,regular:invalid.2,symbolicLink:invalid.3))
        }
        try AttachmentPolicy.validate(name:"notes.TXT",bytes:20,regular:true,symbolicLink:false)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString+".txt")
        try Data("Selection lifecycle test".utf8).write(to:url)
        defer { try? FileManager.default.removeItem(at:url) }
        let (state,defaults,name) = isolatedState(); defer { defaults.removePersistentDomain(forName:name) }
        state.addAttachments([url,url],mode:.chat)
        XCTAssertEqual(state.chatAttachments.count,1); XCTAssertTrue(state.workAttachments.isEmpty)
        weak var selected = state.chatAttachments.first
        let id = try XCTUnwrap(selected?.id)
        state.removeAttachment(id,mode:.chat)
        XCTAssertTrue(state.chatAttachments.isEmpty); XCTAssertNil(selected)
    }
    func testDictationCancelClearsOnlyTransientTranscript() {
        let service = DictationService(); service.transcript = "Transient words"; service.cancel()
        XCTAssertEqual(service.phase,.idle); XCTAssertEqual(service.transcript,""); XCTAssertFalse(service.active)
    }
    func testSpeechAuthorizationCallbackMayArriveOffMainActor() async {
        let status = await DictationService.speechAuthorization { callback in
            DispatchQueue.global().async { callback(.denied) }
        }
        XCTAssertEqual(status,.denied)
    }

}
