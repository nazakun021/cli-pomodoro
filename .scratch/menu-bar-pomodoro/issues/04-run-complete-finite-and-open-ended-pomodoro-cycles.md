# 04 — Run complete finite and open-ended Pomodoro cycles

**What to build:** A user can run, start, pause, resume, skip, and complete every Phase in finite or open-ended Sessions with correct Round and Transition behavior.

**Blocked by:** 03 — Pause, resume, and survive sleep correctly

**Status:** resolved

- [x] Every Session Configuration has exactly one finite or open-ended boundary, and invalid duration, cadence, boundary, or conflicting override input is rejected before Agent mutation.
- [x] Natural Focus completion alone completes a Round and advances long-Break cadence; skipped or interrupted Focus never completes a Round.
- [x] Skipping Focus from Ready, Running, or Paused selects a Short Break, while skipping either Break selects a Ready Focus Phase.
- [x] Automatic-transition choices either start the selected next Phase or leave it Ready at its full duration, and Resume starts Ready as well as Paused.
- [x] Classic selects a Long Break after each fourth completed Round and otherwise selects a Short Break.
- [x] A finite Session ends immediately when its final Focus Phase completes and creates no trailing Break; an open-ended Session continues until stopped.
- [x] CLI and menu controls serialize against current revision so concurrent actions produce one deterministic valid Transition and matching snapshots.
- [x] Generated state-machine and command/event tests cover valid and invalid sequences for all Phase states, automatic-transition choices, skips, finite endings, and open-ended continuation.
- [x] Manual CLI/menu walkthroughs verify Phase symbols, primary-control labels, next-Phase text, and Round progress through a shortened complete Session.

## Validation evidence

- Agent-owned `skip` IPC mutation now accepts the current Focus Phase while Running or Paused and deterministically creates a new running Short Break occurrence under the same Session. It leaves completed rounds at zero; persistence and focus accounting are intentionally not performed.
- `swift test --filter IPCEnvelopeTests` passed: socket-level command/snapshot coverage verifies the new Short Break phase identity, configured break duration, zero completed rounds, and a later Status matching the Skip result.
- `swift test` passed: 32 tests, 0 failures. `swift build` passed without diagnostics.
- `swift test --filter TimingTests/testDuePhasesAdvanceFocusThenShortBreak` passed: an awake due Focus advances to a running Short Break, and a due Short Break selects a Ready Focus with Round progress preserved.
- `swift test --filter TimingTests/testSkipTransitionsFocusToShortBreakAndBreakToReadyFocus` passed: Skip preserves Round progress, selects Short Break from Focus, and selects Ready Focus from a Break.
- `swift test` passed: 36 tests, 0 failures; `swift build` passed after exposing Skip for active Breaks in the native menu.
- `swift test --filter SessionConfigurationTests` passed: finite Session Configuration rejects non-positive targets before Agent mutation.
- `swift test` passed: 37 tests, 0 failures; `swift build` passed after adding validated Configuration construction for duration, cadence, and boundary invariants.
- `swift test --filter ClassicSessionTests/testStartUsesCompleteOpenEndedConfiguration` passed: Agent creation preserves a complete open-ended Configuration and starts its Focus Phase.
- `swift test --filter ClassicSessionTests/testFiniteSessionEndsAfterItsFinalFocus` passed: a finite one-Round Session returns Idle on natural final Focus completion without a trailing Break.
- `swift test` passed: 39 tests, 0 failures; `swift build` passed after adding generic validated-Configuration Session start.
- `swift test --filter IPCEnvelopeTests/testStartWithConfigurationCreatesOpenEndedSession` passed: a complete open-ended Configuration traverses the IPC Start request and is returned in the Agent snapshot.
- `swift test` passed: 40 tests, 0 failures; `swift build` passed after adding optional Configuration to IPC Start requests.
- `swift test --filter DurationParserTests` passed: Start durations accept composable integer units and reject malformed or excessive values.
- `swift test` passed: 42 tests, 0 failures; `swift build` passed after resolving positional and named duration, boundary, cadence, and auto-start options into validated Start Configurations before IPC.
- Manual shortened CLI walkthrough: `pomo start --focus 60s --short-break 1s --rounds 1 --json` created a Running 60-second Focus Session; `pomo skip --json` selected a new Running one-second Short Break without advancing Round progress; the Agent then transitioned to a new Ready 60-second Focus at revision `3` with the same Session ID.
- Manual native menu walkthrough: screenshots verified Idle (`No Session` and Start Classic), Focus Running (Pause, Skip, Stop, Next: Short Break), Break Running (Pause, Skip, Stop, Next: Focus), and Focus Ready (`25:00`, Skip, Stop, Next: Short Break). Ready now presents Start through the Agent Resume transition.
- Final validation: `swift test` passed 42 tests; `swift build` passed.
