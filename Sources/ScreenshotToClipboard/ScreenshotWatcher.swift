import Foundation

/// Watches a folder for new screenshots/recordings.
///
/// This intentionally uses a tight poll loop (every 0.3s) rather than a
/// DispatchSource file-system-object event stream. The event-based version
/// was tried first and looked more "proper," but in real-world testing with
/// actual macOS screenshot captures (as opposed to synthetic file copies)
/// its "write" event didn't fire reliably, so detection fell back to a slow
/// safety-net poll most of the time. A plain fast poll is simpler and was
/// empirically the fast, reliable option — checking a directory listing
/// every 0.3s costs nothing measurable.
final class ScreenshotWatcher {
    private let folder: URL
    private var pollTimer: DispatchSourceTimer?
    private var lastSeen: URL?

    var onNewFile: ((URL) -> Void)?
    var onFilesChanged: (([URL]) -> Void)?

    private let matchExtensions: Set<String> = ["png", "jpg", "jpeg", "heic", "tiff", "tif", "mov"]

    init(folder: URL) {
        self.folder = folder
    }

    func start() {
        lastSeen = newestMatchingFile()

        let timer = DispatchSource.makeTimerSource(queue: .global(qos: .userInitiated))
        timer.schedule(deadline: .now() + 0.3, repeating: 0.3)
        timer.setEventHandler { [weak self] in self?.check() }
        timer.resume()
        pollTimer = timer

        refreshFileList()
    }

    func stop() {
        pollTimer?.cancel()
        pollTimer = nil
    }

    private func modDate(_ url: URL) -> Date {
        (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
    }

    private func newestMatchingFile() -> URL? {
        guard let items = try? FileManager.default.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return nil }

        return items
            .filter { matchExtensions.contains($0.pathExtension.lowercased()) }
            .max { modDate($0) < modDate($1) }
    }

    private func check() {
        guard let newest = newestMatchingFile() else { return }
        if newest.path != lastSeen?.path {
            lastSeen = newest
            onNewFile?(newest)
        }
        refreshFileList()
    }

    private func refreshFileList() {
        guard let items = try? FileManager.default.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return }

        let sorted = items
            .filter { matchExtensions.contains($0.pathExtension.lowercased()) }
            .sorted { modDate($0) > modDate($1) }
        onFilesChanged?(sorted)
    }
}
