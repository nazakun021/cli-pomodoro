# 03 — Pause, resume, and survive sleep correctly

**What to build:** A user can pause and resume the current Phase from either surface, and a running Phase survives Mac sleep with accurate positive remaining time.

**Blocked by:** 02 — Start and stop a Classic Focus Session

**Status:** claimed

- [ ] Pause is accepted only from Running and freezes the same positive remaining duration in CLI, menu, and status-item observations.
- [ ] Resume runs a Paused Phase, and the adaptive menu control and CLI invalid-state guidance always expose only valid next actions.
- [ ] Remaining time derives from a monotonic deadline, rounds upward for display, and is unaffected by delayed callbacks or wall-clock and timezone changes.
- [ ] Sleep before the deadline captures the pre-sleep positive remainder and wakes into Paused without consuming sleep time.
- [ ] A deadline reached at or before observed sleep completes before sleep handling, with no duplicate or lost Transition.
- [ ] Expected Transition wall time is present only while Running and is recalculated from monotonic remainder after resume or wall-clock change.
- [ ] Deterministic clock tests cover pause/resume sequences, display boundaries, deadline races, and wall-clock changes across Focus and Break Phases.
- [ ] Manual supported-macOS sleep/wake evidence verifies both the ordinary pause case and the deadline race from CLI and menu.

## Validation evidence

- Agent-owned `pause` and `resume` IPC mutations now preserve the Focus Session and Phase IDs. Pause captures a positive rounded remaining duration, returns a Paused snapshot with no running wall-clock estimates, and Resume starts the same Focus Phase from that remainder.
- `swift test --filter IPCEnvelopeTests` passed: socket-level command/snapshot coverage verifies pause freezing, resumed running estimates, and unchanged remaining time across the Paused observation.
- `swift test` passed: 32 tests, 0 failures. `swift build` passed without diagnostics.
