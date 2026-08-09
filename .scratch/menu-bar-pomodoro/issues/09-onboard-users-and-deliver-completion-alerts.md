# 09 — Onboard users and deliver completion alerts

**What to build:** A first-time user can discover Pomo and receive controllable, accessible completion feedback without permission timing ever delaying a Session.

**Blocked by:** 04 — Run complete finite and open-ended Pomodoro cycles; 05 — Manage named Presets and the default

**Status:** ready-for-agent

- [ ] First launch shows the compact Welcome popover with Pomo identity, Classic quick start, Settings, and launch-at-login offered once and off by default.
- [ ] First Session start explains notification purpose and starts timing without waiting for the authorization response.
- [ ] Notifications and bundled chime are independently enabled by default, use normal system output volume, and remain configurable in Alerts.
- [ ] Pending authorization skips rather than queues a completion notification while menu feedback and enabled sound still occur.
- [ ] A skipped pending alert creates an accessible non-color missed-alert indicator that does not change Phase state and clears on menu open or explicit dismissal.
- [ ] Denied authorization preserves timing and other cues, and Alerts offers the supported Open System Settings action.
- [ ] A Ready completion notification offers Start Next Phase, while an automatic Transition notification only opens current status.
- [ ] UI automation verifies onboarding persistence, preference combinations, action routing, missed-alert acknowledgment, keyboard access, and VoiceOver semantics without changing real user settings.
- [ ] Manual clean-profile evidence covers allowed, denied, pending, and disabled notification states, bundled sound, and both notification action outcomes.
