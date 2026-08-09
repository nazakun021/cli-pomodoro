# Pomo IPC Protocol v1

Status: Ready for approval

This document is normative for Agent/CLI transport behavior. Message shapes are defined by `schemas/protocol-v1.schema.json`; cross-field invariants are defined by `schema-semantics.md`.

## Runtime endpoint

- Resolve the user-private Darwin temporary directory with `_CS_DARWIN_USER_TEMP_DIR`.
- Create `<Darwin temp>/pomo` with owner-only mode `0700`.
- Use `<Darwin temp>/pomo/agent-v1.sock` with mode `0600`.
- Use `<Darwin temp>/pomo/agent-v1.lock` for single-owner advisory locking.
- Reject runtime directories, locks, or sockets not owned by the effective user.

The Agent acquires and holds the exclusive lock before binding. Startup first attempts a connection. If connection fails, only a process that acquires the same exclusive lock may remove the same-user stale socket and bind a replacement. A PID file is never sufficient proof.

## Framing

Each frame is:

1. Four-byte unsigned big-endian payload length.
2. UTF-8 JSON payload of exactly that length.

The maximum payload length is 1,048,576 bytes. Zero-length, oversized, truncated, invalid UTF-8, invalid JSON, and schema-invalid frames terminate the connection. The Agent records a diagnostic without reflecting untrusted payload text into user-facing errors.

## Connection lifecycle

Ordinary commands use one connection:

1. Client sends `hello`.
2. Agent sends `hello_ack` or `hello_reject`.
3. Client sends exactly one `request`.
4. Agent sends exactly one terminal `response` and closes.

Follow commands use the same handshake and request. After the successful response, the Agent sends an initial snapshot event, then Running tick events, transition events, and one terminal event before normal closure.

## Version negotiation

- Protocol identity is major/minor, initially `1.0`.
- `hello` supplies one major and a supported inclusive minor range.
- Different majors produce `hello_reject` and no command executes.
- For the same major, select the highest minor supported by both peers.
- Capabilities are explicit strings. A feature requiring an unnegotiated capability is rejected before mutation.
- Minor releases may add optional capabilities and additive fields only.
- Removing a field, changing meaning, or changing required behavior requires a new major.
- Product versions are diagnostic metadata and do not determine compatibility by themselves.

## Commands and idempotency

- Every mutating request contains a lowercase UUID request ID, UTC RFC 3339 millisecond `issued_at`, and the negotiated Agent instance ID.
- The retry window is five minutes from `issued_at` using the same machine wall clock.
- Reject requests older than five minutes or more than 30 seconds in the future.
- Cache the terminal outcome of accepted mutating requests for the full retry window.
- A duplicate returns the cached outcome without mutation.
- An expired ID is rejected and never applied.
- Requests bound to another Agent instance are rejected.

Read-only requests also carry request IDs for correlation but do not require outcome caching.

## Follow streams

- Emit a tick only when the rounded displayed remaining second changes while Running.
- Emit no ticks while Ready or Paused.
- Each follower has one replaceable tick slot and a FIFO of 64 non-coalescible events.
- Transitions and terminal events are never intentionally coalesced or dropped.
- FIFO overflow attempts one `backpressure` terminal event, closes that follower, and never blocks Agent mutation.
- Built-in `pomo follow` does not reconnect automatically. It exits with `follow_backpressure`; callers run `status` and explicitly follow again.

## JSON conventions

- Property names use `snake_case`.
- UUIDs use lowercase canonical text.
- Wall times use UTC RFC 3339 strings with exactly millisecond precision.
- Shared snapshots, Session Configurations, and errors use the same payload models in IPC and public CLI JSON.
- IPC and public CLI envelopes remain distinct; public output never exposes frame or socket metadata.
- State-dependent snapshot fields are required but nullable.
- Internal monotonic clock values are never serialized.

## Message families

### Handshake

- `hello`: client/product versions, supported protocol range, and capabilities.
- `hello_ack`: negotiated version/capabilities, Agent product version, Agent instance ID, and current state revision.
- `hello_reject`: stable protocol error and Agent-supported range where available.

### Request and response

- `request`: request metadata plus one typed command and arguments.
- `response`: correlation ID, success flag, state revision, nullable result, and nullable stable error.

Exactly one of response `result` and `error` is non-null.

### Events

- `initial_snapshot`
- `tick`
- `transition`
- `session_ended`
- `agent_quitting`
- `backpressure`
- `recovery_entered`
- `recovery_resolved`

Every event has a stream-local increasing sequence, occurrence time, state revision, nullable snapshot, and nullable error. Tick events may share a state revision because display time changes are not domain mutations.

## Public JSON envelopes

Ordinary `--json` output uses `public_response`. Follow output uses one `public_event` object per NDJSON line. Both contain `schema_version: 1` and shared payload models but omit IPC protocol and socket metadata.

The Agent-not-running status is synthesized by the CLI as a successful public response with `agent_running: false`; it is never an IPC snapshot.

## Required fixtures

Contract tests must retain schema-valid fixtures for:

- successful and rejected handshakes
- every command request
- success and each stable error category
- Idle, Ready, Running, and Paused snapshots
- finite and open-ended Session Configurations
- every event family
- duplicate, expired, wrong-Agent, oversized, malformed, and backpressured cases
- public ordinary and NDJSON envelopes
