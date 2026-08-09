# ADR-0002: Native Swift and Versioned Local IPC

Status: Accepted

## Context

Pomo needs a polished macOS 13 menu-bar experience, a distributable `pomo` executable, shared Session behavior across both surfaces, one authoritative Agent, request/response commands, snapshots, and streamed follow events.

The CLI and app may briefly differ in version during Homebrew upgrades or while an old Agent process remains running. The communication boundary must therefore detect incompatibility before mutating Session state.

## Decision

- Use a Swift package to share domain models, state transitions, validation, protocol messages, and persistence interfaces.
- Build a native SwiftUI app, using AppKit where status-item, activation, window, or lifecycle behavior requires it.
- Run as a menu-bar-only app during normal use. Settings and summary windows activate when requested without adding a second state owner.
- Build the `pomo` executable in the same package and distribution.
- Use Swift Argument Parser for commands, validation, help, and generated zsh, bash, and fish completions.
- Implement interactive terminal behavior with a small internal ANSI/termios renderer behind testable terminal interfaces; do not add a broad TUI framework.
- Enforce one Agent instance. Repeated launches reuse the existing Agent and forward the requested action.
- Communicate through a same-user Unix domain socket under the OS-provided private per-user Darwin temporary directory, using an owner-only Pomo runtime subdirectory and peer validation where the platform permits it.
- Use length-prefixed, explicitly versioned Codable JSON frames for finite requests/responses, state snapshots, errors, and streamed Agent events. Public `follow --json` output remains NDJSON.
- Reject incompatible protocol versions before command execution. Report CLI and Agent versions and direct users to Homebrew upgrade guidance and `pomo doctor`.
- Serialize all Agent mutations and assign each resulting state a monotonic revision included in responses, snapshots, and events.
- Assign every mutating request a unique ID bound to one Agent instance. Cache completed outcomes for a bounded documented retry window and return the original outcome for duplicates during that window.
- Reject expired request IDs rather than applying them again. If a response is lost, allow the CLI to reconnect and retry only with the same request ID during the retry window.
- Coalesce stale tick events for slow followers. If non-coalescible events exceed a bounded queue, send a terminal backpressure error when possible and disconnect that follower without blocking Agent mutations.
- On startup, verify that no live owner/listener exists before removing an owner-owned stale socket endpoint.
- Implement protocol v1 according to `.scratch/menu-bar-pomodoro/ipc-protocol.md` and its machine-readable schema.

Frame contents, version negotiation, runtime path, limits, retry behavior, follower buffering, and stale recovery are defined by the protocol contract. Swift type decomposition and socket implementation details remain implementation-local decisions.

## Consequences

### Positive

- App and CLI share one language and one domain implementation.
- An external terminal executable can communicate without embedding app-specific frameworks.
- Protocol versioning makes mixed-version failures explicit and scriptable.
- The IPC shape supports both ordinary commands and follow-mode event streaming.

### Negative

- The product must secure, clean up, and diagnose a filesystem socket.
- Single-instance coordination and stale endpoints require careful startup sequencing.
- A custom local protocol needs schema fixtures and compatibility tests.
- Protocol limits and compatibility rules become public contracts that require fixtures and compatibility tests.

## Alternatives considered

### Native XPC or Mach service

Not selected because an external Homebrew CLI adds launchd, entitlement, signing, and service-registration complexity. It can be reconsidered if a prototype disproves reliable Unix-socket lifecycle management.

### Separate implementation language for the CLI

Not selected because it would duplicate domain/protocol models and complicate one-package distribution without a demonstrated benefit.
