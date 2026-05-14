# Title

Share core mobile and desktop experience

# Status

Accepted

# Context

Pi Relay targets Android, macOS, Windows, and Linux. The app's main behavior is daemon pairing, project/session browsing, transcript viewing, prompt submission, abort, compact, runtime status rendering, and WebSocket synchronization.

The largest expected platform difference is pairing input. Mobile devices can scan a QR code with the camera. Desktop environments should not require camera support and can accept a pasted pairing string.

# Decision

Mobile and desktop clients share the same core features, state model, daemon protocol, and transcript behavior. Platform-specific behavior is limited to shell-level concerns:

- mobile shows a scan-pairing action that opens the camera
- desktop shows a pairing action that opens a dialog for pasting the pairing string
- layouts adapt to available screen size and window dimensions

# Consequences

The implementation should avoid separate mobile and desktop product flows. Core application, domain, and infrastructure code should remain platform-agnostic. Camera scanning is not required for the initial desktop experience as long as pasted pairing strings are supported.
