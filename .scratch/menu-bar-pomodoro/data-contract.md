# Pomo Durable Data Contract

Status: Planning

This document defines first-release durable-data behavior independently of physical SQLite tables. It does not authorize implementation.

## Ownership

- SQLite transactions own Presets and Summary Records.
- macOS preferences APIs own lightweight global preferences and onboarding state.
- Preferences also own recent-Preset ordering and a minimal interruption marker containing prior Agent instance, active-Session presence, and clean-exit metadata.
- The Agent is the only writer while running.
- Active Session state remains in memory and is not restored after Agent or Mac restart.

## Presets

A stored user Preset contains:

- opaque identifier
- case-insensitively unique display name
- Focus, Short Break, and Long Break durations
- Long Break cadence
- finite Round count or open-ended default
- Focus and Break automatic-start choices
- creation and modification metadata needed for deterministic ordering/migrations

The immutable built-in Classic Preset is represented as a product default rather than a deletable user record. One built-in or user Preset identifier is selected as the default.

Deleting the current default user Preset requires confirmation and atomically selects Classic as the replacement default. Deletion also removes the Preset from recency. Classic itself cannot be deleted.

Up to three distinct recent Preset identifiers are retained across Agent restarts. Recency may include built-in Classic when it is not the default. Every successfully acknowledged CLI, menu, or interactive Session creation updates recency; the current default is excluded from duplicate display and deleted user Presets are removed.

## Summary Records

Summary Records are finalized Focus contributions, not a detailed state-event history.

Each contribution retains:

- opaque identifier
- elapsed Focus time as integer milliseconds
- recorded local calendar date
- timezone identifier and offset context at allocation
- whether this contribution carries the completed-Round marker
- finalization wall time

When elapsed Focus crosses local midnight, accounting creates one contribution per affected local date. Only the contribution containing natural Focus completion carries the completed-Round marker. Interrupted Focus contributions never carry that marker.

Changing timezone later does not regroup historical contributions. Daily totals and streaks remain attached to recorded local dates. Weekly presentation groups those dates using the current macOS locale's first-weekday rule.

## Accounting finalization

Focus elapsed time is finalized transactionally when a Focus Phase:

- completes naturally
- is skipped
- is stopped with its Session
- is replaced by a new Session
- is discarded through confirmed or forced Agent quit

Unexpected Agent failure loses the active uncommitted contribution by design. Duplicate IPC request handling must not finalize the same contribution twice.

Replacement finalizes elapsed Focus only when the old Session's current Phase is Focus and never marks that Round complete. Replacing during a Break creates no contribution. Previously committed contributions remain unchanged; no Session-level interruption or incomplete-Round record is stored.

The interruption marker supports one concise notice after an unclean exit with an active Session. It is cleared after the notice and contains no restorable Session Configuration, Phase duration, or remaining time.

## Precision and presentation

- Durable elapsed Focus uses integer milliseconds.
- Compact menu summaries floor to whole minutes without overstating elapsed time and display `<1m` for a positive sub-minute total.
- Detailed summaries display `h:mm:ss`.
- Presentation rounding never changes stored values.

## Clearing and reset

- Clear History deletes Summary Records transactionally and leaves Presets, preferences, and active Session untouched.
- Full reset requires Idle and explicit confirmation, then removes Presets, preferences, Summary Records, and onboarding state.
- Ordinary Homebrew uninstall preserves data; explicit zap removes all documented Pomo-owned data locations.

## Migrations and recovery

- Create an atomic versioned database backup before schema migration.
- Apply migrations transactionally and record schema version explicitly.
- On failure, preserve the database and backup, disable mutations, and enter recovery mode. Never reset silently.
- Recovery mode offers diagnostics, versioned JSON export, and explicit reset.

The recovery archive includes schema metadata, user Presets, global preferences, and Summary Records. First release exports archives but does not import or merge them.
