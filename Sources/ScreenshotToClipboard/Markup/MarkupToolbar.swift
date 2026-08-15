import SwiftUI

struct MarkupToolbar: View {
    @Binding var tool: MarkupTool
    @Binding var color: Color
    @Binding var lineWidth: CGFloat
    @Binding var zoomLevel: CGFloat
    /// True when the size picker should mean "text size" (Aa, Aa, Aa)
    /// instead of "stroke width" (dots) -- active tool is .text, or a
    /// selected element is a text element.
    let isTextSizeContext: Bool
    let canUndo: Bool
    let canRedo: Bool
    let onUndo: () -> Void
    let onRedo: () -> Void
    let onCancel: () -> Void
    let onDone: () -> Void

    private let toolOrder: [MarkupTool] = [.select, .pen, .rectangle, .ellipse, .arrow, .line, .text, .eraser]
    private let zoomRange: ClosedRange<CGFloat> = 0.25...4.0
    private let swatchPreviewSizes: [CGFloat] = [8, 12, 17]
    private let textPreviewSizes: [CGFloat] = [11, 15, 20]

    var body: some View {
        HStack(spacing: 14) {
            HStack(spacing: 2) {
                ForEach(toolOrder) { t in
                    Button {
                        tool = t
                    } label: {
                        Image(systemName: t.symbolName)
                            .font(.system(size: 14, weight: .medium))
                            .frame(width: 30, height: 26)
                            .background(tool == t ? Color.accentColor.opacity(0.18) : .clear)
                            .foregroundStyle(tool == t ? Color.accentColor : Color.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider().frame(height: 20)

            HStack(spacing: 6) {
                ForEach(MarkupPalette.colors.indices, id: \.self) { i in
                    let swatch = MarkupPalette.colors[i]
                    Button {
                        color = swatch
                    } label: {
                        Circle()
                            .fill(swatch)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Circle().stroke(Color.primary.opacity(colorMatches(swatch) ? 0.6 : 0), lineWidth: 2)
                            )
                            .overlay(
                                Circle().strokeBorder(Color.primary.opacity(0.15), lineWidth: 0.5)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider().frame(height: 20)

            HStack(spacing: isTextSizeContext ? 2 : 6) {
                ForEach(Array(MarkupPalette.strokeWidths.enumerated()), id: \.offset) { i, w in
                    Button {
                        lineWidth = w
                    } label: {
                        if isTextSizeContext {
                            Text("A")
                                .font(.system(size: textPreviewSizes[i], weight: .semibold))
                                .foregroundStyle(lineWidth == w ? Color.accentColor : Color.secondary)
                                .frame(width: 24, height: 26)
                        } else {
                            Circle()
                                .fill(lineWidth == w ? Color.accentColor : Color.secondary.opacity(0.5))
                                .frame(width: swatchPreviewSizes[i], height: swatchPreviewSizes[i])
                                .frame(width: 22, height: 22)
                        }
                    }
                    .buttonStyle(.plain)
                    .help(isTextSizeContext ? "Text size" : "Stroke width")
                }
            }

            Divider().frame(height: 20)

            HStack(spacing: 4) {
                Button {
                    zoomLevel = max(zoomRange.lowerBound, (zoomLevel - 0.25).rounded(toNearest: 0.25))
                } label: {
                    Image(systemName: "minus.magnifyingglass").frame(width: 24, height: 26)
                }
                .buttonStyle(.plain)

                Button {
                    zoomLevel = 1.0
                } label: {
                    Text("\(Int(zoomLevel * 100))%")
                        .font(.system(size: 11, weight: .medium))
                        .monospacedDigit()
                        .frame(minWidth: 36)
                }
                .buttonStyle(.plain)
                .help("Reset to fit window")

                Button {
                    zoomLevel = min(zoomRange.upperBound, (zoomLevel + 0.25).rounded(toNearest: 0.25))
                } label: {
                    Image(systemName: "plus.magnifyingglass").frame(width: 24, height: 26)
                }
                .buttonStyle(.plain)
            }

            Divider().frame(height: 20)

            HStack(spacing: 2) {
                Button(action: onUndo) {
                    Image(systemName: "arrow.uturn.backward").frame(width: 26, height: 26)
                }
                .buttonStyle(.plain)
                .disabled(!canUndo)
                .opacity(canUndo ? 1 : 0.35)
                .keyboardShortcut("z", modifiers: .command)

                Button(action: onRedo) {
                    Image(systemName: "arrow.uturn.forward").frame(width: 26, height: 26)
                }
                .buttonStyle(.plain)
                .disabled(!canRedo)
                .opacity(canRedo ? 1 : 0.35)
                .keyboardShortcut("z", modifiers: [.command, .shift])
            }

            Spacer(minLength: 8)

            Button("Skip", action: onCancel)
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Copy the screenshot as-is, without opening it for editing")

            Button("Done", action: onDone)
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: [])
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.primary.opacity(0.08), lineWidth: 1))
        .shadow(color: .black.opacity(0.18), radius: 14, y: 6)
        .fixedSize()
    }

    private func colorMatches(_ swatch: Color) -> Bool {
        color.description == swatch.description
    }
}

private extension CGFloat {
    func rounded(toNearest step: CGFloat) -> CGFloat {
        (self / step).rounded() * step
    }
}
