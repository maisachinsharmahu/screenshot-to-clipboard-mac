# Contributing to ClipShot

Thanks for considering a contribution! ClipShot is a small, focused app —
please keep PRs scoped and avoid adding new permissions/entitlements without
discussion in an issue first (privacy/minimal-permissions is a core design
goal, see [PRIVACY.md](PRIVACY.md)).

## Setup

```bash
git clone https://github.com/maisachinsharmahu/clipshot.git
cd clipshot
swift build
```

Open `Package.swift` in Xcode for a full IDE experience, or edit with any
editor and use `swift build` / `./scripts/build_app.sh` from the terminal.

## Project layout

```
Sources/ClipShot/
  main.swift              — entry point, activation policy
  AppDelegate.swift        — menu bar, window management
  AppState.swift           — settings, orchestration
  ScreenshotWatcher.swift  — DispatchSource folder watcher
  ClipboardWriter.swift    — NSPasteboard writing
  GalleryView.swift        — screenshot history grid (SwiftUI)
  OnboardingView.swift     — first-run setup
  SettingsView.swift       — preferences window
  ThumbnailView.swift      — QuickLook-based async thumbnails
  FolderPicker.swift       — NSOpenPanel + blocked-folder validation
```

## Reporting bugs

Open a GitHub issue with your macOS version, ClipShot version, and repro
steps.

## Pull requests

- Keep changes focused; one logical change per PR.
- Run `./scripts/build_app.sh` and confirm it builds cleanly before
  submitting.
- Describe *why*, not just *what*, in the PR description.
