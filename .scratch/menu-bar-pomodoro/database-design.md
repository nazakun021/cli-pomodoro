# Pomo Database and Recovery Design v1

Status: Ready for approval

This document is normative for first-release durable storage. Physical v1 DDL is in `schemas/database-v1.sql`; archive objects are defined by `schemas/recovery-archive-v1.schema.json` with cross-field rules in `schema-semantics.md`.

## Files and permissions

- Database: `~/Library/Application Support/Pomo/pomo.sqlite`
- Backups: `~/Library/Application Support/Pomo/Backups/`
- Parent directories: owner-only `0700`
- Database and backup files: owner-only `0600`

Enable foreign keys, WAL journal mode, and synchronous FULL on every writable connection. The Agent is the only writer. Read-only recovery/export connections never mutate pragmas or schema.

## Schema v1

### Presets

`presets` stores all configurations, including protected Classic ID `00000000-0000-0000-0000-000000000001`. Durations are integer seconds. `normalized_name` is the locale-independent case-folded uniqueness key produced by the repository.

The repository and database triggers reject Classic edit/delete outside migrations. Reset preserves or reseeds Classic.

### App state

Singleton `app_state` stores default Preset ID and the next monotonic recency sequence. Agent acceptance of a Session start increments the sequence and assigns it to the source Preset in the same transaction before acknowledgment. UI queries the three highest non-null sequences excluding the current default. A crash before acknowledgment may leave recency updated without a surviving volatile Session by design.

Deleting a user Preset is one transaction: if it is default, select Classic; delete the row (which also removes its row-owned recency metadata); commit.

### Focus contributions

`focus_contributions` stores integer milliseconds split by recorded local date. `(source_phase_id, segment_index)` is unique, making accounting retry idempotent independently of IPC cache state. Zero-elapsed interrupted Focus creates no row.

## Transaction boundaries

The following operations are single SQLite transactions:

- create/edit/delete Preset, including default fallback
- select default Preset
- update accepted-start recency
- finalize all date-split rows for one Focus Phase
- clear Summary Records
- apply each named migration

For replacement, validate and construct the new in-memory Session first, finalize old Focus rows transactionally when needed, then perform an infallible serialized state swap and acknowledge. A Break replacement writes no contribution.

SQLite commit and the volatile state swap are ordered but not atomically durable together. A crash after commit preserves accounting; restart discards all volatile Sessions under the existing lifecycle rule. No success is reported before the swap.

For completion/skip/stop/quit, compute all split rows before opening the transaction. Mutate Agent Session state only after commit. A required write failure enters Recovery with the pending operation and intended next state retained in memory.

## Recovery behavior

Reasons and capabilities:

| Reason                        | Retry | JSON export | Raw DB export | Discard Session                 | Reset Data |
| ----------------------------- | ----- | ----------- | ------------- | ------------------------------- | ---------- |
| accounting write failed       | yes   | yes         | no            | yes                             | yes        |
| known-schema migration failed | yes   | yes         | no            | no                              | yes        |
| newer unknown schema          | no    | no          | yes           | no                              | yes        |
| corrupt/unreadable database   | no    | best effort | yes           | pending Session only if present | yes        |

Accounting Retry uses the same Phase ID/segment keys and applies the pending contribution exactly once. On success the Agent moves to the precomputed next state. Discard Session confirms loss of pending uncommitted Focus, preserves committed data, and returns Idle.

Pending accounting Recovery is in memory only and does not survive Agent/Mac restart. Intentional Agent Quit is unavailable until the pending state is resolved or explicitly discarded/reset.

Reset Data is separate, requires explicit force/GUI confirmation, and presents export-first guidance. Discard Session also presents Export first but does not require it. Reset removes SQLite, WAL/SHM, backups, preferences, and onboarding state, then creates schema v1 and Classic.

## Migrations

- GRDB `DatabaseMigrator` owns ordered, named, forward-only migrations.
- Create a consistent pre-migration backup with the SQLite/GRDB backup API before the first pending migration.
- Apply each migration transactionally in order.
- Test every supported prior schema directly to latest.
- Retain the latest three backups from successful upgrades.
- Never automatically delete the backup associated with a failed migration.
- A newer unknown schema enters read-only Recovery; never downgrade.

## Recovery archives

Export one `.pomo-recovery.zip`.

Known schema contents:

- `manifest.json`
- `data.json`

Unknown/corrupt schema contents:

- `manifest.json`
- `pomo.sqlite` plus available WAL/SHM sidecars or a consistent raw copy where possible

Manifest paths are relative, cannot escape the archive root, and include byte size plus lowercase SHA-256. Known-schema `data.json` contains user Presets, default/recency metadata (including separate Classic recency), exportable preferences, and Focus contributions. Classic is identified by its stable ID and need not be duplicated as a user Preset.

First release does not import archives.

## Required validation

- Apply schema v1 to an empty database and verify constraints/triggers.
- Upgrade a fixture from every released schema to latest.
- Simulate failure before backup, during each migration, and after migration commit.
- Verify successful backup rotation and failed-backup retention.
- Verify duplicate Phase segment insertion cannot double count.
- Verify default deletion falls back to Classic atomically.
- Verify cross-midnight split totals and completion marker placement.
- Verify known JSON and unknown raw recovery archives and all manifest hashes.
- Verify accounting Recovery Retry/Discard and migration Retry/Reset behavior.
