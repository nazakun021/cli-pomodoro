# 04 — Run complete finite and open-ended Pomodoro cycles

**What to build:** A user can run, start, pause, resume, skip, and complete every Phase in finite or open-ended Sessions with correct Round and Transition behavior.

**Blocked by:** 03 — Pause, resume, and survive sleep correctly

**Status:** claimed

- [ ] Every Session Configuration has exactly one finite or open-ended boundary, and invalid duration, cadence, boundary, or conflicting override input is rejected before Agent mutation.
- [ ] Natural Focus completion alone completes a Round and advances long-Break cadence; skipped or interrupted Focus never completes a Round.
- [ ] Skipping Focus from Ready, Running, or Paused selects a Short Break, while skipping either Break selects a Ready Focus Phase.
- [ ] Automatic-transition choices either start the selected next Phase or leave it Ready at its full duration, and Resume starts Ready as well as Paused.
- [ ] Classic selects a Long Break after each fourth completed Round and otherwise selects a Short Break.
- [ ] A finite Session ends immediately when its final Focus Phase completes and creates no trailing Break; an open-ended Session continues until stopped.
- [ ] CLI and menu controls serialize against current revision so concurrent actions produce one deterministic valid Transition and matching snapshots.
- [ ] Generated state-machine and command/event tests cover valid and invalid sequences for all Phase states, automatic-transition choices, skips, finite endings, and open-ended continuation.
- [ ] Manual CLI/menu walkthroughs verify Phase symbols, primary-control labels, next-Phase text, and Round progress through a shortened complete Session.

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
