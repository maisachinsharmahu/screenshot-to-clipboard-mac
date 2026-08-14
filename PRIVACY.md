# Privacy Policy

**Last updated: August 2026**

Screenshot to Clipboard is a local-only macOS utility. This policy is short because there
isn't much to disclose.

## What Screenshot to Clipboard does

- Watches **one folder you explicitly choose** during setup for new
  screenshot/screen-recording files.
- When a new file appears, it copies that file's contents to your system
  clipboard (`NSPasteboard`) — nothing else.
- Optionally shows a local notification ("Copied to Clipboard") using
  Apple's `UNUserNotificationCenter`.
- Optionally registers itself as a login item via Apple's `SMAppService`
  API, if you enable "Launch at Login."

## What Screenshot to Clipboard does not do

- **No network access.** Screenshot to Clipboard makes no HTTP requests, has no analytics
  SDK, no crash reporter, and no auto-update pinging. You can verify this
  yourself — the source is public, and you can check with Little Snitch or
  the macOS network monitor.
- **No account, no sign-in, no cloud sync.**
- **No telemetry or usage tracking of any kind.**
- **No access to any folder other than the one you chose.** Screenshot to Clipboard never
  reads your Desktop, Documents, Downloads, Photos, or any other files.
- **No reading of existing clipboard contents.** Screenshot to Clipboard only *writes* to
  the clipboard when it detects a new file it created a reference to; it
  never inspects what's already there.

## Data storage

The only data Screenshot to Clipboard stores is your own settings (which folder you chose,
whether notifications are on, whether login-launch is on), saved locally via
`UserDefaults` in `~/Library/Preferences/com.screenshottoclipboard.app.plist`. This never
leaves your Mac.

## Screenshots and recordings themselves

Screenshot to Clipboard does not copy, move, upload, or duplicate your screenshot files
anywhere. It only reads the file already sitting in your chosen folder
(which macOS itself wrote there) long enough to place its contents on the
clipboard.

## Questions

Open an issue on the GitHub repository.
