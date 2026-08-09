# 04 — Run complete finite and open-ended Pomodoro cycles

**What to build:** A user can run, start, pause, resume, skip, and complete every Phase in finite or open-ended Sessions with correct Round and Transition behavior.

**Blocked by:** 03 — Pause, resume, and survive sleep correctly

**Status:** ready-for-agent

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
