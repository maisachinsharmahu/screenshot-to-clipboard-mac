import SwiftUI
import AppKit

struct MarkupEditorView: View {
    let baseImage: NSImage
    let imagePixelSize: CGSize
    let displaySize: CGSize
    let onDone: (NSImage) -> Void
    let onCancel: () -> Void

    @StateObject private var document = MarkupDocument()
    @State private var tool: MarkupTool = .pen
    @State private var color: Color = MarkupPalette.colors[1] // red -- the classic "mark this up" color
    @State private var lineWidth: CGFloat = MarkupPalette.strokeWidths[1]
    @State private var pendingText: PendingText?

    private struct PendingText: Identifiable {
        let id = UUID()
        var position: CGPoint
        var text: String = ""
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.opacity(0.001) // full-window hit area so clicks outside the image still register

            VStack(spacing: 16) {
                ZStack(alignment: .topLeading) {
                    Image(nsImage: baseImage)
                        .resizable()
                        .frame(width: displaySize.width, height: displaySize.height)

                    MarkupCanvasView(
                        document: document,
                        displaySize: displaySize,
                        tool: $tool,
                        color: $color,
                        lineWidth: $lineWidth,
                        onRequestText: { location in
                            pendingText = PendingText(position: location)
                        }
                    )

                    if let pending = pendingText {
                        TextField("Type…", text: Binding(
                            get: { pending.text },
                            set: { pendingText?.text = $0 }
                        ))
                        .textFieldStyle(.plain)
                        .font(.custom("Bradley Hand", size: lineWidth * 6.5))
                        .foregroundColor(color)
                        .fixedSize()
                        .padding(4)
                        .background(Color.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 4))
                        .position(x: pending.position.x + 40, y: pending.position.y + 10)
                        .onSubmit { commitPendingText() }
                    }
                }
                .frame(width: displaySize.width, height: displaySize.height)
                .background(Color.black.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: .black.opacity(0.25), radius: 20, y: 8)

                MarkupToolbar(
                    tool: $tool,
                    color: $color,
                    lineWidth: $lineWidth,
                    canUndo: document.canUndo,
                    canRedo: document.canRedo,
                    onUndo: document.undo,
                    onRedo: document.redo,
                    onCancel: onCancel,
                    onDone: finishAndCopy
                )
            }
            .padding(24)
        }
        .onExitCommand(perform: onCancel) // Escape key
        .onChange(of: tool) { newTool in
            if newTool != .text, pendingText != nil { commitPendingText() }
        }
    }

    private func commitPendingText() {
        guard let pending = pendingText, !pending.text.trimmingCharacters(in: .whitespaces).isEmpty else {
            pendingText = nil
            return
        }
        document.commit(DrawingElement(tool: .text, points: [pending.position], color: color, lineWidth: lineWidth, text: pending.text))
        pendingText = nil
    }

    private func finishAndCopy() {
        if pendingText != nil { commitPendingText() }

        let scale = imagePixelSize.width / displaySize.width
        let scaledElements = document.elements.map { element -> DrawingElement in
            var copy = element
            copy.points = element.points.map { CGPoint(x: $0.x * scale, y: $0.y * scale) }
            copy.lineWidth = element.lineWidth * scale
            return copy
        }

        let exportView = ZStack(alignment: .topLeading) {
            Image(nsImage: baseImage)
                .resizable()
                .frame(width: imagePixelSize.width, height: imagePixelSize.height)
            StaticMarkupOverlay(elements: scaledElements)
                .frame(width: imagePixelSize.width, height: imagePixelSize.height)
        }
        .frame(width: imagePixelSize.width, height: imagePixelSize.height)

        let renderer = ImageRenderer(content: exportView)
        renderer.scale = 1
        renderer.proposedSize = ProposedViewSize(imagePixelSize)

        if let nsImage = renderer.nsImage {
            onDone(nsImage)
        } else {
            onDone(baseImage)
        }
    }
}

/// Non-interactive replay of committed elements, used only for the
/// full-resolution export render (no gestures, no selection outline).
private struct StaticMarkupOverlay: View {
    let elements: [DrawingElement]

    var body: some View {
        Canvas { context, _ in
            for element in elements {
                MarkupElementRenderer.draw(element, in: &context)
            }
        }
    }
}
