# Issue tracker: Local Markdown

Issues and specs for this repo live as markdown files in `.scratch/`.

## Conventions

- One feature per directory: `.scratch/<feature-slug>/`
- The formal issue-tracker spec is `.scratch/<feature-slug>/SPEC.md`
- Resolved grilling and design context, when present, is preserved separately in `.scratch/<feature-slug>/FEATURES.md`; never overwrite it when publishing the formal spec
- Implementation issues are one file per ticket at `.scratch/<feature-slug>/issues/<NN>-<slug>.md`, numbered from `01` — never a single combined tickets file
- Triage state is recorded as a `Status:` line near the top of each spec or issue file
- Ticket statuses are `ready-for-agent`, `claimed`, `blocked`, or `resolved`
- Comments and conversation history append to the bottom of the file under a `## Comments` heading

## When a skill says "publish to the issue tracker"

Create a new file under `.scratch/<feature-slug>/` (creating the directory if needed).

For `/to-spec`, publish to `SPEC.md`, apply `Status: ready-for-agent`, and retain `FEATURES.md` as supporting context.

For `/to-tickets`, create one file per approved vertical slice, apply `Status: ready-for-agent`, and preserve the approved backward-only `Blocked by` edges.

## When a skill says "fetch the relevant ticket"

Read the file at the referenced path. The user will normally pass the path or the issue number directly.

## Wayfinding operations

Used by `/wayfinder`. The **map** is a file with one **child** file per ticket.

- **Map**: `.scratch/<effort>/map.md` — the Notes / Decisions-so-far / Fog body.
- **Child ticket**: `.scratch/<effort>/issues/NN-<slug>.md`, numbered from `01`, with one end-to-end outcome, blocker field, ready status, and observable acceptance criteria.
- **Blocking**: a `Blocked by: NN, NN` line near the top. A ticket is unblocked when every file it lists is `resolved`.
- **Frontier**: scan `.scratch/<effort>/issues/` for files that are `ready-for-agent` and whose blockers are all `resolved`; first by number wins unless parallel ownership is explicitly coordinated.
- **Claim**: change `ready-for-agent` to `claimed` and save before any work.
- **Block**: change `claimed` to `blocked` and record attempted action, observed result, and required decision/access in the feature blocker log.
- **Resolve**: append validation evidence, change `claimed` to `resolved`, and update any roadmap/map pointer used by the effort.
