# 05 — Manage named Presets and the default

**What to build:** A user can manage reusable named Presets in Settings, choose a default, and trust every started Session to keep its resolved Configuration unchanged.

**Blocked by:** 02 — Start and stop a Classic Focus Session

**Status:** claimed

- [ ] Presets Settings lists Classic and user Presets and supports create, duplicate, edit, delete, and default selection with complete Configuration fields.
- [ ] User Preset names are unique under locale-independent case-insensitive comparison, and validation preserves pending form values.
- [ ] Classic remains immutable and undeletable but can be duplicated and need not remain the default.
- [ ] Exactly one existing Preset is default; deleting the default user Preset confirms and atomically selects Classic.
- [ ] Deleting any Preset removes its recency metadata in the same transaction and cannot leave a stale default or recent entry.
- [ ] Editing or deleting a source Preset during an active Session does not alter that Session's immutable Configuration.
- [ ] Durable Presets, default selection, and protected Classic survive Agent restart with owner-only storage and one Agent writer.
- [ ] Repository and temporary-database tests verify physical constraints, protected-row triggers, rollback, default fallback, and case-insensitive uniqueness.
- [ ] Native UI automation verifies keyboard operation, read-only Classic behavior, confirmations, focus order, and VoiceOver labels in Presets Settings.

## Validation evidence

- Agent command/snapshot and temporary-database repository seams are the agreed automated boundaries for this ticket.
- `swift test --filter PresetRepositoryTests` passed: SQLite-backed Preset storage seeds Classic, persists created user Presets across reopening, enforces case-insensitive names, falls back to Classic when deleting the default, supports duplicate/edit, and protects Classic from edit/delete.
- `swift test` passed: 45 tests, 0 failures.
- `swift build` passed without diagnostics.

## Comments

- The durable repository slice is complete. Ticket remains claimed for Agent integration, Settings UI, owner-only production storage, recency transaction coupling, and native accessibility automation.
