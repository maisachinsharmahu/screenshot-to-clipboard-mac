import SwiftUI
import AppKit

struct MarkupEditorView: View {
    let baseImage: NSImage
    let imagePixelSize: CGSize
    let onDone: (NSImage) -> Void
    let onCancel: () -> Void

    @StateObject private var document = MarkupDocument()
    @State private var tool: MarkupTool = .pen
    @State private var color: Color = MarkupPalette.colors[1] // red -- the classic "mark this up" color
    @State private var lineWidth: CGFloat = MarkupPalette.strokeWidths[1]
    @State private var zoomLevel: CGFloat = 1.0
    @State private var pinchBaseline: CGFloat = 1.0
    @State private var pendingText: PendingText?
    @FocusState private var textFieldFocused: Bool

    /// Position is stored in image-pixel space, same as committed
    /// DrawingElements, so it stays correct if zoom changes mid-entry and
    /// so finishAndCopy() can commit it without needing the current scale.
    private struct PendingText: Identifiable {
        let id = UUID()
        var imagePosition: CGPoint
        var text: String = ""
    }

    var body: some View {
        VStack(spacing: 16) {
            GeometryReader { geo in
                let fitScale = min(geo.size.width / imagePixelSize.width, geo.size.height / imagePixelSize.height, 1)
                let scale = fitScale * zoomLevel
                let displaySize = CGSize(width: imagePixelSize.width * scale, height: imagePixelSize.height * scale)

                ScrollView([.horizontal, .vertical], showsIndicators: true) {
                    ZStack(alignment: .topLeading) {
                        Image(nsImage: baseImage)
                            .resizable()
                            .frame(width: displaySize.width, height: displaySize.height)

                        MarkupCanvasView(
                            document: document,
                            imagePixelSize: imagePixelSize,
                            scale: scale,
                            tool: $tool,
                            color: $color,
                            lineWidth: $lineWidth,
                            onRequestText: { displayPoint in
                                if pendingText != nil { commitPendingText() }
                                pendingText = PendingText(imagePosition: CGPoint(x: displayPoint.x / scale, y: displayPoint.y / scale))
                            },
                            onInteractionBegan: {
                                if pendingText != nil { commitPendingText() }
                            }
                        )

                        if let pending = pendingText {
                            // No background box: typing should look exactly
                            // like the text will once placed -- just the
                            // cursor and characters directly on the image.
                            TextField("Type…", text: Binding(
                                get: { pending.text },
                                set: { pendingText?.text = $0 }
                            ))
                            .textFieldStyle(.plain)
                            .font(.custom(MarkupTextStyle.fontName, size: MarkupTextStyle.pointSize(for: lineWidth) * scale))
                            .foregroundColor(color)
                            .fixedSize()
                            .position(x: pending.imagePosition.x * scale + 40, y: pending.imagePosition.y * scale + 10)
                            .focused($textFieldFocused)
                            .onSubmit(commitPendingText)
                            .onAppear { textFieldFocused = true }
                        }
                    }
                    .frame(width: displaySize.width, height: displaySize.height)
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .background(Color.black.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: .black.opacity(0.25), radius: 20, y: 8)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            zoomLevel = min(4.0, max(0.25, pinchBaseline * value))
                        }
                        .onEnded { _ in
                            pinchBaseline = zoomLevel
                        }
                )
            }

            MarkupToolbar(
                tool: $tool,
                color: $color,
                lineWidth: $lineWidth,
                zoomLevel: $zoomLevel,
                isTextSizeContext: tool == .text || document.elements.first(where: { $0.id == document.selectedID })?.tool == .text,
                canUndo: document.canUndo,
                canRedo: document.canRedo,
                onUndo: document.undo,
                onRedo: document.redo,
                onCancel: onCancel,
                onDone: finishAndCopy
            )
        }
        .padding(24)
        .onExitCommand(perform: onCancel) // Escape key
        .onChange(of: tool) { newTool in
            if newTool != .text, pendingText != nil { commitPendingText() }
        }
        .onChange(of: zoomLevel) { newValue in
            pinchBaseline = newValue
        }
        .onChange(of: color) { newColor in
            if document.selectedID != nil { document.restyleSelected(color: newColor) }
        }
        .onChange(of: lineWidth) { newWidth in
            if document.selectedID != nil { document.restyleSelected(lineWidth: newWidth) }
        }
        .onChange(of: textFieldFocused) { focused in
            // Commit as soon as focus leaves the field -- e.g. clicking
            // elsewhere on the canvas -- not only on pressing Return.
            if !focused, pendingText != nil { commitPendingText() }
        }
    }

    private func commitPendingText() {
        guard let pending = pendingText, !pending.text.trimmingCharacters(in: .whitespaces).isEmpty else {
            pendingText = nil
            return
        }
        document.commit(DrawingElement(tool: .text, points: [pending.imagePosition], color: color, lineWidth: lineWidth, text: pending.text))
        pendingText = nil
    }

    private func finishAndCopy() {
        if pendingText != nil { commitPendingText() }

        let exportView = ZStack(alignment: .topLeading) {
            Image(nsImage: baseImage)
                .resizable()
                .frame(width: imagePixelSize.width, height: imagePixelSize.height)
            StaticMarkupOverlay(elements: document.elements)
                .frame(width: imagePixelSize.width, height: imagePixelSize.height)
        }
        .frame(width: imagePixelSize.width, height: imagePixelSize.height)

        let renderer = ImageRenderer(content: exportView)
        renderer.scale = 1
        renderer.proposedSize = ProposedViewSize(imagePixelSize)

        onDone(renderer.nsImage ?? baseImage)
    }
}

/// Non-interactive replay of committed elements, used only for the
/// full-resolution export render (no gestures, no selection outline).
/// Elements are already in image-pixel space, so no transform is needed.
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
