# 15 — Validate complete accessible native and terminal workflows

**What to build:** A release reviewer can prove that complete native and terminal user workflows agree, remain accessible, meet performance targets, and do not touch real user state.

**Blocked by:** 06 — Quick-start and customize Sessions from the menu; 07 — Configure Sessions through the terminal wizard; 08 — Observe Sessions through Follow and NDJSON; 09 — Onboard users and deliver completion alerts; 10 — Handle launch, quit, crash, and login lifecycle; 12 — Review weekly history, streaks, and clear summaries; 14 — Export Recovery evidence and diagnose Pomo

**Status:** ready-for-agent

- [ ] The non-destructive validation gate resolves pinned dependencies and passes strict formatting, schema semantics, unit, integration, CLI, native UI, and development-build checks with warnings treated as errors.
- [ ] End-to-end tests prove equivalent Session Configuration, snapshots, revisions, controls, summaries, and Recovery descriptors across CLI, wizard, Follow, menu, popovers, Settings, notifications, and windows.
- [ ] Keyboard-only users can start, inspect, control, stop, configure Presets, navigate summaries, and resolve Recovery while focused, with correct default and cancel actions.
- [ ] VoiceOver labels, values, grouping, missed-alert and state announcements are concise and omit one-second tick noise.
- [ ] Light and dark appearances, Increase Contrast, Reduce Motion, increased text, ASCII/no-color terminal mode, and non-color meaning remain usable at contracted minimum layouts.
- [ ] Isolated test profiles and stores ensure UI and integration suites never mutate maintainer data, login registration, or notification choices.
- [ ] Release-build measurements record environment and raw evidence for Idle/active CPU, local command latency, cold Start acknowledgment, awake Transition latency, and stalled-follower memory.
- [ ] Manual platform evidence covers sleep races, alerts and sound, login registration, complete terminal cleanup, native accessibility, lifecycle interruption, and Recovery actions.
- [ ] Any unavailable required macOS or hardware coverage is reported as a release blocker rather than silently waived.
