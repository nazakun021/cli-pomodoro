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
