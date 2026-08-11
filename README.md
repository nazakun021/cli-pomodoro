# Pomo

Pomo is a native macOS Pomodoro application with a persistent menu-bar Agent and
a companion `pomo` CLI. The Agent owns the Session state, timing, persistence,
menu controls, and completion feedback. The CLI and menu bar operate on the same
Session.

Pomo supports macOS 13 and newer on Apple Silicon and Intel Macs.

## Features

- Classic, finite, and open-ended Sessions.
- Start, pause, resume, skip, and stop controls from the CLI or menu bar.
- Custom one-off Sessions and reusable Presets.
- Persistent Agent ownership independent of the terminal process.
- Monotonic timing with sleep-aware pause behavior.
- Local IPC over a private Unix socket.
- Bundled completion sound and accessible missed-alert feedback.
- JSON status output and Follow mode for automation.

System notifications are enabled only for Apple-signed builds. The current
ad-hoc release uses sound and menu-bar feedback instead.

## Install

The latest Apple Silicon release installs both the menu-bar app and CLI:

```sh
curl -fsSL https://github.com/nazakun021/cli-pomodoro/releases/latest/download/install-pomo-macos-arm64.sh -o /tmp/install-pomo.sh
sh /tmp/install-pomo.sh
```

The installer places `Pomo.app` in `~/Applications`, links `pomo` into
`~/.local/bin`, and opens the app. Add the local bin directory to `PATH` when
needed:

```sh
export PATH="$HOME/.local/bin:$PATH"
```

The current release is ad-hoc signed and not notarized. macOS may require
approval in System Settings under Privacy & Security before the first launch.

## Start Pomo

After installation, run `pomo` in an interactive terminal:

```sh
pomo
```

Pomo activates or attaches to the menu-bar Agent. Press Enter to configure a
Session in the CLI, or type `m` to continue setup from the menu bar.

For a direct Classic Session:

```sh
pomo start
```

For a configured Session:

```sh
pomo start 25m --auto-start-focus --rounds 4
```

Useful options include `--focus`, `--short-break`, `--long-break`, `--rounds`,
`--long-break-every`, `--open-ended`, `--auto-start-focus`, and
`--auto-start-breaks`.

## CLI Commands

```sh
pomo status          # Show the current Agent and Session state
pomo pause           # Pause a running Phase
pomo resume          # Resume a paused or ready Phase
pomo skip            # Skip the current Phase
pomo stop            # Stop the active Session
pomo follow          # Stream state changes until detached
```

Use `--json` for machine-readable output:

```sh
pomo status --json
pomo start 25m --auto-start-focus --rounds 1 --json
```

Follow mode can be observed from another terminal. Press `q`, Escape, or
Control-C to detach without stopping the Session:

```sh
pomo follow
```

## Development

Requirements:

- macOS 13 or newer
- Swift 6 toolchain
- Xcode for packaged app and UI tests

Build and test the package:

```sh
swift build
swift test
```

Package a locally signed app:

```sh
POMO_ARCHES=arm64 POMO_VERSION=0.1.0 \
	Scripts/package-agent-app.sh release /tmp/Pomo.app
```

Set `POMO_ARCHES="arm64 x86_64"` for a universal app. The VS Code workspace
also provides build, test, packaging, and release-validation tasks.

## Release

Releases are built by [.github/workflows/release.yml](.github/workflows/release.yml)
from semantic-version tags:

```sh
git tag vMAJOR.MINOR.PATCH
git push origin vMAJOR.MINOR.PATCH
```

The workflow publishes universal and arm64 app archives, an arm64 CLI-only
binary, the installer, checksums, and version metadata.

## Architecture

- `PomoAgent` is the persistent macOS menu-bar Agent.
- `pomo` is the short-lived CLI client.
- `PomoCore` contains Session state, timing, IPC, persistence, and protocol
  models.
- `PomoAgentKit` contains the AppKit and SwiftUI integration.

The Agent is the sole owner of authoritative Session state. Closing a terminal
does not stop an Agent-owned Session.

## Project Documentation

- [Domain context](CONTEXT.md)
- [Feature context](.scratch/menu-bar-pomodoro/FEATURES.md)
- [CLI contract](.scratch/menu-bar-pomodoro/cli-contract.md)
- [Release design](.scratch/menu-bar-pomodoro/release-design.md)
- [Architecture decisions](docs/adr/)
