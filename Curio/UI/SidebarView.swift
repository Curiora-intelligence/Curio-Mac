import SwiftUI

struct SidebarView: View {
    @Bindable var state: WorkspaceState
    var isOverlay = false
    let close: () -> Void
    @FocusState private var searchFocused: Bool
    var body: some View {
        VStack(spacing:4) {
            HStack(spacing:8) {
                Button { state.newChat() } label: {
                    HStack(spacing:9) {
                        CurioMark().frame(width:26,height:26)
                        Text("curio").font(.system(size:23,weight:.semibold)).tracking(-1.15)
                    }
                }.buttonStyle(.plain).accessibilityLabel("Curio home")
                Spacer(minLength:0)
                HStack(spacing:0) {
                    IconButton(icon:.search,label:"Search conversations",size:32,iconSize:18) {
                        state.searchVisible.toggle(); searchFocused = state.searchVisible
                    }
                    IconButton(icon:.panel,label:"Collapse navigation",size:32,iconSize:18,shortcut:isOverlay ? .cancelAction : nil,action:close)
                }
            }.frame(height:36).padding(.leading,8).padding(.trailing,2).padding(.bottom,19)
            VStack(spacing:3) {
                navigation("New chat",icon:.edit) { state.newChat() }.padding(.bottom,8)
                navigation("Scheduled",icon:.clock) { state.destination = .scheduled }
                navigation("Library",icon:.library) { state.destination = .library }
            }
            if state.searchVisible {
                TextField("Search conversations",text:$state.search)
                    .textFieldStyle(.roundedBorder).font(.system(size:12)).focused($searchFocused)
                    .padding(.horizontal,4).padding(.top,12)
            }
            Text("Recents").font(.system(size:11,weight:.medium)).foregroundStyle(Curiora.secondary)
                .frame(maxWidth:.infinity,alignment:.leading).padding(.leading,12).padding(.top,27).padding(.bottom,10)
            ScrollView {
                Text(state.search.isEmpty ? "No conversations yet" : "No matching conversations")
                    .font(.system(size:12)).foregroundStyle(Curiora.secondary)
                    .frame(maxWidth:.infinity,alignment:.leading).padding(.horizontal,12).padding(.top,8)
            }.accessibilityLabel("Recents")
            Rectangle().fill(Curiora.border).frame(height:1)
            Button { state.destination = .settings } label: {
                HStack(spacing:11) {
                    Text("C").font(.system(size:14,weight:.semibold)).foregroundStyle(Curiora.accentText)
                        .frame(width:34,height:34).background(Curiora.accentSurface,in:Circle())
                    VStack(alignment:.leading,spacing:2) {
                        Text("Your space").font(.system(size:12,weight:.medium))
                        Text("Not connected").font(.system(size:11)).foregroundStyle(Curiora.secondary)
                    }
                    Spacer()
                }.padding(.horizontal,8).padding(.vertical,9)
            }.buttonStyle(CurioraButtonStyle()).padding(.top,6).accessibilityLabel("Open profile and settings")
        }
        .padding(.horizontal,12).padding(.top,18).padding(.bottom,12)
        .background(Curiora.sidebar)
        .overlay(alignment:.trailing) { Rectangle().fill(Curiora.border).frame(width:1) }
        .accessibilityElement(children:.contain).accessibilityLabel("Main navigation")
    }
    private func navigation(_ title: String, icon: CurioIcon.Kind, action: @escaping () -> Void) -> some View {
        Button(action:action) {
            HStack(spacing:10) {
                CurioIcon(kind:icon)
                Text(title).font(.system(size:13,weight:title == "New chat" ? .medium : .regular))
                Spacer(minLength:0)
            }.padding(.horizontal,12).frame(height:42)
        }.buttonStyle(CurioraButtonStyle()).accessibilityIdentifier("nav-\(title)")
    }
}

struct SidebarResizeHandle: View {
    @Bindable var state: WorkspaceState
    let windowWidth: CGFloat
    @State private var dragOrigin: CGFloat?
    @State private var hovering = false
    @FocusState private var focused: Bool
    var body: some View {
        RoundedRectangle(cornerRadius:4).fill(hovering || focused || dragOrigin != nil ? Curiora.secondary.opacity(0.3) : .clear)
            .padding(.horizontal,3).padding(.vertical,8).frame(width:10)
            .contentShape(Rectangle()).focusable().focused($focused)
            .accessibilityLabel("Resize navigation")
            .accessibilityValue("\(Int(state.sidebarWidth(for:windowWidth))) points")
            .accessibilityHint("Left and Right arrows resize. Return resets to 270 points.")
            .accessibilityAdjustableAction { direction in
                state.resizeSidebar(to:state.sidebarWidth(for:windowWidth)+(direction == .increment ? 10 : -10),windowWidth:windowWidth)
            }
            .onHover { hovering = $0; if $0 { NSCursor.resizeLeftRight.push() } else { NSCursor.pop() } }
            .onDisappear { if hovering { NSCursor.pop() } }
            .onKeyPress(keys:[.leftArrow,.rightArrow,.return,.home,.end]) { press in
                let step: CGFloat = press.modifiers.contains(.shift) ? 40 : 10
                var value = state.sidebarWidth(for:windowWidth)
                switch press.key {
                case .leftArrow: value -= step
                case .rightArrow: value += step
                case .home: value = 252
                case .end: value = 420
                default: value = 270
                }
                state.resizeSidebar(to:value,windowWidth:windowWidth); return .handled
            }
            .onTapGesture(count:2) { state.resizeSidebar(to:270,windowWidth:windowWidth); focused = true }
            .onTapGesture { focused = true }
            .gesture(DragGesture(minimumDistance:1,coordinateSpace:.global)
                .onChanged { value in
                    if dragOrigin == nil { dragOrigin = state.sidebarWidth(for:windowWidth) }
                    state.resizeSidebar(to:(dragOrigin ?? 270)+value.translation.width,windowWidth:windowWidth)
                }.onEnded { _ in dragOrigin = nil })
            .help("Drag to resize. Double-click or press Return to reset.")
    }
}
