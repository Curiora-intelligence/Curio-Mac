import SwiftUI

/// Hand-drawn paths from Curio-Web/templates/components/icons.html.
/// Keep the product's 24-unit grid and 1.65-unit rounded stroke.
struct CurioIcon: View {
    enum Kind { case panel, search, edit, library, clock, plus, microphone, arrow, voice, chevron, close, temporary }
    let kind: Kind
    var size: CGFloat = 20
    var body: some View {
        Canvas { context, canvasSize in
            context.scaleBy(x: canvasSize.width / 24, y: canvasSize.height / 24)
            var p = Path()
            func line(_ points: CGPoint...) {
                guard let first = points.first else { return }
                p.move(to: first); for point in points.dropFirst() { p.addLine(to: point) }
            }
            func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat) {
                p.addRoundedRect(in: CGRect(x: x, y: y, width: w, height: h), cornerSize: CGSize(width: r, height: r))
            }
            switch kind {
            case .panel: rect(3,4,18,16,3); line(.init(x:9,y:4),.init(x:9,y:20))
            case .search:
                p.addEllipse(in: CGRect(x:4,y:4,width:13,height:13)); line(.init(x:16,y:16),.init(x:20,y:20))
            case .edit:
                p.move(to:.init(x:12,y:5)); p.addLine(to:.init(x:6,y:5)); p.addQuadCurve(to:.init(x:3,y:8),control:.init(x:3,y:5)); p.addLine(to:.init(x:3,y:18)); p.addQuadCurve(to:.init(x:6,y:21),control:.init(x:3,y:21)); p.addLine(to:.init(x:16,y:21)); p.addQuadCurve(to:.init(x:19,y:18),control:.init(x:19,y:21)); p.addLine(to:.init(x:19,y:12))
                line(.init(x:10,y:14),.init(x:11,y:10),.init(x:19,y:2),.init(x:22,y:5),.init(x:14,y:13),.init(x:10,y:14))
            case .library:
                rect(4,3,16,18,3); line(.init(x:9,y:3),.init(x:9,y:21)); line(.init(x:13,y:8),.init(x:16,y:8)); line(.init(x:13,y:12),.init(x:16,y:12))
            case .clock:
                p.addEllipse(in:CGRect(x:3,y:3,width:18,height:18)); line(.init(x:12,y:7),.init(x:12,y:12),.init(x:15,y:14))
            case .plus: line(.init(x:12,y:5),.init(x:12,y:19)); line(.init(x:5,y:12),.init(x:19,y:12))
            case .microphone:
                rect(9,3,6,11,3); p.move(to:.init(x:5,y:11)); p.addLine(to:.init(x:5,y:12)); p.addCurve(to:.init(x:19,y:12), control1:.init(x:5,y:21.33),control2:.init(x:19,y:21.33)); p.addLine(to:.init(x:19,y:11)); line(.init(x:12,y:19),.init(x:12,y:22)); line(.init(x:8,y:22),.init(x:16,y:22))
            case .arrow: line(.init(x:12,y:19),.init(x:12,y:5)); line(.init(x:6,y:11),.init(x:12,y:5),.init(x:18,y:11))
            case .voice:
                for (x,h) in [(4.25,3.5),(8.125,9.75),(12.0,16.5),(15.875,9.75),(19.75,3.5)] { line(.init(x:x,y:12-h/2),.init(x:x,y:12+h/2)) }
            case .chevron: line(.init(x:8,y:10),.init(x:12,y:14),.init(x:16,y:10))
            case .close: line(.init(x:6,y:6),.init(x:18,y:18)); line(.init(x:6,y:18),.init(x:18,y:6))
            case .temporary:
                for angle in stride(from: -90.0, to: 250.0, by: 55) {
                    p.move(to:.init(x:12+9*cos(angle * .pi/180),y:12+9*sin(angle * .pi/180)))
                    p.addArc(center:.init(x:12,y:12),radius:9,startAngle:.degrees(angle),endAngle:.degrees(angle+28),clockwise:false)
                }
                line(.init(x:8,y:20),.init(x:3,y:21),.init(x:4,y:16))
            }
            context.stroke(p, with: .foreground, style: StrokeStyle(lineWidth: kind == .voice ? 1.8 : 1.65, lineCap:.round,lineJoin:.round))
        }.frame(width:size,height:size).accessibilityHidden(true)
    }
}

struct CurioMark: View {
    var body: some View {
        Canvas { context, size in
            context.scaleBy(x:size.width/40,y:size.height/40)
            context.fill(Path(roundedRect:CGRect(x:0,y:0,width:40,height:40),cornerRadius:13),with:.color(Color(red:0,green:113.0/255,blue:227.0/255)))
            var p = Path()
            p.addArc(center:.init(x:19.515,y:20),radius:11,startAngle:.degrees(-39.52),endAngle:.degrees(-320.48),clockwise:true)
            p.move(to:.init(x:28,y:13)); p.addLine(to:.init(x:28,y:19)); p.addLine(to:.init(x:22,y:19))
            context.stroke(p,with:.color(.white),style:StrokeStyle(lineWidth:3.2,lineCap:.round,lineJoin:.round))
        }.accessibilityHidden(true)
    }
}
