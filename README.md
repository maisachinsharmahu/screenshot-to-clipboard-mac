# ClipShot - Screen to Clipboard

**Screenshots that copy themselves.**

macOS shows your screenshot as a floating thumbnail for a few seconds, then
it's gone — and if you didn't drag it somewhere in time, you're digging
through Finder to find it. ClipShot fixes that: every screenshot and screen
recording you take is copied to your clipboard automatically, the instant
it's saved. Just `⌘⇧4`, then `⌘V` wherever you need it.

It's a small native macOS menu bar app. No network access, no accounts, no
telemetry — see [PRIVACY.md](PRIVACY.md).

## Features

- **Markup editor pops up on every screenshot** (image captures only —
  can be turned off in Settings): a full-size preview with pen, shapes
  (rectangle/ellipse/line/arrow), text, and eraser tools, rendered in a
  hand-drawn "sketchy" style similar to Excalidraw. Click **Done** to copy
  your annotated version, or **Skip** to copy the screenshot as-is —
  either way something always ends up on your clipboard automatically.
- **Automatic clipboard copy** for `.png`/`.jpg`/`.heic`/`.tiff` screenshots
  and `.mov` screen recordings, the moment they're written to disk.
- **Native, in-process file watching** — not a fragile shell-script cron
  job, so it's fast and reliable.
- **Gallery window** — open the app anytime to see every screenshot you've
  taken, re-copy one, reveal it in Finder, or trash it.
- **Menu bar only** — no Dock icon clutter; it just runs.
- **Launch at Login**, optional copy notifications, and a settings window.
- **100% local.** No cloud, no sign-in, no data collection of any kind.

## Install

### Option A — Download (recommended)

Grab the latest `ClipShot.dmg` from the [Releases](../../releases) page and
open it. Inside you'll find `ClipShot.app` and **`Install ClipShot.command`**
— double-click the `.command` file for a guided, one-click install (it
copies the app to `/Applications`, clears the macOS download-quarantine
flag that causes the unnotarized-app warning below, and launches it).

Because ClipShot isn't notarized by Apple (that requires a paid $99/year
Developer Program membership, which this free, source-available project
doesn't have), opening it manually will otherwise trip a Gatekeeper
warning on first launch. **See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)**
for the fix if you hit "ClipShot.app is damaged" or "cannot be opened" —
or just double-click the **`Fix Permission Error.command`** file also
included in the DMG, which runs the one-line fix for you.

If you'd rather verify the binary yourself first, build from source
instead (Option B) — the build script shows exactly what's happening at
every step.

### Option B — Build from source

Requires Xcode (or the Xcode Command Line Tools) and Swift 5.9+.

```bash
git clone https://github.com/maisachinsharmahu/ClipShot.git
cd ClipShot
./scripts/build_app.sh
open "dist/ClipShot.app"
```

## First launch

ClipShot will ask you to choose a folder to watch. **It cannot watch
Desktop, Documents, or Downloads** — macOS silently blocks unapproved
background processes from those special folders, which makes the feature
unreliable, so ClipShot doesn't allow it. Pick (or create) a plain folder
instead, e.g. `~/Screenshots` (this is the suggested default). ClipShot will
also point macOS's own screenshot tool (`⌘⇧3/4/5`) at that folder for you,
and **turns off the floating screenshot thumbnail preview** — that preview
holds your screenshot in a temporary staging location until it's dismissed
or times out, which delays the real file from ever reaching your watched
folder. Since ClipShot copies it automatically anyway, you don't need the
preview; disabling it means the file is written straight to disk with no
delay at all.

## How it works

- A fast poll (every 0.3s) checks your chosen folder for a new file — this
  was chosen over a real-time OS file-system-event stream because, in
  testing, actual screenshot writes didn't reliably fire that event; a
  plain poll turned out to be the fast, reliable option.
- When a new matching file appears, ClipShot waits for it to finish
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

1. Quit ClipShot from the menu bar (or `killall ScreenshotToClipboard`).
2. Move `/Applications/ClipShot.app` to the Trash.
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
