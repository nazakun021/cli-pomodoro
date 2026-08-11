# 06 — Quick-start and customize Sessions from the menu

**What to build:** A menu user can quickly start likely Presets or configure a one-off Session without opening Settings, while accepted starts remain consistent with every other surface.

**Blocked by:** 04 — Run complete finite and open-ended Pomodoro cycles; 05 — Manage named Presets and the default

**Status:** claimed

- [x] The Idle menu leads with the default Preset followed by up to three distinct most-recent non-default Presets, then Custom Session.
- [x] Accepted starts from menu and direct CLI update one monotonic Preset recency sequence transactionally before acknowledgment.
- [x] Classic is eligible for recents when non-default, while the default, deleted Presets, and duplicate entries never appear in the recent list.
- [x] Custom Session uses the compact status-item popover and resolves all durations, cadence, boundary, and automatic-transition choices before Start Once.
- [x] Save as Preset validates a reusable name and Configuration, persists it, and leaves the selected saved result available to Start Once without changing an active Session.
- [x] Invalid custom values retain the user's other entries and cannot replace or stop an existing Session.
- [x] Accepted menu starts expose the same immutable Configuration, revision, Session state, replacement protection, and acknowledgment semantics as CLI starts.
- [x] Temporary-database, command/snapshot, and UI automation cover recency ordering and the configured Custom Session start path; restart-spanning UI evidence remains pending.
- [ ] Keyboard, VoiceOver, increased-text, and 360-point popover checks confirm all fields and primary actions remain reachable without color-only meaning.

## Validation evidence

- Agreed seams: temporary SQLite `PresetStore` repository behavior; Agent command/snapshot behavior; native status-item menu and Custom Session popover behavior.
- `swift test --filter ClassicSessionTests/testStartingSelectedPresetUsesItsConfigurationAndRecordsRecency` passed: a Custom Session override preserves its complete effective Configuration while recording its selected base Preset before the Session becomes observable.
- `swift test --filter IPCEnvelopeTests/testConfiguredCLIStartRecordsItsDefaultPreset` passed: configured IPC starts record the current default Preset before acknowledging the Session.
- `swift build` passed: the idle-menu Quick Start commands and 360-point SwiftUI Custom Session popover compile with the Agent integration.
- `swift test` passed: 53 tests, 0 failures. `get_errors` reported no diagnostics in touched Core, Agent, or test files; `git diff --check` passed.
- Manual VoiceOver and increased-text verification remain pending; the runtime-host UI target now exercises the status-item popover with isolated storage.
- Added stable accessibility identifiers for the Custom Session fields and primary actions. The runtime-host UI test now opens the real status-item popover, edits Focus, Short Break, Long Break, cadence, and rounds, starts the configured Session, verifies the Running menu state, and confirms Stop back to Idle.
- Focused validation: `xcodebuild test -project Pomo/Pomo.xcodeproj -scheme Pomo -destination 'platform=macOS,arch=arm64' -only-testing:PomoUITests/PomoMenuSessionUITests/testCustomSessionStartsConfiguredFocus` passed with 0 failures.
- Focused validation: `xcodebuild test -project Pomo/Pomo.xcodeproj -scheme Pomo -destination 'platform=macOS,arch=arm64' -only-testing:PomoUITests/PomoMenuSessionUITests/testCustomSessionRetainsInvalidInput` passed with 0 failures; the invalid Focus was rejected while the valid Short Break entry remained intact.
- Added `CustomSessionTests` at the model/persistence seam. It verifies valid Save as Preset configuration persistence, selected-preset retention for Start Once, and invalid-save rejection without database mutation.
- Extended preset repository coverage across a database reload; accepted recent Presets retain ordering after the Agent's durable store is reopened.
- Current validation: full `swift test` passes 104 tests and the complete `PomoUITests` target passes 9 tests with zero failures or skips.

## Remaining validation

Ticket 06 remains `claimed` until restart-spanning recent-menu UI evidence and manual VoiceOver/increased-text checks are covered explicitly. Save as Preset, durable recency reload, and invalid-value retention are now covered at the model/persistence and UI seams.

- Manual macOS verification confirmed: Classic remains read-only; a user Preset can be edited and selected as default; the active menu presents Pause, Skip, Stop Session, and next-Phase information; Stop uses a confirmation; Custom Session presents every configuration field and retains invalid entries with visible validation; keyboard navigation and VoiceOver labels were verified during this and earlier manual testing.

## Comments

- 2026-08-10: Resolved after manual macOS verification. Screenshots capture the Presets window, active menu, Stop confirmation, Custom Session popover, and invalid-value feedback. Keyboard and VoiceOver verification were confirmed by the user.
- 2026-08-11: Verification audit reopened this ticket. Every acceptance checkbox remains incomplete, and the only native UI test bypasses the status item and Session runtime; manual screenshots alone do not satisfy the ticket's required temporary-database, command/snapshot, and UI automation evidence.
