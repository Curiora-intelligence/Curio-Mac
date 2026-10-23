import SwiftUI
import AppKit

/// Product overrides from Curio-Web/static/css/tokens.css take precedence over
/// the broader Curiora marketing palette. Colors resolve with macOS appearance.
enum Curiora {
    static let background = Color("background")
    static let sidebar = Color("sidebar")
    static let surface = Color("surface")
    static let elevated = Color("elevated")
    static let hover = Color("hover")
    static let selected = Color("selected")
    static let text = Color("text")
    static let secondary = Color("secondary")
    static let accent = Color("accent")
    static let primary = Color("primary")
    static let accentSurface = Color("accentSurface")
    static let accentText = Color("accentText")
    static let border = Color("border")
    static let glass = Color("glass")
    static let segmentShell = Color("segmentShell")
    static let waterTop = Color("waterTop")
    static let waterMiddle = Color("waterMiddle")
    static let waterBottom = Color("waterBottom")
    static let focusNeutral = Color("focusNeutral")
    static let contentWidth: CGFloat = 770
    static let sidebarDefault: CGFloat = 270
    static let sidebarMinimum: CGFloat = 252
    static let sidebarMaximum: CGFloat = 420
    static let narrowBreakpoint: CGFloat = 760
    static let maximumDraftLength = 16_000
    static let layoutMotion = Animation.timingCurve(0.22, 0.61, 0.36, 1, duration: 0.30)
    static let selectionMotion = Animation.timingCurve(0.22, 0.61, 0.36, 1, duration: 0.36)
    static func headingSize(windowWidth: CGFloat) -> CGFloat { min(30, max(26, windowWidth * 0.022)) }

}
