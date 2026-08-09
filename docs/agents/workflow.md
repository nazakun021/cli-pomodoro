# Engineering Workflow

Use this workflow for non-trivial changes. It separates decisions from execution while retaining small, reviewable task context.

## 1. Plan

- Preserve resolved grilling/design detail in `.scratch/<feature-slug>/FEATURES.md` when that context exists.
- Publish the formal feature specification to `.scratch/<feature-slug>/SPEC.md` from `docs/agents/templates/spec.md`; do not overwrite `FEATURES.md`.
- Clarify the user outcome, non-goals, constraints, acceptance criteria, and validation commands before editing source code.
- Break `ready-for-agent` work into independent issue files under `.scratch/<feature-slug>/issues/`, using `docs/agents/templates/task.md`.
- Put shared foundations before dependent feature work. Keep tasks small enough to implement and validate in one focused session.

## 2. Execute one task

- Work only from the current frontier: a `ready-for-agent` ticket whose blockers are all `resolved`.
- Change the ticket status to `claimed` before editing. Use only `ready-for-agent`, `claimed`, `blocked`, or `resolved`.
- Read `SPEC.md`, `FEATURES.md` when present, the task file, relevant domain docs, and the local code path before editing.
- Make the smallest change that can satisfy the task's observable acceptance criteria.
- Run the task's focused validation immediately after editing. Record the exact command and result in the task file.
- Append a `## Validation evidence` section when execution begins if one is not present.
- Update the task status to `resolved` only after every criterion and focused validation passes.

## 3. Stop on blockers

Do not guess about missing requirements, unavailable credentials, external dependencies, or failing unrelated infrastructure. Record the blocker in `.scratch/<feature-slug>/blocked.md` with:

- Task path and date
- What was attempted and the observed result
- What decision, access, or information is needed

Set the affected task to `blocked` and stop work on it. Continue only with independent, unblocked tasks.

## 4. Learn from repeatable failures

- Add a durable rule to `docs/agents/learnings.md` only when it prevents a likely repeated mistake.
- Record intentional compromises in `docs/agents/tech-debt.md` with impact, owner, and a revisit condition.
- Update instructions or templates when the failure reveals a missing reusable guardrail; do not add rules for one-off accidents.

## Safety and quality rules

- Prefer observable behavior and risk-based test coverage over an arbitrary coverage percentage.
- Use a fresh session when the task no longer fits the available context, but preserve the spec, task, validation results, and blockers in files first.
- Do not run destructive Git commands such as `git reset --hard` on a shared or dirty working tree. Use a dedicated branch or worktree, and discard only changes you own and have confirmed are safe to discard.
- Parallel agents may research independently, but only one agent writes to a given code area at a time unless worktrees isolate the changes.
- Dependency independence does not imply edit independence; coordinate tickets that touch the Agent state machine, protocol models, or shared schemas.
- Add browser or runtime logs to validation only when the feature needs them; use the cheapest check that can disprove the change.

## Automation maturity

Start with reviewed, sequential tasks. Introduce an automated loop only after several tasks consistently have clear acceptance criteria, deterministic validation, and reliable blocker handling. Keep per-iteration logs and explicit outcomes: `resolved`, `blocked`, or `failed`.
