import SwiftUI

struct GalleryView: View {
    @EnvironmentObject var appState: AppState
    private let columns = [GridItem(.adaptive(minimum: 140, maximum: 180), spacing: 14)]

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if appState.files.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(appState.files, id: \.path) { url in
                            GalleryItem(url: url)
                        }
                    }
                    .padding(16)
                }
            }
        }
        .frame(minWidth: 560, minHeight: 420)
    }

    private var header: some View {
        HStack {
            Text("ClipShot").font(.headline)
            Spacer()
            if let name = appState.lastCopiedName {
                Label("Copied \(name)", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
            Text("No screenshots yet")
                .font(.title3)
            Text("Take one with ⌘⇧4 — it'll show up here and land on your clipboard automatically.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct GalleryItem: View {
    let url: URL
    @EnvironmentObject var appState: AppState
    @State private var hovering = false

    var body: some View {
        VStack(spacing: 6) {
            ThumbnailView(url: url, size: 140)
                .overlay(alignment: .topTrailing) {
                    if hovering {
                        actionMenu
                    }
                }
            Text(url.lastPathComponent)
                .font(.caption2)
                .lineLimit(1)
                .truncationMode(.middle)
                .foregroundStyle(.secondary)
        }
        .padding(6)
        .background(hovering ? Color.gray.opacity(0.08) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .onHover { hovering = $0 }
        .onTapGesture(count: 2) { appState.reveal(url) }
    }

    private var actionMenu: some View {
        Menu {
            Button("Copy Again") { appState.recopy(url) }
            Button("Reveal in Finder") { appState.reveal(url) }
            Divider()
            Button("Move to Trash", role: .destructive) { appState.delete(url) }
        } label: {
            Image(systemName: "ellipsis.circle.fill")
                .foregroundStyle(.white, .black.opacity(0.5))
        }
        .menuStyle(.borderlessButton)
        .frame(width: 22, height: 22)
        .padding(4)
    }
}
