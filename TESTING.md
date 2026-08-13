# Pomo Manual Testing Guide

This guide covers the native macOS menu-bar app, the `pomo` CLI, Session timing, Presets, accessibility, completion feedback, and cleanup.

## 1. Prerequisites

- macOS 13 or newer
- Xcode installed for the native app
- A working Swift 6 toolchain
- The repository opened at its root
- Notification testing requires an Apple-signed local build. The current ad-hoc build uses sound, menu state, and missed-alert feedback instead.

Check the toolchain:

```sh
swift --version
xcodebuild -version
```

## 2. Build and Launch the Native App

The Swift package executable `.build/debug/pomo` is the CLI. It does not by itself open the menu-bar app.

### Xcode

1. Open `Pomo/Pomo.xcodeproj`.
2. Select the `Pomo` scheme.
3. Select `My Mac` as the destination.
4. Choose the `Debug` configuration.
5. Press `Command-R`.
6. Look for the Pomo target icon in the macOS menu bar.
7. Click the icon and choose `Start Classic` or `Custom Session...`.

### Terminal build and launch

Use a predictable DerivedData path:

```sh
xcodebuild -project Pomo/Pomo.xcodeproj \
  -scheme Pomo \
  -configuration Debug \
  -derivedDataPath /tmp/PomoDerived \
  build
open /tmp/PomoDerived/Build/Products/Debug/Pomo.app
```

Verify that the Agent is reachable:

```sh
./.build/debug/pomo status
```

Expected idle output:

```text
Pomo Agent is Idle (revision 0).
```

If it says `Pomo Agent is not running`, the native `.app` was not launched.

## 3. First Launch and Onboarding

1. Launch the app.
2. Confirm the Welcome popover identifies Pomo.
3. Confirm `Start Classic`, `Open Alerts`, and `Later` are available.
4. Confirm `Launch at Login` is off by default.
5. Choose `Later`.
6. Confirm the popover closes and the menu-bar icon remains available.
7. Open the menu again and confirm onboarding does not appear a second time.

## 4. Idle Menu

Open the Pomo menu while no Session is active.

Verify, in order:

1. The status item is icon-only and exposes an accessible idle label.
2. The default quick-start Preset is available first.
3. Recent Presets are available without duplicates.
4. `Custom Session...` opens the Custom Session popover.
5. Today's focus total, completed Rounds, and streak are visible.
6. `Presets...` opens Preset settings.
7. `Alerts...` opens alert settings or the sound-only fallback.
8. `Launch at Login` is a checkbox-style menu item.
9. `Quit Pomo` exits the Agent.

Use the arrow keys, Return, and Escape to verify keyboard navigation.

## 5. Custom Focus Session

1. Open the menu and choose `Custom Session...`.
2. Confirm the form is divided into `Focus session`, `Rest`, `Automation`, and `Save` sections.
3. Set `Focus duration` to `30s`.
4. Set `Rest breaks` to `1`.
5. Set `Short break duration` to `5s`.
6. Set `Long break duration` to `10s`.
7. Set `Long break after every` to `4`.
8. Leave `Open-ended session` off.
9. Leave `Auto-start Focus` off.
10. Set `Auto-start breaks` on.
11. Choose `Start Once`.
12. Confirm the popover closes and the status item shows Running Focus.
13. Confirm `Rest breaks: 1` produces two Focus Rounds in the resulting Session.
14. Open the menu and confirm Focus duration, Round progress, percentage progress, and next Phase are shown.

Test invalid input:

1. Open `Custom Session...` again.
2. Enter `not-a-duration` for Focus duration.
3. Enter a valid Short Break duration.
4. Choose `Start Once`.
5. Confirm an error is shown.
6. Confirm the valid Short Break value remains unchanged.
7. Correct the Focus value and start successfully.

Test open-ended mode:

1. Open `Custom Session...`.
2. Enable `Open-ended session`.
3. Confirm the Rest breaks control is disabled or no longer required.
4. Start the Session.
5. Confirm the Session continues after each Focus and Break until manually stopped.

## 6. Active Menu Controls

Start a short custom Session so the controls can be tested quickly.

### Running

Confirm:

- The status icon represents Focus or Break.
- The menu shows remaining time.
- The menu shows Round progress.
- The menu shows a textual percentage.
- The primary action is `Pause`.
- `Skip Phase` and `Stop Session` are available.
- The next Phase and duration are visible.
- Today's summary remains visible.

Keep the menu open for at least five seconds. Confirm the countdown and percentage update without closing or reopening the menu. Confirm the menu actions remain usable.

### Pause and resume

1. Choose `Pause`.
2. Confirm the status changes to Paused.
3. Wait five seconds.
4. Confirm the displayed remaining time does not decrease while paused.
5. Choose `Resume`.
6. Confirm the countdown continues.

### Skip

1. Choose `Skip Phase`.
2. Confirm the Phase changes to the configured next Phase.
3. Confirm skipping Focus does not complete a Round.
4. Confirm skipping a Break creates a Ready Focus Phase.
5. Confirm Skip does not show a confirmation dialog.

### Stop

1. Choose `Stop Session`.
2. Confirm a confirmation dialog appears.
3. Confirm it explains the effect on partial Focus accounting.
4. Cancel once and confirm the Session remains active.
5. Choose Stop again and confirm.
6. Confirm the app returns to Idle.

## 7. Natural Phase Transitions

Use a Session with a 5-second Focus and 3-second Break.

1. Set Auto-start Breaks on and Auto-start Focus off.
2. Start the Session.
3. Wait for Focus to complete.
4. Confirm Break becomes Running automatically.
5. Wait for Break to complete.
6. Confirm Focus becomes Ready with its full duration.
7. Confirm the menu primary action is `Start`.
8. Confirm starting Focus does not create a new Session or reset Round accounting.

For ad-hoc builds, verify the completion sound and menu state. System Notification Center banners require an Apple-signed build and may not appear in the current environment.

## 8. Status Item and Accessibility

### VoiceOver

1. Enable VoiceOver with `Command-F5`.
2. Focus the menu-bar status item.
3. Confirm Idle, Running, Paused, Ready, and missed-alert states have meaningful labels.
4. Confirm the countdown is announced as time remaining.
5. Confirm the alert symbol is not the only missed-alert cue.
6. Navigate the menu using VoiceOver and verify every action has a meaningful name.
7. Confirm a missed alert can be explicitly dismissed.

### Keyboard

Verify that menu items can be reached with the keyboard and that these commands work where applicable:

- Pause: `P`
- Resume: `R`
- Start: Return
- Skip Phase: `S`
- Stop Session: `X`
- Presets: `Command-,`
- Alerts: `A`
- Quit: `Command-Q`

### Appearance and motion

1. Test Light and Dark appearance.
2. Test Increase Contrast if available.
3. Enable Reduce Motion.
4. Confirm symbols and text remain legible.
5. Confirm state is never communicated by color alone.
6. Confirm no essential behavior depends on animation.

## 9. Missed Completion Feedback

This test applies when a notification is denied, unavailable, or cannot be delivered.

1. Disable notification permission or use the current ad-hoc build.
2. Complete a short Focus or Break.
3. Confirm the completion sound plays when enabled.
4. Confirm the menu-bar icon changes to `bell.badge`.
5. Open the menu.
6. Confirm a missed completion row explains the condition.
7. Confirm the row has `Dismiss missed completion alert`.
8. Dismiss it.
9. Confirm the warning icon and menu row disappear.

Notification Center testing requires an Apple-signed Xcode build:

1. Configure a free Xcode Personal Team if available.
2. Run the app once and allow notifications.
3. Confirm Pomo appears under System Settings > Notifications.
4. Complete a Break with Auto-start Focus off.
5. Confirm the notification says `Break complete. Focus round N is ready.`.
6. Confirm its action starts the matching Ready Focus Phase.
7. Dismiss the notification instead and confirm Focus remains Ready.

## 10. Presets and Persistence

1. Open `Presets...`.
2. Confirm Classic cannot be edited or deleted.
3. Duplicate Classic.
4. Rename the copy.
5. Change its Focus duration.
6. Make it the default.
7. Close and reopen Presets.
8. Confirm the changes persist.
9. Start a Session from the new Preset.
10. Edit the source Preset while the Session is active.
11. Confirm the active Session keeps its original configuration.
12. Delete the copied Preset.
13. Confirm deletion requires confirmation.
14. Confirm it disappears from recent Presets.
15. Confirm Classic becomes the default when required.

## 11. CLI and IPC

Use a second terminal while the menu-bar Agent is running.

```sh
./.build/debug/pomo status
./.build/debug/pomo status --json
```

Confirm both commands report the same Agent and Session state as the menu.

Test commands:

```sh
./.build/debug/pomo start 5s --short-break 3s --rounds 2
./.build/debug/pomo pause
./.build/debug/pomo resume
./.build/debug/pomo skip
./.build/debug/pomo stop
```

Verify each mutation is reflected in the menu and that the Agent remains active after the terminal command exits.

Test Follow mode:

```sh
./.build/debug/pomo follow
```

In another terminal, pause or resume the Session. Confirm Follow reports state changes. Press `q`, Escape, or Control-C in Follow and confirm observation stops without stopping the Session.

Test one-Agent ownership:

1. Launch the native app.
2. Run `./.build/debug/pomo status` repeatedly.
3. Attempt to launch another copy of the app.
4. Confirm the second launch does not create a second independent Session owner.

## 12. Timing, Sleep, and Accounting

### Monotonic countdown

1. Start a 30-second Focus.
2. Record the displayed remaining time.
3. Wait ten seconds.
4. Confirm approximately ten seconds elapsed.
5. Change the wall clock or timezone if safe to do so.
6. Confirm the Phase duration is not shortened or extended.

### Sleep handling

1. Start a 30-second Focus.
2. Note the remaining time.
3. Put the Mac to sleep.
4. Wake the Mac.
5. Confirm the Phase is Paused rather than consuming the sleep duration.
6. Resume and confirm the positive remainder continues.

### Accounting

1. Start a Focus.
2. Let it run for several seconds.
3. Stop or skip it.
4. Open the Pomo menu and inspect the `Today` summary row.
5. Confirm elapsed Focus time is recorded there.
6. Confirm an interrupted or skipped Focus does not count as a completed Round.
7. Complete a full Focus and confirm the menu summary increments completed Rounds and streak eligibility.

## 13. CLI Validation and Package Checks

Run the automated package checks before manual release testing:

```sh
swift build
swift test
git diff --check
sh -n Scripts/package-agent-app.sh
sh -n Scripts/install-pomo-macos-arm64.sh
```

Build a local arm64 app:

```sh
POMO_ARCHES=arm64 POMO_VERSION=0.1.1 \
Scripts/package-agent-app.sh debug /tmp/Pomo-debug.app
```

Verify the result:

```sh
codesign --verify --deep --strict /tmp/Pomo-debug.app
open /tmp/Pomo-debug.app
```

Confirm the packaged app launches, creates the menu-bar item, and can be controlled through the bundled CLI at:

```text
/tmp/Pomo-debug.app/Contents/Resources/pomo
```

## 14. Cleanup

Stop any active Session:

```sh
./.build/debug/pomo stop
```

Quit the Agent with the `Quit Pomo` menu action. The current CLI command surface does not include a `quit` command.

Remove temporary test artifacts when finished:

```sh
rm -rf /tmp/PomoDerived /tmp/Pomo-debug.app
```

Do not delete application data during ordinary testing unless testing reset behavior. Presets, summaries, and preferences are intentionally persistent.

## Known Limitations

- The current ad-hoc build cannot receive macOS Notification Center authorization or actions.
- Notification tests require an Apple-signed local build with a valid team identifier.
- The repeated `com.apple.linkd.autoShortcut` XPC messages are macOS/Xcode service diagnostics and are unrelated to Pomo unless another concrete app failure accompanies them.
- Native XCUITest coverage depends on the runtime-host setup and macOS accessibility permissions; manual testing remains useful for visual hierarchy, VoiceOver announcements, and real Notification Center behavior.
