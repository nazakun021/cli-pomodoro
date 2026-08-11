# 10 — Handle launch, quit, crash, and login lifecycle

**What to build:** A user can rely on one Agent across launches, explicitly control startup and quit behavior, and understand Session loss after restart or crash.

**Blocked by:** 02 — Start and stop a Classic Focus Session

**Status:** claimed

## Validation evidence

- Ticket 10 is the prerequisite for ticket 07 cold-Agent Preset discovery and Start. The launch adapter must target the installed app artifact rather than the development executable.

- Added durable clean/crash lifecycle markers, one-time interruption notices, ordered startup persistence, immediate active-session marking after menu starts, and clean-quit protection against stale refresh tasks.
- `pomo start` now probes the Agent and launches a packaged Pomo app when needed, with stale-socket recovery and bounded startup waiting. Launch-at-login uses `SMAppService.mainApp` with enabled, disabled, approval-pending, and failure feedback states.
- Added `PomoAgent.app` metadata and a safe ad-hoc Hardened Runtime packaging helper using the ADR-approved `com.nazakun.pomo` identifier; strict codesign verification passed.
- Validation: `swift build`, lifecycle-focused tests, package verification, diagnostics, and `git diff --check` passed. The current full Swift suite passes 104 tests.
- Active menu Quit now confirms before ending a Session, saves eligible partial Focus through the Agent, refuses shutdown when accounting fails, and tolerates a Session ending while the confirmation dialog is open. Deterministic lifecycle-marker tests cover one-time crash notices and clean exits.
- Validation: `swift test --filter LifecycleTests` passed with 2 tests and 0 failures; final full-suite validation is recorded below.
- Temporary bundled `Pomo.app` packaging for the lifecycle smoke path passed ad-hoc Hardened Runtime signing and strict codesign verification; the isolated Xcode UI target passed with 2 tests and 0 failures.
- Manual menu validation: the Pomo status item is visible and clickable after launch, with `Quit Pomo` exposed in the startup menu.
- The persistent Agent now disables AppKit automatic termination while Idle, so menu and CLI commands retain one live owner. Menu Start failures are surfaced instead of silently ignored.
- Fixed relaunch ordering so an unexpected-termination marker is consumed before the new Agent writes its running marker; a new lifecycle regression test proves the prior Agent identity and active-Session bit survive this handoff.
- CLI startup now waits for a successful Agent status response instead of treating socket-file creation alone as readiness.
- Focused validation: `swift test --filter LifecycleTests` passed 3 tests; `swift build` passed.
- Existing socket validation also covers live-owner exclusivity, stale owned-socket recovery, reachable Idle status, and Follow startup; these tests pass in the current 104-test Swift suite.
- Added opt-in packaged-process coverage that launches the same packaged Agent twice and verifies the original process remains the sole owner with the same instance and revision. It compiles in the current 104-test suite and runs when `POMO_TEST_APP_PATH` is provided with Accessibility permission.
- Packaged validation passed `POMO_TEST_APP_PATH=/tmp/Pomo-Ticket10.app swift test --filter NativeMenuAccessibilityTests/testRepeatedPackagedLaunchKeepsOneAgentOwner` in 0.687s.
- Packaged validation passed `POMO_TEST_APP_PATH=/tmp/Pomo-Ticket10.app swift test --filter NativeMenuAccessibilityTests/testForcedPackagedCrashRelaunchesIdleWithoutRestoringSession` in 0.239s; the replacement Agent returned Idle with no restored Session.
- Current native UI validation passes 9 tests with zero failures or skips, including clean Idle Quit.

Remaining criteria: universal app/CLI packaging, launch-at-login UI/settings integration and real registration evidence, forced-quit semantics, and full cold-launch/repeated-launch/crash process coverage.

- [ ] Start launches the installed Agent when needed and acknowledges within the bounded startup wait or fails with actionable Agent-unavailable guidance.
- [x] Repeated app launches cannot create competing owners; the packaged repeated-launch test preserves the original Agent instance and revision.
- [ ] Launch at login is opt-in through the supported macOS service API, can be enabled and disabled, and exposes registration failures in Settings.
- [x] Quit succeeds while Idle; the native Idle Quit UI test confirms clean Agent termination. During a Session it confirms in the menu and finalizes eligible partial Focus before shutdown.
- [x] Agent or Mac restart constructs a fresh Idle Agent and does not restore volatile Session Configuration or remaining time; durable Presets and preferences remain outside the Agent actor.
- [x] Unexpected Agent failure discards the active Session and uncommitted partial Focus, then exposes one concise interruption notice on next launch.
- [x] The interruption marker contains only prior Agent identity, active-Session presence, and clean-exit metadata and is consumed after notice; lifecycle tests cover one-time consumption and relaunch ordering.
- [ ] Process, real-socket, and CLI tests cover cold launch timeout, clean/forced quit, and one-time interruption reporting; repeated-owner and forced-crash relaunch are covered by packaged tests.
- [ ] Manual login registration and clean/unclean lifecycle checks confirm expected behavior on supported macOS without modifying shell startup files.

## Remaining validation

The implementation and packaged repeated-owner/forced-crash checks are complete. Ticket 10 remains `claimed` until cold-launch/CLI startup, clean/forced quit, one-time interruption UI, and real launch-at-login registration evidence are recorded.

## Comments

- 2026-08-11 audit: reset the stale claim to `ready-for-agent`; all acceptance criteria remain unchecked and the recorded remaining lifecycle/release work is substantial.
