import Foundation
import AppKit
import UserNotifications
import ServiceManagement

/// Central, observable app state: settings, the watched folder, and the
/// live list of screenshots/recordings shown in the gallery.
final class AppState: ObservableObject {
    static let shared = AppState()

    @Published var watchFolderPath: String? {
        didSet { UserDefaults.standard.set(watchFolderPath, forKey: Keys.watchFolder) }
    }
    @Published var files: [URL] = []
    @Published var launchAtLogin: Bool = false {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: Keys.launchAtLoginDesired)
            applyLaunchAtLogin()
        }
    }
    @Published var showNotifications: Bool {
        didSet { UserDefaults.standard.set(showNotifications, forKey: Keys.notifications) }
    }
    @Published var openEditorOnCapture: Bool {
        didSet { UserDefaults.standard.set(openEditorOnCapture, forKey: Keys.openEditor) }
    }
    @Published var needsOnboarding: Bool
    @Published var lastCopiedName: String?

    /// Set by AppDelegate at launch. Fired instead of an immediate copy
    /// when a new screenshot arrives and openEditorOnCapture is on, so the
    /// window layer (which AppState doesn't own) can present the markup
    /// editor. Never fired for videos -- those always copy instantly.
    var onScreenshotCaptured: ((URL) -> Void)?

    private var watcher: ScreenshotWatcher?
    private var generation: Int = 0
    private let imageExtensions: Set<String> = ["png", "jpg", "jpeg", "heic", "tiff", "tif"]

    private enum Keys {
        static let watchFolder = "watchFolderPath"
        static let notifications = "showNotifications"
        static let onboardingDone = "onboardingDone"
        static let launchAtLoginDesired = "launchAtLoginDesired"
        static let openEditor = "openEditorOnCapture"
    }

    private init() {
        let defaults = UserDefaults.standard
        self.watchFolderPath = defaults.string(forKey: Keys.watchFolder)
        self.showNotifications = defaults.object(forKey: Keys.notifications) as? Bool ?? true
        self.openEditorOnCapture = defaults.object(forKey: Keys.openEditor) as? Bool ?? true
        self.needsOnboarding = !defaults.bool(forKey: Keys.onboardingDone)
        self.launchAtLogin = SMAppService.mainApp.status == .enabled

        // Reconcile a previously-expressed preference (e.g. set up before
        // the app was ever launched) with actual SMAppService state.
        let desired = defaults.object(forKey: Keys.launchAtLoginDesired) as? Bool
        if let desired, desired != launchAtLogin {
            launchAtLogin = desired // triggers didSet -> applyLaunchAtLogin()
        }

        if let path = watchFolderPath, FileManager.default.fileExists(atPath: path) {
            startWatching(URL(fileURLWithPath: path))
        }
    }

    // MARK: - Folder validation

    /// macOS silently restricts unapproved background processes from the
    /// special Desktop/Documents/Downloads folders. Rather than fight that,
    /// ClipShot simply doesn't allow watching them (or anything inside them).
    static func isBlockedFolder(_ url: URL) -> Bool {
        let home = FileManager.default.homeDirectoryForCurrentUser.standardizedFileURL.path
        let blockedNames = ["Desktop", "Documents", "Downloads", "Library"]
        let target = url.standardizedFileURL.path
        for name in blockedNames {
            let blockedPath = home + "/" + name
            if target == blockedPath || target.hasPrefix(blockedPath + "/") {
                return true
            }
        }
        return false
    }

    static var defaultSuggestedFolder: URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Screenshots")
    }

    // MARK: - Folder setup

    @discardableResult
    func setWatchFolder(_ url: URL) -> Bool {
        guard !Self.isBlockedFolder(url) else { return false }
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        watchFolderPath = url.path
        pointSystemScreenshotsAt(url)
        startWatching(url)
        return true
    }

    /// Runs the bundled configure-screencapture.sh (Contents/Resources/) —
    /// kept as its own script file rather than inline Process() calls so
    /// exactly what this app does to your system defaults is a plain,
    /// readable, auditable file instead of hidden in the compiled binary.
    private func pointSystemScreenshotsAt(_ url: URL) {
        guard let scriptPath = Bundle.main.path(forResource: "configure-screencapture", ofType: "sh") else {
            return
        }
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/bash")
        task.arguments = [scriptPath, url.path]
        try? task.run()
        task.waitUntilExit()
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: Keys.onboardingDone)
        needsOnboarding = false
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        // Runs in the background no matter what, from the very first setup —
        // not an opt-in the user has to remember to flip.
        launchAtLogin = true
    }

    // MARK: - Watching

    private func startWatching(_ url: URL) {
        watcher?.stop()
        let w = ScreenshotWatcher(folder: url)
        w.onNewFile = { [weak self] fileURL in
            self?.handleNewFile(fileURL)
        }
        w.onFilesChanged = { [weak self] urls in
            DispatchQueue.main.async { self?.files = urls }
        }
        w.start()
        watcher = w
    }

    private func handleNewFile(_ url: URL) {
        let isImage = imageExtensions.contains(url.pathExtension.lowercased())
        if isImage && openEditorOnCapture {
            DispatchQueue.main.async { [weak self] in
                self?.onScreenshotCaptured?(url)
            }
            return
        }
        copyAndAnnounce(url)
    }

    private func copyAndAnnounce(_ url: URL) {
        generation += 1
        let myGeneration = generation
        ClipboardWriter.copy(url, generation: myGeneration, currentGeneration: { [weak self] in self?.generation ?? -1 })
        DispatchQueue.main.async { [weak self] in
            self?.lastCopiedName = url.lastPathComponent
            self?.notify(fileName: url.lastPathComponent)
        }
    }

    /// Called by AppDelegate when the markup editor finishes with "Done":
    /// overwrites the file with the annotated version and copies that.
    func finalizeEditedScreenshot(url: URL, image: NSImage) {
        if let tiff = image.tiffRepresentation,
           let rep = NSBitmapImageRep(data: tiff),
           let png = rep.representation(using: .png, properties: [:]) {
            try? png.write(to: url)
        }
        generation += 1
        let myGeneration = generation
        ClipboardWriter.copyImage(image, generation: myGeneration, currentGeneration: { [weak self] in self?.generation ?? -1 })
        lastCopiedName = url.lastPathComponent
        notify(fileName: url.lastPathComponent)
    }

    /// Called by AppDelegate when the markup editor is skipped/cancelled:
    /// the plain, unedited screenshot still gets copied, same as if the
    /// editor were off -- this app's core promise (something always ends
    /// up on your clipboard automatically) holds either way.
    func skipEditingAndCopyOriginal(url: URL) {
        copyAndAnnounce(url)
    }

    private func notify(fileName: String) {
        guard showNotifications else { return }
        let content = UNMutableNotificationContent()
        content.title = "Copied to Clipboard"
        content.body = fileName
        content.sound = nil
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Launch at login

    private func applyLaunchAtLogin() {
        do {
            if launchAtLogin {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
        } catch {
            // Non-fatal: reflect actual system state back into the toggle.
            DispatchQueue.main.async { [weak self] in
                self?.launchAtLogin = SMAppService.mainApp.status == .enabled
            }
        }
    }

    // MARK: - Manual actions (gallery row menu)

    func recopy(_ url: URL) {
        // A deliberate "copy this again" from the gallery is not a new
        // capture -- always instant, never reopens the markup editor.
        copyAndAnnounce(url)
    }

    func reveal(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    func delete(_ url: URL) {
        try? FileManager.default.trashItem(at: url, resultingItemURL: nil)
    }
}
