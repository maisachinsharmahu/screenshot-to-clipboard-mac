# Prototype v1 (bash/launchd) — superseded

This folder is a historical archive of the first working prototype, built
before ClipShot became a native Swift app. Kept for reference only — **not
used by the app and not run by anything.**

Evolution:
1. `screenshot-clipboard-watcher.sh` v1 — polled the screenshot folder,
   copied new files via `osascript`'s AppleScript picture coercion. Worked,
   but slow (multi-second `read file as «class PNGf»` coercion) and used a
   `launchd` `StartInterval` timer (rejected as wasteful polling).
2. Switched `launchd` trigger from `StartInterval` to `WatchPaths` —
   discovered empirically that `WatchPaths` has large, unpredictable
   latency (10–30s+) on this system; unsuitable for near-instant copying.
3. Switched to a persistent single process with a tight `sleep` loop
   instead of a repeatedly-spawned job — fixed the "many processes" concern
   without giving up responsiveness.
4. Discovered the real root cause of unreliable delivery: **macOS silently
   blocks unapproved background processes (bare `/bin/bash` under
   `launchd`, no app identity) from the TCC-protected Desktop/Documents/
   Downloads folders** — no error, `find` just returns nothing. Fixed by
   moving the watched folder to `~/Screenshots` (a plain, unprotected
   folder) and repointing `com.apple.screencapture location` there.
5. Replaced the slow AppleScript coercion (`copy-to-clipboard.js`, a JXA/
   `osascript -l JavaScript` helper using `NSPasteboard` directly) — much
   faster (~0.1–0.2s) than the AppleScript picture-class approach.
6. `com.sachinsharma.screenshotclipboard.plist` — the `launchd` LaunchAgent
   that kept the persistent script running and auto-started it at login.

All of these lessons (folder must not be Desktop/Documents/Downloads;
avoid slow AppleScript coercion; avoid `WatchPaths`) carried directly into
the native app's design — see `Sources/ClipShot/` in the repo root.
