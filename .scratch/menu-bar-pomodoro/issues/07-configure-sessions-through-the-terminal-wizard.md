# 07 — Configure Sessions through the terminal wizard

**What to build:** A terminal user can safely choose, configure, review, and start a Session through an accessible interactive wizard or equivalent plain prompts.

**Blocked by:** 04 — Run complete finite and open-ended Pomodoro cycles; 05 — Manage named Presets and the default

**Status:** claimed

- [ ] Bare Pomo requires TTY input and output, while non-TTY and JSON attempts fail promptly with explicit non-interactive alternatives.
- [ ] The three-step Preset, Configure, and Review flow offers the default, recent, named, and custom choices and displays every effective Session Configuration value before Start.
- [ ] Invalid fields keep logical focus and preserve all other entries; finite/open-ended and override conflicts cannot reach Agent mutation.
- [ ] Existing-Session replacement appears in Review, always requires interactive confirmation, and cannot be bypassed by a wizard flag.
- [ ] Arrow, Tab, Shift-Tab, Space, Enter, Escape, contextual help, cancellation, and Control-C follow the terminal contract.
- [ ] Plain mode provides equivalent choices, defaults, validation, review, and replacement confirmation without cursor movement or alternate-screen behavior.
- [ ] Resize below the supported minimum preserves wizard state and offers dimensions plus plain-mode guidance; Unicode/color degrade without losing meaning.
- [ ] Every normal, cancel, signal, disconnect, rendering-error, and input-error exit restores cooked input, cursor, style, and the previous screen exactly once.
- [ ] Rendering snapshots and pseudo-terminal tests cover all steps, supported widths, resize recovery, plain mode, accessibility fallbacks, replacement, and terminal restoration.

## Validation evidence

- Initial seam: public bare `pomo` process behavior, including its stdout/stderr text and usage exit code in a non-TTY invocation.
- `swift run pomo` passed: bare non-TTY invocation prints explicit `pomo start 25m` and `pomo start 25m --json` alternatives to standard error and exits 2.
- `swift run pomo --json` passed: standard output contains one JSON envelope with `error.code` `usage`, and the command exits 2.
