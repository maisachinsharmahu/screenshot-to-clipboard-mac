import SwiftUI

/// The drawable surface: renders the base screenshot plus every committed
/// annotation, and turns drag/tap gestures into new or edited elements
/// depending on the currently selected tool. Operates entirely in its own
/// on-screen point space -- the caller rescales to native pixels on export.
struct MarkupCanvasView: View {
    @ObservedObject var document: MarkupDocument
    let displaySize: CGSize
    @Binding var tool: MarkupTool
    @Binding var color: Color
    @Binding var lineWidth: CGFloat
    var onRequestText: (CGPoint) -> Void

    @State private var liveElement: DrawingElement?
    @State private var dragOrigin: CGPoint?

    var body: some View {
        Canvas { context, _ in
            for element in document.elements {
                draw(element, in: &context, selected: element.id == document.selectedID)
            }
            if let liveElement {
                draw(liveElement, in: &context, selected: false)
            }
        }
        .frame(width: displaySize.width, height: displaySize.height)
        .contentShape(Rectangle())
        .gesture(dragGesture)
        .gesture(
            SpatialTapGesture().onEnded { value in
                switch tool {
                case .text:
                    onRequestText(value.location)
                case .select:
                    _ = document.select(at: value.location)
                default:
                    break
                }
            }
        )
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                switch tool {
                case .pen:
                    if liveElement == nil {
                        liveElement = DrawingElement(tool: .pen, points: [value.startLocation], color: color, lineWidth: lineWidth)
                    }
                    liveElement?.points.append(value.location)

                case .rectangle, .ellipse, .line, .arrow:
                    liveElement = DrawingElement(tool: tool, points: [value.startLocation, value.location], color: color, lineWidth: lineWidth)

                case .eraser:
                    document.erase(at: value.location)

                case .select:
                    if dragOrigin == nil {
                        dragOrigin = value.startLocation
                        if document.selectedID == nil || document.select(at: value.startLocation) == nil {
                            dragOrigin = nil
                            return
                        }
                        document.beginDirectEdit()
                    }
                    if let origin = dragOrigin {
                        document.moveSelected(by: CGSize(width: value.location.x - origin.x, height: value.location.y - origin.y))
                        dragOrigin = value.location
                    }

                case .text:
                    break
                }
            }
            .onEnded { _ in
                if let element = liveElement, element.tool != .select {
                    document.commit(element)
                }
                liveElement = nil
                dragOrigin = nil
            }
    }

    private func draw(_ element: DrawingElement, in context: inout GraphicsContext, selected: Bool) {
        MarkupElementRenderer.draw(element, in: &context, selected: selected)
    }
}
