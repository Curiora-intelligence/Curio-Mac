import SwiftUI

struct WorkspaceView: View {
    @Bindable var state: WorkspaceState
    let windowWidth: CGFloat
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing:0) {
                    Spacer(minLength:24)
                    VStack(spacing:0) {
                        Text(state.mode == .chat ? "Where should we begin?" : "What should we work on?")
                            .font(.system(size:Curiora.headingSize(windowWidth:windowWidth),weight:.medium))
                            .tracking(-0.035 * Curiora.headingSize(windowWidth:windowWidth))
                            .frame(maxWidth:.infinity).padding(.bottom,state.mode == .chat ? 36 : 28)
                            .accessibilityAddTraits(.isHeader)
                        ComposerView(state:state,mode:state.mode).id(state.mode)
                        if state.mode == .work {
                            VStack(alignment:.leading,spacing:0) {
                                Text("Task execution and file deliverables aren't connected yet.")
                                    .frame(minHeight:36,alignment:.center).padding(.vertical,12)
                                Text("Your task draft stays in this window.")
                            }
                            .font(.system(size:11)).foregroundStyle(Curiora.secondary)
                            .frame(maxWidth:.infinity,alignment:.leading).padding(.horizontal,4)
                        } else {
                            Text("Chat isn't connected yet. You can prepare a draft.")
                                .font(.system(size:11)).foregroundStyle(Curiora.secondary)
                                .frame(height:19).padding(.top,6)
                        }
                        if let notice = state.notice {
                            HStack(spacing:8) {
                                Text(notice).font(.system(size:12)).frame(maxWidth:.infinity,alignment:.leading)
                                IconButton(icon:.close,label:"Dismiss message",size:28,iconSize:16) { state.notice = nil }
                            }.padding(10).background(Curiora.surface,in:RoundedRectangle(cornerRadius:12)).padding(.top,12)
                                .accessibilityIdentifier("availability-notice")
                        }
                    }.frame(maxWidth:Curiora.contentWidth)
                    Spacer(minLength:24)
                    if state.mode == .chat { Spacer(minLength:0) }
                }
                .padding(.horizontal,windowWidth <= 760 ? 16 : 28)
                .frame(maxWidth:.infinity,minHeight:geometry.size.height)
            }.scrollBounceBehavior(.basedOnSize)
        }.accessibilityElement(children:.contain).accessibilityLabel(state.mode.rawValue)
    }
}

struct RootView: View {
    @Bindable var state: WorkspaceState
    @Environment(\.accessibilityReduceMotion) private var reducedMotion
    var body: some View {
        GeometryReader { geometry in
            let narrow = geometry.size.width <= Curiora.narrowBreakpoint
            ZStack(alignment:.leading) {
                HStack(spacing:0) {
                    if state.sidebarVisible && !narrow {
                        sidebar(width:state.sidebarWidth(for:geometry.size.width),windowWidth:geometry.size.width,narrow:false)
                    }
                    VStack(spacing:0) {
                        topbar(narrow:narrow)
                        WorkspaceView(state:state,windowWidth:geometry.size.width)
                    }.frame(maxWidth:.infinity,maxHeight:.infinity).background(Curiora.background)
                        .disabled(narrow && state.narrowSidebarOpen)
                        .accessibilityHidden(narrow && state.narrowSidebarOpen)
                }
                if narrow && state.narrowSidebarOpen {
                    Color.black.opacity(0.32).onTapGesture { state.narrowSidebarOpen = false }.accessibilityHidden(true)
                    sidebar(width:290,windowWidth:geometry.size.width,narrow:true)
                        .shadow(color:.black.opacity(0.12),radius:18,x:8)
                }
            }
            .onChange(of:narrow) { _,_ in state.narrowSidebarOpen = false }
            .onExitCommand { state.narrowSidebarOpen = false; state.notice = nil }
            .animation(reducedMotion ? nil : Curiora.layoutMotion,value:state.sidebarVisible)
            .animation(reducedMotion ? nil : Curiora.layoutMotion,value:state.narrowSidebarOpen)
            .onChange(of:state.toggleSidebarRequest) { _,_ in
                if narrow { state.narrowSidebarOpen.toggle() } else { state.sidebarVisible.toggle() }
            }
        }
        .foregroundStyle(Curiora.text).background(Curiora.background)
        .sheet(item:$state.destination) { destination in AvailabilitySheet(destination:destination) }
        .frame(minWidth:560,minHeight:420)
    }
    private func sidebar(width: CGFloat, windowWidth: CGFloat, narrow: Bool) -> some View {
        SidebarView(state:state,isOverlay:narrow) {
            if narrow { state.narrowSidebarOpen = false } else { state.sidebarVisible = false }
        }.frame(width:width)
            .overlay(alignment:.trailing) {
                if !narrow { SidebarResizeHandle(state:state,windowWidth:windowWidth) }
            }
            .transition(.move(edge:.leading).combined(with:.opacity))
    }
    private func topbar(narrow: Bool) -> some View {
        ZStack {
            HStack(spacing:8) {
                if narrow || !state.sidebarVisible {
                    IconButton(icon:.panel,label:"Open navigation") {
                        if narrow { state.narrowSidebarOpen = true } else { state.sidebarVisible = true }
                    }
                }
                if !narrow { Text("Curio").font(.system(size:13,weight:.medium)).foregroundStyle(Curiora.secondary) }
                Spacer()
                IconButton(icon:.temporary,label:"Temporary chat — unavailable") {
                    state.notice = "Temporary chat isn't available. No messages are sent or stored by this shell."
                }
            }
            WorkspaceSwitch(state:state)
        }.frame(height:72).padding(.horizontal, narrow ? 12 : 24)
    }
}

struct AvailabilitySheet: View {
    let destination: WorkspaceState.Destination
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(alignment:.leading,spacing:20) {
            HStack {
                Text(destination.rawValue).font(.title2.weight(.semibold)).accessibilityAddTraits(.isHeader)
                Spacer()
                Button("Done") { dismiss() }.keyboardShortcut(.defaultAction)
            }
            if destination == .settings {
                HStack(spacing:12) {
                    CurioMark().frame(width:40,height:40)
                    VStack(alignment:.leading) { Text("Curio by Curiora").font(.headline); Text("Native macOS foundation").foregroundStyle(Curiora.secondary) }
                }
                Text("No account is connected. Authentication and chat inference are not implemented yet.")
                Text("Appearance follows macOS. Reduce Motion and Increase Contrast follow Accessibility settings.")
                Text("Drafts stay in this window until you quit. Only sidebar width and thinking effort are saved on this Mac.")
            } else {
                Text(destination == .scheduled ? "Scheduled tasks aren't connected yet." : "Your library isn't connected yet.").font(.headline)
                Text(destination == .scheduled ? "Scheduling will require the shared Curiora backend. No tasks are running." : "Saved files and memory will appear here when the shared Curiora backend is connected.")
            }
        }.font(.system(size:13)).foregroundStyle(Curiora.text).padding(28).frame(width:460)
            .background(Curiora.background)
    }
}

