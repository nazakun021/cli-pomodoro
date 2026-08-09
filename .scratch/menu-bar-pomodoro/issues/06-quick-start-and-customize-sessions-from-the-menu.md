# 06 — Quick-start and customize Sessions from the menu

**What to build:** A menu user can quickly start likely Presets or configure a one-off Session without opening Settings, while accepted starts remain consistent with every other surface.

**Blocked by:** 04 — Run complete finite and open-ended Pomodoro cycles; 05 — Manage named Presets and the default

**Status:** ready-for-agent

- [ ] The Idle menu leads with the default Preset followed by up to three distinct most-recent non-default Presets, then Custom Session.
- [ ] Accepted starts from menu, direct CLI, or later interactive setup update one monotonic Preset recency sequence transactionally before acknowledgment.
- [ ] Classic is eligible for recents when non-default, while the default, deleted Presets, and duplicate entries never appear in the recent list.
- [ ] Custom Session uses the compact status-item popover and resolves all durations, cadence, boundary, and automatic-transition choices before Start Once.
- [ ] Save as Preset validates a reusable name and Configuration, persists it, and leaves the user able to start from the saved result without changing an active Session.
- [ ] Invalid custom values retain the user's other entries and cannot replace or stop an existing Session.
- [ ] Accepted menu starts expose the same immutable Configuration, revision, Session state, replacement protection, and acknowledgment semantics as CLI starts.
- [ ] Temporary-database, command/snapshot, and UI automation verify recency ordering across restart and all Custom Session outcomes.
- [ ] Keyboard, VoiceOver, increased-text, and 360-point popover checks confirm all fields and primary actions remain reachable without color-only meaning.
