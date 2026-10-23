import Foundation

struct SearchConversation: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let messages: [String]
    var contentAvailable: Bool = true
}
struct ConversationCatalog: Sendable {
    var conversations: [SearchConversation]
    var status: String
}
/// Future authenticated adapters return only conversations authorized for their
/// current identity. No guessed search endpoint or automatic bulk transcript fetch.
protocol ConversationSearchSource: Sendable {
    func catalog() async throws -> ConversationCatalog
}
struct DisconnectedConversationSource: ConversationSearchSource {
    func catalog() async throws -> ConversationCatalog {
        ConversationCatalog(conversations:[],status:"No account or conversation history is connected on this Mac yet.")
    }
}
enum ConversationSearch {
    static func matches(_ entries: [SearchConversation], query: String) -> [SearchConversation] {
        let query = query.trimmingCharacters(in:.whitespacesAndNewlines)
        return entries.filter { query.isEmpty || $0.title.localizedStandardContains(query) || $0.messages.contains { $0.localizedStandardContains(query) } }
    }
}
