import AppKit
import SwiftUI

private extension NSImage {
    /// NSImage.size reports point size (which can differ from actual pixel
    /// dimensions on Retina screenshots); the markup editor needs true
    /// pixel dimensions so exports stay full resolution.
    var pixelSize: CGSize {
        guard let rep = representations.first else { return size }
        return CGSize(width: rep.pixelsWide, height: rep.pixelsHigh)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var galleryWindow: NSWindow?
    private var onboardingWindow: NSWindow?
    private var markupWindow: NSWindow?
    private let appState = AppState.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()

        appState.onScreenshotCaptured = { [weak self] url in
            self?.showMarkupEditor(for: url)
        }

        if appState.needsOnboarding {
            showOnboarding()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showGallery()
        return true
    }

    /// Belt-and-suspenders: the background watcher must never die just
    /// because every window happened to close. Only the explicit "Quit
    /// ClipShot" menu item should terminate the app.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    // MARK: - Status bar

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "photo.badge.checkmark", accessibilityDescription: "ClipShot")
        }

        let menu = NSMenu()
        menu.addItem(withTitle: "Show Screenshots", action: #selector(showGalleryMenuAction), keyEquivalent: "")
            .target = self
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Settings…", action: #selector(showSettingsMenuAction), keyEquivalent: ",")
            .target = self
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Quit ClipShot", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        item.menu = menu
        statusItem = item
    }

    @objc private func showGalleryMenuAction() { showGallery() }
    @objc private func showSettingsMenuAction() { showSettings() }

    // MARK: - Windows
    //
    // Deliberately never call NSApp.setActivationPolicy(.regular) here.
    // Staying .accessory the whole time (no Dock icon, no synthesized
    // application menu bar) means there's never an auto-bound Cmd+Q to
    // accidentally terminate the whole app when someone just wants to
    // close a window -- windows still open, focus, and work normally
    // under .accessory, they just don't get Dock/Cmd+Tab presence.

    func showGallery() {
        if galleryWindow == nil {
            let view = GalleryView().environmentObject(appState)
            let hosting = NSHostingController(rootView: view)
            let window = NSWindow(contentViewController: hosting)
            window.title = "ClipShot"
            window.subtitle = "Screen to Clipboard"
            window.setContentSize(NSSize(width: 720, height: 560))
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            window.center()
            window.isReleasedWhenClosed = false
            galleryWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
        galleryWindow?.makeKeyAndOrderFront(nil)
    }

    func showSettings() {
        let view = SettingsView().environmentObject(appState)
        let hosting = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: hosting)
        window.title = "ClipShot Settings"
        window.setContentSize(NSSize(width: 460, height: 380))
        window.styleMask = [.titled, .closable]
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// A new screenshot arrived and the editor is enabled: show the full-
    /// size markup window. If one's already open for an older screenshot,
    /// it's superseded (closed without copying) so only the latest ever
    /// waits for you -- same "always the newest wins" rule the rest of the
    /// app follows.
    func showMarkupEditor(for url: URL) {
        markupWindow?.close()
        markupWindow = nil

        guard let baseImage = NSImage(contentsOf: url) else {
            appState.skipEditingAndCopyOriginal(url: url)
            return
        }
        let pixelSize = baseImage.pixelSize

        // Initial window size only -- the canvas itself is driven by a
        // GeometryReader inside MarkupEditorView, so resizing this window
        // (now .resizable) reflows the content live rather than clipping it.
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let maxDisplayWidth = screenFrame.width * 0.82
        let maxDisplayHeight = screenFrame.height * 0.74
        let fitScale = min(1, min(maxDisplayWidth / pixelSize.width, maxDisplayHeight / pixelSize.height))
        let initialContentSize = CGSize(width: pixelSize.width * fitScale, height: pixelSize.height * fitScale)

        let view = MarkupEditorView(
            baseImage: baseImage,
            imagePixelSize: pixelSize,
            onDone: { [weak self] edited in
                self?.appState.finalizeEditedScreenshot(url: url, image: edited)
                self?.markupWindow?.close()
                self?.markupWindow = nil
            },
            onCancel: { [weak self] in
                self?.appState.skipEditingAndCopyOriginal(url: url)
                self?.markupWindow?.close()
                self?.markupWindow = nil
            }
        )
        let hosting = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: hosting)
        window.styleMask = [.titled, .closable, .resizable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        // Deliberately NOT isMovableByWindowBackground: with a hidden title
        // bar, that makes the whole window draggable from any unclaimed
        // background pixel -- which raced against and stole the canvas's
        // own drag gestures, making the window move instead of drawing.
        window.setContentSize(NSSize(width: initialContentSize.width + 48, height: initialContentSize.height + 130))
        window.minSize = NSSize(width: 420, height: 340)
        window.center()
        window.isReleasedWhenClosed = false
        window.level = .floating
        markupWindow = window

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    private func showOnboarding() {
        let view = OnboardingView(onFinished: { [weak self] in
            self?.onboardingWindow?.close()
            self?.onboardingWindow = nil
        })
        .environmentObject(appState)
        let hosting = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: hosting)
        window.title = "Welcome to ClipShot"
        window.subtitle = "Screen to Clipboard"
        window.setContentSize(NSSize(width: 520, height: 500))
        window.styleMask = [.titled, .closable]
        window.center()
        window.isReleasedWhenClosed = false
        onboardingWindow = window
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
}
