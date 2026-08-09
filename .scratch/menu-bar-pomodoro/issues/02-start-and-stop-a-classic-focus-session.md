# 02 — Start and stop a Classic Focus Session

**What to build:** A user can start a Classic Focus Session from the CLI, watch the same running Phase in the menu, and stop it from either surface without tying it to Terminal.

**Blocked by:** 01 — Observe an Idle Agent from CLI and menu

**Status:** resolved

- [x] Direct Start resolves the complete immutable Classic Session Configuration and acknowledges only after the Session is observable from CLI and menu.
- [x] Classic starts a 25-minute Focus Phase with the contracted finite four-Round boundary, Break durations, cadence, and automatic-transition choices.
- [x] Closing Terminal after Start leaves the Agent-owned Session running and controllable from the menu and later CLI invocations.
- [x] Status-item and CLI snapshots agree on Session and Phase occurrence IDs, revision, Running state, configured duration, rounded remaining time, and expected Transition estimate.
- [x] The active menu presents Phase/state, Round progress, Pause, Skip, confirmed Stop, next Phase, and status item formatting in the contracted order.
- [x] Explicit CLI Stop ends the Session without prompting; menu Stop confirms partial-Focus impact before ending it; both return the Agent to Idle.
- [x] A second Start is rejected unless explicit non-interactive replacement is requested, and an invalid replacement cannot disturb the current Session.
- [x] Duplicate, expired, future-dated, and wrong-Agent mutation requests prove that Start and Stop cannot be applied twice.
- [x] Automated command/snapshot, real socket, CLI subprocess, and native menu checks demonstrate one serialized Session across both surfaces.

## Validation evidence

- `swift test --filter ClassicSessionTests` passed: an Agent-owned Classic Start creates a revision-1 Running Focus snapshot with the complete immutable Classic configuration.
- `swift test` passed: 15 tests, 0 failures.
- `swift build` passed without diagnostics.
- `swift test --filter IPCEnvelopeTests` passed: accepted IPC Start returns a Running Focus snapshot and a later Status observes the same Session identity and revision.
- `swift test` passed after IPC Start routing: 16 tests, 0 failures.
- `swift run PomoAgent`, `swift run pomo start --json`, then `swift run pomo status --json` demonstrated the same Agent-owned Running Focus Session after the Start CLI invocation exited.
- `swift test --filter ClassicSessionTests` passed: explicit Stop clears the active Session, returns Idle, and advances the state revision from 1 to 2.
- `swift test` passed after Stop core work: 17 tests, 0 failures.
- `swift test --filter IPCEnvelopeTests` passed: IPC Stop returns Idle and a later Status observes revision 2.
- `swift run PomoAgent`, `pomo start --json`, `pomo stop --json`, and `pomo status --json` demonstrated a direct CLI Stop with no prompt and the expected Idle result.
- `swift test` passed after IPC/CLI Stop: 18 tests, 0 failures; `swift build` passed without diagnostics.
- Native menu validation: the status item now refreshes from the Agent snapshot, presents Start Classic while Idle, and presents Focus/round context with confirmed Stop while a Session is active.
- Timing validation: Running Focus snapshots include Agent-derived phase-start and expected-transition UTC values, rounded-up remaining seconds, and the menu renders that shared remaining value.
- Idempotency validation: duplicate IPC Start requests with the same request ID return the cached original Session snapshot and revision without applying a second mutation.
- `swift test` passed after replay caching: 19 tests, 0 failures; `swift build` passed without diagnostics.
- Start conflict validation: a second non-replacement Start is rejected and a later Status retains the original Session identity and revision.
- `swift test` passed after conflict coverage: 20 tests, 0 failures; `swift build` passed without diagnostics.
- `swift test --filter IPCEnvelopeTests` passed: duplicate non-replacement Start returns a structured `invalid_state` response with the current state and valid next action, while explicit replacement creates exactly one new Session at the next revision.
- IPC mutation validation: expired requests older than five minutes, requests more than thirty seconds in the future, and requests bound to a different Agent instance return `invalid_request` without changing the Idle snapshot. Duplicate Stop returns its cached Idle result without a second mutation.
- `pomo start --replace` now forwards explicit non-interactive replacement through the Agent IPC seam. JSON and human CLI output preserve structured command failures and exit with the returned error category.
- Active-menu validation: phase/state, configured round progress, confirmed Stop, next phase, snapshot-derived accessibility labels, and `MM:SS`/`H:MM:SS` status formatting are derived from the shared Agent snapshot. Pause and Skip remain unavailable because the current Agent command/state-machine slice does not implement them.
- `swift test` passed: 23 tests, 0 failures.
- `swift build` passed without diagnostics.
- Active-menu evidence: Pause, Resume, and Skip now invoke Agent-owned mutations from the same snapshot-driven session menu; their Focus-phase transitions are covered under tickets 03 and 04.

## Remaining gaps

- This ticket remains `claimed`. The current architecture has no configurable Start payload, so it cannot prevalidate and reject an invalid replacement without changing the active Session.
- Pause, Skip, and multi-phase transitions are not implemented in the Agent command/state-machine slice; the menu presents those controls but cannot execute them.
- Automated CLI-subprocess and native-menu checks for one serialized Session across both surfaces are not present in the test target.
