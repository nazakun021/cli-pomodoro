# 08 — Observe Sessions through Follow and NDJSON

**What to build:** A terminal user or automation client can continuously observe an Agent-owned Session without mutating it or flooding output.

**Blocked by:** 04 — Run complete finite and open-ended Pomodoro cycles

**Status:** claimed

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
