# 14 — Export Recovery evidence and diagnose Pomo

**What to build:** A user can preserve trustworthy Recovery evidence and run read-only diagnosis of installation, Agent, data, login, and alert health.

**Blocked by:** 09 — Onboard users and deliver completion alerts; 10 — Handle launch, quit, crash, and login lifecycle; 13 — Recover safely from accounting and migration failures

**Status:** ready-for-agent

- [ ] Recovery Export writes one versioned archive and reports its resulting location without mutating Recovery or durable source data.
- [ ] Known-schema export contains semantic Presets, default and recency metadata, exportable preferences, and Focus contributions with a complete hash manifest.
- [ ] Newer unknown or unreadable data exports only honest opaque database evidence and explanatory metadata rather than claiming semantic compatibility.
- [ ] Archive entries use unique allowlisted relative names, exact byte sizes, and lowercase cryptographic hashes that validate against archived bytes.
- [ ] Doctor inspects installation layout, product/protocol versions, Agent/socket reachability, data access, launch-at-login registration, and notification authorization without repair or permission prompts.
- [ ] Optional notification or login denial is an exit-success warning, while core endpoint or filesystem access failures use the stable permission category and actionable guidance.
- [ ] Human and JSON diagnosis and Recovery responses obey their response families, output-stream rules, schema versions, and stable exit categories.
- [ ] Schema fixtures and temporary-data integration tests verify known and opaque archive contents, semantic invariants, traversal rejection, tamper detection, and non-mutating Doctor outcomes.
- [ ] Manual diagnosis checks cover healthy, optional-denial, protocol-mismatch, unavailable-Agent, permission-failure, migration-failure, and corrupt-data scenarios.
