# ADR-0003: Transactional Storage and Monotonic Timing

Status: Accepted

## Context

Presets and Summary Records must survive Agent restarts, support future schema evolution, and remain consistent across destructive actions and crashes. Lightweight macOS preferences such as launch-at-login, alerts, and sound do not require relational queries.

Active Sessions do not survive Agent or Mac restart. While awake, delayed run-loop or UI callbacks must not lengthen a Phase. Mac sleep must pause rather than consume Phase time.

## Decision

- Store Presets and Summary Records in SQLite using GRDB behind domain-owned persistence interfaces, transactions, and explicit schema migrations.
- Store finalized Focus contributions at integer-millisecond precision, split by recorded local date/timezone context at local midnight. Later timezone changes do not regroup history.
- Store lightweight global preferences through macOS preferences APIs.
- Store default-Preset selection and recent-Preset ordering in SQLite so deletion/fallback/recency updates remain transactional.
- Store only lightweight global preferences and a minimal non-restorable clean-exit/active-Session interruption marker through macOS preferences APIs.
- Keep active Session state in Agent memory; do not persist it for restoration.
- Before migration, create an atomic versioned database backup. Migrate transactionally; on failure, retain the backup, preserve the existing database, disable mutations, and enter a user-visible recovery mode with diagnostics and explicit export/reset actions. Never reset automatically.
- Known-schema Recovery export is a versioned JSON archive of Presets, preferences, Summary Records, and schema metadata. An older binary facing a newer unknown schema exports a hashed raw database copy instead. First release does not import archives.
- Represent a running Phase using a monotonic deadline and derive displayed remaining time from that deadline rather than decrementing a counter.
- Observe macOS sleep/wake lifecycle. On sleep, capture the last reliable remaining duration; on wake, return the Phase in Paused state with that duration.
- If the deadline is at or before the observed sleep instant, complete the Phase before processing sleep; otherwise pause its positive remainder.
- Ignore system wall-clock changes for duration accounting and recompute only the estimated expected transition wall time.
- Round displayed whole seconds up until the completion/transition instant.

Schema, migration, backup/export, transaction, and Recovery behavior are defined by `.scratch/menu-bar-pomodoro/database-design.md` and its schemas. Clock implementation types remain implementation-local behind the documented monotonic/wall/sleep abstractions.

Swift package dependencies use pinned resolved versions and require compatible permissive licenses plus maintenance/security review.

## Consequences

### Positive

- Summary and Preset mutations are transactional and migration-friendly.
- Global preferences integrate with standard macOS behavior.
- Timer accuracy is independent of one-second UI callback scheduling.
- Sleep behavior directly matches the product rule.

### Negative

- Two persistence mechanisms require clear ownership and test fixtures.
- Recovery/export UI and migration failure tests are required before release.
- Sleep/deadline ordering and wake behavior require lifecycle integration tests.
- Wall-clock start timestamps and recalculated transition estimates may appear discontinuous after a user changes system time even though duration remains correct.

## Alternatives considered

### JSON files for domain records

Not selected because summary aggregation, uniqueness constraints, transactional history clearing, and schema evolution are stronger fits for SQLite.

### One-second decrementing counter

Rejected because delayed callbacks under load would extend Phases and make timing depend on rendering cadence.

### Wall-clock deadline

Rejected because elapsed sleep would consume Phase time, contradicting automatic pause-on-sleep behavior.
