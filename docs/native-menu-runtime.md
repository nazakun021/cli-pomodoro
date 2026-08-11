# Native Menu Runtime

Status: Implemented and automated

The menu-bar Agent remains the sole Session authority defined by ADR-0001. The native status item calls the same `PomoAgentCore` actor mutations used by IPC; it does not own parallel Session state.

## AppKit lifecycle constraints

`PomoAgent` currently enters `NSApplication.run()` manually. Under this lifecycle, inherited MainActor tasks and main-queue `DispatchSourceTimer` callbacks do not reliably execute while AppKit is running or tracking a status menu.

The implemented boundary therefore follows these rules:

- Agent reads and mutations run in detached tasks against `PomoAgentCore`.
- AppKit updates are delivered in order by `MainRunLoopDispatcher` through a queued `performSelector(onMainThread:)` drain.
- Periodic Session refresh uses a Foundation `Timer` in `RunLoop.main` common modes.
- The current `NSMenu` and its retained action targets are never replaced while the menu is open.
- Every menu command uses a stable NSObject action target rather than an actor-isolated Objective-C selector thunk.
- The isolated XCUITest runtime host enters AppKit immediately through a normal window, builds the shared Agent/socket foundation off-main, and installs the production status item through `MainRunLoopDispatcher`.

## UI contract conformance

- Idle is an icon-only `target` focus symbol with `Pomo Idle` accessibility text.
- Running Focus uses the target symbol and remaining time; Break uses the cup symbol.
- Ready and Paused use play and pause symbols with formatted remaining time.
- Idle Quick Start precedes Custom Session and today's compact summary.
- Active menus expose the adaptive Start/Pause/Resume control, Skip, confirmed Stop, next Phase and duration, and today's summary.

## Validation

On macOS 26.5.2 arm64, a signed packaged app using isolated durable storage passed the live status-menu workflow:

1. Start Classic created a Running Focus Session at revision 1.
2. Pause produced Paused revision 2 with frozen remaining time.
3. Resume produced Running revision 3 with the same Session and Phase.
4. Skip produced a running Short Break at revision 4 without completing a Round.
5. Confirmed Stop returned Idle at revision 5.

The runtime-host Idle status-item test attaches deterministically and passes on repeated runs. The complete Start/Pause/Resume/Skip/confirmed-Stop workflow passes unskipped after runtime-host mode suppresses only the education modals covered by separate onboarding tests. The full Swift suite passes 104 tests, including ordered dispatcher delivery, menu-target retention, lifecycle marker ordering, Custom Session persistence, and notification capability gating. All nine UI tests pass with zero skips, including the sound-only Alerts fallback, Custom Session, invalid-input, and clean Quit flows for ad-hoc builds.
