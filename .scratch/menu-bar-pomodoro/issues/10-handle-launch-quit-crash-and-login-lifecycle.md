# 10 — Handle launch, quit, crash, and login lifecycle

**What to build:** A user can rely on one Agent across launches, explicitly control startup and quit behavior, and understand Session loss after restart or crash.

**Blocked by:** 02 — Start and stop a Classic Focus Session

**Status:** claimed

## Validation evidence

- Ticket 10 is the prerequisite for ticket 07 cold-Agent Preset discovery and Start. The launch adapter must target the installed app artifact rather than the development executable.

- Added durable clean/crash lifecycle markers, one-time interruption notices, ordered startup persistence, immediate active-session marking after menu starts, and clean-quit protection against stale refresh tasks.
- `pomo start` now probes the Agent and launches a packaged Pomo app when needed, with stale-socket recovery and bounded startup waiting. Launch-at-login uses `SMAppService.mainApp` with enabled, disabled, approval-pending, and failure feedback states.
- Added `PomoAgent.app` metadata and a safe ad-hoc Hardened Runtime packaging helper using the ADR-approved `com.nazakun.pomo` identifier; strict codesign verification passed.
- Validation: `swift build`, full `swift test` with 83 passing tests, lifecycle-focused tests, package verification, diagnostics, and `git diff --check` passed.

Remaining criteria: universal app/CLI packaging, launch-at-login UI/settings integration and real registration evidence, forced-quit semantics, and full cold-launch/repeated-launch/crash process coverage.

- [ ] Start launches the installed Agent when needed and acknowledges within the bounded startup wait or fails with actionable Agent-unavailable guidance.
- [ ] Repeated app launches forward to the existing Agent and cannot create competing owners.
- [ ] Launch at login is opt-in through the supported macOS service API, can be enabled and disabled, and exposes registration failures in Settings.
- [ ] Quit succeeds while Idle; during a Session it confirms in the menu or requires explicit CLI force and finalizes eligible partial Focus before shutdown.
- [ ] Agent or Mac restart returns Idle, preserves durable configuration, and never restores volatile Session Configuration or remaining time.
- [ ] Unexpected Agent failure discards the active Session and uncommitted partial Focus, then shows one concise interruption notice on next launch only.
- [ ] The interruption marker contains only prior Agent identity, active-Session presence, and clean-exit metadata and is cleared after notice.
- [ ] Process, real-socket, and CLI tests cover cold launch timeout, repeated launch, clean/forced quit, crash, relaunch, and one-time interruption reporting.
- [ ] Manual login registration and clean/unclean lifecycle checks confirm expected behavior on supported macOS without modifying shell startup files.
