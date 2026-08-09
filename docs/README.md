# Pomo Documentation

## Product and implementation

- [Live implementation roadmap](../.scratch/menu-bar-pomodoro/ROADMAP.md) — canonical milestone topology, blocker graph, and frontier rules.
- [Roadmap pointer](implementation-roadmap.md) — stable `/docs` wayfinding for tools that begin here.
- [Domain documentation guidance](agents/domain.md) — how to consume the glossary and ADRs.
- [Engineering workflow](agents/workflow.md) — planning, claiming, validation, blockers, and resolution.
- [Local issue tracker](agents/issue-tracker.md) — `FEATURES.md`, `SPEC.md`, and ticket conventions.

## Architecture

- [ADR-0001: Menu-Bar Agent Owns Session State](adr/0001-menu-bar-agent-owns-session-state.md)
- [ADR-0002: Native Swift and Versioned Local IPC](adr/0002-native-swift-and-versioned-local-ipc.md)
- [ADR-0003: Transactional Storage and Monotonic Timing](adr/0003-transactional-storage-and-monotonic-timing.md)
- [ADR-0004: Project Tap and Ad-Hoc Signing](adr/0004-project-tap-and-ad-hoc-signing.md)

## Engineering records

- [Learnings](agents/learnings.md)
- [Tech debt](agents/tech-debt.md)

The canonical product vocabulary remains in the repository-root `CONTEXT.md`. Formal feature scope and detailed grilling context live under `.scratch/menu-bar-pomodoro/` as `SPEC.md` and `FEATURES.md` respectively.
