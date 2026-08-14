import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    let onFinished: () -> Void

    @State private var step: Step = .welcome
    @State private var chosenFolder: URL?

    private enum Step: Int, CaseIterable {
        case welcome, folder, finish
    }

    var body: some View {
        VStack(spacing: 0) {
            stepIndicator
            Divider()

            Group {
                switch step {
                case .welcome: welcomePage
                case .folder: folderPage
                case .finish: finishPage
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(28)
        }
        .frame(width: 520, height: 500)
    }

    private var stepIndicator: some View {
        HStack(spacing: 6) {
            ForEach(Step.allCases, id: \.self) { s in
                Capsule()
                    .fill(s.rawValue <= step.rawValue ? Color.accentColor : Color.gray.opacity(0.25))
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    // MARK: Step 1

    private var welcomePage: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "photo.badge.checkmark")
                .font(.system(size: 52))
                .foregroundStyle(.tint)
            Text("Welcome to Screenshot to Clipboard")
                .font(.title.bold())
            Text("Every screenshot and screen recording you take is copied to your clipboard automatically — no more racing the floating thumbnail before it vanishes.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 400)

            VStack(alignment: .leading, spacing: 10) {
                privacyLine("lock.fill", "Runs entirely on your Mac. No network access, no accounts, no telemetry.")
                privacyLine("folder.fill", "Watches one folder you choose — nothing else on your disk.")
                privacyLine("bolt.fill", "Runs quietly in the background from now on — no need to keep it open.")
            }
            .padding(16)
            .background(Color.gray.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            Spacer()
            Button("Continue") { step = .folder }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
        }
    }

    // MARK: Step 2

    private var folderPage: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "folder.badge.gearshape")
                .font(.system(size: 44))
                .foregroundStyle(.tint)
            Text("Choose a Screenshots Folder")
                .font(.title2.bold())
            Text("This is the only folder Screenshot to Clipboard will ever look at. Desktop, Documents, and Downloads can't be chosen — macOS blocks background apps from watching them reliably.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 400)

            if let chosenFolder {
                Label(chosenFolder.path, systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.callout)
            } else {
                Label(AppState.defaultSuggestedFolder.path, systemImage: "sparkles")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            }

            Button(chosenFolder == nil ? "Choose Folder…" : "Choose a Different Folder…") {
                FolderPicker.choose(suggested: AppState.defaultSuggestedFolder) { url in
                    guard let url else { return }
                    chosenFolder = url
                }
            }
            .controlSize(.large)

            Spacer()
            HStack {
                Button("Back") { step = .welcome }
                Spacer()
                Button("Continue") { step = .finish }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
        }
    }

    // MARK: Step 3

    private var finishPage: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 52))
                .foregroundStyle(.green)
            Text("All Set")
                .font(.title.bold())
            Text("Screenshot to Clipboard will now watch **\((chosenFolder ?? AppState.defaultSuggestedFolder).path)** and copy every new screenshot straight to your clipboard. It'll keep running in the background even after you close this window or restart your Mac.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 420)
            Spacer()
            HStack {
                Button("Back") { step = .folder }
                Spacer()
                Button("Finish Setup") {
                    let folder = chosenFolder ?? AppState.defaultSuggestedFolder
                    appState.setWatchFolder(folder)
                    appState.completeOnboarding()
                    onFinished()
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private func privacyLine(_ symbol: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: symbol).frame(width: 18)
            Text(text).font(.callout)
        }
    }
}
