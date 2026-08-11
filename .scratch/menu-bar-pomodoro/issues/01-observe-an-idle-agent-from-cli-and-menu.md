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
- 2026-08-11 audit: reopened because the recorded evidence proves core/socket/CLI Idle behavior but contains no executable native status-item check or repeated-app forwarding check.
- 2026-08-11 live packaged validation: the Idle status item exposes no text title, uses the `target` focus symbol with `Pomo Idle` accessibility description, and rebuilds the full Quick Start menu through the production Agent runtime.
- 2026-08-11 isolated packaged ownership validation: a signed Agent started with isolated support storage reported instance `443754AB-1B6D-4865-B2C5-CB464137853E`, Idle revision `0`; a second launch exited, one Agent process remained, and a later framed IPC Status returned the same instance and revision.
- Added `testIdleStatusItemUsesRealAgentRuntime` as the minimal native tracer through production Agent startup. Both this test and the previously passing onboarding test currently fail before app launch because `PomoUITests-Runner` times out enabling automation mode while `DevToolsSecurity -status` reports Developer Mode disabled.
- Replaced the blocked Idle XCUITest with `NativeMenuAccessibilityTests/testPackagedIdleMenuMatchesSocketSnapshot`. With `POMO_TEST_APP_PATH=/tmp/Pomo-Ticket01.app`, it launches the signed app under isolated preferences/storage, observes Idle revision `0` over framed IPC, finds the `Pomo Idle` AX element, clicks its AX-derived screen frame with CGEvent, and verifies `Start Classic`; the focused test passed in 1.380 seconds.
- Final validation: the full Swift suite passed 94 tests; the complete `PomoUITests` target passed both onboarding tests with Ticket 02's real Session workflow as the only intentional skip; `swift build` and touched-file diagnostics pass.
- Deterministic replacement: `testRuntimeHostExposesIdleStatusItem` enters AppKit immediately through a normal runtime-host window, then installs the same extracted Agent/socket/status-item foundation. Two consecutive focused runs passed in 4.567 and 4.498 seconds; the complete UI target passed the host test and both onboarding tests with only Ticket 02's Pause workflow skipped.
- Post-refactor validation: the full Swift suite passes 98 tests, including ordered main-run-loop delivery and menu-target retention, and the complete five-test UI target passes with zero skips.

## Resolution

The dedicated runtime host gives XCUITest a deterministic normal-window attachment boundary while preserving isolated storage and the real Agent, socket, status item, menu, and AppKit run-loop behavior. Production launches do not create the host window.
