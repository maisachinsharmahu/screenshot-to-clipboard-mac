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
                waitForStableSize(url, pollInterval: 1.0, maxTries: 600)
                guard generation == currentGeneration() else { return }
                DispatchQueue.main.async {
                    let pb = NSPasteboard.general
                    pb.clearContents()
                    pb.writeObjects([url as NSURL])
                }
            }
        } else {
            DispatchQueue.global(qos: .userInitiated).async {
                // The watcher fires the instant the file is *created*, which
                // can be before macOS finishes writing its bytes — reading
                // too early yields a nil/partial NSImage that silently drops
                // the copy until the next safety-net poll. Screenshots write
                // fast, so a short stabilization wait (unlike the multi-
                // second one recordings need) is enough to avoid that.
                waitForStableSize(url, pollInterval: 0.05, maxTries: 40)

                var image = NSImage(contentsOf: url)
                var attempt = 0
                while image == nil && attempt < 5 {
                    Thread.sleep(forTimeInterval: 0.05)
                    image = NSImage(contentsOf: url)
                    attempt += 1
                }
                guard let image else { return }
                guard generation == currentGeneration() else { return }
                DispatchQueue.main.async {
                    let pb = NSPasteboard.general
                    pb.clearContents()
                    pb.writeObjects([image])
                }
            }
        }
    }

    /// Same generation-guarded write, but for an image already in memory
    /// (the just-flattened markup export) -- no disk read needed.
    static func copyImage(_ image: NSImage, generation: Int, currentGeneration: @escaping () -> Int) {
        guard generation == currentGeneration() else { return }
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.writeObjects([image])
    }

    /// Waits until a file's size stops changing between polls, i.e. macOS
    /// has finished writing it. Returns as soon as two consecutive reads
    /// agree, or after maxTries polls if it never stabilizes.
    private static func waitForStableSize(_ url: URL, pollInterval: TimeInterval, maxTries: Int) {
        var lastSize: Int64 = -1
        var tries = 0
        while tries < maxTries {
            guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
                  let size = attrs[.size] as? Int64 else { return }
            if size == lastSize && size > 0 { return }
            lastSize = size
            Thread.sleep(forTimeInterval: pollInterval)
            tries += 1
        }
    }
}
