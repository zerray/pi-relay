# Title

Use Flutter for the cross-platform client

# Status

Accepted

# Context

Pi Relay needs Android, macOS, Windows, and Linux clients. Android quality is a first-class requirement. The app is centered on a chat/transcript experience with smooth scrolling, input, gestures, and consistent rendering across platforms.

Tauri v2 was considered because it offers strong desktop shell integration, small bundles, low resource usage, and Web-based text/code rendering.

# Decision

Implement Pi Relay as a Flutter application for Android, macOS, Windows, and Linux. iOS is not part of this effort because the native `../pi-ios` client already exists.

# Consequences

The project optimizes for consistent app behavior and mobile-quality UI across supported platforms. Desktop-native shell integration and bundle size are secondary to a polished cross-platform transcript experience.
