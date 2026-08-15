import SwiftUI

enum MarkupTool: String, CaseIterable, Identifiable {
    case select, pen, rectangle, ellipse, arrow, line, text, eraser
    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .select: return "cursorarrow"
        case .pen: return "pencil.tip"
        case .rectangle: return "rectangle"
        case .ellipse: return "circle"
        case .arrow: return "arrow.up.right"
        case .line: return "line.diagonal"
        case .text: return "textformat"
        case .eraser: return "eraser"
        }
    }
}

/// A single hand-drawn-style annotation, positioned in the *base image's*
/// native pixel space -- not the on-screen view's, which changes size as
/// the window is resized or zoomed. Storing in image space means the
/// canvas can apply a single scale transform for both display and export,
/// and annotations never drift when the window is resized mid-edit.
struct DrawingElement: Identifiable {
    let id = UUID()
    var tool: MarkupTool
    var points: [CGPoint]      // pen: every sampled point. shapes/line/arrow: [start, end].
    var color: Color
    var lineWidth: CGFloat
    var text: String = ""
    let seed: Int = Int.random(in: 0..<1_000_000)

    var boundingBox: CGRect {
        guard let first = points.first else { return .zero }

        if tool == .text {
            // Text is anchored at one point but renders much wider than a
            // fixed padding box would suggest -- measure the actual string
            // so select/eraser hit-testing matches what's on screen.
            let size = MarkupTextStyle.measure(text, lineWidth: lineWidth)
            return CGRect(x: first.x, y: first.y, width: size.width, height: size.height)
        }

        var minX = first.x, minY = first.y, maxX = first.x, maxY = first.y
        for p in points {
            minX = min(minX, p.x); minY = min(minY, p.y)
            maxX = max(maxX, p.x); maxY = max(maxY, p.y)
        }
        // Give thin shapes (a perfectly horizontal/vertical line) a hittable
        // thickness for eraser/select tap targets.
        let pad: CGFloat = max(lineWidth, 10)
        return CGRect(x: minX - pad, y: minY - pad, width: max(maxX - minX, 1) + pad * 2, height: max(maxY - minY, 1) + pad * 2)
    }

    func hitTest(_ point: CGPoint) -> Bool {
        boundingBox.contains(point)
    }
}

/// The standard Excalidraw-adjacent palette: a handful of saturated marker
/// colors plus black, which covers nearly everything people annotate with.
enum MarkupPalette {
    static let colors: [Color] = [
        .black,
        Color(red: 0.91, green: 0.30, blue: 0.24),   // red
        Color(red: 0.18, green: 0.60, blue: 0.29),   // green
        Color(red: 0.15, green: 0.47, blue: 0.91),   // blue
        Color(red: 0.95, green: 0.61, blue: 0.07),   // orange
        Color(red: 0.60, green: 0.35, blue: 0.85),   // purple
    ]
    /// In image-pixel space (see DrawingElement doc) -- these look like odd
    /// large numbers at rest, but render at a normal 2-8pt on screen once
    /// the canvas's display scale (typically ~0.3-0.5 for a Retina
    /// screenshot fit to a window) is applied.
    static let strokeWidths: [CGFloat] = [6, 12, 20]
}
