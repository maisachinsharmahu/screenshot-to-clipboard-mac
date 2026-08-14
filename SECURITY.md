# Security Policy

## Reporting a Vulnerability

If you find a security issue in Screenshot to Clipboard, please open a GitHub issue, or if
it's sensitive, use GitHub's private "Report a vulnerability" flow under the
Security tab of this repository rather than a public issue.

Please include:
- macOS version and Screenshot to Clipboard version
- Steps to reproduce
- What you expected vs. what happened

## Scope notes

- Screenshot to Clipboard is an unsigned, ad-hoc-signed, non-notarized open-source binary
  (no paid Apple Developer Program membership). This means Gatekeeper will
  warn on first launch — see the README for how to verify what you're
  running before opening it.
- Screenshot to Clipboard requests no Accessibility, Screen Recording, Full Disk Access, or
  network entitlements. If a future version ever asks for one of these,
  treat that as suspicious and check the diff before upgrading.
- Because Screenshot to Clipboard writes to the system clipboard automatically, any app
  that reads the clipboard on a timer could observe screenshot content
  slightly sooner than if you'd pasted manually. This is inherent to the
  feature (auto-copy), not a bug — be mindful when screenshotting sensitive
  material on a machine where other software actively polls the clipboard.
