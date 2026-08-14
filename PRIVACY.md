# Privacy Policy

**Last updated: August 2026**

ClipShot is a local-only macOS utility. This policy is short because there
isn't much to disclose.

## What ClipShot does

- Watches **one folder you explicitly choose** during setup for new
  screenshot/screen-recording files.
- When a new file appears, it copies that file's contents to your system
  clipboard (`NSPasteboard`) — nothing else.
- Optionally shows a local notification ("Copied to Clipboard") using
  Apple's `UNUserNotificationCenter`.
- Optionally registers itself as a login item via Apple's `SMAppService`
  API, if you enable "Launch at Login."

## What ClipShot does not do

- **No network access.** ClipShot makes no HTTP requests, has no analytics
  SDK, no crash reporter, and no auto-update pinging. You can verify this
  yourself — the source is public, and you can check with Little Snitch or
  the macOS network monitor.
- **No account, no sign-in, no cloud sync.**
- **No telemetry or usage tracking of any kind.**
- **No access to any folder other than the one you chose.** ClipShot never
  reads your Desktop, Documents, Downloads, Photos, or any other files.
- **No reading of existing clipboard contents.** ClipShot only *writes* to
  the clipboard when it detects a new file it created a reference to; it
  never inspects what's already there.

## Data storage

The only data ClipShot stores is your own settings (which folder you chose,
whether notifications are on, whether login-launch is on), saved locally via
`UserDefaults` in `~/Library/Preferences/com.clipshot.app.plist`. This never
leaves your Mac.

## Screenshots and recordings themselves

ClipShot does not copy, move, upload, or duplicate your screenshot files
anywhere. It only reads the file already sitting in your chosen folder
(which macOS itself wrote there) long enough to place its contents on the
clipboard.

## Questions

Open an issue on the GitHub repository.
