import SwiftUI

struct ComposerView: View {
    @Bindable var state: WorkspaceState
    let mode: WorkspaceState.Mode
    @FocusState private var inputFocused: Bool
    private var isWork: Bool { mode == .work }
    private var draft: Binding<String> { isWork ? $state.workDraft : $state.chatDraft }
    private var hasDraft: Bool { !draft.wrappedValue.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty }
    var body: some View {
        VStack(spacing:0) {
            if isWork {
                editor.frame(minHeight:114,alignment:.topLeading)
                HStack(spacing:4) { capabilities; Spacer(minLength:0); effort; microphone; primaryAction }
            } else {
                HStack(alignment:.bottom,spacing:4) { capabilities; editor; effort; microphone; primaryAction }
            }
        }
        .padding(.horizontal,isWork ? 10 : 6).padding(.vertical,isWork ? 8 : 5)
        .background(Curiora.glass,in:RoundedRectangle(cornerRadius:isWork ? 32 : 25))
        .overlay(RoundedRectangle(cornerRadius:isWork ? 32 : 25).stroke(Curiora.border,lineWidth:1))
        .overlay(RoundedRectangle(cornerRadius:isWork ? 34 : 27).stroke(inputFocused ? Curiora.focusNeutral : .clear,lineWidth:2).padding(-3))
        .shadow(color:.black.opacity(0.045),radius:12,y:6)
        .onChange(of:state.focusComposer) { _,_ in inputFocused = true }
        .onChange(of:draft.wrappedValue) { _,newValue in
            if newValue.count > Curiora.maximumDraftLength { draft.wrappedValue = String(newValue.prefix(Curiora.maximumDraftLength)) }
        }
        .onDisappear { inputFocused = false }
    }
    private var editor: some View {
        TextField(isWork ? "Describe a task for Curio" : "Ask Curio anything…",text:draft,axis:.vertical)
            .textFieldStyle(.plain).font(.system(size:16)).foregroundStyle(Curiora.text)
            .lineLimit(isWork ? 4...7 : 1...7)
            .padding(.horizontal,4).padding(.vertical,isWork ? 10 : 7)
            .frame(minHeight:isWork ? 114 : 44,alignment:isWork ? .topLeading : .center)
            .focused($inputFocused)
            .accessibilityLabel(isWork ? "Task draft" : "Message Curio")
            .accessibilityIdentifier(isWork ? "work-draft" : "chat-draft")
            .onKeyPress(keys:[.return]) { press in
                if press.modifiers.contains(.shift) { return .ignored }
                state.explainUnavailable(isWork ? "Task execution" : "Chat inference"); return .handled
            }
    }
    private var capabilities: some View {
        Menu {
            Section("Capabilities — not connected") {
                Label("Add photos & files — unavailable",systemImage:"photo").disabled(true)
                Label("Add from library — unavailable",systemImage:"books.vertical").disabled(true)
                Label("Create image — unavailable",systemImage:"photo.badge.plus").disabled(true)
                Label("Web search — unavailable",systemImage:"globe").disabled(true)
                Text("GitHub — unavailable")
                Label("Gmail — unavailable",systemImage:"envelope").disabled(true)
            }
        } label: { Image(systemName:"plus").font(.system(size:17,weight:.regular)) }
            .menuStyle(.borderlessButton).menuIndicator(.hidden).frame(width:isWork ? 42 : 36,height:isWork ? 42 : 36)
            .foregroundStyle(Curiora.secondary).accessibilityLabel("Open capabilities").help("Capabilities are not connected yet")
    }
    private var effort: some View {
        Menu {
            Picker("Thinking effort",selection:$state.effort) {
                ForEach(WorkspaceState.Effort.allCases,id:\.self) { Text($0.rawValue).tag($0) }
            }.pickerStyle(.inline)
            Divider()
            Text("Preference only. Not applied to responses yet.")
        } label: {
            Text(state.effort.rawValue).font(.system(size:13)).foregroundStyle(Curiora.secondary)
        }.menuStyle(.borderlessButton).menuIndicator(.visible).frame(width:88,height:36)
            .accessibilityLabel("Thinking effort: \(state.effort.rawValue)")
            .help("Thinking effort. Preference only. Not applied to responses yet.")
    }
    private var microphone: some View {
        IconButton(icon:.microphone,label:"Dictation — not connected",size:isWork ? 42 : 36) { state.explainUnavailable("Dictation") }
    }
    private var primaryAction: some View {
        IconButton(icon:isWork || hasDraft ? .arrow : .voice,
                   label:isWork ? "Work execution is not available" : hasDraft ? "Send message — not connected" : "Curio Speak — not connected",
                   size:isWork ? 42 : 36,primary:true) {
            state.explainUnavailable(hasDraft ? "Chat inference" : "Curio Speak")
        }.disabled(isWork)
    }
}
