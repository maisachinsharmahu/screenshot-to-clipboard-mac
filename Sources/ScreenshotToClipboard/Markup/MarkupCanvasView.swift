import SwiftUI

/// The drawable surface: renders the base screenshot plus every committed
/// annotation, and turns drag/tap gestures into new or edited elements
/// depending on the currently selected tool.
///
/// Displayed at `imagePixelSize * scale` on screen, but all element
/// coordinates -- both stored and in the live gesture -- are converted to
/// the image's native pixel space immediately, via `scale`. That's what
/// lets the window resize or zoom freely without existing annotations
/// drifting out of alignment.
///
/// Select and text placement are both handled inside the single drag
/// gesture (minimumDistance: 0) rather than a separate tap gesture: two
/// independently-attached gesture recognizers compete for the same touch,
/// and the low-threshold drag was winning that race before a tap could
/// ever be recognized, which is why select-to-move didn't work.
struct MarkupCanvasView: View {
    @ObservedObject var document: MarkupDocument
    let imagePixelSize: CGSize
    let scale: CGFloat
    @Binding var tool: MarkupTool
    @Binding var color: Color
    @Binding var lineWidth: CGFloat
    var onRequestText: (CGPoint) -> Void // display-space point, for overlay placement

    @State private var liveElement: DrawingElement?
    @State private var dragOrigin: CGPoint?

    private var displaySize: CGSize {
        CGSize(width: imagePixelSize.width * scale, height: imagePixelSize.height * scale)
    }

    var body: some View {
        Canvas { context, _ in
            context.scaleBy(x: scale, y: scale)
            for element in document.elements {
                MarkupElementRenderer.draw(element, in: &context, selected: element.id == document.selectedID)
            }
            if let liveElement {
                MarkupElementRenderer.draw(liveElement, in: &context)
            }
        }
        .frame(width: displaySize.width, height: displaySize.height)
        .contentShape(Rectangle())
        .gesture(dragGesture)
    }

    private func toImageSpace(_ displayPoint: CGPoint) -> CGPoint {
        CGPoint(x: displayPoint.x / scale, y: displayPoint.y / scale)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let start = toImageSpace(value.startLocation)
                let current = toImageSpace(value.location)

                switch tool {
                case .pen:
                    if liveElement == nil {
                        liveElement = DrawingElement(tool: .pen, points: [start], color: color, lineWidth: lineWidth)
                    }
                    liveElement?.points.append(current)

                case .rectangle, .ellipse, .line, .arrow:
                    liveElement = DrawingElement(tool: tool, points: [start, current], color: color, lineWidth: lineWidth)

                case .eraser:
                    document.erase(at: current)

                case .select:
                    if dragOrigin == nil {
                        // First movement of this gesture: (re)select whatever
                        // is under the touch-down point, or deselect if empty.
                        dragOrigin = start
                        if document.select(at: start) != nil {
                            document.beginDirectEdit()
                        }
                    }
                    if let origin = dragOrigin, document.selectedID != nil {
                        document.moveSelected(by: CGSize(width: current.x - origin.x, height: current.y - origin.y))
                        dragOrigin = current
                    }

                case .text:
                    break
                }
            }
            .onEnded { value in
                if let element = liveElement, element.tool != .select {
                    document.commit(element)
                }
                if tool == .text, hypot(value.translation.width, value.translation.height) < 3 {
                    onRequestText(value.location)
                }
                liveElement = nil
                dragOrigin = nil
            }
    }
}
