# cli-pomodoro

Planning artifacts:

- [Feature context](.scratch/menu-bar-pomodoro/FEATURES.md)
- [Ready-for-agent specification](.scratch/menu-bar-pomodoro/SPEC.md)
- [Domain glossary](CONTEXT.md)
- [Architecture decisions](docs/adr/)

## Package the Agent

Build a launch-at-login-compatible application bundle with:

```sh
Scripts/package-agent-app.sh release
```

The bundle is written to `.build/release/Pomo.app` by default and uses the
`com.nazakun.pomo` bundle identifier with ad-hoc Hardened Runtime signing.
Set `POMO_ARCHES="arm64 x86_64"` to produce universal Agent and CLI binaries.

## Validate Session controls

Run the automated state, timing, IPC, and persistence suite:

```sh
swift test
```

For a signed packaged-process smoke without touching normal Presets or summaries:

```sh
mkdir -p /tmp/pomo-validation
Scripts/package-agent-app.sh debug /tmp/pomo-validation/Pomo.app
POMO_TEST_SUPPORT_DIR=/tmp/pomo-validation/support \
	/tmp/pomo-validation/Pomo.app/Contents/MacOS/PomoAgent
```

In another terminal, use `/tmp/pomo-validation/Pomo.app/Contents/Resources/pomo`
to run `start`, `pause`, `resume`, `skip`, `stop`, and `status --json`. Stop the
validation Agent when finished. The signed packaged status menu has also
passed Start, Pause, Resume, Skip, and confirmed Stop against the same Agent,
with an icon-only focus symbol while Idle. The deterministic runtime-host
XCUITest now covers the native status-item workflow; the complete nine-test UI
target passes with zero skips.

## Interactive startup

After packaging and launching Pomo, type `pomo` with no subcommand in a TTY. The
CLI activates or attaches to the menu-bar Agent, then lets you choose the setup
surface: press Enter to configure a Session in the CLI, or type `m` to continue
from the menu bar.

## Install from GitHub Releases

Pomo releases include both the menu-bar app and its bundled CLI. Install the
latest Apple Silicon release with:

```sh
curl -fsSL https://github.com/nazakun021/cli-pomodoro/releases/latest/download/install-pomo-macos-arm64.sh -o /tmp/install-pomo.sh
sh /tmp/install-pomo.sh
```

The installer places `Pomo.app` in `~/Applications`, links its bundled `pomo`
command into `~/.local/bin`, and opens the app. Add `~/.local/bin` to `PATH` if
needed. A raw `pomo-macos-arm64` release asset is also published for CLI-only
automation, but it does not include the menu-bar Agent.
