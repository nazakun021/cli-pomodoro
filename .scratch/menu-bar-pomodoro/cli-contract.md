# Pomo CLI Contract

Status: Ready for approval

This document defines the first-release public command and automation contract. It does not authorize implementation.

## General rules

- Public executable: `pomo`.
- Human-readable output is the default.
- Global `--json` requests machine-readable output from every command.
- Bare `pomo --json` is a usage error; interactive setup is available only in human TTY mode.
- Bare `pomo` requires TTY stdin and stdout. Non-TTY use is a usage error with explicit `pomo start` and JSON examples.
- Global `--plain` selects line-oriented prompts/output without cursor movement, alternate screen, or live redraw.
- Human errors go to standard error. JSON mode writes one parseable envelope to standard output even on failure, except that `follow --json` and `start --follow --json` write NDJSON streams.
- Durations are positive, composable integer units from 1 second through 24 hours, such as `90s`, `25m`, and `1h30m`. Zero, negative, fractional, unitless, malformed, and over-24-hour values are usage errors.
- Control-C detaches interactive and JSON follow clients without stopping the Agent-owned Session.
- Every mutating command has a unique request ID bound to the current Agent instance. If a response is lost, the CLI may reconnect and retry only with the same ID during the documented retry window. The Agent returns the original outcome; an expired ID is rejected and never applied again.
- Ordinary commands with a running Agent should complete within 200 ms under typical local conditions.
- Start waits up to 3 seconds when launching the Agent. Human TTY mode may show startup progress; JSON mode still writes only its final envelope.

## Commands

### `pomo`

Open interactive setup: choose the default, a recent, or another named Preset; review and optionally override values; then start.

Default TTY mode uses the three-step alternate-screen wizard in `tui-design.md`. `--plain` uses equivalent numbered, line-oriented prompts.

### `pomo start [DURATION] [options]`

Create a Session. Positional `DURATION` is shorthand for `--focus DURATION`. Without a named Preset, values inherit from the default Preset.

Options:

- `--preset NAME`
- `--focus DURATION`
- `--short-break DURATION`
- `--long-break DURATION`
- `--rounds N` or `--open-ended`, mutually exclusive
- `--long-break-every N`
- `--auto-start-focus` or `--no-auto-start-focus`, mutually exclusive
- `--auto-start-breaks` or `--no-auto-start-breaks`, mutually exclusive
- `--replace` to replace an active Session after applying the accounting rules below
- `--follow` to remain attached after successful creation

Supplying both positional `DURATION` and `--focus` is a usage error. Without `--replace`, non-interactive Start fails if a Session exists. Bare interactive `pomo` does not accept `--replace` and always asks before replacement.

Replacement is one serialized operation: if the old Session is in Focus, finalize elapsed Focus time without completing a Round; if it is in a Break, create no Summary Record. Preserve all prior summaries, commit eligible accounting, then swap to the prevalidated new in-memory Session and acknowledge success.

SQLite commit and volatile Session swap are not falsely described as one transaction. If the Agent crashes after accounting commits but before acknowledgment, committed Focus remains while restart discards both volatile old/new Sessions. The CLI reports success only after acknowledgment; an unavailable/lost response cannot promise that the new Session exists.

### `pomo status`

Print one current snapshot. If the Agent is not running, report that distinct state without launching it.

Successfully observing that the Agent is not running exits 0, including in JSON mode. Exit 4 is reserved for an Agent that was required for an operation but could not be launched or reached.

### `pomo pause`

Pause a Running Phase. It is an invalid-state error from Idle, Ready, or Paused.

### `pomo resume`

Run the current Phase from Ready or Paused. It is an invalid-state error from Idle or Running.

### `pomo skip`

Skip the current Phase from Ready, Running, or Paused. A skipped Ready Focus records zero elapsed focus time. It is an invalid-state error from Idle.

### `pomo stop`

Stop the active Session immediately without a CLI confirmation. Finalize partial focus accounting when applicable. It is an invalid-state error from Idle.

### `pomo follow`

Attach to the active Session. Human mode opens the observer-only alternate-screen dashboard in `tui-design.md`. Plain mode prints the initial state, transitions, and terminal event without tick redraws. JSON mode emits NDJSON. It is an invalid-state error from Idle.

The dashboard accepts only help and detach input; it displays explicit `pomo pause|resume|skip|stop` command hints rather than mutating the Session. On exit it restores the terminal and prints one concise detached/ended line.

### `pomo quit [--force]`

Quit an idle Agent. If a Session exists, refuse unless `--force` is present. Forced quit finalizes partial focus accounting, discards the Session, and quits the Agent.

### `pomo doctor`

Perform read-only checks of installation layout, CLI/Agent versions, protocol compatibility, socket and Agent reachability, data access, launch-at-login registration, and notification authorization. Print manual recovery steps; do not mutate state or repair automatically.

Optional capabilities that are intentionally disabled or denied are reported as warnings. Doctor exits successfully when core installation, Agent communication, and durable-data health are good.

Doctor is read-only and never requests permission or repairs state. If diagnosis finds a core filesystem/socket permission failure, it exits 7 with a stable permission error. Optional notification or launch-at-login denial remains an exit-0 warning.

### `pomo recovery status`

Print the Recovery descriptor and available actions. Ordinary `pomo status` also exits 0 with a Recovery snapshot. Normal mutating commands exit 6 and point to recovery actions.

### `pomo recovery retry`

Retry the exact pending accounting transaction or known-schema migration when the Recovery descriptor advertises `can_retry`. The operation is idempotent. On success, accounting completes once and the Session proceeds to its already-determined next state, or migration completes and the Agent returns Idle.

### `pomo recovery export PATH`

Write one `.pomo-recovery.zip`. Known schemas contain a SHA-256 manifest and JSON data payload. Unknown newer schemas contain a hashed raw SQLite copy and explanatory metadata.

### `pomo recovery discard --force`

When `can_discard_session` is true, confirm loss of only the pending uncommitted Focus contribution, end that Session, preserve committed data, and return Idle.

### `pomo recovery reset --force`

When `can_reset_data` is true, remove all Pomo-owned durable data after explicit force/GUI confirmation. This is distinct from Discard Session and presents export-first guidance.

## Exit codes

| Code | Category          | Meaning                                                                                         |
| ---: | ----------------- | ----------------------------------------------------------------------------------------------- |
|    0 | success           | The requested operation completed.                                                              |
|    1 | unexpected        | An unclassified internal failure occurred.                                                      |
|    2 | usage             | Arguments, duration syntax, or option combinations are invalid.                                 |
|    3 | invalid_state     | The command is not valid for the current Agent/Session/Phase state.                             |
|    4 | agent_unavailable | The Agent is not installed, cannot launch, or cannot be reached.                                |
|    5 | protocol_mismatch | CLI and Agent cannot safely communicate.                                                        |
|    6 | recovery_mode     | Durable data is in read-only recovery mode.                                                     |
|    7 | permission        | A filesystem, notification, service-registration, or related permission prevents the operation. |

JSON errors include both the numeric exit category and a stable symbolic error code with a human message and optional recovery details.

## JSON rules

- Every envelope and event contains a major `schema_version`.
- Responses, snapshots, and events include the current monotonic Agent state revision so clients can order and reconcile observations.
- Fields may be added within a major schema. Removing a field or changing its meaning requires a new major schema.
- Ordinary commands emit one success or error envelope.
- `follow --json` emits one NDJSON object per initial snapshot, tick, transition, and terminal event.
- `start --follow --json` uses the same stream, with its first object representing successful creation/current state.
- A slow follow client may receive coalesced tick events. Transition and terminal events remain ordered and are never intentionally dropped.
- If non-coalescible events exceed a bounded client queue, emit a terminal backpressure error when possible, disconnect that follower, and leave Agent/Session processing unaffected. The client reconciles with `status` before following again.
- Built-in follow mode does not auto-retry after backpressure. It exits 1 with stable symbolic error `follow_backpressure`; the caller explicitly runs `status` and starts a new follow operation.

## Status snapshot

A Session snapshot includes:

- Agent and Session state
- opaque Session ID and Phase occurrence ID
- monotonic Agent state revision
- Phase type and state
- full effective Session Configuration and optional source Preset name
- completed round count and finite target or open-ended marker
- configured Phase duration and remaining whole seconds
- Session and Phase wall-clock start times where applicable
- nullable expected transition wall time

The expected transition time is an estimate available only while Running. It is null in Ready and Paused. Internal monotonic clock values are never exposed.

When no Session exists, a reachable Agent reports Idle without Session fields. When the Agent is not running, `status` reports an Agent-not-running representation without launching it.
