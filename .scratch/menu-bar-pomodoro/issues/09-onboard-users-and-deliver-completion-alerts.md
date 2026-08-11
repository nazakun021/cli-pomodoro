# 09 — Onboard users and deliver completion alerts

**What to build:** A first-time user can discover Pomo and receive controllable, accessible completion feedback without permission timing ever delaying a Session.

**Blocked by:** 04 — Run complete finite and open-ended Pomodoro cycles; 05 — Manage named Presets and the default

**Status:** resolved

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
- Manual menu validation: the bundled/Xcode-launched Pomo status item is visible and clickable; the menu exposes `Alerts...` and the idle controls.
- Fixed the live deadline smoke failure: the Agent now uses a dispatch timer, and IPC Status reconciles due phases before responding. A real five-second Session advanced from Running revision 1 to Idle revision 2 after its deadline.
- 2026-08-11 packaged MVP validation: a signed app launched through LaunchServices with isolated storage advanced a five-second finite Focus Session from Running revision `1` to Idle revision `2` through the live follow stream.
- Completion chime evidence: CoreAudio started and stopped Pomo playback on the built-in output with `AudioDeviceStart (err 0)` at the Phase transition.
- Notification evidence remains blocked: `UNUserNotificationCenter` created the category, but authorization returned `didGrant: 0, hasError: 1`; no notification request was delivered in this ad-hoc packaged run.
- 2026-08-11 authorization recheck: multiple Xcode-signed runtime-host Sessions created the notification center/category and called `requestAuthorization(options: 6)`, but every request returned `didGrant: 0, hasError: 1`. The failure persists after deterministic Session automation and in-process education-modal suppression, so notification authorization remains unavailable rather than merely pending or obscured by UI.
- Installed-app recheck: a freshly packaged app copied under `~/Applications`, launched through LaunchServices with isolated data, and driven through a five-second finite Session completed at revision `2` but returned `UNError.notificationsNotAllowed` (`Notifications are not allowed for this application`). No Notification Center preference record was created. The tested bundle was ad-hoc signed with `TeamIdentifier=not set`, and this Mac has zero valid code-signing identities.
- Revised ADR-0004 and the product contracts so system notifications are conditional on Apple team signing. Ad-hoc builds do not request unavailable authorization, always preserve sound/menu/missed-alert completion feedback, and expose a sound-only Alerts fallback that explains the signing limitation.
- Added a pure notification-capability test and deterministic ad-hoc Alerts UI coverage. Final validation passed 100 Swift tests and all 6 XCUITests with zero failures or skips. The packaged five-second Session and CoreAudio evidence above validate natural completion and chime playback.

- [x] First launch shows the compact Welcome popover with Pomo identity, Classic quick start, Settings, and launch-at-login offered once and off by default.
- [x] A capable signed build explains notification purpose without delaying Session timing; an ad-hoc build does not request unavailable permission.
- [x] The embedded chime is enabled by default, uses normal system output volume, and remains configurable in every build; notification preferences appear only when capability exists.
- [x] Pending or unavailable authorization skips rather than queues a completion notification while menu feedback and enabled sound still occur.
- [x] A skipped pending alert creates an accessible non-color missed-alert indicator that does not change Phase state and clears on menu open or explicit dismissal.
- [x] Denied authorization in a capable signed build preserves timing and other cues and offers Open System Settings; an ad-hoc build explains the signing limitation and retains Sound controls.
- [x] Notification action routing is state-safe when capability exists: Ready offers Start Next Phase, while automatic Transition only opens current status.
- [x] Isolated UI automation verifies onboarding persistence, native Session controls, and the ad-hoc Alerts preference fallback without changing real user settings.
- [x] Clean-profile packaged evidence covers natural completion and bundled sound; capability detection prevents unsupported authorization in the ad-hoc release.

## Deferred signed-build validation

Allowed, denied, pending, and disabled notification presentation plus both notification action outcomes require an Apple Development or Developer ID build. This does not block the ad-hoc MVP under ADR-0004; the limitation and revisit condition remain in `docs/agents/tech-debt.md`.
