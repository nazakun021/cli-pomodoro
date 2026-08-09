# 13 — Recover safely from accounting and migration failures

**What to build:** A user encountering a required accounting or database migration failure sees a blocked Recovery state and can resolve it without silent loss or reset.

**Blocked by:** 11 — Persist Focus accounting and show today’s summary

**Status:** ready-for-agent

- [ ] A required accounting failure enters Recovery before the intended Transition, retains the pending contribution and precomputed next state in memory, and stops timing and ordinary mutation.
- [ ] Accounting Recovery advertises Retry, Export, Discard Session, and Reset Data; migration and unknown-schema reasons expose only their contracted capabilities.
- [ ] Retry applies pending accounting exactly once before entering the predetermined next state, while successful migration Retry returns Idle.
- [ ] Discard Session confirms loss of only pending uncommitted Focus, preserves committed data and preferences, and returns Idle.
- [ ] Reset Data is distinct, capability-gated, export-first, and confirmed with the full durable scope; normal active Sessions cannot invoke it.
- [ ] Intentional Quit is refused during unresolved pending accounting, and Agent restart loses volatile pending Recovery with one interruption notice while preserving committed data.
- [ ] Migrations create a consistent versioned backup, apply forward steps transactionally, retain failed backups, rotate successful backups by policy, and never downgrade a newer schema.
- [ ] CLI, menu, status item, and an attached Follow observer show the same descriptor; Follow stops ticks during Recovery and remains connected through resolution.
- [ ] Temporary-database, Agent, Follow, and UI tests inject accounting, migration, newer-schema, and corrupt-data failures and verify every capability, rollback, retry, discard, reset, restart, and backup outcome.
