# Feature: Menu Bar Pomodoro

Status: Ready for approval

## Outcome

Technical macOS users can start and control a Pomodoro session with `pomo` or the menu bar while seeing the active phase and remaining time in the Mac menu bar status area.

## Context

- The product name is Pomo and its public terminal command is `pomo`.
- The product is a self-contained native macOS experience distributed through Homebrew.
- A persistent menu-bar agent owns timer state. The CLI is a short-lived controller and optional live observer.
- The first release supports classic focus, short-break, and long-break phases.
- Planning is complete. This document records resolved product decisions; implementation begins only after explicit spec approval and task creation.
- Domain vocabulary is defined in `../../CONTEXT.md`.
- The proposed process boundary is recorded in `../../docs/adr/0001-menu-bar-agent-owns-session-state.md`.
- The proposed implementation and IPC stack is recorded in `../../docs/adr/0002-native-swift-and-versioned-local-ipc.md`.
- The proposed persistence and timing model is recorded in `../../docs/adr/0003-transactional-storage-and-monotonic-timing.md`.
- The proposed release and installation model is recorded in `../../docs/adr/0004-project-tap-and-ad-hoc-signing.md`.
- The planned command and automation surface is defined in `cli-contract.md`.
- Interactive terminal setup, Follow dashboard, plain fallback, and terminal safety are defined in `tui-design.md`.
- IPC framing, negotiation, messages, and shared/public payload schemas are defined in `ipc-protocol.md` and `schemas/protocol-v1.schema.json`.
- Durable accounting and recovery semantics are defined in `data-contract.md`.
- Physical SQLite schema, transaction boundaries, migrations, backups, and Recovery behavior are defined in `database-design.md`, `schemas/database-v1.sql`, and `schemas/recovery-archive-v1.schema.json`.
- Menu, Settings, summary, and accessibility behavior is defined in `ui-contract.md`.
- Native popover/window dimensions and information layouts are defined in `native-ui-layouts.md`.
- Build, release, Gatekeeper, tap, and update behavior is defined in `release-design.md`.
- Required commands, test layers, evidence, and manual release matrix are defined in `validation-plan.md`.

## User experience

### Starting a session

- Running `pomo` without arguments opens an interactive setup flow.
- Interactive setup selects the default, a recent, or another named preset; reviews its key values; allows overrides; and then starts.
- A user can bypass prompts with `pomo start 25m` or `pomo start --preset NAME`.
- Flexible durations accept values such as `25m`, `90s`, or `1h`.
- A direct focus duration overrides the focus duration from the default preset and inherits all other values from that preset.
- Command flags may override focus, short-break, and long-break durations; finite round count or open-ended mode; long-break cadence; and auto-start behavior for one Session.
- Starting resolves a Preset and any overrides into an immutable Session Configuration. Later Preset edits do not alter the running Session.
- A start chooses either a finite round count or an open-ended session.
- If a Session is active, bare interactive `pomo` always asks before replacing it and does not accept `--replace`. The flag belongs only to explicit non-interactive `pomo start`.
- The CLI confirms startup and exits by default. An explicit `--follow` mode keeps live status in the terminal.
- Human Follow mode uses the compact observer dashboard defined by the TUI contract; JSON Follow remains NDJSON and plain Follow prints durable state changes without live redraw.
- Pressing Control-C in follow mode detaches the CLI without stopping the Agent-owned Session.
- The idle menu offers named/recent presets and a custom-session setup.
- Custom Session opens a compact menu-bar popover rather than the Settings window.

### Controlling a session

- CLI controls: `status`, `pause`, `resume`, `skip`, and `stop`.
- `resume` starts the current Phase from either Ready or Paused; `start` always creates a new Session.
- `skip` is valid from Ready, Running, or Paused and follows the same Phase transition rules in each state.
- `follow` attaches to an existing Session and detaches on Control-C without changing it.
- `status` is human-readable by default. A global `--json` option provides stable machine-readable output for every command.
- Bare `pomo --json` is a usage error because interactive setup requires a TTY and explicit choices.
- `pomo status --json` exits successfully with an explicit Agent-not-running representation when the Agent is absent.
- `pomo start ... --follow --json` uses the same NDJSON event contract as `pomo follow --json`, beginning with the successful creation/current snapshot.
- Follow JSON uses newline-delimited versioned events. Slow consumers may lose stale tick events but never ordered transitions or terminal events.
- If non-coalescible transition events exceed a follower's bounded queue, the Agent sends a terminal backpressure error when possible, disconnects that follower, and continues Session processing.
- Built-in follow mode does not reconnect automatically after backpressure. It exits nonzero with a stable error and instructs the caller to run `status` before explicitly following again.
- JSON snapshots include opaque Session and Phase occurrence identifiers, the full effective Session Configuration, round progress, configured and remaining seconds, Session/Phase wall-clock start times, and a nullable expected transition time.
- The monotonic deadline remains authoritative; expected wall-clock transition time is an estimate while Running and is null while Ready or Paused.
- JSON schema changes are additive within a major `schema_version`; removing fields or changing their meaning requires a new major schema.
- With `--json`, one parseable envelope is written to standard output, except follow mode's NDJSON stream. Human-readable errors are written to standard error.
- CLI exit categories are stable: 0 success, 1 unexpected failure, 2 usage, 3 invalid state, 4 Agent unavailable, 5 protocol mismatch, 6 data recovery mode, and 7 permission failure.
- An operation that is invalid for the current state exits nonzero and reports the current state and valid next actions.
- Menu controls: pause/resume, skip phase, and stop session.
- Starting, pausing, resuming, skipping, or stopping through either surface updates the same agent-owned session.
- Paused status shows a pause symbol and frozen remaining time.
- Skipping focus records its elapsed focus time, does not complete a round, and advances to a short break.
- Skipping a break advances to the next focus phase in the ready state.
- Stop from the menu requires confirmation; explicit `pomo stop` stops directly without prompting.
- Replacing during Focus finalizes only that Phase's elapsed Focus contribution without completing a Round. Replacing during a Break creates no new Summary Record. In both cases, prior completed-Round and Focus summaries remain unchanged and the old Session ends before the new one is created.

### Menu-bar display

- An active phase shows a phase-specific symbol and formatted remaining time: `MM:SS` below one hour or `H:MM:SS` at one hour or more.
- Menu-bar visuals use restrained monochrome SF Symbols: a focus target, a break cup, and clear play/pause state cues.
- The agent remains in the menu bar while idle and shows only the app icon.
- Ready shows a play/phase symbol and the upcoming phase's full duration; Paused shows a pause symbol and frozen remaining time.
- When automatic transition is disabled, completion enters a ready state showing the upcoming phase and its full duration.
- Phase completion can produce a macOS notification, a sound, and a visible menu-bar state change.
- Notifications and sound are enabled by default and can be disabled globally.
- The bundled default completion sound is a subtle, system-like chime suitable for repeated use.
- On the first session start, the app briefly explains phase notifications before requesting macOS notification permission.
- The first Session starts regardless of how or when the user responds to the notification prompt.
- If authorization is still pending when a Phase completes, that completion notification is skipped rather than queued; menu feedback and enabled sound still occur, and later completions notify only after authorization is granted.
- A skipped pending-permission notification sets a temporary, non-color-only missed-alert indicator on the status item and in the menu without altering the current Phase. It has meaningful VoiceOver semantics and clears when the menu is opened or the indicator is explicitly dismissed.
- Denied notification permission does not affect timing, menu feedback, or enabled app sound. Alerts shows the denied state and offers Open System Settings.
- A completion notification offers Start Next Phase only when the Session is Ready; otherwise opening it reveals current status.
- Sound configuration is one global on/off preference using the bundled chime and normal macOS output volume.

### Lifecycle

- Closing Terminal does not stop the timer.
- Mac sleep automatically pauses an active phase; the same remaining time is available after wake.
- An in-progress session is not restored after the agent or Mac restarts.
- Launch at login is an opt-in setting.
- A start command automatically launches the installed agent when it is not running.
- `status` reports a distinct, script-friendly agent-not-running state without launching the agent.
- Quitting the agent during an active session requires confirmation, saves elapsed focus time when applicable, and then discards the session.
- An agent launch or connection failure makes the CLI exit nonzero, distinguishes a missing installation from runtime failure, and points to `pomo doctor`.
- `pomo doctor` is read-only in the first release and checks installation, versions, socket/Agent reachability, data access, launch-at-login registration, and notification authorization before printing manual recovery steps.
- Optional disabled or denied notification/login capabilities appear as doctor warnings and do not cause failure when core Agent and data health is good.
- Doctor never requests permissions or performs repairs. A detected core filesystem/socket permission failure exits 7; optional notification/login denial remains an exit-0 warning.
- An unexpected agent crash discards the active session and uncommitted partial focus time. The next launch shows one concise notice; committed configuration and summaries remain intact.
- A durable interruption marker stores only prior Agent instance, active-Session presence, and clean-exit metadata needed for that one-time notice; it never restores timing state.

### Presets and settings

- The app ships with a classic default: 25-minute focus, 5-minute short break, and 15-minute long break every four completed rounds.
- Users can create named presets and choose a default preset.
- A preset stores phase durations, long-break cadence, default finite/open-ended mode, default round count, auto-start work behavior, and auto-start break behavior.
- Presets and global preferences are managed through the menu-bar settings UI in the first release.
- The classic preset auto-starts breaks but leaves each focus phase ready for an explicit start.

### Completion and summaries

- One round means one focus phase.
- Only a fully completed focus phase advances completed-round count and long-break cadence.
- Skipping a focus phase advances to the next phase but does not count as a completed round.
- A finite session ends when its final focus phase completes; it has no trailing break.
- The first release stores a local summary rather than detailed event history.
- Elapsed focus time from an interrupted focus phase contributes to summary focus time.
- Focus elapsed before skip, stop, or active-session replacement is saved consistently.
- A completed round is assigned to the local calendar date on which it completes.
- Finalized Focus elapsed time is split at each local midnight and allocated to the corresponding recorded local dates.
- Historical contributions retain their local date and timezone context; later timezone changes do not regroup prior totals or rewrite streaks.
- Summary accounting retains integer-millisecond precision. The compact menu shows focus totals in minutes; the detail window shows `h:mm:ss`.
- Compact whole minutes floor elapsed time without overstating it and display `<1m` for positive sub-minute totals.
- Summaries show focus time and completed rounds by day and week, plus a current streak.
- At least one completed round qualifies a local calendar day for a streak; partial focus time alone does not.
- Yesterday's qualifying streak remains current through today and resets only after an entire local day is missed.
- The menu dropdown shows a compact today summary and opens a dedicated window for detailed summaries.
- Weekly summaries use the first weekday from the user's macOS locale.
- Summary Records remain local and are retained until the user explicitly clears them.
- Clear History requires confirmation and deletes only Summary Records; it does not alter Presets, preferences, or the active Session.

### Menu and settings

- Custom Session offers Start Once and Save as Preset actions.
- While Idle, Quick Start leads the menu with the default Preset followed by up to three distinct Presets ordered by most recent start, then Custom Session and today's summary.
- Recent Preset order survives Agent restart and updates when the Agent accepts CLI, menu, or interactive Session creation. It may persist if the Agent crashes before acknowledgment because recency is convenience metadata, not proof of a surviving Session.
- When Classic is not the default, it is eligible for recent Quick Start like any user Preset; only the current default is excluded as a duplicate.
- During a Session, Phase/state and remaining time lead the menu, followed by completed/target or open-ended Round progress, the primary control, secondary Skip/Stop actions, and the next Phase.
- The primary control reads Start in Ready, Pause in Running, and Resume in Paused. Skip and Stop remain secondary actions.
- The compact today summary contains focus minutes, completed Rounds, and current streak only.
- Presets may be edited or deleted while a Session created from them is active because the Session Configuration is immutable.
- The built-in Classic Preset is immutable and cannot be deleted, but it can be duplicated and need not remain the default.
- Deleting the current default user Preset requires confirmation that Classic will become the new default; successful deletion performs that fallback and removes the deleted Preset from recents.
- User Preset names are unique under case-insensitive comparison.
- Settings are organized into General, Presets, and Alerts sections.
- General contains launch-at-login and app-level behavior; Presets contains timing and transition configuration; Alerts contains notification and sound controls.
- First app launch opens a compact welcome popover identifying the status item, offering Classic quick start, and linking Settings.
- The welcome popover offers launch at login once, defaulting off; it never enables registration without explicit consent.
- In-app full reset is available while Idle or when a Recovery descriptor explicitly advertises Reset Data. It is unavailable during a normal active Session and requires confirmation naming Presets, preferences, Summary Records, and onboarding state as deleted data.
- The detail summary window uses previous/next locale-aware week navigation, one accessible daily row per date, and weekly rollups.
- First release has no system-wide keyboard shortcuts; complete keyboard operation applies while Pomo menus and windows are focused.

### Accessibility

- Every menu, popover, Settings, and summary action is fully keyboard navigable.
- Menu-bar symbols and controls have meaningful VoiceOver labels, values, and state-change announcements.
- Motion and transitions honor Reduce Motion.
- State and meaning never rely on color alone.

## Compatibility

- The minimum supported operating system is macOS 13 Ventura.
- The first release supports Apple Silicon and Intel Macs that can run the supported macOS versions.

## Distribution and updates

- One cask in the project Homebrew tap installs a universal Pomo app bundle and exposes its bundled `pomo` executable on `PATH`.
- GitHub releases provide the matching universal app/CLI archive, cryptographic checksums, and installation/trust instructions.
- Preview and stable builds are ad-hoc signed with Hardened Runtime enabled, are not App Sandbox-enabled, and are not Apple-notarized.
- Every release documents and validates the resulting Gatekeeper trust steps. Notarization remains an intentional future improvement rather than a stable 1.0 gate.
- Updates are delivered through Homebrew; Pomo has no in-app or self-update mechanism in the first release.
- Users explicitly stop any Session and run `pomo quit` before `brew upgrade`; package scripts do not silently terminate the Agent.
- Ordinary cask uninstall preserves local Presets, preferences, and Summary Records. An explicit cask zap or in-app full reset removes all Pomo-owned local data.
- Opt-in launch at login uses the supported macOS 13 service-registration API and reports registration failures in Settings.
- Bundle identifier is `com.nazakun.pomo`; source is released under the MIT License.

## Technical constraints

- A Swift package provides shared domain logic to a native SwiftUI/AppKit menu-bar app and the `pomo` executable.
- Swift Argument Parser implements commands, validation, help, and generated zsh, bash, and fish completions.
- GRDB provides SQLite access behind domain-owned persistence interfaces.
- Third-party packages must have pinned resolved versions, compatible permissive licenses, and maintenance/security review.
- The app is menu-bar-only during normal use; opening Settings or summaries activates their windows without creating another Agent.
- Only one Agent instance may own state. Repeated app launches reuse the existing instance and surface the requested action.
- CLI requests, snapshots, and follow events use a versioned same-user Unix domain socket protocol.
- The socket lives under the OS-provided private per-user Darwin temporary directory with an owner-only Pomo runtime subdirectory.
- IPC uses length-prefixed, versioned Codable JSON frames; CLI follow JSON remains NDJSON at the public output boundary.
- The Agent serializes menu and CLI actions, revalidates each action against current state, and increments a monotonic state revision for every mutation.
- Mutating IPC requests carry unique IDs bound to one Agent instance. The Agent returns the original cached outcome within a bounded documented retry window; expired IDs are rejected rather than reapplied.
- Startup removes an owner-owned stale socket only after verifying that no live Agent owns or listens on it.
- Incompatible CLI/Agent protocol versions fail without executing a command and report both versions with upgrade and `pomo doctor` guidance.
- SQLite transactions store Presets and Summary Records. macOS preferences store lightweight global settings.
- Before schema migration, Pomo creates an atomic versioned database backup and then migrates transactionally. Failure retains the backup and enters recovery mode.
- Database migration failure preserves existing data, disables mutation, and enters a recovery mode offering diagnostics and explicit export/reset paths.
- Recovery export produces a versioned JSON archive containing Presets, preferences, Summary Records, and schema metadata. First release does not import archives.
- A required accounting or known-schema migration failure enters a blocked Recovery state. Timing and normal mutations stop while the exact pending operation remains retryable.
- Recovery offers capability-driven Retry, Export, Discard Session, and Reset Data actions. Discard loses only pending uncommitted Focus; Reset is a distinct full-data action.
- Known-schema exports are `.pomo-recovery.zip` bundles with SHA-256 manifest and JSON payload. An older app facing a newer unknown schema can export only a hashed raw database copy with explanatory metadata.
- A running Phase derives remaining time from a monotonic deadline. Sleep detection captures the last reliable remaining duration and resumes in Paused state.
- If the monotonic deadline is reached at or before observed sleep, completion occurs first; otherwise sleep pauses the positive remainder.
- Wall-clock changes do not alter Phase duration; expected transition wall time is recalculated from the monotonic remainder.
- Whole-second display rounds remaining duration up so `00:00` appears only at completion/transition.
- Status time uses `MM:SS` below one hour and `H:MM:SS` at one hour or more.

## Quality attributes

- The Agent performs no timer polling while Idle and should remain near zero CPU use.
- Sustained active-Session CPU above 1% under normal conditions requires investigation before release.
- With a running Agent, ordinary local `status` and control commands complete within 200 ms under typical conditions.
- When Start must launch the Agent, the CLI waits up to 3 seconds for an acknowledged result. Human TTY mode may show progress; JSON mode still emits one final envelope.
- While the Mac is awake and normally loaded, deadline transition UI and alert handling occurs within 250 ms under typical conditions.

## Delivery milestones

All milestones preserve the full stable 1.0 scope; they sequence risk rather than silently removing features.

1. Prove one authoritative Agent, shared domain state machine, local IPC, minimal native menu countdown, and direct non-interactive CLI Start/Status/Stop in development builds.
2. Complete the interactive TUI wizard/Follow dashboard, Phase controls, finite/open-ended transitions, sleep handling, Presets, Settings, notifications, sound, onboarding, and accessibility behavior.
3. Complete Summary Records, streaks, history/reset, SQLite migrations, recovery mode, diagnostics, and failure-path UX.
4. Complete universal packaging, invited technical preview validation, project Homebrew tap/GitHub releases, checksums, Hardened Runtime, trust instructions, and release automation.

Ad-hoc-signed previews are limited to maintainers and invited testers. Stable distribution retains documented Gatekeeper friction until the notarization debt is revisited.

## Non-goals

- Support for operating systems other than macOS.
- Cloud accounts, synchronization, or team features.
- Restoring an active session after process or Mac restart.
- Detailed logs of every pause, skip, and interruption.
- Full configuration parity between the CLI and settings UI in the first release.
- Source-code implementation during the planning and grilling phase.

## Acceptance criteria

- [ ] A session started from the CLI continues after Terminal closes and is immediately controllable from the menu bar.
- [ ] Every CLI, interactive, and menu start path resolves the same complete immutable Session Configuration.
- [ ] Bare interactive replacement always confirms, while only non-interactive `pomo start --replace` bypasses confirmation.
- [ ] Editing a Preset does not alter an active Session created from it.
- [ ] Follow mode updates without terminal log spam, reports transitions, and detaches without stopping the Session.
- [ ] The menu bar displays the correct phase, run/pause/ready state, and remaining time.
- [ ] CLI and menu actions operate on one authoritative session without divergent state.
- [ ] Human-readable and JSON `status` outputs represent the same session snapshot and agent-not-running state.
- [ ] Every CLI command emits the documented exit category and, with `--json`, a schema-versioned success or error representation.
- [ ] NDJSON follow mode preserves ordered transitions and terminal events when tick events are coalesced.
- [ ] Backpressure disconnect exits with a stable error and never auto-reconnects or blocks Agent/Session processing.
- [ ] Focus, short-break, and long-break transitions follow the selected preset and completion rules.
- [ ] Sleep pauses the active phase without consuming remaining time.
- [ ] Notifications, sound, and menu-bar feedback occur according to global preferences.
- [ ] Denied notification permission never blocks Session start or control and exposes an actionable Settings status.
- [ ] Ready completion notifications can start the next Phase without exposing an invalid action after automatic transition.
- [ ] A completion occurring while notification authorization is pending is not queued, still produces enabled non-notification cues, and leaves an accessible missed-alert indicator until acknowledged.
- [ ] Finite and open-ended sessions behave as defined.
- [ ] Local summaries count elapsed focus time and completed rounds according to the domain rules.
- [ ] Daily, locale-aware weekly, and current-streak summaries agree between the menu snapshot and detail window.
- [ ] Cross-midnight Focus time splits by recorded local date, later timezone changes do not rewrite history, and completed Rounds remain assigned to completion date.
- [ ] Users can clear all locally retained summary history.
- [ ] Clear History preserves Presets, preferences, and any active Session.
- [ ] Preset edits and deletion do not mutate the active Session Configuration.
- [ ] Deleting the default user Preset confirms and atomically falls back to Classic while removing stale recency.
- [ ] Keyboard-only and VoiceOver users can start, inspect, control, and stop a Session and manage Presets.
- [ ] Idle and active menu hierarchy, adaptive primary controls, recent-Preset ordering, and weekly history navigation match the UI contract.
- [ ] Reduce Motion and non-color state cues apply across the menu, Settings, and summary window.
- [ ] Quitting/restarting the agent discards the active session but retains presets, preferences, and summaries.
- [ ] Relaunch after a detected crash returns to idle, preserves committed data, and shows one concise interruption notice.
- [ ] The CLI and menu-bar agent can be installed together through Homebrew.
- [ ] The product runs on supported Apple Silicon and Intel Macs with macOS 13 Ventura or newer.
- [ ] The project tap cask and GitHub archive install the same checksummed universal app/CLI artifact, and uninstall preserves user data unless zap is explicitly requested.
- [ ] Ad-hoc signatures include Hardened Runtime, no App Sandbox entitlement is assumed, and tested Gatekeeper trust steps are published for every release.
- [ ] Homebrew upgrade does not silently terminate an Agent or active Session.
- [ ] Launch-at-login can be enabled, disabled, and diagnosed through supported macOS APIs.
- [ ] First launch explains the status item and offers, but does not enable, launch at login.
- [ ] Full reset is unavailable during a normal active Session and removes only explicitly confirmed Pomo-owned data while Idle or in Reset-capable Recovery.
- [ ] A second app launch reuses the existing Agent and cannot create a competing state owner.
- [ ] The local IPC endpoint rejects other-user access and incompatible protocol versions.
- [ ] Concurrent controls serialize deterministically, revisions increase with mutations, and duplicate request IDs cannot apply an action twice.
- [ ] Lost mutating responses can be retried with the same request ID without ambiguous duplicate effects.
- [ ] Replacement finalizes only eligible partial Focus accounting, never invents Break or incomplete-Round records, and preserves prior summaries.
- [ ] Stale-socket recovery never removes an endpoint owned by a live Agent or another user.
- [ ] Database writes are transactional, migrations preserve data on failure, and recovery never resets data silently.
- [ ] Migration creates a recoverable versioned backup and recovery export produces a schema-versioned JSON archive without promising first-release import.
- [ ] Recovery freezes normal mutation, exposes only applicable actions, retries idempotently, and never conflates pending-Session discard with full-data reset.
- [ ] Delayed UI ticks do not change Phase duration, and sleep always returns a running Phase to Paused with its pre-sleep remainder.
- [ ] Deadline/sleep races and system wall-clock changes preserve the documented monotonic timing behavior.
- [ ] Idle and active resource measurements, command latency, Agent launch timeout, and transition latency meet the documented quality targets under the release test conditions.

## Open questions

No decision-bearing product, protocol, storage, TUI, native-layout, release, or validation questions remain open. Implementation-local type decomposition and script internals belong in task breakdown.

## Tasks

Implementation tasks will be created only after this spec is approved.

## Validation plan

Planning validation:

- Review each acceptance criterion against the domain glossary and proposed ADR.
- Resolve every open question or explicitly defer it as a non-goal.
- Walk through finite, open-ended, paused, sleeping, skipped, stopped, and replaced session scenarios.

Stable 1.0 requires:

- Domain/state-machine unit tests, including generated transition sequences and clock boundaries.
- SQLite migration, uniqueness, transaction, focus-accounting, streak, clear-history, and recovery tests.
- Real Unix-socket/Agent integration tests, including version mismatch, stale endpoints, concurrent commands, deduplication, reconnect, and slow followers.
- CLI subprocess contract tests for parsing, output streams, JSON/NDJSON schemas, exit codes, Agent startup, and Control-C detachment.
- UI automation and accessibility audits for keyboard navigation, VoiceOver semantics, Reduce Motion, and non-color state cues.
- Manual macOS checks for sleep/wake, notifications and actions, denied permissions, launch at login, Gatekeeper, upgrade, uninstall/zap, and full reset.
- Runtime and packaging validation on Apple Silicon and Intel, covering macOS 13 Ventura and the current supported macOS release.

Exact commands, fixtures, performance test conditions, hardware availability, and evidence locations will be assigned during task breakdown.
