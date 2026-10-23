import SwiftUI

/// Bounded responses to real hover/focus. No idle loops or fake audio levels.
struct InteractionIcon: View {
    let kind: CurioIcon.Kind
    var active = false
    var size: CGFloat = 20
    @Environment(\.accessibilityReduceMotion) private var reduced
    @State private var hovered = false
    var body: some View {
        let responds = !reduced && (active || hovered)
        CurioIcon(kind:kind,size:size)
            .rotationEffect(.degrees(responds ? (kind == .clock ? -12 : kind == .edit ? -6 : 0) : 0))
            .offset(y:responds && kind == .library ? -1.5 : 0)
            .animation(reduced ? nil : .easeOut(duration:0.18),value:responds)
            .onHover { hovered = $0 }
    }
}
struct VoiceWave: View {
    var active: Bool
    @Environment(\.accessibilityReduceMotion) private var reduced
    var body: some View {
        HStack(spacing:0) {
            ForEach(0..<5) { i in
                let heights: [CGFloat] = [3.5,9.75,16.5,9.75,3.5]
                let scales: [CGFloat] = [2.1,0.56,0.62,0.56,2.1]
                let delays = [0.0,0.035,0.070,0.035,0.0]
                Capsule().frame(width:1.5,height:heights[i]*20/24)
                    .keyframeAnimator(initialValue:CGFloat(1),trigger:active && !reduced) { content,value in
                        content.scaleEffect(x:1,y:value)
                    } keyframes: { _ in
                        if active && !reduced {
                            LinearKeyframe(1,duration:delays[i])
                            CubicKeyframe(scales[i],duration:0.134)
                            CubicKeyframe(1,duration:0.186)
                        } else { LinearKeyframe(1,duration:0) }
                    }
                    .frame(width:3.23,height:20)

            }
        }.frame(width:20,height:20).accessibilityHidden(true)
    }
}

struct NavigationRow: View {
    let title: String
    let icon: CurioIcon.Kind
    let action: () -> Void
    @State private var hovered = false
    @FocusState private var focused: Bool
    var body: some View {
        Button(action:action) {
            HStack(spacing:10) {
                InteractionIcon(kind:icon,active:hovered || focused)
                Text(title).font(.system(size:13,weight:title == "New chat" ? .medium : .regular))
                Spacer(minLength:0)
            }.padding(.horizontal,12).frame(height:42)
        }.buttonStyle(CurioraButtonStyle()).focused($focused).onHover { hovered = $0 }
            .accessibilityIdentifier("nav-\(title)")
    }
}
