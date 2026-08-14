import AppKit

enum FolderPicker {
    /// Presents an NSOpenPanel restricted to directories, retrying until the
    /// user picks something that isn't a blocked special folder (or cancels).
    static func choose(suggested: URL, completion: @escaping (URL?) -> Void) {
        let panel = NSOpenPanel()
        panel.title = "Choose a Screenshots Folder"
        panel.message = "Desktop, Documents, and Downloads can't be used — macOS blocks background apps from watching them reliably. Pick or create a different folder."
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = suggested.deletingLastPathComponent()
        panel.prompt = "Use This Folder"

        panel.begin { response in
            guard response == .OK, let url = panel.urls.first else {
                completion(nil)
                return
            }
            if AppState.isBlockedFolder(url) {
                let alert = NSAlert()
                alert.messageText = "That folder can't be used"
                alert.informativeText = "\"\(url.lastPathComponent)\" is inside a macOS-protected location. Please choose a different folder, like ~/Screenshots."
                alert.alertStyle = .warning
                alert.addButton(withTitle: "Choose Another Folder")
                alert.runModal()
                choose(suggested: suggested, completion: completion)
            } else {
                completion(url)
            }
        }
    }
}
