# 03 — Pause, resume, and survive sleep correctly

**What to build:** A user can pause and resume the current Phase from either surface, and a running Phase survives Mac sleep with accurate positive remaining time.

**Blocked by:** 02 — Start and stop a Classic Focus Session

**Status:** resolved

- [x] Pause is accepted only from Running and freezes the same positive remaining duration in CLI, menu, and status-item observations.
- [x] Resume runs a Paused Phase, and the adaptive menu control and CLI invalid-state guidance always expose only valid next actions.
- [x] Remaining time derives from a monotonic deadline, rounds upward for display, and is unaffected by delayed callbacks or wall-clock and timezone changes.
- [x] Sleep before the deadline captures the pre-sleep positive remainder and wakes into Paused without consuming sleep time.
- [x] A deadline reached at or before observed sleep completes before sleep handling, with no duplicate or lost Transition.
- [x] Expected Transition wall time is present only while Running and is recalculated from monotonic remainder after resume or wall-clock change.
- [x] Deterministic clock tests cover pause/resume sequences, display boundaries, deadline races, and wall-clock changes across Focus and Break Phases.
- [x] Manual supported-macOS sleep/wake evidence verifies both the ordinary pause case and the deadline race from CLI and menu.

## Validation evidence

- Agent-owned `pause` and `resume` IPC mutations now preserve the Focus Session and Phase IDs. Pause captures a positive rounded remaining duration, returns a Paused snapshot with no running wall-clock estimates, and Resume starts the same Focus Phase from that remainder.
- `swift test --filter IPCEnvelopeTests` passed: socket-level command/snapshot coverage verifies pause freezing, resumed running estimates, and unchanged remaining time across the Paused observation.
- `swift test` passed: 32 tests, 0 failures. `swift build` passed without diagnostics.
- `swift test --filter TimingTests` passed: injected monotonic/wall clocks prove elapsed time ignores wall-clock jumps, sleep preserves a positive remainder, a reached Focus deadline transitions before sleep, and Break Phases pause and resume correctly.
- `swift test --filter TimingTests` passed after review: sleep-time Phase completion follows the finite four-Round Session boundary and Resume accepts the resulting Ready Focus Phase.
- `swift test --filter IPCEnvelopeTests` passed: invalid pause reports the Paused state and its valid actions; snapshots retain stable Session identity while expected wall transitions are recalculated.
- `swift build` passed after connecting `NSWorkspace.willSleepNotification` to the Agent-owned sleep transition.
- `swift test --filter TimingTests` passed: exact sub-second monotonic remainder drives expected wall transitions, display seconds round up at boundaries, and Resume recalculates the estimate after a wall-clock change.
- Manual ordinary sleep/wake CLI evidence: Focus began Running at revision `1` with Session `68D02B76-B2F2-4B6D-A910-0737D7E82129` and Phase `24A18E91-0BF7-4420-BC3C-89AC50A4E021`; after wake, the same IDs were Paused at revision `2`, with `remaining_seconds: 1448` and `expected_transition_at: null`.
- Manual ordinary sleep/wake stability: two post-wake Status responses remained Paused at revision `2` with the same IDs and `remaining_seconds: 1448`; validated on macOS `26.5.2` (`arm64`).
- Manual menu parity: the native status item rendered the Focus icon and `24:09` on one line; its menu showed `Focus - Paused`, `Round 1 of 4`, Resume, Skip, Stop Session, and `Next: Short Break`, matching the CLI paused snapshot.
- Manual deadline race: the original Focus Session advanced exactly once to a new running Short Break at revision `4`, with `completed_rounds: 1`, Phase `8E48B671-FE82-43A9-9259-9FCD44116233`, and 242 seconds remaining. A subsequent sleep during that Break paused the same new Phase at revision `5` with 12 seconds remaining and no transition estimate.

## Comments

- Automated implementation and deterministic validation, ordinary CLI sleep/wake behavior, menu-bar parity, and the deadline race are verified on macOS `26.5.2` (`arm64`).
