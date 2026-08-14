import AppKit

/// Writes screenshots/recordings to the general pasteboard, natively —
/// no shelling out to osascript. A generation-check guards against a
/// slower, older copy clobbering a faster, newer one when screenshots are
/// taken back-to-back.
enum ClipboardWriter {
    static func copy(_ url: URL, generation: Int, currentGeneration: @escaping () -> Int) {
        let ext = url.pathExtension.lowercased()

        if ext == "mov" {
            DispatchQueue.global(qos: .userInitiated).async {
                waitForStableSize(url)
                guard generation == currentGeneration() else { return }
                DispatchQueue.main.async {
                    let pb = NSPasteboard.general
                    pb.clearContents()
                    pb.writeObjects([url as NSURL])
                }
            }
        } else {
            DispatchQueue.global(qos: .userInitiated).async {
                guard let image = NSImage(contentsOf: url) else { return }
                guard generation == currentGeneration() else { return }
                DispatchQueue.main.async {
                    let pb = NSPasteboard.general
                    pb.clearContents()
                    pb.writeObjects([image])
                }
            }
        }
    }

    /// Screen recordings keep growing after the file appears; wait until
    /// the size stops changing before treating it as finished.
    private static func waitForStableSize(_ url: URL) {
        var lastSize: Int64 = -1
        var tries = 0
        while tries < 600 {
            guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
                  let size = attrs[.size] as? Int64 else { return }
            if size == lastSize { return }
            lastSize = size
            Thread.sleep(forTimeInterval: 1)
            tries += 1
        }
    }
}
