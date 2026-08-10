# 08 — Observe Sessions through Follow and NDJSON

**What to build:** A terminal user or automation client can continuously observe an Agent-owned Session without mutating it or flooding output.

**Blocked by:** 04 — Run complete finite and open-ended Pomodoro cycles

**Status:** ready-for-agent

- [ ] Human Follow shows Phase/state, rounded time, progress, Rounds, next Phase, recent Transitions, and explicit separate CLI control hints.
- [ ] Help and detach are the only dashboard actions; Control-C, q, or Escape detaches while the Session continues.
- [ ] Ready and Paused do not poll or redraw, and Running redraws only when the rounded displayed second changes.
- [ ] Plain Follow prints initial state, durable Transitions, and one terminal outcome without one-second tick lines.
- [ ] JSON Follow emits schema-versioned NDJSON beginning with the current snapshot and preserves gap-free ordered visible events when stale ticks are coalesced.
- [ ] A follower queue retains ordered non-coalescible events, terminates a slow follower with stable backpressure guidance, and never blocks Session processing or auto-reconnects.
- [ ] Every exit restores terminal state and writes exactly one concise final scrollback line without replaying dashboard history.
- [ ] Event fixtures, real-socket integration, stalled-consumer, rendering-snapshot, and pseudo-terminal tests cover all states, widths, stream modes, detachment, overflow, and disconnect.

## Validation evidence

- Agreed seam: the Agent-owned Unix socket Follow connection and its public NDJSON adapter. Current server behavior closes after one response, so Follow must be implemented as a protocol extension rather than CLI polling.
- `swift test --filter IPCEnvelopeTests/testFollowInitialSnapshotEventRoundTripsWithSequenceZero` passed: the shared Follow event begins at sequence zero with a schema-stable `initial_snapshot` payload and nullable error.
- `swift test` passed after the schema addition; touched-file diagnostics are clean.
- `swift test --filter UnixSocketTests/testFollowReceivesInitialSnapshotEventAfterAcknowledgement` passed: a Follow request receives its normal acknowledgment and then the sequence-zero initial snapshot on the same socket.
- `swift test` passed after the socket extension; touched Core and socket-test diagnostics are clean.
- `swift test --filter IPCEnvelopeTests/testFollowTickEventUsesTheNextVisibleSequence` passed: tick events retain the current Agent state revision while advancing the caller-controlled visible sequence.
- Full validation: `swift test` passed with 56 tests, 0 failures; touched-file diagnostics and `git diff --check` passed.
- `swift test --filter TimingTests/testFollowSnapshotsYieldsInitialAndStartedSession` passed: Agent-owned subscriptions yield the current snapshot immediately and a serialized Session snapshot after Start.
- Full validation after the subscription foundation passed; touched Core and timing-test diagnostics are clean.
- Follow sockets are now handled concurrently, remain subscribed after their initial snapshot, and relay later serialized Agent snapshots as ordered transition events without blocking the listener.
- Full validation after the persistent transport foundation passed with 57 tests, 0 failures; Core diagnostics and `git diff --check` passed.
- The CLI now consumes the persistent Follow socket: JSON mode emits every ordered event as NDJSON, while human mode renders the initial dashboard and remains attached for later updates.
- `testFollowStreamReceivesLaterSessionSnapshot` passed, proving an initial snapshot followed by a later Agent-owned Session transition; `swift build` passed, the full suite passed with 70 tests and 0 failures, and `git diff --check` passed.
- Human Follow now detaches on `q`, `Q`, Escape, or Control-C, restores termios settings, closes the Follow socket on cancellation, preserves redirected output, and reports unexpected Agent disconnects.
- Validation: `swift build`, full `swift test` with 83 passing tests, diagnostics, and `git diff --check` passed.

Remaining criteria: PTY coverage for keypresses and terminal restoration, durable transition history/backpressure behavior, and precise redraw/coalescing rules.

## Comments

- 2026-08-11 audit: reset the stale claim to `ready-for-agent`; the explicit remaining criteria prevent resolution.
