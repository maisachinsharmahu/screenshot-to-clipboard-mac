# Troubleshooting

## "Screenshot to Clipboard.app is damaged and can't be opened. You should move it to the Trash."

This is **not actual damage** — it's macOS Gatekeeper being strict about
apps that (a) aren't notarized by Apple and (b) were downloaded through a
browser, which tags the file with a "quarantine" flag. Screenshot to Clipboard isn't
notarized because that requires a paid $99/year Apple Developer Program
membership, which this free, noncommercial project doesn't have.

**Do not click "Move to Trash."** Fix it instead — pick one:

### Option A — use the installer script (easiest)

The DMG includes **`Install Screenshot to Clipboard.command`** right next to the app icon.
Double-click it. It will:
1. Ask you to confirm ("downloaded from the Internet, are you sure?") —
   click **Open**.
2. Copy Screenshot to Clipboard to `/Applications` and clear the quarantine flag.
3. Launch it automatically.

If macOS still won't run the `.command` file at all, use Option B.

### Option B — Terminal (guaranteed to work)

Open **Terminal** (Spotlight → type "Terminal" → Enter) and run:

```bash
xattr -cr "/Applications/Screenshot to Clipboard.app"
```

(If you haven't dragged it to Applications yet, point the command at
wherever it currently is, e.g. `~/Downloads/Screenshot to Clipboard.app`.)

Then double-click Screenshot to Clipboard.app again — it will open normally.

### Option C — right-click Open (works only for the milder warning)

If you instead see **"Screenshot to Clipboard.app cannot be opened because the developer
cannot be verified"** (a gentler message than "damaged"), you can bypass it
without Terminal:
1. Right-click (Control-click) `Screenshot to Clipboard.app` → **Open**.
2. Click **Open** again in the dialog.

This does *not* work for the "damaged" message above — use Option A or B
for that one.

### Why this happens at all

Downloaded, unnotarized, ad-hoc-signed apps trip a stricter Gatekeeper path
on modern macOS than older "unidentified developer" apps did — Apple
intentionally made this harder to bypass by accident. `xattr -cr` removes
the `com.apple.quarantine` extended attribute the browser added; once it's
gone, Screenshot to Clipboard's (valid, just not notarized) ad-hoc signature is enough for
Gatekeeper to allow it.

---

## Screenshot copied to clipboard, but it's the *previous* one

This was a real bug in early testing and should be fixed as of this
version — each copy operation checks it's still the most-recently-requested
file right before writing to the pasteboard, so a slow older copy can never
overwrite a faster newer one. If you still see this, please open a GitHub
issue with your macOS version.

## A screenshot never shows up in the watched folder at all

If you can find the file in Finder but at a path like
`/private/var/folders/.../TemporaryItems/NSIRD_screencaptureui_.../Screenshot ....png`
instead of your chosen folder, that means you dragged the *floating
thumbnail preview* out before it finished saving — that thumbnail is a
temporary macOS staging file, separate from the real save. Let the
thumbnail sit for a couple of seconds without touching it (or click
elsewhere to dismiss it) and macOS will finish writing it to your chosen
folder on its own; Screenshot to Clipboard will then pick it up immediately.

## Screenshot to Clipboard doesn't run after a restart

Open Screenshot to Clipboard → menu bar icon → **Settings…** and confirm **Launch at
Login** is on. If you just installed, this should already be on
automatically — if it got turned off, macOS may be blocking it in
**System Settings → General → Login Items & Extensions**; make sure
Screenshot to Clipboard is allowed there.

## Still stuck?

Open an issue: <https://github.com/maisachinsharmahu/screenshot-to-clipboard-mac/issues>
