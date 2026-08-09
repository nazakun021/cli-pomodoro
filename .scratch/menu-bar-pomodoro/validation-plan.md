# Pomo Validation Plan v1

Status: Ready for approval

All implementation tasks record exact command, environment, result, and evidence path. `make validate` is the local non-destructive umbrella; release-only/manual checks remain separate.

## Static and schema gates

```sh
make resolve
make format-check
make schema-check
```

`schema-check` must:

- parse and apply `schemas/database-v1.sql` to an empty SQLite database
- parse both JSON Schema documents and resolve every local `$ref`
- validate every required IPC/public/archive fixture against its schema
- run the semantic validator defined by `schema-semantics.md`, including protocol-range ordering and unique archive paths
- reject schema-invalid and semantically invalid fixtures
- verify schema/document version constants agree

## Automated tests

```sh
make test-unit
make test-integration
make test-cli
make test-ui
```

Unit tests use Swift Testing for state-machine transitions, clocks, duration parsing, Configuration resolution, midnight splitting, streaks, schema mapping, and repositories.

Integration tests use real temporary SQLite databases and Unix sockets for migrations, backups, transactions, retry deduplication, stale endpoints, version negotiation, concurrent commands, follower overflow, Recovery Retry/Discard/Reset, and Agent relaunch.

Recovery integration fixtures explicitly verify that pending accounting is lost with one interruption notice after Agent restart, and that an active Follow stream remains connected through `recovery_entered` and `recovery_resolved` without ticks during Recovery.

Transport framing, 1 MiB limits, incompatible negotiation, invalid-state command rejection, and backpressure behavior belong to integration tests rather than schema parsing alone.

CLI subprocess/pseudo-terminal tests cover all commands, exit codes, output streams, public JSON fixtures, alternate-screen restoration, `--plain`, non-TTY behavior, signals, resize, backpressure, and Agent startup timeout.

XCUITest covers status-item/menu flows, Settings tabs, popovers, summary layout, Recovery actions, notification action routing, launch-at-login errors, keyboard-only navigation, and accessibility labels. Tests must not mutate the maintainer's real Pomo data or login registration.

## Build gates

```sh
make build
make validate
make package VERSION=x.y.z
make release-check VERSION=x.y.z
```

Release check verifies:

- macOS 13 deployment target
- `arm64` and `x86_64` slices
- shared app/CLI product version and `com.nazakun.pomo` bundle identifier
- ad-hoc Hardened Runtime signatures and nested-code verification
- archive contents and SHA-256
- cask syntax/version/checksum/artifacts/zap paths
- dependency lock and license inventory
- no dirty generated files after rebuild

## Performance conditions

Measure on an otherwise idle supported Mac using Release builds:

- Idle Agent: no timer polling and near-zero sustained CPU over 10 minutes.
- Active Session: investigate sustained CPU above 1% over 10 minutes.
- Running Agent command latency: p50 and p95 from 100 local requests; p95 must be under 200 ms.
- Cold Agent Start acknowledgement: 20 runs; every run under 3 seconds.
- Awake deadline-to-transition handling: 100 fake-clock/integration samples plus 20 real-clock samples; p95 under 250 ms.
- Follow clients: verify tick coalescing and bounded memory with a stalled follower.

Record hardware, architecture, macOS, Xcode, Swift, build configuration, and raw results.

## Manual platform matrix

Stable release evidence covers:

- Apple Silicon on macOS 13 and current supported macOS.
- Intel on macOS 13 and current Intel-supported macOS available to the project.
- clean user profile for first launch, notification prompt, login registration, and data paths.
- sleep/wake during Focus and Break, including deadline race.
- notification allowed, denied, pending, disabled, action handling, sound, and missed-alert acknowledgment.
- VoiceOver, keyboard-only use, Increase Contrast, Reduce Motion, light/dark appearance.
- Homebrew install/upgrade/uninstall/zap and direct GitHub archive install.
- Direct archive: checksum, app installation, first launch, bundled CLI execution, and Agent auto-launch after Apple's Open Anyway flow.
- Project cask: cask/checksum verification, first launch, exposed CLI/completions, and Agent auto-launch after Apple's Open Anyway flow.
- app/CLI mismatch, newer database, migration failure, corrupt database, Recovery export/retry/discard/reset.

Unavailable hardware/OS combinations are release blockers unless the spec is explicitly revised; they are not silently waived.

## Milestone 1 minimum gate

Before expanding beyond the Agent/IPC/state-machine proof:

```sh
make format-check
make schema-check
make test-unit
make test-integration
make test-cli
make test-ui
make build
```

Evidence must demonstrate one Agent owner, direct non-interactive Start/Status/Stop, minimal native menu countdown, protocol mismatch rejection, stale-socket safety, request deduplication, and no divergent CLI/menu state. Interactive wizard/Follow terminal restoration is a Milestone 2 gate.
