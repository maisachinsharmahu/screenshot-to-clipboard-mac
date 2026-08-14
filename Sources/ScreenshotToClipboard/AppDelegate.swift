import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var galleryWindow: NSWindow?
    private var onboardingWindow: NSWindow?
    private let appState = AppState.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()

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
