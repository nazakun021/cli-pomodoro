# Pomo UI Behavior Contract

Status: Ready for approval

This document defines first-release information hierarchy and interaction behavior without prescribing final pixel layout. It does not authorize implementation.

## Status item

- Idle displays only the Pomo app icon.
- Ready displays a play/Phase symbol and the upcoming Phase's full formatted duration.
- Running displays the Focus target or Break cup symbol and formatted remaining time.
- Paused displays a pause/Phase symbol and frozen formatted remaining time.
- Time uses `MM:SS` below one hour and `H:MM:SS` at one hour or more.
- Whole seconds round up; `00:00` appears only when completion/transition occurs.
- Symbols are monochrome SF Symbols, remain legible in macOS menu-bar appearances, and never serve as the only accessible state label.

## Idle menu

Order:

1. Quick Start with the default Preset.
2. Up to three distinct non-duplicate Presets ordered by most recent Session start.
3. Custom Session.
4. Today's focus minutes, completed Rounds, and current streak.
5. Summary, Settings, and Quit commands.

Deleted Presets disappear from recents. The default is not repeated in recent entries.

When Classic is not the default, it is eligible for recent Quick Start like any user Preset.

Recency survives Agent restart and updates when the Agent accepts a Session start, regardless of whether it originated from CLI, menu, or interactive setup. It may remain after a pre-acknowledgment Agent crash and does not claim that the Session survived.

Custom Session opens a compact status-item popover. It supports Preset selection, one-Session overrides, finite/open-ended choice, Start Once, and Save as Preset.

## Active Session menu

Order:

1. Current Phase type/state and remaining time.
2. Completed versus target Round progress, or completed Rounds plus an Open-ended label.
3. Adaptive primary control: Start in Ready, Pause in Running, Resume in Paused.
4. Secondary Skip and Stop controls.
5. Next Phase type and duration where applicable.
6. Today's compact summary.
7. Summary, Settings, and Quit commands.

Stop requires confirmation and names the impact on partial Focus accounting. Skip does not confirm. Quit during a Session requires the previously defined active-Session protection.

## Settings

- General: launch at login, app-level behavior, full reset, and onboarding state where support access is needed.
- Presets: list, create, duplicate, edit, delete, and select default.
- Alerts: sound on/off and distinct Focus-complete/Break-complete chime cues in every build; notification authorization/status and Open System Settings only when the running build has Apple notification capability.

The built-in Classic Preset is immutable and duplicable. User Preset names are case-insensitively unique. Editing or deleting a source Preset never changes an active Session Configuration. Deleting the current default user Preset confirms that Classic becomes default and removes the deleted Preset from recents.

## Summary window

- Previous and next controls navigate locale-aware calendar weeks.
- Each date has one accessible row containing formatted Focus time and completed Rounds.
- Each week has a Focus-time and completed-Round rollup.
- Current streak appears in the window summary but is not repeated in every daily row.
- Compact menu totals floor to whole minutes, using `<1m` for positive sub-minute time. Detailed rows and rollups use `h:mm:ss`.
- Clear History is available with confirmation and does not affect Presets, preferences, or an active Session.

## First launch and permissions

- First app launch opens a compact welcome popover identifying the status item, offering Classic quick start, linking Settings, and offering launch at login once with the choice off by default.
- First Session start explains notifications and requests authorization without delaying Session start only in an Apple team-signed build. Ad-hoc builds do not request unavailable permission.
- A Phase completion while authorization remains pending or unavailable skips rather than queues that notification; menu feedback and enabled sound still occur.
- The skipped notification adds a temporary, non-color-only missed-alert indicator to the current status-item representation and a concise menu row explaining that the completion alert was unavailable. VoiceOver announces the indicator without changing Phase state.
- Opening the menu acknowledges and clears the status-item indicator; the menu row also supports explicit dismissal. The missed completion is never delivered later as a stale notification.
- Denial or unavailable capability preserves timing, menu cues, and enabled app sound. Signed builds show denial and Open System Settings; ad-hoc builds explain the signing requirement and retain Sound controls.
- In capable signed builds, a natural Break-to-Focus Transition that leaves Focus Ready delivers one Ready Focus Prompt offering Start Next Phase. Dismissing it leaves the Focus Phase Ready and does not open the status-item menu automatically.
- Notifications after an automatic transition open current status without an invalid Start action. Pending, denied, or unavailable notification capability preserves sound and menu feedback without queuing a stale prompt.

## Accessibility

- All menus, popovers, Settings, confirmations, and summary navigation support keyboard-only operation while focused.
- First release does not register system-wide shortcuts.
- Every symbol-only status representation has meaningful VoiceOver label, value, and current-state semantics.
- Phase and Session state changes produce concise VoiceOver announcements without announcing every one-second tick.
- Reduce Motion disables nonessential transitions.
- State, validation, and destructive-action meaning never rely on color alone.

## Recovery state

- The status item uses a non-color warning symbol and concise VoiceOver announcement without opening a forced modal.
- The menu shows the failure reason and only actions advertised by the Recovery descriptor: Retry, Export, Discard Session, and/or Reset Data.
- Normal Session controls are unavailable while Recovery blocks mutation.
- Discard Session confirms loss of pending uncommitted Focus only. Reset Data is visually and verbally distinct, requires stronger confirmation, and presents export-first guidance.
- Successful accounting Retry applies the contribution once and moves to the already-determined next Phase state. Successful migration Retry returns the Agent to Idle.
