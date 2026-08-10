# Engineering Learnings

Add concise, reusable lessons here only after they are demonstrated by a real task. Each entry should state the trigger, rule, and evidence.

## Entries

- Trigger: a ticket is proposed as `resolved`. Rule: every acceptance checkbox must be complete and backed by the exact evidence type it names; manual screenshots do not satisfy an automation criterion, and a `Known gaps` or `Remaining gaps` section prevents resolution. Evidence: the 2026-08-11 menu audit reopened Tickets 01, 02, 05, 06, and 11.
- Trigger: native UI automation uses an isolated launch mode. Rule: isolation may redirect storage, preferences, and runtime endpoints, but the test must still construct the production Agent, socket, and status item before it can support menu behavior claims. Evidence: the former onboarding-only branch returned before all three while tickets cited it as menu validation.
- Trigger: an async `@main` AppKit Agent calls `NSApplication.run()` manually. Rule: do not rely on inherited MainActor tasks or main-queue DispatchSource timers for status-menu behavior; keep Agent work off the tracking loop, deliver UI work through the AppKit main run loop, use a RunLoop timer, and never rebuild an open NSMenu. Evidence: menu actions entered their selectors but stalled before Agent mutation, and CLI mutations never refreshed the initial menu until these paths moved to the AppKit run loop.
