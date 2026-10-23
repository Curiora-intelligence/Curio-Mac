import SwiftUI

struct ConversationSearchView: View {
    @Bindable var state: WorkspaceState
    @State private var catalog: ConversationCatalog?
    @State private var error: String?
    @State private var loading = true
    @FocusState private var focused: Bool
    private var results: [SearchConversation] { ConversationSearch.matches(catalog?.conversations ?? [],query:state.search) }
    var body: some View {
        VStack(alignment:.leading,spacing:16) {
            HStack {
                Text("Search conversations").font(.title3.weight(.semibold)).accessibilityAddTraits(.isHeader)
                Spacer()
                Button("Done") { state.searchVisible = false }.keyboardShortcut(.cancelAction)
            }
            TextField("Search titles and available messages",text:$state.search).textFieldStyle(.roundedBorder).focused($focused)
                .accessibilityLabel("Search conversations")
            if loading { ProgressView("Loading conversations…") }
            else if let error {
                Text(error).foregroundStyle(Curiora.secondary)
                Button("Try again") { Task { await load() } }
            } else {
                Text(catalog?.status ?? "").font(.caption).foregroundStyle(Curiora.secondary)
                if results.isEmpty { Text(state.search.isEmpty ? "No conversations available" : "No matching conversations").padding(.vertical,24) }
                if !results.isEmpty { ScrollView {
                    LazyVStack(alignment:.leading,spacing:4) {
                        ForEach(results) { conversation in
                            Button {
                                state.openConversation(conversation); state.searchVisible = false
                            } label: {
                                VStack(alignment:.leading,spacing:4) {
                                    Text(conversation.title).font(.headline)
                                    Text(conversation.contentAvailable ? (conversation.messages.first ?? "No messages") : "Only the title is available on this Mac.")
                                        .font(.caption).lineLimit(2).foregroundStyle(Curiora.secondary)
                                }.frame(maxWidth:.infinity,alignment:.leading).padding(12)
                            }.buttonStyle(CurioraButtonStyle())
                        }
                    }
                }.frame(maxHeight:280) }
            }
        }.padding(24).frame(maxWidth:560).frame(minHeight:240)
            .background(Curiora.elevated,in:RoundedRectangle(cornerRadius:20))
            .overlay(RoundedRectangle(cornerRadius:20).stroke(Curiora.border))
            .shadow(color:.black.opacity(0.2),radius:30,y:10)
            .accessibilityAddTraits(.isModal)
            .onExitCommand { state.searchVisible = false }
            .defaultFocus($focused,true)
            .task { await load(); await Task.yield(); focused = true }
    }
    private func load() async {
        loading = true; error = nil
        do { let result = try await state.conversationSource.catalog(); guard !Task.isCancelled else { return }; catalog = result }
        catch { self.error = "Conversations couldn't be loaded. \(error.localizedDescription)" }
        loading = false
    }
}
