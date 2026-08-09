# 01 — Observe an Idle Agent from CLI and menu

**What to build:** A user can launch one authoritative Agent, see its Idle state in the menu bar, and inspect the same state from the CLI without creating a Session.

**Blocked by:** None — can start immediately

**Status:** ready-for-agent

- [ ] Launching Pomo presents one menu-bar-only Agent whose Idle status item shows only the app icon and whose menu identifies that no Session exists.
- [ ] Human and JSON Status report the same reachable Idle snapshot, including Agent identity and revision with no Session, Phase, timing, Configuration, or Recovery data.
- [ ] Status reports Agent-not-running successfully and does not launch the Agent when no Agent is available.
- [ ] Repeated app launches reuse the existing Agent, and concurrent CLI/menu observations cannot create a second state owner.
- [ ] Same-user endpoint ownership, framing, negotiation, malformed-input rejection, stale-endpoint safety, and protocol mismatch are exercised before any command can mutate state.
- [ ] JSON Status emits one schema-valid public response, while human and machine errors use their contracted output streams and stable exit categories.
- [ ] Contract fixtures accept the not-running and Idle state matrices and reject invalid nullable-field, version, UUID, timestamp, and response-family combinations.
- [ ] Automated Agent, socket, CLI, and minimal native UI checks demonstrate matching Idle revisions and snapshots across both surfaces.
