// Render the existing Curio-Web mark at macOS app-icon sizes; no external tools.
import AppKit
import Foundation
let output = URL(fileURLWithPath:CommandLine.arguments[1])
var images: [[String:String]] = []
for size in [16,32,128,256,512] {
    for scale in [1,2] {
        let pixels = size*scale
        let rep = NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:pixels,pixelsHigh:pixels,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep:rep)
        let ctx = NSGraphicsContext.current!.cgContext
        ctx.scaleBy(x:CGFloat(pixels)/40,y:CGFloat(pixels)/40)
        ctx.translateBy(x:0,y:40); ctx.scaleBy(x:1,y:-1)
        ctx.setFillColor(NSColor(srgbRed:0,green:113.0/255,blue:227.0/255,alpha:1).cgColor)
        // Native icon padding leaves room for the Dock's shadow.
        ctx.translateBy(x:2,y:2); ctx.scaleBy(x:0.9,y:0.9)
        ctx.addPath(CGPath(roundedRect:CGRect(x:0,y:0,width:40,height:40),cornerWidth:13,cornerHeight:13,transform:nil));ctx.fillPath()
        ctx.setStrokeColor(NSColor.white.cgColor);ctx.setLineWidth(3.2);ctx.setLineCap(.round);ctx.setLineJoin(.round)
        ctx.addArc(center:CGPoint(x:19.515,y:20),radius:11,startAngle:-39.52 * .pi/180,endAngle:-320.48 * .pi/180,clockwise:true)
        ctx.move(to:CGPoint(x:28,y:13));ctx.addLine(to:CGPoint(x:28,y:19));ctx.addLine(to:CGPoint(x:22,y:19));ctx.strokePath()
        NSGraphicsContext.restoreGraphicsState()
        let filename="icon_\(size)x\(size)@\(scale)x.png"
        try rep.representation(using:.png,properties:[:])!.write(to:output.appendingPathComponent(filename))
        images.append(["idiom":"mac","size":"\(size)x\(size)","scale":"\(scale)x","filename":filename])
    }
}
let contents:[String:Any] = ["images":images,"info":["author":"xcode","version":1]]
try JSONSerialization.data(withJSONObject:contents,options:[.prettyPrinted,.sortedKeys]).write(to:output.appendingPathComponent("Contents.json"))
