# Pomo Native UI Layouts v1

Status: Ready for approval

This document is normative for first-release native information layout. It complements `ui-contract.md`; exact spacing follows macOS controls and accessibility sizing rather than pixel-perfect screenshots.

## Visual language

- Quiet macOS-native utility using system typography, materials, accent color, controls, and SF Symbols.
- Full light/dark and Increase Contrast support.
- No decorative cards, gradients, custom font dependency, or color-only state.
- Standard focus rings, keyboard order, VoiceOver grouping, and Dynamic Type/accessibility text behavior where macOS supports it.

## Status-item popovers

Default width is 360 points. Height follows content up to 560 points, after which the content region scrolls while primary actions remain reachable. Popovers are not user-resizable.

### Welcome

Order:

1. Pomo name and status-item identification.
2. Classic timing summary.
3. Start Classic primary action.
4. Launch at login opt-in, off by default.
5. Settings link.

No feature-tour carousel.

### Custom Session

Order:

1. Base Preset picker.
2. Focus/Short/Long duration fields.
3. Long Break cadence.
4. finite Rounds/Open-ended segmented choice and conditional count.
5. auto-start Focus/Break toggles.
6. validation summary.
7. Start Once primary action and Save as Preset secondary action.

Use native duration text fields with parsed examples, not separate card panels.

## Settings window

Use a standard SwiftUI Settings scene with General, Presets, and Alerts toolbar tabs. Default content width is approximately 560 points; each tab chooses a stable natural height and remains keyboard navigable.

### General

- Launch at login status/toggle and registration error.
- App behavior and onboarding support actions.
- Data section separated at bottom: Clear History and destructive Full Reset.

Full Reset is unavailable outside Idle/eligible Recovery and uses a confirmation sheet naming deleted data.

### Presets

Use a list/detail split layout within the tab:

- Left: Classic then user Presets, default marker, add/duplicate/delete controls.
- Right: selected Preset form with durations, cadence, boundary, and auto-start values.
- Bottom-right: Revert/Save where edits are pending.

Classic fields are read-only and Duplicate remains available. Deleting the default user Preset confirms Classic fallback.

### Alerts

- Notification authorization state and Open System Settings action when denied.
- Notification enabled preference.
- Sound enabled preference and chime Preview button.
- Explanation of pending-permission missed-alert indicator.

## Summary window

- Default size: 640 × 440 points.
- Minimum size: 520 × 360 points.
- Resizable; table consumes additional space.

Header:

- Previous week button.
- locale-formatted week range.
- Next week button, disabled beyond current week.
- current streak summary.

Body is one accessible seven-row table with Date, Focus Time, and Completed Rounds columns. Footer shows weekly totals. Empty dates remain visible with zero values for predictable navigation.

Clear History is a trailing footer action with confirmation. It does not sit beside week navigation where accidental activation is likely.

## Recovery presentation

Recovery does not force-open a modal. The status item uses a warning symbol layered with the current state and VoiceOver announcement. Opening the menu shows:

1. Recovery heading and concise reason.
2. Pending-data impact.
3. Capability-driven actions in this order: Retry, Export, Discard Session, Reset Data.
4. Diagnostic/details disclosure.

Destructive actions use confirmation sheets. Reset Data is visually separated from Retry/Export and never shares a button label with Discard Session.

## Layout validation

- Verify standard and increased text sizes without truncating controls.
- Verify keyboard focus order and default/cancel buttons.
- Verify VoiceOver groups and state announcements.
- Verify light, dark, Increase Contrast, Reduce Motion, and no-color-only meaning.
- Verify 360-point popovers and 520 × 360 minimum Summary window in English with longest planned labels.
