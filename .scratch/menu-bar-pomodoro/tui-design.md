# Pomo Terminal UI Design v1

Status: Ready for approval

This document is normative for human terminal interaction. JSON/NDJSON behavior remains governed by `cli-contract.md` and `schemas/protocol-v1.schema.json`.

## Capability policy

- Interactive TUI requires TTY stdin and stdout.
- Bare non-TTY `pomo` exits with usage examples and never waits for input.
- `--plain` uses durable line-oriented prompts/output with no alternate screen, cursor addressing, or live redraw.
- Honor `NO_COLOR` and terminal color capability.
- Use Unicode when supported and ASCII equivalents otherwise.
- Never encode state or validation through color alone.
- No mouse support or system-wide shortcuts.

The alternate-screen minimum is 60 columns by 18 rows. Below that size, preserve wizard/dashboard state and show a centered resize message with current/required dimensions plus `--plain` guidance. Resume after resize.

## Terminal safety

One idempotent cleanup path restores cooked input, cursor visibility, style, and the previous screen for:

- normal completion
- `q` or Escape detach where applicable
- Control-C
- handled termination/hangup signals
- Agent disconnect
- rendering/input error
- setup cancellation

Cleanup handlers perform only signal-safe notification; restoration occurs on the main terminal loop. Tests use a virtual terminal and pseudo-terminal subprocesses to prove restoration. Pomo must never intentionally leave raw or alternate-screen mode active.

## Interactive setup wizard

Three steps share a stable header, step indicator, content region, validation line, and contextual footer.

### Step 1: Preset

- Default Preset first.
- Up to three recent non-default Presets.
- Remaining named Presets.
- Custom configuration.

Show name plus compact Focus/Short/Long durations and finite/open-ended summary. Search is not needed in v1.

### Step 2: Configure

Fields:

- Focus duration
- Short Break duration
- Long Break duration
- Long Break cadence
- finite Rounds or Open-ended
- auto-start Focus
- auto-start Breaks

Changes are one-Session overrides unless Save as Preset is explicitly selected in the menu UI; terminal setup starts once and does not edit the source Preset.

Validate on field commit and before advancing. Keep focus on an invalid field, show a concise text error, and preserve all other entries.

### Step 3: Review

Show source Preset, every effective Session Configuration value, finite/open-ended boundary, and auto-start behavior. If another Session exists, replacement confirmation appears here and cannot be bypassed by bare `pomo`.

Primary action: Start. Secondary actions: Back and Cancel.

### Navigation

- Arrow keys move/select.
- Tab and Shift-Tab move between fields/actions.
- Space toggles focused binary controls.
- Enter selects, commits, advances, or confirms the focused action.
- Escape goes back; at Step 1 it asks to cancel only if values changed.
- Control-C cancels immediately after terminal restoration.
- `?` opens contextual help; Escape closes help.

Visible footer hints update by focused control. Plain mode communicates equivalent numbered choices and explicit defaults.

## Follow dashboard

Follow is an observer, not a hidden command surface.

Normal layout contains:

- Phase/state label and large formatted remaining time
- responsive elapsed/remaining progress bar with text percentage or fraction
- completed/target Rounds or Open-ended label
- next Phase and duration
- last three transition messages
- footer: `? help  q detach  Ctrl-C detach`

The dashboard shows equivalent explicit command hints (`pomo pause`, `pomo resume`, `pomo skip`, `pomo stop`) but does not execute them. Help and detach are the only interactive actions.

At narrower supported widths, shorten labels and bar width before hiding the transition list. Phase, time, Round progress, and detach hint always remain.

Ticks redraw only when rounded displayed seconds change. Ready and Paused states do not poll/redraw. Reduce flicker by diffing terminal cells/lines before output.

### Exit behavior

After restoring normal screen, print exactly one concise line:

- Detached: current Phase/time and “Session continues”.
- Session ended/stopped: terminal reason and completed Rounds.
- Agent/recovery/error: stable reason and next command (`pomo status`, `pomo recovery status`, or `pomo doctor`).

Do not replay the transition list into scrollback.

Recovery entry is not itself an exit condition. The active Follow stream emits `recovery_entered`, stops ticks, and changes to the observer-only Recovery dashboard. It remains connected until `recovery_resolved`, Session/Agent terminal event, transport failure, or user detach.

## Plain Follow

`pomo follow --plain` prints:

1. Initial Phase/state/time line.
2. One durable line per transition, Recovery entry, and terminal event.
3. No one-second tick lines.

Control-C detaches and prints the same concise final line.

## Accessibility and testing

- Plain mode is the recommended terminal screen-reader path.
- Alternate-screen content has stable textual labels and logical focus order.
- Help documents `--plain` prominently.
- Snapshot tests cover widths 60, 80, and 120; Unicode/color and ASCII/no-color modes; every wizard step/state; Running/Ready/Paused/Recovery dashboards; validation; resize; and help.
- Pseudo-terminal tests cover input keys, Control-C, signals, disconnects, cleanup, non-TTY errors, and final scrollback lines.
