import SwiftUI

/// Native numeric translation of the approved Curiora contour and edge timing.
/// Positions and control points are retained together when direction reverses.
struct LiquidFrame: Equatable {
    var x: CGFloat
    var width: CGFloat
    var points: [CGFloat]
    static func rest(x: CGFloat, width: CGFloat = 96, height: CGFloat = 32) -> Self {
        Self(x:x,width:width,points:outline(width:width,height:height))
    }
    static func smooth(_ n: CGFloat) -> CGFloat { let t = min(1,max(0,n)); return t*t*(3-2*t) }
    static func outline(width: CGFloat, height: CGFloat, amount: CGFloat = 0, direction: CGFloat = 1) -> [CGFloat] {
        let r = min(height/2-1,width/2-1), a = min(1,max(0,amount)), cy = height/2
        var tail = r*(1-0.24*a), head = r*(1-0.015*a)
        if direction < 0 { swap(&tail,&head) }
        let left = 1+tail, right = width-1-head, mid = (left+right)/2
        let tt = cy-tail, th = cy-head, bt = cy+tail, bh = cy+head
        let wt = (tt+th)/2+height*0.045*a, wb = (bt+bh)/2-height*0.025*a, k = 0.55228475
        return [left,tt,
                left+(mid-left)*0.55,tt, mid-(mid-left)*0.35,wt, mid,wt,
                mid+(right-mid)*0.35,wt, right-(right-mid)*0.55,th, right,th,
                right+head*k,th, width-1,cy-head*k, width-1,cy,
                width-1,cy+head*k, right+head*k,bh, right,bh,
                right-(right-mid)*0.55,bh, mid+(right-mid)*0.35,wb, mid,wb,
                mid-(mid-left)*0.35,wb, left+(mid-left)*0.55,bt, left,bt,
                left-tail*k,bt, 1,cy+tail*k, 1,cy,
                1,cy-tail*k, left-tail*k,tt, left,tt]
    }
    static func travel(from start: Self, to end: Self, height: CGFloat = 32, progress t: CGFloat) -> Self {
        let t = min(1,max(0,t))
        if t == 0 { return start }
        if t == 1 { return end }
        let direction: CGFloat = end.x+end.width/2 >= start.x+start.width/2 ? 1 : -1
        let lead = smooth(t/0.83), trail = smooth((t-0.10)/0.90)
        func mix(_ a: CGFloat,_ b: CGFloat,_ p: CGFloat) -> CGFloat { a+(b-a)*p }
        let left = mix(start.x,end.x,direction > 0 ? trail : lead)
        let right = mix(start.x+start.width,end.x+end.width,direction > 0 ? lead : trail)
        let width = right-left, distance = abs(end.x-start.x)/max(end.width,1)
        let amount = pow(sin(.pi*t),1.2)*min(1,distance)
        var points = outline(width:width,height:height,amount:amount,direction:direction)
        let rest = outline(width:start.width,height:height), carry = 1-smooth(t/0.5)
        for i in points.indices { points[i] += (start.points[i]-rest[i])*carry*(i.isMultiple(of:2) ? width/start.width : 1) }
        return Self(x:left,width:width,points:points)
    }
    var path: Path {
        Path { p in
            guard points.count == 50 else { return }
            p.move(to:.init(x:x+points[0],y:points[1]))
            for i in stride(from:2,to:50,by:6) {
                p.addCurve(to:.init(x:x+points[i+4],y:points[i+5]),control1:.init(x:x+points[i],y:points[i+1]),control2:.init(x:x+points[i+2],y:points[i+3]))
            }
            p.closeSubpath()
        }
    }
}

@MainActor @Observable final class LiquidMotion {
    private(set) var frame = LiquidFrame.rest(x:0)
    private var animation: Task<Void,Never>?
    func select(work: Bool, reduced: Bool) {
        animation?.cancel()
        let end = LiquidFrame.rest(x:work ? 96 : 0), start = frame
        if reduced || start == end { frame = end; return }
        animation = Task { [weak self] in
            let clock = ContinuousClock(), begin = clock.now
            while !Task.isCancelled {
                let elapsed = begin.duration(to:clock.now)
                let seconds = Double(elapsed.components.seconds)+Double(elapsed.components.attoseconds)/1e18
                self?.frame = LiquidFrame.travel(from:start,to:end,progress:seconds/0.36)
                if seconds >= 0.36 { break }
                do { try await Task.sleep(for:.milliseconds(8)) } catch { return }
            }
        }
    }
    func stop() { animation?.cancel(); animation = nil }
}

struct LiquidSurface: View {
    let frame: LiquidFrame
    var body: some View {
        frame.path.fill(LinearGradient(stops:[.init(color:Curiora.waterTop.opacity(0.96),location:0),.init(color:Curiora.waterMiddle,location:0.52),.init(color:Curiora.waterBottom.opacity(0.96),location:1)],startPoint:UnitPoint(x:frame.x/192,y:0),endPoint:UnitPoint(x:(frame.x+frame.width)/192,y:1)))
            .overlay(frame.path.stroke(Curiora.border,lineWidth:1))
    }
}
