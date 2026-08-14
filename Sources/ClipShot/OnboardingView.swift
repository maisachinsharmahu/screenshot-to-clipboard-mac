import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    let onFinished: () -> Void

    @State private var step = 0
    @State private var chosenFolder: URL?

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.badge.checkmark")
                .font(.system(size: 48))
                .foregroundStyle(.tint)

            Text("Welcome to ClipShot")
                .font(.title.bold())

            Text("Every screenshot and screen recording you take is copied to your clipboard automatically — no more racing the floating thumbnail before it vanishes.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 400)

            VStack(alignment: .leading, spacing: 10) {
                privacyLine("lock.fill", "Runs entirely on your Mac. No network access, no accounts, no telemetry.")
                privacyLine("folder.fill", "Watches one folder you choose — nothing else on your disk.")
                privacyLine("eye.slash.fill", "Never reads clipboard contents you didn't create with a screenshot.")
            }
            .padding(16)
            .background(Color.gray.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Spacer(minLength: 4)

            if let chosenFolder {
                Label(chosenFolder.path, systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.callout)
            }

            Button(chosenFolder == nil ? "Choose Screenshots Folder" : "Change Folder") {
                FolderPicker.choose(suggested: AppState.defaultSuggestedFolder) { url in
                    guard let url else { return }
                    chosenFolder = url
                }
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)

            Button("Get Started") {
                if let chosenFolder {
                    appState.setWatchFolder(chosenFolder)
                } else {
                    appState.setWatchFolder(AppState.defaultSuggestedFolder)
                }
                appState.completeOnboarding()
                onFinished()
            }
            .disabled(false)
        }
        .padding(28)
    }

    private func privacyLine(_ symbol: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: symbol).frame(width: 18)
            Text(text).font(.callout)
        }
    }
}
