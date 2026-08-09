# Blockers

## Resolved: Ticket 05 — Manage named Presets and the default

Date: 2026-08-10

Attempted: Built the native Presets Settings window with `swift build`; it completed successfully. The automated SwiftPM suite also passes, but this package has no XCUITest target.

Observed result: Keyboard focus order, delete confirmation presentation, and VoiceOver labels cannot be verified in the current environment.

Resolved: Manual verification on macOS confirmed Tab/Shift-Tab navigation, Classic read-only controls, user-Preset deletion confirmation, and VoiceOver announcements in the Presets Settings window.

## Resolved: Ticket 06 — Quick-start and customize Sessions from the menu

Date: 2026-08-10

Attempted: Built the current native menu and Custom Session popover with `swift build`; it completed successfully. Core and IPC tests verify selected-Preset and configured-CLI recency behavior.

Observed result: Manual macOS screenshots verified Preset editing/default selection, the active menu and Stop confirmation, compact Custom Session fields, and invalid-value feedback. The user confirmed keyboard navigation and VoiceOver labels from this and earlier manual testing.

Resolved: Ticket 06 manual UI/VoiceOver evidence is complete.

## Resolved: Ticket 07 Preset Discovery Blocker

Date: 2026-08-10

Attempted: Implemented TTY-gated plain Classic setup with validated overrides, review, and explicit active-Session replacement confirmation. Builds and 53 automated tests pass.

Observed result: Implemented the Agent-owned read-only `presets` IPC command and versioned discovery response. A real-socket test verifies the default and named Presets return without direct CLI database access.

Resolved: Ticket 07 can resume its terminal Preset-selection implementation.
