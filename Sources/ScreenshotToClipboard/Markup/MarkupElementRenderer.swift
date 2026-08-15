import SwiftUI

/// Shared draw routine used by both the live editing canvas and the
/// full-resolution export pass, so the two can never drift out of sync.
enum MarkupElementRenderer {
    static func draw(_ element: DrawingElement, in context: inout GraphicsContext, selected: Bool = false) {
        let strokeStyle = StrokeStyle(lineWidth: element.lineWidth, lineCap: .round, lineJoin: .round)

        switch element.tool {
        case .pen:
            guard !element.points.isEmpty else { return }
            context.stroke(RoughRenderer.smoothedFreehand(points: element.points), with: .color(element.color), style: strokeStyle)

        case .rectangle:
            guard element.points.count == 2 else { return }
            context.stroke(RoughRenderer.roughRectangle(rect(element), seed: element.seed), with: .color(element.color), style: strokeStyle)

        case .ellipse:
            guard element.points.count == 2 else { return }
            context.stroke(RoughRenderer.roughEllipse(rect(element), seed: element.seed), with: .color(element.color), style: strokeStyle)

        case .line:
            guard element.points.count == 2 else { return }
            context.stroke(RoughRenderer.roughLine(from: element.points[0], to: element.points[1], seed: element.seed), with: .color(element.color), style: strokeStyle)

        case .arrow:
            guard element.points.count == 2 else { return }
            context.stroke(RoughRenderer.roughArrow(from: element.points[0], to: element.points[1], seed: element.seed), with: .color(element.color), style: strokeStyle)

        case .text:
            guard let anchor = element.points.first else { return }
            let resolved = context.resolve(
                Text(element.text)
                    .font(MarkupTextStyle.swiftUIFont(lineWidth: element.lineWidth))
                    .foregroundColor(element.color)
            )
            context.draw(resolved, at: anchor, anchor: .topLeading)

        case .select, .eraser:
            break
        }

        if selected {
            context.stroke(Path(roundedRect: element.boundingBox, cornerRadius: 4), with: .color(.accentColor), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
        }
    }

    private static func rect(_ element: DrawingElement) -> CGRect {
        let a = element.points[0], b = element.points[1]
        return CGRect(x: min(a.x, b.x), y: min(a.y, b.y), width: abs(b.x - a.x), height: abs(b.y - a.y))
    }
}
