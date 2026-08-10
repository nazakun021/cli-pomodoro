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

The source implementation and SwiftPM validation are complete. The remaining UI automation and clean-profile macOS evidence require an XCUITest target and interactive notification/VoiceOver execution, neither of which exists in the current package workflow.
