# 02 — Start and stop a Classic Focus Session

**What to build:** A user can start a Classic Focus Session from the CLI, watch the same running Phase in the menu, and stop it from either surface without tying it to Terminal.

**Blocked by:** 01 — Observe an Idle Agent from CLI and menu

**Status:** ready-for-agent

- [ ] Direct Start resolves the complete immutable Classic Session Configuration and acknowledges only after the Session is observable from CLI and menu.
- [ ] Classic starts a 25-minute Focus Phase with the contracted finite four-Round boundary, Break durations, cadence, and automatic-transition choices.
- [ ] Closing Terminal after Start leaves the Agent-owned Session running and controllable from the menu and later CLI invocations.
- [ ] Status-item and CLI snapshots agree on Session and Phase occurrence IDs, revision, Running state, configured duration, rounded remaining time, and expected Transition estimate.
- [ ] The active menu presents Phase/state, Round progress, Pause, Skip, confirmed Stop, next Phase, and status item formatting in the contracted order.
- [ ] Explicit CLI Stop ends the Session without prompting; menu Stop confirms partial-Focus impact before ending it; both return the Agent to Idle.
- [ ] A second Start is rejected unless explicit non-interactive replacement is requested, and an invalid replacement cannot disturb the current Session.
- [ ] Duplicate, expired, future-dated, and wrong-Agent mutation requests prove that Start and Stop cannot be applied twice.
- [ ] Automated command/snapshot, real socket, CLI subprocess, and native menu checks demonstrate one serialized Session across both surfaces.
