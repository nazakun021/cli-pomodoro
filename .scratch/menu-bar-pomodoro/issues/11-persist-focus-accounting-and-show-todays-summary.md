# 11 — Persist Focus accounting and show today’s summary

**What to build:** A user sees honest local Focus time and completed Rounds for today after natural completion or interruption, with committed work preserved across Agent restarts.

**Blocked by:** 04 — Run complete finite and open-ended Pomodoro cycles; 05 — Manage named Presets and the default; 10 — Handle launch, quit, crash, and login lifecycle

**Status:** ready-for-agent

## Validation evidence

- Implemented and tested a durable `SummaryStore` with idempotent `(phaseID, local date)` contributions, natural Focus completion, interrupted Focus accounting for Stop and Skip, and local-midnight splitting with the completion marker on the final segment.
- Production Agent construction injects the summary store, and deterministic tests cover natural completion, Stop, Skip, replacement accounting, persistence reload, duplicate replay, split contributions, and wall-clock rollback handling.
- Current validation: `swift build` passed and the full Swift suite passed with 83 tests and 0 failures.

Known gaps: Summary Records are still JSON rather than the required SQLite/GRDB transactional schema; Recovery is not exposed through IPC; pause/resume date anchors, weekly/streak summaries, clear/reset behavior, and full restart/recovery coverage remain incomplete.

- [ ] Natural Focus completion, skip, Stop, replacement, and forced Quit finalize positive elapsed Focus transactionally with stable Phase/segment identity.
- [ ] Only natural Focus completion writes a completed-Round marker; Break interruption and zero-elapsed Focus write no contribution.
- [ ] Replacement prevalidates the new Session, commits eligible old Focus once, swaps serialized volatile state, and preserves all prior Summary Records.
- [ ] Cross-midnight Focus is split into integer-millisecond contributions by recorded local date, timezone, and offset, with the completion marker on only the completing segment.
- [ ] Duplicate IPC requests and accounting retries cannot double-count a Phase segment or completed Round.
- [ ] The menu's today summary shows floored Focus minutes or positive sub-minute notation, completed Rounds, and current streak without overstating stored precision.
- [ ] Committed Summary Records survive Agent restart, while an unexpected crash adds no uncommitted partial Focus.
- [ ] Deterministic clock, temporary-database, replacement, rollback, restart, and idempotency tests cover every finalization path and date split.
- [ ] A shortened manual CLI/menu walkthrough confirms today's summary after completion, skip, Stop, replacement, and restart.
