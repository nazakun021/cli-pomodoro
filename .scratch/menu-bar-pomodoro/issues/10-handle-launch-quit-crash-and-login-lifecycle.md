# 10 — Handle launch, quit, crash, and login lifecycle

**What to build:** A user can rely on one Agent across launches, explicitly control startup and quit behavior, and understand Session loss after restart or crash.

**Blocked by:** 02 — Start and stop a Classic Focus Session

**Status:** ready-for-agent

- [ ] Start launches the installed Agent when needed and acknowledges within the bounded startup wait or fails with actionable Agent-unavailable guidance.
- [ ] Repeated app launches forward to the existing Agent and cannot create competing owners.
- [ ] Launch at login is opt-in through the supported macOS service API, can be enabled and disabled, and exposes registration failures in Settings.
- [ ] Quit succeeds while Idle; during a Session it confirms in the menu or requires explicit CLI force and finalizes eligible partial Focus before shutdown.
- [ ] Agent or Mac restart returns Idle, preserves durable configuration, and never restores volatile Session Configuration or remaining time.
- [ ] Unexpected Agent failure discards the active Session and uncommitted partial Focus, then shows one concise interruption notice on next launch only.
- [ ] The interruption marker contains only prior Agent identity, active-Session presence, and clean-exit metadata and is cleared after notice.
- [ ] Process, real-socket, and CLI tests cover cold launch timeout, repeated launch, clean/forced quit, crash, relaunch, and one-time interruption reporting.
- [ ] Manual login registration and clean/unclean lifecycle checks confirm expected behavior on supported macOS without modifying shell startup files.
