# ADR-0001: Menu-Bar Agent Owns Session State

Status: Proposed

## Context

The product must support three compatible workflows: terminal-first control, menu-first control, and start-and-forget operation after Terminal closes. The menu bar must update continuously and allow pause, resume, skip, and stop actions. The CLI must also expose those operations and an optional live-follow mode.

The product is named Pomo and exposes the public `pomo` command.

A foreground CLI process cannot provide start-and-forget behavior after Terminal closes. A third-party menu-bar host could render command output, but it would make installation dependent on another app and constrain update frequency, interaction design, settings, and lifecycle behavior.

## Decision

Ship two cooperating surfaces as one macOS product:

- A self-contained native menu-bar Agent owns the authoritative Session state, phase deadlines, sleep handling, persistence, notifications, sounds, menu controls, and settings UI.
- A companion CLI exposed as `pomo` sends commands to the Agent and receives snapshots or a live event stream.
- Human-readable output is the default, while status snapshots also have a stable JSON representation for automation.
- The Agent remains available while idle and can optionally launch at login.
- A start command launches the installed Agent automatically when necessary.
- The Agent does not restore an in-progress Session after it or the Mac restarts. It does persist Presets, global preferences, and Summary Records.
- Unexpected Agent failure discards uncommitted active-Session state and partial focus time; the next launch reports the interruption once.
- The CLI and Agent are installed together through Homebrew for an initial audience of technical macOS users.
- The first release supports macOS 13 Ventura and newer supported macOS releases.
- Distribution supports both Apple Silicon and Intel Macs within that operating-system range.

ADR-0002 resolves implementation language and interprocess communication. ADR-0004 resolves packaging, code-signing, and hardware-architecture distribution. Their detailed schemas, layouts, and release mechanics remain implementation-planning decisions.

## Consequences

### Positive

- Terminal can close without ending a Session.
- CLI and menu actions can share one authoritative state machine.
- The menu can offer native controls, settings, notification permissions, sounds, and launch-at-login behavior.
- The product does not require xbar, SwiftBar, or another menu-bar host.

### Negative

- Distribution includes a native app/agent in addition to a CLI binary.
- Interprocess communication, lifecycle supervision, code signing, notarization, and Homebrew packaging require explicit design and validation.
- Agent unavailability and mid-session failure need user-visible error behavior.

## Alternatives considered

### Foreground CLI owns the Session

Rejected because closing Terminal would stop the Session and remove menu controls, contradicting the hybrid and start-and-forget workflows.

### xbar or SwiftBar hosts the menu item

Rejected for the planned product because it adds an external installation dependency and provides less control over responsive updates, native settings, and process lifecycle. It remains viable for a disposable feasibility prototype but is not the intended product architecture.
