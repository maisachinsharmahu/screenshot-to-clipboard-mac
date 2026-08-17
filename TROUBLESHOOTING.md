# Troubleshooting

## "ClipShot.app is damaged and can't be opened. You should move it to the Trash."

This is **not actual damage** — it's macOS Gatekeeper being strict about
apps that (a) aren't notarized by Apple and (b) were downloaded through a
browser, which tags the file with a "quarantine" flag. ClipShot isn't
notarized because that requires a paid $99/year Apple Developer Program
membership, which this free, noncommercial project doesn't have.

**Do not click "Move to Trash."** Fix it instead — pick one:

### Option A — double-click the fix file (easiest)

The DMG includes **`Fix Permission Error.command`**, right next to the app
icon. Double-click it, confirm the one "downloaded from the Internet, are
you sure?" dialog, and it's fixed. This runs exactly one command:

```bash
xattr -cr "/Applications/ClipShot.app"
```

That's genuinely all it does — open it in a text editor first if you want
to see for yourself before running it.

### Option B — the installer script

**`Install ClipShot.command`** (also in the DMG) does the same fix as part
of a full install: copies ClipShot to `/Applications`, clears the
quarantine flag, and launches it.

### Option C — Terminal, manually

Open **Terminal** (Spotlight → type "Terminal" → Enter) and run:

```bash
xattr -cr "/Applications/ClipShot.app"
```

(If you haven't dragged it to Applications yet, point the command at
wherever it currently is, e.g. `~/Downloads/ClipShot.app`.)

Then double-click ClipShot.app again — it will open normally.

### Option D — right-click Open (works only for the milder warning)

If you instead see **"ClipShot.app cannot be opened because the developer
cannot be verified"** (a gentler message than "damaged"), you can bypass it
without Terminal:
1. Right-click (Control-click) `ClipShot.app` → **Open**.
2. Click **Open** again in the dialog.

This does *not* work for the "damaged" message above — use Option A, B, or
C for that one.

### Why this happens at all

Downloaded, unnotarized, ad-hoc-signed apps trip a stricter Gatekeeper path
on modern macOS than older "unidentified developer" apps did — Apple
intentionally made this harder to bypass by accident. `xattr -cr` removes
the `com.apple.quarantine` extended attribute the browser added; once it's
gone, ClipShot's (valid, just not notarized) ad-hoc signature is enough for
Gatekeeper to allow it.

---

## Screenshot copied to clipboard, but it's the *previous* one

This was a real bug in early versions and is fixed as of the current
release, via two changes:
1. Each copy operation waits for the file to finish being written and
   checks it's still the most-recently-requested file right before writing
   to the pasteboard, so a slow/partial older copy can never overwrite a
   faster newer one.
2. Setup now disables macOS's floating screenshot thumbnail preview, which
   was itself the main source of delay — see the next section.

If you still see this, please open a GitHub issue with your macOS version.

## A screenshot never shows up in the watched folder at all / feels delayed

If you can find the file in Finder but at a path like
`/private/var/folders/.../TemporaryItems/NSIRD_screencaptureui_.../Screenshot ....png`
instead of your chosen folder, that's macOS's **floating thumbnail
preview** — it holds the screenshot in a temporary staging location until
it's dismissed or times out, before the real file ever reaches your
watched folder. ClipShot's setup step disables this preview automatically
(`defaults write com.apple.screencapture show-thumbnail -bool false`) so
screenshots save straight to disk immediately. If you still see this
behavior, confirm that setting stuck:

```bash
defaults read com.apple.screencapture show-thumbnail
```

It should print `0`. If it doesn't, run:

```bash
defaults write com.apple.screencapture show-thumbnail -bool false
killall SystemUIServer
```

## ClipShot doesn't run after a restart

Open ClipShot → menu bar icon → **Settings…** and confirm **Launch at
Login** is on. If you just installed, this should already be on
automatically — if it got turned off, macOS may be blocking it in
**System Settings → General → Login Items & Extensions**; make sure
ClipShot is allowed there.

## Still stuck?

Open an issue: <https://github.com/maisachinsharmahu/ClipShot/issues>
