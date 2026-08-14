# ClipShot

**Screenshots that copy themselves.**

macOS shows your screenshot as a floating thumbnail for a few seconds, then
it's gone — and if you didn't drag it somewhere in time, you're digging
through Finder to find it. ClipShot fixes that: every screenshot and screen
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

Grab the latest `ClipShot.dmg` from the [Releases](../../releases) page and
open it. Inside you'll find `ClipShot.app` and **`Install ClipShot.command`**
— double-click the `.command` file for a guided, one-click install (it
copies the app to `/Applications`, clears the macOS download-quarantine
flag that causes the unnotarized-app warning below, and launches it).

Because ClipShot isn't notarized by Apple (that requires a paid $99/year
Developer Program membership, which this free, source-available project
doesn't have), opening it manually will otherwise trip a Gatekeeper
warning on first launch. **See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)**
for the one-command fix if you hit "ClipShot.app is damaged" or
"cannot be opened."

If you'd rather verify the binary yourself first, build from source
instead (Option B) — the build script shows exactly what's happening at
every step.

### Option B — Build from source

Requires Xcode (or the Xcode Command Line Tools) and Swift 5.9+.

```bash
git clone https://github.com/maisachinsharmahu/clipshot.git
cd clipshot
./scripts/build_app.sh
open dist/ClipShot.app
```

## First launch

ClipShot will ask you to choose a folder to watch. **It cannot watch
Desktop, Documents, or Downloads** — macOS silently blocks unapproved
background processes from those special folders, which makes the feature
unreliable, so ClipShot doesn't allow it. Pick (or create) a plain folder
instead, e.g. `~/Screenshots` (this is the suggested default). ClipShot will
also point macOS's own screenshot tool (`⌘⇧3/4/5`) at that folder for you,
so nothing else changes about how you take screenshots.

## How it works

- A `DispatchSource` file-system-object stream watches your chosen folder
  from inside ClipShot's own process — the same low-level mechanism
  professional screenshot tools use — plus a 2-second safety-net poll in
  case an event is ever missed.
- When a new matching file appears, ClipShot loads it and writes it
  directly to `NSPasteboard` — no shelling out to `osascript`, no
  intermediate processes.
- A generation counter guards against a slow copy finishing *after* a
  newer one, so rapid back-to-back screenshots never leave a stale image on
  your clipboard.
- Screen recordings (`.mov`) are copied as a **file reference** once their
  file size stops growing (i.e. once the recording is finished writing),
  since videos aren't put on the clipboard as raw pixel data.

## Uninstall

1. Quit ClipShot from the menu bar (or `killall ClipShot`).
2. Move `/Applications/ClipShot.app` to the Trash.
3. Optional cleanup:
   ```bash
   defaults delete com.clipshot.app
   ```
4. If you'd like macOS screenshots to go back to the Desktop:
   ```bash
   defaults delete com.apple.screencapture location
   killall SystemUIServer
   ```

## Contributing

Issues and PRs welcome — see [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[PolyForm Noncommercial 1.0.0](LICENSE) — free for personal, educational,
and nonprofit use. Commercial use requires a separate license from the
copyright holder.
