# Menu Bar Pomodoro Planning

Status: ready-for-agent

This directory is the canonical feature workspace for Pomo planning and execution.

## Start here

1. [Formal specification](SPEC.md) — implementation scope, user stories, decisions, testing seams, exclusions, and ready-for-agent status.
2. [Feature context](FEATURES.md) — detailed grilling history, acceptance context, and resolved product behavior.
3. [Implementation roadmap](ROADMAP.md) — milestones, dependency graph, frontier rules, and ticket links.
4. [Current tickets](issues/) — live blocker/status/acceptance records; Ticket 01 is the initial frontier.

## Behavioral contracts

- [CLI contract](cli-contract.md)
- [IPC protocol](ipc-protocol.md)
- [Schema semantic rules](schema-semantics.md)
- [Durable data contract](data-contract.md)
- [Database and Recovery design](database-design.md)
- [Terminal UI design](tui-design.md)
- [Native UI behavior](ui-contract.md)
- [Native UI layouts](native-ui-layouts.md)
- [Release design](release-design.md)
- [Validation plan](validation-plan.md)

## Machine-readable schemas

- [Protocol and public JSON schema v1](schemas/protocol-v1.schema.json)
- [Database schema v1](schemas/database-v1.sql)
- [Recovery archive schema v1](schemas/recovery-archive-v1.schema.json)

## Architecture and vocabulary

- [Domain glossary](../../CONTEXT.md)
- [Agent ownership ADR](../../docs/adr/0001-menu-bar-agent-owns-session-state.md)
- [Native Swift and local IPC ADR](../../docs/adr/0002-native-swift-and-versioned-local-ipc.md)
- [Storage and timing ADR](../../docs/adr/0003-transactional-storage-and-monotonic-timing.md)
- [Distribution ADR](../../docs/adr/0004-project-tap-and-ad-hoc-signing.md)

## Authority order

When documents appear to differ, use this order and stop for an explicit revision rather than guessing:

1. Accepted ADRs for architecture constraints.
2. `SPEC.md` for approved feature scope and observable outcomes.
3. Machine-readable schemas and companion contracts for detailed normative behavior.
4. `FEATURES.md` for rationale and grilling context.
5. Individual tickets for the current implementation slice.

Live execution state exists only in ticket files. The roadmap summarizes topology and must not be used to infer that a ticket is claimed, blocked, or resolved.
