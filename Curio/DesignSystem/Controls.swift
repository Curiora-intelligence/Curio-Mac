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
    var body: some View {
        Button(action: action) {
            CurioIcon(kind: icon, size: iconSize)
                .foregroundStyle(primary ? .white : Curiora.secondary)
                .frame(width:size,height:size)
                .background(primary ? Curiora.primary : .clear,in:Circle())
        }
        .buttonStyle(CurioraButtonStyle(radius: size/2))
        .keyboardShortcut(shortcut)
        .focused($focused)
        .overlay(Circle().stroke(focused ? Curiora.accent : .clear,lineWidth:2).padding(-2))
        .accessibilityLabel(label).help(label)
    }
}

struct WorkspaceSwitch: View {
    @Bindable var state: WorkspaceState
    @Environment(\.accessibilityReduceMotion) private var reducedMotion
    @FocusState private var focused: WorkspaceState.Mode?
    var body: some View {
        ZStack {
            Capsule().fill(Curiora.segmentShell)
            LiquidSelection(progress: state.mode == .chat ? 0 : 1)
                .fill(LinearGradient(colors:[Curiora.waterTop,Curiora.waterBottom],startPoint:.topLeading,endPoint:.bottomTrailing))
                .overlay(LiquidSelection(progress:state.mode == .chat ? 0 : 1).stroke(Curiora.border,lineWidth:1))
                .padding(4)
                .animation(reducedMotion ? nil : Curiora.selectionMotion,value:state.mode)
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
            .onKeyPress(.leftArrow) { state.select(.chat); focused = .chat; return .handled }
            .onKeyPress(.rightArrow) { state.select(.work); focused = .work; return .handled }
    }
}

/// A single native animatable contour. Leading and trailing edges separate in
/// transit, forming a small waist and settling to a stadium. No JS or idle timer.
struct LiquidSelection: Shape {
    var progress: CGFloat
    var animatableData: CGFloat { get { progress } set { progress = newValue } }
    func path(in rect: CGRect) -> Path {
        guard rect.width > 0, rect.height > 0 else { return Path() }
        let p = min(1,max(0,progress)), bulge = sin(p * .pi)
        let width = rect.width / 2, extensionWidth = width * 0.24 * bulge
        let left = max(0,min(rect.width-width-extensionWidth,p*width-extensionWidth/2))
        let right = left + width + extensionWidth, r = rect.height/2
        let waist = 2.0 * bulge, middle = (left+right)/2, k = r*0.5522848
        var path = Path()
        path.move(to:.init(x:left+r,y:0))
        path.addQuadCurve(to:.init(x:middle,y:waist),control:.init(x:middle-12,y:0))
        path.addQuadCurve(to:.init(x:right-r,y:0),control:.init(x:middle+12,y:0))
        path.addCurve(to:.init(x:right,y:r),control1:.init(x:right-r+k,y:0),control2:.init(x:right,y:r-k))
        path.addCurve(to:.init(x:right-r,y:2*r),control1:.init(x:right,y:r+k),control2:.init(x:right-r+k,y:2*r))
        path.addQuadCurve(to:.init(x:middle,y:2*r-waist),control:.init(x:middle+12,y:2*r))
        path.addQuadCurve(to:.init(x:left+r,y:2*r),control:.init(x:middle-12,y:2*r))
        path.addCurve(to:.init(x:left,y:r),control1:.init(x:left+r-k,y:2*r),control2:.init(x:left,y:r+k))
        path.addCurve(to:.init(x:left+r,y:0),control1:.init(x:left,y:r-k),control2:.init(x:left+r-k,y:0))
        path.closeSubpath(); return path
    }
}
