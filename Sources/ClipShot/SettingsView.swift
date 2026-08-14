import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Form {
            Section("Watched Folder") {
                HStack {
                    Text(appState.watchFolderPath ?? "Not set")
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Change…") {
                        FolderPicker.choose(suggested: AppState.defaultSuggestedFolder) { url in
                            guard let url else { return }
                            appState.setWatchFolder(url)
                        }
                    }
                }
            }

            Section("Behavior") {
                Toggle("Launch at Login", isOn: $appState.launchAtLogin)
                Toggle("Show a notification when copied", isOn: $appState.showNotifications)
            }

            Section("About") {
                LabeledContent("Version", value: appVersion)
                Link("Privacy Policy & Source on GitHub", destination: URL(string: "https://github.com/maisachinsharmahu/clipshot")!)
            }
        }
        .padding(20)
        .frame(width: 440)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}
