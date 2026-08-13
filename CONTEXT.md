# Pomodoro Domain Context

## Purpose

This context defines the shared language for Pomo, a macOS Pomodoro product controlled through the `pomo` CLI and a menu-bar interface.

## Glossary

### Agent

The persistent macOS process that owns authoritative timer state, presents the menu-bar interface, receives CLI commands, and records local configuration and summaries. The Agent may be idle or may own one Session. Do not call the Agent the CLI process.

### CLI

The terminal interface exposed through the public `pomo` command and used to start, inspect, and control the Agent. A CLI invocation normally exits after the Agent acknowledges a command. In follow mode, it remains attached as an observer; it still does not own timer state.

### Preset

A named reusable configuration containing Phase durations, long-break cadence, default Session boundary, and automatic transition choices. The built-in Classic Preset is immutable and duplicable. User Preset names are unique under case-insensitive comparison.

### Session Configuration

The immutable configuration resolved when a Session starts by combining a base Preset with any one-off overrides. It contains all Phase durations, long-break cadence, Session boundary, and automatic transition choices needed by the Agent. Editing the source Preset does not alter a running Session.

### Session

One user-initiated Pomodoro run owned by the Agent. A Session is either finite, ending after a selected number of completed Rounds, or open-ended, continuing until stopped. At most one Session is active.

### Phase

One timed interval within a Session. A Phase is exactly one of Focus, Short Break, or Long Break. A Phase can be ready, running, or paused, and can complete, be skipped, or be interrupted by stopping the Session.

### Round

One Focus Phase. A Round becomes completed only when its Focus Phase naturally reaches zero. A skipped Focus Phase is not a completed Round and does not advance long-break cadence.

### Transition

Movement from one Phase to the next. A Transition may start the next Phase automatically or leave it ready for an explicit start, according to the active Preset.

### Ready

The state after a Phase completes when the next Phase is selected but automatic start is disabled. Ready displays the upcoming Phase and its full duration; it is neither idle nor paused.

### Ready Focus Prompt

A one-shot macOS User Notification shown when a Break completes and the next Focus Phase enters Ready. It offers starting that existing Focus Phase and does not create a new Session or open the status-item menu automatically.

### Idle

The Agent state in which no Session exists. The menu-bar item remains available and can start a new Session.

### Recovery

The blocked Agent state entered when required accounting, migration, or database access cannot complete safely. Timing and ordinary mutation stop. A capability descriptor exposes only valid Retry, Export, Discard Session, or Reset Data actions. Recovery is not Idle, Ready, or Paused.

### Summary Record

Locally persisted finalized Focus contributions used for daily and weekly focus-time and completed-Round totals, plus a current streak. Contributions retain integer-millisecond elapsed time and recorded local date/timezone context, split at local midnight where necessary. They include elapsed focus from Phases interrupted by skip, stop, Session replacement, or confirmed Agent quit. Records remain local until explicitly cleared. A Summary Record is not a detailed event log.

## Core rules

- The Agent is the sole authority for Session state.
- The CLI and menu-bar UI are control surfaces over the same Agent.
- Every Session owns one complete immutable Session Configuration.
- Closing Terminal does not affect an Agent-owned Session.
- Mac sleep pauses a running Phase without consuming its remaining duration.
- Agent or Mac restart discards an in-progress Session.
- An unexpected Agent crash also discards uncommitted partial focus time and produces a concise notice on next launch.
- Presets, global preferences, and Summary Records survive Agent restart.
- Skipping a Focus Phase records elapsed focus time and transitions to a Short Break without completing a Round.
- Skipping a Break Phase transitions to a ready Focus Phase.
- Replacing a Session finalizes elapsed Focus without completing its Round, records nothing new during a Break, preserves prior summaries, and ends the old Session before creating the new one.
- A finite Session ends immediately when its final Round completes, without a trailing break.
- Completed Rounds are assigned to the local date on which their Focus Phase completes.
- Elapsed Focus crossing local midnight is split between recorded local dates, which later timezone changes do not rewrite.
- At least one completed Round qualifies a local date for the current streak; partial focus time does not.
- A streak through yesterday remains current during today and resets only after a full local date is missed.
- Weekly boundaries follow the user's macOS locale.
- Required accounting failure enters Recovery with the pending contribution held in memory; successful Retry applies it exactly once before continuing.
- Discard Session in Recovery loses only pending uncommitted Focus and preserves committed data. Reset Data is separate and destructive.

## Terms to avoid

- Do not use "timer" when the distinction between Session and Phase matters.
- Do not use "cycle" as a synonym for Round; it is ambiguous about whether a break is included.
- Do not use "background CLI" for the Agent.
