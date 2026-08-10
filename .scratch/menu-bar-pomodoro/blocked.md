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

## Ticket 09 — Native alert validation unavailable

Date: 2026-08-10

Attempted: Completed the Welcome popover, Alerts settings, authorization policy, missed-alert handling, notification actions, embedded chime, and an isolated `PomoUITests` target. `swift build`, Xcode `build-for-testing`, and the full SwiftPM suite pass.

Observed result: The focused Welcome accessibility test now passes consistently with a fresh per-run preferences/support profile. Interactive notification permission/action testing and clean-profile VoiceOver validation remain unexecuted.

Required: Extend the UI target for Alerts and notification action routing, then run clean-profile macOS validation for allowed, denied, pending, and disabled notifications, sound playback, keyboard navigation, and VoiceOver semantics.
