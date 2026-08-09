# Pomo Durable Data Contract

Status: Ready for approval

This document defines first-release durable-data behavior independently of physical SQLite tables. It does not authorize implementation.

## Ownership

- SQLite transactions own Presets, default-Preset selection, recency metadata, and Summary Records.
- macOS preferences APIs own lightweight global preferences and onboarding state.
- Preferences also own a minimal interruption marker containing prior Agent instance, active-Session presence, and clean-exit metadata.
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

SQLite seeds the immutable built-in Classic Preset as a protected row so default and recency references remain relationally consistent. The repository exposes it as a product default rather than an editable user record.

Exactly one existing Preset is selected as the default at all times. Classic is the initial default; the selection may later reference Classic or one user Preset.

Deleting the current default user Preset requires confirmation and atomically selects Classic as the replacement default. Deletion also removes the Preset from recency. Classic itself cannot be deleted.

Every Preset row may retain a monotonic last-started sequence. Agent acceptance of CLI, menu, or interactive Session creation updates that sequence transactionally before acknowledgment. Recency may therefore survive an ambiguous pre-acknowledgment crash; it is convenience metadata, not evidence that a volatile Session survived. The UI selects the three most recent rows excluding the current default; Classic is eligible when not default and deleted user rows disappear automatically.

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
- Full Reset requires Idle or a Recovery descriptor with `can_reset_data`, plus explicit confirmation. It is unavailable during a normal active Session and removes Presets, preferences, Summary Records, and onboarding state.
- Ordinary Homebrew uninstall preserves data; explicit zap removes all documented Pomo-owned data locations.

## Migrations and recovery

- Create an atomic versioned database backup before schema migration.
- Apply migrations transactionally and record schema version explicitly.
- On failure, preserve the database and backup, disable mutations, and enter recovery mode. Never reset silently.
- Recovery mode offers diagnostics, versioned JSON export, and explicit reset.

Known-schema recovery archives include schema metadata, user Presets, default/recency metadata, global preferences, and Summary Records with SHA-256 integrity manifest. First release exports archives but does not import or merge them.

An older binary encountering a newer unknown schema cannot claim semantic JSON compatibility. It offers a hashed raw database copy in the recovery archive instead.

Required accounting failure enters Recovery before Phase transition. The pending contribution remains in memory and ordinary timing/mutation stop. Retry executes the same idempotent contribution transaction; success then applies the already-determined next state. Discard Session confirms loss of only pending uncommitted Focus and preserves committed data. Full Reset is a distinct capability-gated action.

Pending accounting Recovery does not survive Agent or Mac restart. The existing interruption marker reports the loss once; committed data remains. Intentional Quit is refused until Retry, Discard Session, or explicit destructive Reset resolves the pending state. Export is presented first and strongly recommended but is not mandatory before Discard.
