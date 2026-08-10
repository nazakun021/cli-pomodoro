# 09 — Onboard users and deliver completion alerts

**What to build:** A first-time user can discover Pomo and receive controllable, accessible completion feedback without permission timing ever delaying a Session.

**Blocked by:** 04 — Run complete finite and open-ended Pomodoro cycles; 05 — Manage named Presets and the default

**Status:** blocked

## Validation evidence

- Added an injectable `AlertPreferencesStore` with isolated `UserDefaults` persistence. Defaults enable notifications and sound independently, and onboarding completion persists across store reloads.
- Added native Agent Welcome and Alerts controls. Welcome is shown once, offers Classic start, Settings, or Later, and Alerts saves independent notification and sound choices without participating in Session start.
- `testAlertPreferencesDefaultToEnabledAndPersistOnboardingDismissal` passed; `swift build` passed and touched-file diagnostics are clean.
- Review follow-up moved onboarding persistence until after the Welcome dialog returns and renamed the action to `Open Alerts`; notification delivery and authorization remain outstanding acceptance criteria.

- Agent completion cues now request authorization without blocking Session start, independently honor sound and notification preferences, persist missed-alert state, expose accessible dismissal, and register a stale-safe Start Next Phase notification action for Ready phases.
- Validation: `swift build`, full `swift test` with 83 passing tests, strict diagnostics, and signed app-bundle verification passed.

- Added pending-versus-denied authorization policy, notification-purpose explanation persistence, disabled-notification permission suppression, default notification status routing, menu-open missed-alert acknowledgement, duplicate-cue prevention, a compact Welcome popover, and an embedded completion chime.
- Validation: `swift build` passed after each implementation slice; final `swift test` passed with 72 tests and 0 failures; `git diff --check` passed; final read-only code review found no remaining source correctness findings.
- Added `PomoAgentKit` Xcode integration, an isolated `PomoUITests` target, and a `POMO_TEST_PROFILE` harness that uses a temporary preferences suite and support directory without starting production sockets or touching maintainer data.
- Validation: Xcode `build-for-testing` and the complete `PomoUITests` target passed on macOS 26.5.2; the Welcome test now uses a fresh per-run profile and passes consistently; final `swift test` passed with 72 tests and 0 failures.
- Verification run: Xcode app build and live Agent status passed; `swift run pomo start 5s --auto-start-focus --rounds 1 --json` returned a Running Focus snapshot, but repeated status checks remained Running with `remaining_seconds: 0` and did not expose completion cues. The Session was stopped cleanly afterward.
- Verification limitation: standalone `swift run PomoAgent` crashes in `UNUserNotificationCenter.current()` because SwiftPM executables have no app bundle; notification verification must use the bundled Xcode app. Notifications, sound, and VoiceOver were not marked passed without interactive observation.
- Standalone Agent startup now skips UserNotifications APIs when no app bundle is present, while bundled app launches retain notification delegates, categories, authorization, and completion delivery.
- Focused validation: `swift test --filter 'LifecycleTests|SummaryTests'` passed with 5 tests and 0 failures.
- Added clean-profile UI coverage for onboarding dismissal persistence across relaunch. Xcode `PomoUITests` passed with 2 tests and 0 failures.

- [x] First launch shows the compact Welcome popover with Pomo identity, Classic quick start, Settings, and launch-at-login offered once and off by default.
- [x] First Session start explains notification purpose and starts timing without waiting for the authorization response.
- [x] Notifications and embedded chime are independently enabled by default, use normal system output volume, and remain configurable in Alerts.
- [x] Pending authorization skips rather than queues a completion notification while menu feedback and enabled sound still occur.
- [x] A skipped pending alert creates an accessible non-color missed-alert indicator that does not change Phase state and clears on menu open or explicit dismissal.
- [x] Denied authorization preserves timing and other cues, and Alerts offers the supported Open System Settings action.
- [x] A Ready completion notification offers Start Next Phase, while an automatic Transition notification only opens current status.
- [ ] UI automation verifies onboarding persistence, preference combinations, action routing, missed-alert acknowledgment, keyboard access, and VoiceOver semantics without changing real user settings.
- [ ] Manual clean-profile evidence covers allowed, denied, pending, and disabled notification states, bundled sound, and both notification action outcomes.

## Blocker

The source implementation and deterministic Welcome UI validation are complete. Remaining coverage requires fixing or explaining the Xcode-app deadline transition smoke failure, interactive notification permission/action testing, complete Alerts routing, and manual VoiceOver/clean-profile evidence.
