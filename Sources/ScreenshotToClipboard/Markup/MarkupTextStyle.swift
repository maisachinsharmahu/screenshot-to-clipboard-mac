import SwiftUI
import AppKit

/// Single source of truth for the annotation font, shared by the live
/// canvas, the export renderer, and the hit-test bounding box -- so all
/// three always agree on exactly how big a piece of text actually is.
enum MarkupTextStyle {
    static let fontName = "Bradley Hand"
    static let sizeMultiplier: CGFloat = 6.5

    static func pointSize(for lineWidth: CGFloat) -> CGFloat {
        lineWidth * sizeMultiplier
    }

    static func swiftUIFont(lineWidth: CGFloat) -> Font {
        .custom(fontName, size: pointSize(for: lineWidth))
    }

    static func nsFont(lineWidth: CGFloat) -> NSFont {
        NSFont(name: fontName, size: pointSize(for: lineWidth)) ?? NSFont.systemFont(ofSize: pointSize(for: lineWidth))
    }

    /// Actual rendered size of a text element's string at its current
    /// size, used for hit-testing (select/eraser) so the tappable area
    /// matches what's actually on screen instead of a fixed small box.
    static func measure(_ text: String, lineWidth: CGFloat) -> CGSize {
        let string = text.isEmpty ? " " : text
        let size = (string as NSString).size(withAttributes: [.font: nsFont(lineWidth: lineWidth)])
        return CGSize(width: max(size.width, 16), height: max(size.height, 16))
    }
}
