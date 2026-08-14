# Screenshot to Clipboard

**Screenshots that copy themselves.**

macOS shows your screenshot as a floating thumbnail for a few seconds, then
it's gone — and if you didn't drag it somewhere in time, you're digging
through Finder to find it. Screenshot to Clipboard fixes that: every screenshot and screen
recording you take is copied to your clipboard automatically, the instant
it's saved. Just `⌘⇧4`, then `⌘V` wherever you need it.

It's a small native macOS menu bar app. No network access, no accounts, no
telemetry — see [PRIVACY.md](PRIVACY.md).

## Features

- **Automatic clipboard copy** for `.png`/`.jpg`/`.heic`/`.tiff` screenshots
  and `.mov` screen recordings, the moment they're written to disk.
- **Native, in-process file watching** (`DispatchSource` + a safety-net
  poll) — not a fragile shell-script cron job, so it's fast and reliable.
- **Gallery window** — open the app anytime to see every screenshot you've
  taken, re-copy one, reveal it in Finder, or trash it.
- **Menu bar only** — no Dock icon clutter; it just runs.
- **Launch at Login**, optional copy notifications, and a settings window.
- **100% local.** No cloud, no sign-in, no data collection of any kind.

## Install

### Option A — Download (recommended)

Grab the latest `Screenshot to Clipboard.dmg` from the [Releases](../../releases) page and
open it. Inside you'll find `Screenshot to Clipboard.app` and **`Install Screenshot to Clipboard.command`**
— double-click the `.command` file for a guided, one-click install (it
copies the app to `/Applications`, clears the macOS download-quarantine
flag that causes the unnotarized-app warning below, and launches it).

Because Screenshot to Clipboard isn't notarized by Apple (that requires a paid $99/year
Developer Program membership, which this free, source-available project
doesn't have), opening it manually will otherwise trip a Gatekeeper
warning on first launch. **See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)**
for the one-command fix if you hit "Screenshot to Clipboard.app is damaged" or
"cannot be opened."

If you'd rather verify the binary yourself first, build from source
instead (Option B) — the build script shows exactly what's happening at
every step.

### Option B — Build from source

Requires Xcode (or the Xcode Command Line Tools) and Swift 5.9+.

```bash
git clone https://github.com/maisachinsharmahu/screenshot-to-clipboard-mac.git
cd screenshot-to-clipboard-mac
./scripts/build_app.sh
open "dist/Screenshot to Clipboard.app"
```

## First launch

Screenshot to Clipboard will ask you to choose a folder to watch. **It cannot watch
Desktop, Documents, or Downloads** — macOS silently blocks unapproved
background processes from those special folders, which makes the feature
unreliable, so Screenshot to Clipboard doesn't allow it. Pick (or create) a plain folder
instead, e.g. `~/Screenshots` (this is the suggested default). Screenshot to Clipboard will
also point macOS's own screenshot tool (`⌘⇧3/4/5`) at that folder for you,
and **turns off the floating screenshot thumbnail preview** — that preview
holds your screenshot in a temporary staging location until it's dismissed
or times out, which delays the real file from ever reaching your watched
folder. Since Screenshot to Clipboard copies it automatically anyway, you don't need the
preview; disabling it means the file is written straight to disk with no
delay at all.

## How it works

- A fast poll (every 0.3s) checks your chosen folder for a new file — this
  was chosen over a real-time OS file-system-event stream because, in
  testing, actual screenshot writes didn't reliably fire that event; a
  plain poll turned out to be the fast, reliable option.
- When a new matching file appears, Screenshot to Clipboard waits for it to finish
  being written (so a half-saved file is never read), then loads it and
  writes it directly to `NSPasteboard` — no shelling out to `osascript`,
  no intermediate processes.
- A generation counter guards against a slow copy finishing *after* a
  newer one, so rapid back-to-back screenshots never leave a stale image on
  your clipboard.
- Screen recordings (`.mov`) are copied as a **file reference** once their
  file size stops growing (i.e. once the recording is finished writing),
  since videos aren't put on the clipboard as raw pixel data.
- The one-time system changes made during setup (pointing macOS's
  screenshot location, disabling the floating thumbnail) aren't hidden
  inline in the compiled app — they live in a plain, readable shell script
  bundled at `Contents/Resources/configure-screencapture.sh`, so you can
  see exactly what it runs before or after installing. Source:
  [`Resources/configure-screencapture.sh`](Resources/configure-screencapture.sh).

## Uninstall

1. Quit Screenshot to Clipboard from the menu bar (or `killall ScreenshotToClipboard`).
2. Move `/Applications/Screenshot to Clipboard.app` to the Trash.
3. Optional cleanup:
   ```bash
   defaults delete com.screenshottoclipboard.app
   ```
4. If you'd like macOS screenshots to go back to the Desktop, and to bring
   back the floating thumbnail preview:
   ```bash
   defaults delete com.apple.screencapture location
   defaults delete com.apple.screencapture show-thumbnail
   killall SystemUIServer
   ```

## Contributing

Issues and PRs welcome — see [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[PolyForm Noncommercial 1.0.0](LICENSE) — free for personal, educational,
and nonprofit use. Commercial use requires a separate license from the
copyright holder.
