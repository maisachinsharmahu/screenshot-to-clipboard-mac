import SwiftUI

/// Holds the in-progress annotation state for one markup session: the
/// committed elements plus undo/redo history. Coordinates are in the
/// on-screen canvas's own display space (whatever size it's shown at);
/// MarkupEditorView rescales to the base image's native pixel space only
/// once, at export time.
final class MarkupDocument: ObservableObject {
    @Published var elements: [DrawingElement] = []
    @Published var selectedID: UUID?

    private var undoStack: [[DrawingElement]] = []
    private var redoStack: [[DrawingElement]] = []

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    private func snapshot() {
        undoStack.append(elements)
        redoStack.removeAll()
    }

    func commit(_ element: DrawingElement) {
        snapshot()
        elements.append(element)
    }

    /// Call once when a drag-to-move gesture begins, so undo has a clean
    /// pre-move snapshot; then mutate `elements` directly each frame for
    /// smooth live feedback without spamming the undo stack.
    func beginDirectEdit() {
        snapshot()
    }

    func moveSelected(by delta: CGSize) {
        guard let id = selectedID, let idx = elements.firstIndex(where: { $0.id == id }) else { return }
        elements[idx].points = elements[idx].points.map { CGPoint(x: $0.x + delta.width, y: $0.y + delta.height) }
    }

    func erase(at point: CGPoint) {
        guard let idx = elements.lastIndex(where: { $0.hitTest(point) }) else { return }
        snapshot()
        elements.remove(at: idx)
        if selectedID == elements[safe: idx]?.id { selectedID = nil }
    }

    func deleteSelected() {
        guard let id = selectedID, let idx = elements.firstIndex(where: { $0.id == id }) else { return }
        snapshot()
        elements.remove(at: idx)
        selectedID = nil
    }

    func select(at point: CGPoint) -> UUID? {
        let hit = elements.last { $0.hitTest(point) }
        selectedID = hit?.id
        return hit?.id
    }

    func undo() {
        guard let last = undoStack.popLast() else { return }
        redoStack.append(elements)
        elements = last
    }

    func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(elements)
        elements = next
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
