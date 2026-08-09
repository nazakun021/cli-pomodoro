# Pomo CLI Contract

Status: Planning

This document defines the first-release public command and automation contract. It does not authorize implementation.

## General rules

- Public executable: `pomo`.
- Human-readable output is the default.
- Global `--json` requests machine-readable output from every command.
- Bare `pomo --json` is a usage error; interactive setup is available only in human TTY mode.
- Human errors go to standard error. JSON mode writes one parseable envelope to standard output even on failure, except that `follow --json` and `start --follow --json` write NDJSON streams.
- Durations are positive, composable integer units from 1 second through 24 hours, such as `90s`, `25m`, and `1h30m`. Zero, negative, fractional, unitless, malformed, and over-24-hour values are usage errors.
- Control-C detaches interactive and JSON follow clients without stopping the Agent-owned Session.
- Every mutating command has a unique request ID bound to the current Agent instance. If a response is lost, the CLI may reconnect and retry only with the same ID during the documented retry window. The Agent returns the original outcome; an expired ID is rejected and never applied again.
- Ordinary commands with a running Agent should complete within 200 ms under typical local conditions.
- Start waits up to 3 seconds when launching the Agent. Human TTY mode may show startup progress; JSON mode still writes only its final envelope.

## Commands

### `pomo`

Open interactive setup: choose the default, a recent, or another named Preset; review and optionally override values; then start.

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

Replacement is one serialized mutation: if the old Session is in Focus, finalize elapsed Focus time without completing a Round; if it is in a Break, create no Summary Record. Preserve all prior summaries, end the old Session, then create the new Session. Failure before new-Session creation must not leave accounting partially applied.

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

Attach to the active Session. Human mode updates one status line once per second and prints transitions as durable lines. JSON mode emits NDJSON. It is an invalid-state error from Idle.

### `pomo quit [--force]`

Quit an idle Agent. If a Session exists, refuse unless `--force` is present. Forced quit finalizes partial focus accounting, discards the Session, and quits the Agent.

### `pomo doctor`

Perform read-only checks of installation layout, CLI/Agent versions, protocol compatibility, socket and Agent reachability, data access, launch-at-login registration, and notification authorization. Print manual recovery steps; do not mutate state or repair automatically.

Optional capabilities that are intentionally disabled or denied are reported as warnings. Doctor exits successfully when core installation, Agent communication, and durable-data health are good.

Doctor is read-only and never requests permission or repairs state. If diagnosis finds a core filesystem/socket permission failure, it exits 7 with a stable permission error. Optional notification or launch-at-login denial remains an exit-0 warning.

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
