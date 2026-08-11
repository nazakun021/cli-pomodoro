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

- 2026-08-11 verification audit reopened this ticket: the existing native UI test launches an onboarding-only branch that returns before constructing the Agent, socket, or status item, so it cannot prove the menu acceptance criteria above.
- The core command and socket tests remain useful evidence; XCUITest must still automate the now-live packaged workflow before this ticket can return to `resolved`.
- Before the 2026-08-11 fix, native menu mutation failures were discarded for Pause, Resume, Skip, and Stop, making a rejected action appear to do nothing.
- 2026-08-11 implementation: native Start now creates the Session before first-run notification onboarding can block, Custom Session follows the same ordering, and Pause/Resume/Skip/Stop failures are visible instead of discarded.
- 2026-08-11 validation: `swift build` passed; 42 focused transition/IPC tests passed; the full Swift suite passed 93 tests; a signed packaged Agent and bundled CLI produced revisions `0` through `5` across Start, Pause, Resume, Skip, and Stop with the expected Focus-to-Short-Break transition.
- Native UI suite: `xcodebuild test -project Pomo/Pomo.xcodeproj -scheme Pomo -destination 'platform=macOS,arch=arm64' -only-testing:PomoUITests` passed two onboarding tests, explicitly skipped the blocked real-menu workflow test, and reported zero failures.
- 2026-08-11 live packaged menu evidence: icon-only Idle; Start produced Running revision `1`; Pause produced Paused revision `2`; Resume produced Running revision `3`; Skip produced a running Short Break at revision `4` with zero completed Rounds; confirmed Stop returned Idle at revision `5`. The menu updated from CLI mutations through the same Agent and displayed the documented adaptive controls.
- Root cause fixed: manually running `NSApplication` blocked inherited MainActor tasks and main-queue dispatch timers. Menu mutations now run detached, AppKit UI delivery uses a main-run-loop dispatcher, periodic refresh uses a common-mode RunLoop timer, and menus are not rebuilt while AppKit tracks them.
- Remaining blocker: the real-runtime XCUITest target creates isolated storage and an Agent endpoint, but Xcode 26.4 on macOS 26.5.2 times out before interaction and reports `Application 'com.nazakun.pomo' has not loaded accessibility`.
- 2026-08-11 rerun prerequisite: the new minimal real-runtime Idle test and the known-good onboarding test both fail before launching Pomo with `Timed out while enabling automation mode`; local Developer Mode is disabled. Enable it and rerun the minimal tracer before diagnosing any remaining app-specific accessibility attachment failure.
- 2026-08-11 AX replacement progress: the packaged workflow test launches isolated storage, clicks Start Classic, and observes Running revision `1` with the complete Classic configuration over IPC. Reopening the active status item currently selects a descriptive AX child without position/size, so CGEvent cannot click it and the confirmed Stop slice remains incomplete.
- 2026-08-11 dedicated-host progress: XCUITest now attaches deterministically, opens the real Idle menu, starts Classic, observes `Pomo Focus Running`, reopens the active menu, and clicks Pause. The isolated support root is short enough for the Unix socket, and onboarding is covered separately.
- Final native workflow: `testClassicSessionControlsWorkFromStatusItem` passed unskipped through Start, Pause, Resume, Skip to a running Break, confirmed Stop, and final Idle/Start Classic in 36.155 seconds.
- Final validation: all 98 Swift tests pass; all five `PomoUITests` pass with zero skips; touched-file diagnostics and `git diff --check` are clean.

## Resolution history

The dedicated runtime host now attaches deterministically and automates Idle, Start Classic, Running, and the Pause menu action. `MainRunLoopDispatcher` was proven to overwrite pending actions (`[2]` instead of `[1, 2]`) and now drains an ordered queue, with focused regression coverage. Even after that fix, `Pomo Focus Paused` never appears within 10 seconds. The next discriminating step is to observe the isolated socket immediately after Pause to determine whether the mutation failed to reach the Agent or only the UI refresh is missing.

The PomoCore-linked UI-test runner could not connect to the app-owned isolated socket (`LocalAgentTransportError.connectFailed`), so that probe was removed after three focused iterations. The next bounded discriminator is host-owned snapshot presentation: render the Agent revision/state inside the runtime-host window and assert it through XCUITest after Pause.

The host-owned snapshot stream confirms Start reaches revision `1` Running, but Pause leaves the Agent at revision `1` after both ordinary and coordinate menu-item clicks. The next implementation hypothesis is action-target lifetime: strongly retain each `MenuActionTarget` on its `NSMenuItem` so a concurrent menu rebuild cannot deallocate the weak target before AppKit delivers `invokeMenuAction`.

Action-target retention is now explicit through `NSMenuItem.representedObject` and covered by a focused AppKit test, but the host still remains at revision `1` after Pause. The next discriminator is selector instrumentation: expose whether `MenuActionTarget.invokeMenuAction` runs for Pause before changing mutation or refresh code.

Selector instrumentation proved Pause invokes and reaches revision `2` Paused, and the full workflow passed once with the host snapshot/action barriers present. After temporary instrumentation was removed, the workflow again raced while waiting for the Paused status label. The remaining task is test synchronization: retain a minimal host-owned revision label and wait for revisions `1` through `5` before each native UI assertion, without retaining the separate diagnostic test.

Validation after dispatcher/target-retention repair: the full Swift suite passes 98 tests and the five-test UI target passes with zero skips. The focused full workflow passed once in 39.491 seconds with host barriers present.

Resolved: runtime-host mode now suppresses only its separately tested education modals inside the app process, preventing `Completion Alerts` from intercepting Session controls. The full workflow and complete UI target pass unskipped.
