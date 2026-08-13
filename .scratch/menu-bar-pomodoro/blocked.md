# Blockers

## Open: System notifications unavailable without Apple signing

Date: 2026-08-12

Attempted: Tested the Xcode Debug app after enabling the local Debug notification path.

Observed result: The built app is ad-hoc signed (`Signature=adhoc`, `TeamIdentifier=not set`). macOS logs `UNError.notificationsNotAllowed` when Pomo requests notification authorization. The repeated `com.apple.linkd.autoShortcut` XPC messages are unrelated system-service diagnostics.

Impact: Notification Center banners and notification actions cannot be validated on this Mac without an Apple-signed local build. Pomo must rely on its completion sound, menu state, and missed-alert fallback for the current build.

Next decision: Use a free Xcode Personal Team if available for local notification testing, or defer signed-notification validation until an Apple Development/Developer ID signing identity exists. Do not weaken the Release/ad-hoc capability policy to bypass macOS authorization.

## Resolved: Ticket 01 deterministic native Idle automation

Date: 2026-08-11

Attempted: Added a minimal real-runtime Idle status-item XCUITest and ran it separately from Session controls. Reran the established Welcome accessibility test as a control.

Observed result: Both tests fail before Pomo launches because `PomoUITests-Runner` times out enabling automation mode. `DevToolsSecurity -status` reports Developer Mode disabled. Independently, isolated packaged validation proved a second Agent launch cannot replace the live owner: one process remained and framed IPC Status retained the original Agent instance and Idle revision.

Update: Developer Mode is enabled and the Welcome accessibility control passes. The production-runtime tracer now reaches app launch, where XCTest waits about 65 seconds and fails with `Application 'com.nazakun.pomo' does not have a process ID`. macOS assigns the launched app a PID, no crash report is produced, and the same Xcode-built executable remains running outside XCTest with identical isolated environment values. Test-only off-screen and visible host windows plus explicit `finishLaunching()` did not change attachment and were removed.

Required: Choose a different UI automation launch/attachment strategy, such as attaching to an independently launched app or moving the real runtime into an attachable dedicated UI-test host, then preserve status-item assertions at the native boundary.

Option 1 result: `NSWorkspace` independently launched the isolated Xcode-built app, but `XCUIApplication(bundleIdentifier:)` remained unbound and the target-bound `XCUIApplication()` path hung for about 17 minutes before XCTest restarted. Xcode then failed result-bundle collection. The independent-launch harness was removed; a dedicated attachable UI-test host or non-XCTest native automation is still required.

AXUIElement update: An opt-in SwiftPM integration test launches the signed packaged app with isolated storage, observes Idle revision `0` through framed IPC, and locates the `Pomo Idle` accessibility element. Although the element advertises `AXPress`, performing that action returns `kAXErrorActionUnsupported`. Continue with a CGEvent click derived from the AX frame or use a dedicated attachable UI-test host.

Resolved: The integration test now derives the status item's center from AX position/size, synthesizes a CGEvent click, and verifies `Start Classic` in the opened menu. The focused packaged test passes, the full Swift suite passes 94 tests, and the Xcode UI target passes with Ticket 02's full Session workflow as its only intentional skip.

Reopened: Immediate repeated packaged AX runs produced one pass in 10.105 seconds followed by one `Accessibility element` timeout in 10.398 seconds. The coordinate/AX approach is useful diagnostic evidence but not deterministic validation. Replace it with a dedicated attachable UI-test host before resolving Ticket 01 or its dependent Ticket 02.

Resolved: A dedicated normal-window runtime host enters AppKit immediately, then installs the same extracted Agent/socket/status-item foundation. Two consecutive focused Idle tests passed in 4.567 and 4.498 seconds; the UI target subsequently expanded to eight tests and passes with zero skips.

## Resolved: Ticket 02 native Session workflow

Date: 2026-08-11

Attempted: Replaced the onboarding-only UI harness with isolated real Agent storage and runtime endpoints, added a status-item workflow test for Start, Pause, Resume, Skip, and confirmed Stop, and ran the focused test through `xcodebuild` with both automatic signing and signing disabled.

Observed result: Pomo creates its isolated SQLite store and Agent lock/socket path, and the same signed app passes the full Start/Pause/Resume/Skip/Stop workflow through the live status menu. Xcode 26.4 on macOS 26.5.2 times out before menu interaction and reports `Application 'com.nazakun.pomo' has not loaded accessibility`. Core, socket, packaged-app, bundled-CLI, and live Accessibility validation pass.

Required: Repair or replace the XCUITest launch/attachment setup, then pass the real status-item workflow test before resolving Ticket 02. Manual observation may supplement but does not replace this executable criterion.

Update: The current environment now fails earlier than the recorded app attachment error: both real-runtime and onboarding UI tests time out enabling automation mode while Developer Mode is disabled. Resolve this prerequisite before changing Pomo's launch path.

AX replacement update: The packaged test now clicks Start Classic and observes Running revision `1` with Classic configuration over IPC. Its second menu open finds a `Pomo Focus Running` descriptive AX child that advertises `AXPress` but has no position/size, so the CGEvent helper reports `Status item frame` unavailable. Select a geometry-bearing ancestor before continuing through confirmed Stop.

Geometry-ancestor result: The active descriptive child exposes no usable AX parent chain. A broad framed menu-bar fallback selected the wrong element and left IPC at Idle revision `0`, so it was removed. The next bounded strategy is to retain the known-good Idle status item's screen anchor and reuse that stable menu-bar location after Start.

Stable-anchor result: The Idle status item's point can be captured atomically and retained, but the next `Start Classic` AX menu item loses position/size between semantic lookup and `click(_:)`. Apply the same atomic point-resolution pattern to menu items and confirmation buttons before continuing the workflow.

Dedicated-host update: A normal runtime-host window now lets XCUITest attach in under a second while the same extracted Agent/socket/status-item foundation installs asynchronously. Idle, Start Classic, Running, and the Pause action are automated. After Pause, the expected `Pomo Focus Paused` status state does not appear within 10 seconds, blocking Resume/Skip/confirmed Stop. The full workflow remains skipped while a focused runtime-host Idle test stays active.

Dispatcher update: A focused test proved `MainRunLoopDispatcher` dropped earlier pending actions (`[2]` observed instead of `[1, 2]`); it now drains an ordered queue and the regression test passes. The runtime-host workflow still does not expose Paused after clicking Pause. Observe the isolated socket immediately after the click to separate mutation delivery from UI refresh before making another runtime change.

Socket-probe result: PomoCore linked successfully into PomoUITests, but the test runner received `LocalAgentTransportError.connectFailed` for the app-owned isolated socket and no snapshot. The linkage/probe was removed. Expose revision/state from inside the runtime-host process as the next discriminator.

Host-state result: The runtime host's `followSnapshots()` view reaches revision `1` Running after Start and remains there after Pause with both standard and center-coordinate XCUITest clicks. The mutation is not delivered. Next, strongly associate each `MenuActionTarget` with its `NSMenuItem`; AppKit targets are not retained and the mutable target array can be cleared by a concurrent rebuild before selector delivery.

Target-retention result: `NSMenuItem` now strongly retains `MenuActionTarget` through `representedObject`, and a focused AppKit test proves the target survives and invokes. Pause still leaves the runtime host at revision `1`. Instrument `invokeMenuAction` next to determine whether XCUITest reaches the selector at all.

Selector result: With host-owned action/state instrumentation, Pause invoked and reached revision `2` Paused, and the complete Start/Pause/Resume/Skip/confirmed-Stop workflow passed once. Removing the temporary host barriers reintroduced a race waiting for the Paused status label. Keep a minimal revision/state label in runtime-host mode and make the full workflow wait for revisions `1` through `5` before asserting native controls.

Resolved: Runtime-host mode now sets its separately tested onboarding/notification-explanation flags inside the launched app process, so `Completion Alerts` cannot intercept menu automation. The focused workflow passed through Start/Pause/Resume/Skip/confirmed Stop to Idle, and the nine-test UI target passes with zero skips.

## Historical manual evidence: Ticket 05 — Manage named Presets and the default

Date: 2026-08-10

Attempted: Built the native Presets Settings window with `swift build`; it completed successfully. The automated SwiftPM suite also passes, but this package has no XCUITest target.

Observed result: Keyboard focus order, delete confirmation presentation, and VoiceOver labels cannot be verified in the current environment.

Resolved: Manual verification on macOS confirmed Tab/Shift-Tab navigation, Classic read-only controls, user-Preset deletion confirmation, and VoiceOver announcements in the Presets Settings window.

Automation resolution: Runtime-host XCUITest now verifies Classic protection, duplication, keyboard focus order, default selection, and confirmed deletion. Ticket 05 is resolved.

## Historical manual evidence: Ticket 06 — Quick-start and customize Sessions from the menu

Date: 2026-08-10

Attempted: Built the current native menu and Custom Session popover with `swift build`; it completed successfully. Core and IPC tests verify selected-Preset and configured-CLI recency behavior.

Observed result: Manual macOS screenshots verified Preset editing/default selection, the active menu and Stop confirmation, compact Custom Session fields, and invalid-value feedback. The user confirmed keyboard navigation and VoiceOver labels from this and earlier manual testing.

Resolved: Ticket 06 manual UI/VoiceOver evidence is complete.

## Resolved: Ticket 07 Preset Discovery Blocker

Date: 2026-08-10

Attempted: Implemented TTY-gated plain Classic setup with validated overrides, review, and explicit active-Session replacement confirmation. Builds and 53 automated tests pass.

Observed result: Implemented the Agent-owned read-only `presets` IPC command and versioned discovery response. A real-socket test verifies the default and named Presets return without direct CLI database access.

Resolved: Ticket 07 can resume its terminal Preset-selection implementation.

## Ticket 09 — Native alert validation unavailable

Date: 2026-08-10

Attempted: Completed the Welcome popover, Alerts settings, authorization policy, missed-alert handling, notification actions, embedded chime, and an isolated `PomoUITests` target. `swift build`, Xcode `build-for-testing`, and the full SwiftPM suite pass.

Observed result: The focused Welcome accessibility test passes with a fresh per-run preferences/support profile. A live Xcode-app smoke test accepted CLI Start but remained Running with `remaining_seconds: 0` after the deadline, so completion cues were not verified. Standalone SwiftPM Agent launch also crashes because UserNotifications requires an app bundle. Interactive notification permission/action testing and clean-profile VoiceOver validation remain unexecuted.

Historical requirement superseded by the capability-gated MVP decision: extend the UI target for the ad-hoc sound fallback now; defer allowed, denied, pending, and disabled notification delivery/action validation until an Apple team-signed build exists.

Update: A LaunchServices-started signed app with isolated storage completed a five-second finite Focus Session at Idle revision `2`. CoreAudio logs prove the completion chime played through the built-in output. Notification authorization returned `didGrant: 0, hasError: 1`, so notification presentation remains unverified for the ad-hoc bundle.

Authorization recheck: Multiple Xcode-signed runtime-host Session runs repeated the same result after category registration and `requestAuthorization(options: 6)`: `didGrant: 0, hasError: 1`. The education modal no longer intercepts automation. Capture the callback's concrete error from an installed app before treating allowed notification/action coverage as executable.

Installed-app result: A fresh app under `~/Applications` completed a five-second Session but authorization returned `UNError.notificationsNotAllowed` (`Notifications are not allowed for this application`) and created no Notification Center preference record. The bundle was ad-hoc signed with no Team ID, and no valid signing identity exists on this Mac. This result led to the capability-gated ADR-0004/Ticket 09 decision; an Apple Development or Developer ID build is only required for deferred signed-notification validation.

Resolution: ADR-0004 and Ticket 09 now make system notifications conditional on Apple team signing. The ad-hoc MVP suppresses unavailable authorization and guarantees sound, menu, and accessible missed-alert feedback. Signed notification presentation and action validation remain tracked as technical debt rather than blocking Ticket 09.
