import Foundation

/// Interface boundary only. A future authenticated adapter must validate its
/// transport/session contract against the shared FastAPI backend before use.
/// Existing web references: POST /curio/runs (multipart, mode=general),
/// GET /curio/runs/{id}, GET /curio/runs/{id}/events (SSE),
/// GET /marketplace/history/conversations, GET /marketplace/conversations/{id}.
/// Thinking effort and Work are deliberately absent: no supported wire contract.
protocol CurioraBackend: Sendable {
    func submit(_ request: ChatRequest) async throws -> AcceptedRun
    func events(for run: AcceptedRun) -> AsyncThrowingStream<ConversationEvent, Error>
    func conversations() async throws -> [ConversationSummary]
}
struct ChatRequest: Sendable {
    let requestID: UUID
    let message: String
    let conversationID: String?
}
struct AcceptedRun: Sendable { let requestID: String }
struct ConversationSummary: Identifiable, Sendable { let id: String; let title: String }
enum ConversationEvent: Sendable {
    // Data, never executable instructions. Native services cannot consume this enum.
    case text(String)
    case status(String)
    case completed
}
enum BackendUnavailable: LocalizedError {
    case notConnected
    var errorDescription: String? { "The Curiora backend isn't connected in this native shell." }
}
struct DisconnectedBackend: CurioraBackend {
    func submit(_ request: ChatRequest) async throws -> AcceptedRun { throw BackendUnavailable.notConnected }
    func events(for run: AcceptedRun) -> AsyncThrowingStream<ConversationEvent, Error> {
        AsyncThrowingStream { $0.finish(throwing: BackendUnavailable.notConnected) }
    }
    func conversations() async throws -> [ConversationSummary] { throw BackendUnavailable.notConnected }
}
