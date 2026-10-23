import SwiftUI

struct CurioraButtonStyle: ButtonStyle {
    var radius: CGFloat = 12
    var selected = false
    func makeBody(configuration: Configuration) -> some View {
        Surface(configuration: configuration, radius: radius, selected: selected)
    }
    private struct Surface: View {
        let configuration: Configuration
        let radius: CGFloat
        let selected: Bool
        @State private var hovered = false
        @Environment(\.isEnabled) private var enabled
        var body: some View {
            configuration.label
                .foregroundStyle(Curiora.text)
                .background(selected || configuration.isPressed ? Curiora.selected : hovered ? Curiora.hover : .clear,
                            in: RoundedRectangle(cornerRadius: radius))
                .contentShape(RoundedRectangle(cornerRadius: radius))
                .opacity(enabled ? 1 : 0.5)
                .onHover { hovered = $0 }
        }
    }
}

struct IconButton: View {
    let icon: CurioIcon.Kind
    let label: String
    var size: CGFloat = 36
    var iconSize: CGFloat = 20
    var primary = false
    var shortcut: KeyboardShortcut? = nil
    var action: () -> Void
    @FocusState private var focused: Bool
    @State private var hovered = false
    var body: some View {
        Button(action: action) {
            Group {
                if icon == .voice { VoiceWave(active:hovered || focused) }
                else { CurioIcon(kind:icon,size:iconSize) }
            }
                .foregroundStyle(primary ? .white : Curiora.secondary)
                .frame(width:size,height:size)
                .background(primary ? Curiora.primary : .clear,in:Circle())
        }
        .buttonStyle(CurioraButtonStyle(radius: size/2))
        .keyboardShortcut(shortcut)
        .focused($focused)
        .onHover { hovered = $0 }
        .overlay(Circle().stroke(focused ? Curiora.accent : .clear,lineWidth:2).padding(-2))
        .accessibilityLabel(label).help(label)
    }
}

struct WorkspaceSwitch: View {
    @Bindable var state: WorkspaceState
    @Environment(\.accessibilityReduceMotion) private var reducedMotion
    @FocusState private var focused: WorkspaceState.Mode?
    @State private var liquid = LiquidMotion()
    var body: some View {
        ZStack {
            Capsule().fill(Curiora.segmentShell)
            LiquidSurface(frame:liquid.frame).frame(width:192,height:32).allowsHitTesting(false)
            HStack(spacing:0) {
                ForEach(WorkspaceState.Mode.allCases) { mode in
                    Button { state.select(mode); focused = mode } label: {
                        Text(mode.rawValue).font(.system(size:13,weight:.medium))
                            .foregroundStyle(state.mode == mode ? Curiora.text : Curiora.secondary)
                            .frame(maxWidth:.infinity).frame(height:32)
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain).focused($focused,equals:mode)
                    .overlay(Capsule().stroke(focused == mode ? Curiora.accent : .clear,lineWidth:2))
                    .accessibilityIdentifier("mode-\(mode.rawValue.lowercased())")
                    .accessibilityAddTraits(state.mode == mode ? [.isSelected] : [])
                    .accessibilityHint(mode == .work ? "Prepare a task draft. Execution is not connected." : "Ask questions, learn, and explore ideas.")
                }
            }.padding(4)
        }.frame(width:200,height:40)
            .overlay(Capsule().stroke(Curiora.border,lineWidth:1))
            .accessibilityElement(children:.contain).accessibilityLabel("Workspace")
            .onAppear { liquid.select(work:state.mode == .work,reduced:true) }
            .onChange(of:state.mode) { _,mode in liquid.select(work:mode == .work,reduced:reducedMotion) }
            .onChange(of:reducedMotion) { _,_ in liquid.select(work:state.mode == .work,reduced:true) }
            .onDisappear { liquid.stop() }
            .onKeyPress(.leftArrow) { state.select(.chat); focused = .chat; return .handled }
            .onKeyPress(.rightArrow) { state.select(.work); focused = .work; return .handled }
    }
}
