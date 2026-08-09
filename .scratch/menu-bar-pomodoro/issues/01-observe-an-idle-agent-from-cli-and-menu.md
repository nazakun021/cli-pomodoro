# 01 — Observe an Idle Agent from CLI and menu

**What to build:** A user can launch one authoritative Agent, see its Idle state in the menu bar, and inspect the same state from the CLI without creating a Session.

**Blocked by:** None — can start immediately

**Status:** resolved

- [x] Launching Pomo presents one menu-bar-only Agent whose Idle status item shows only the app icon and whose menu identifies that no Session exists.
- [x] Human and JSON Status report the same reachable Idle snapshot, including Agent identity and revision with no Session, Phase, timing, Configuration, or Recovery data.
- [x] Status reports Agent-not-running successfully and does not launch the Agent when no Agent is available.
- [x] Repeated app launches reuse the existing Agent, and concurrent CLI/menu observations cannot create a second state owner.
- [x] Same-user endpoint ownership, framing, negotiation, malformed-input rejection, stale-endpoint safety, and protocol mismatch are exercised before any command can mutate state.
- [x] JSON Status emits one schema-valid public response, while human and machine errors use their contracted output streams and stable exit categories.
- [x] Contract fixtures accept the not-running and Idle state matrices and reject invalid nullable-field, version, UUID, timestamp, and response-family combinations.
- [x] Automated Agent, socket, CLI, and minimal native UI checks demonstrate matching Idle revisions and snapshots across both surfaces.

## Validation evidence

- `swift test --filter IdleAgentTests` passed: actor-owned Idle snapshot, required nullable JSON fields, and successful Agent-not-running Status envelope.
- `swift test --filter FrameCodecTests` passed: bounded big-endian frame round-trip and oversized-payload rejection.
- `swift test --filter UnixSocketTests` passed: a live Unix socket returned the reachable Agent's Idle snapshot at revision `0`.
- `swift build` passed with no diagnostics.
- `swift run PomoAgent` followed by `swift run pomo status --json` returned `agent_running: true`, the Agent identity, and the Idle snapshot; the temporary Agent was stopped after the smoke test.
- `swift test` passed: 7 tests, 0 failures, including refusal to replace a live socket endpoint.
- `swift test` passed after protocol hardening: 10 tests, 0 failures. Socket Status now requires a successful version/capability handshake and rejects a mismatched protocol major before command execution.
- `swift test` and `swift build` passed after Idle schema alignment: the reachable Idle snapshot now emits exactly the required v1 state matrix, including all Session and Phase fields as explicit nulls.
- `swift test` and `swift build` passed after IPC envelope work: Status now uses a versioned, Agent-bound request and returns a correlated response with the negotiated protocol version and original request ID.
- `swift test` and `swift build` passed after runtime endpoint hardening: Agent startup creates and verifies an owner-only `pomo` runtime directory before binding the versioned socket.
- `swift test` and `swift build` passed after UUID validation: public Idle snapshots encode Agent identity as canonical lowercase UUID text.
- `swift test` and `swift build` passed after framing validation: zero-length, truncated, oversized, and declared-length-mismatched frames are rejected before JSON decoding.
- Final ticket validation: `swift test` passed 14 tests, `swift build` passed without diagnostics, and a temporary `PomoAgent` returned the same revision-0 Idle state through both `pomo status --json` and human `pomo status` before it was stopped.
