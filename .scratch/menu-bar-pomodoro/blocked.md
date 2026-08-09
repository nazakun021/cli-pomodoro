# Blockers

## Resolved: Ticket 05 — Manage named Presets and the default

Date: 2026-08-10

Attempted: Built the native Presets Settings window with `swift build`; it completed successfully. The automated SwiftPM suite also passes, but this package has no XCUITest target.

Observed result: Keyboard focus order, delete confirmation presentation, and VoiceOver labels cannot be verified in the current environment.

Resolved: Manual verification on macOS confirmed Tab/Shift-Tab navigation, Classic read-only controls, user-Preset deletion confirmation, and VoiceOver announcements in the Presets Settings window.

## Blocked: Ticket 06 — Quick-start and customize Sessions from the menu

Date: 2026-08-10

Attempted: Built the current native menu and Custom Session popover with `swift build`; it completed successfully. Core and IPC tests verify selected-Preset and configured-CLI recency behavior.

Observed result: This environment cannot open or automate the macOS status-item popover, VoiceOver, or increased-text presentation. The package has no UI-test target.

Needed: Manual macOS verification at 360 points covering default and recent Quick Start order, Custom Session validation and save/start paths, keyboard focus, and VoiceOver labels.
