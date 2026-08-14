import Foundation

/// Watches a folder for new screenshots/recordings using a live
/// DispatchSource file-system-object stream (real FSEvents-backed
/// notification from inside our own approved process — this is what makes
/// detection near-instant, unlike a background launchd job watching from
/// the outside). A slow safety-net poll covers the rare missed event.
final class ScreenshotWatcher {
    private let folder: URL
    private var source: DispatchSourceFileSystemObject?
    private var fileDescriptor: CInt = -1
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

        fileDescriptor = open(folder.path, O_EVTONLY)
        if fileDescriptor >= 0 {
            let src = DispatchSource.makeFileSystemObjectSource(
                fileDescriptor: fileDescriptor,
                eventMask: .write,
                queue: DispatchQueue.global(qos: .userInitiated)
            )
            src.setEventHandler { [weak self] in self?.check() }
            src.setCancelHandler { [weak self] in
                if let fd = self?.fileDescriptor, fd >= 0 { close(fd) }
            }
            src.resume()
            source = src
        }

        let timer = DispatchSource.makeTimerSource(queue: .global(qos: .utility))
        timer.schedule(deadline: .now() + 2, repeating: 2)
        timer.setEventHandler { [weak self] in self?.check() }
        timer.resume()
        pollTimer = timer

        refreshFileList()
    }

    func stop() {
        source?.cancel()
        source = nil
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
