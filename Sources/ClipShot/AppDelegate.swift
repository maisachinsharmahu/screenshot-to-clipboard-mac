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

    func showGallery() {
        NSApp.setActivationPolicy(.regular)
        if galleryWindow == nil {
            let view = GalleryView().environmentObject(appState)
            let hosting = NSHostingController(rootView: view)
            let window = NSWindow(contentViewController: hosting)
            window.title = "ClipShot"
            window.setContentSize(NSSize(width: 720, height: 560))
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            window.center()
            window.isReleasedWhenClosed = false
            window.delegate = self
            galleryWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
        galleryWindow?.makeKeyAndOrderFront(nil)
    }

    func showSettings() {
        NSApp.setActivationPolicy(.regular)
        let view = SettingsView().environmentObject(appState)
        let hosting = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: hosting)
        window.title = "ClipShot Settings"
        window.setContentSize(NSSize(width: 460, height: 380))
        window.styleMask = [.titled, .closable]
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func showOnboarding() {
        NSApp.setActivationPolicy(.regular)
        let view = OnboardingView(onFinished: { [weak self] in
            self?.onboardingWindow?.close()
            self?.onboardingWindow = nil
            NSApp.setActivationPolicy(.accessory)
        })
        .environmentObject(appState)
        let hosting = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: hosting)
        window.title = "Welcome to ClipShot"
        window.setContentSize(NSSize(width: 520, height: 480))
        window.styleMask = [.titled, .closable]
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = self
        onboardingWindow = window
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        // Drop back to agent (no Dock icon) once no regular windows remain.
        DispatchQueue.main.async {
            let anyVisible = NSApp.windows.contains { $0.isVisible && $0.styleMask.contains(.titled) }
            if !anyVisible {
                NSApp.setActivationPolicy(.accessory)
            }
        }
    }
}
