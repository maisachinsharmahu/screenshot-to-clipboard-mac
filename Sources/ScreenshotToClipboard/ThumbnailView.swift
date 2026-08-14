import SwiftUI
import QuickLookThumbnailing

/// Async thumbnail generator with a simple in-memory cache, used by the
/// gallery grid. Works for both images and .mov recordings via QuickLook.
final class ThumbnailCache {
    static let shared = ThumbnailCache()
    private var cache = NSCache<NSString, NSImage>()

    func thumbnail(for url: URL, size: CGSize, completion: @escaping (NSImage?) -> Void) {
        let key = "\(url.path)|\(url.resourceModificationStamp)" as NSString
        if let cached = cache.object(forKey: key) {
            completion(cached)
            return
        }
        let scale = NSScreen.main?.backingScaleFactor ?? 2
        let request = QLThumbnailGenerator.Request(
            fileAt: url,
            size: size,
            scale: scale,
            representationTypes: .thumbnail
        )
        QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { [weak self] rep, _ in
            let image = rep?.nsImage
            if let image { self?.cache.setObject(image, forKey: key) }
            DispatchQueue.main.async { completion(image) }
        }
    }
}

private extension URL {
    var resourceModificationStamp: String {
        let date = (try? resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
        return String(date.timeIntervalSince1970)
    }
}

struct ThumbnailView: View {
    let url: URL
    let size: CGFloat
    @State private var image: NSImage?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.12))
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                ProgressView().controlSize(.small)
            }
            if url.pathExtension.lowercased() == "mov" {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.white, .black.opacity(0.4))
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            ThumbnailCache.shared.thumbnail(for: url, size: CGSize(width: size, height: size)) { image = $0 }
        }
    }
}
