# Pomo Schema Semantic Rules v1

Status: Ready for approval

JSON Schema validates message/archive structure. The `make schema-check` semantic validator additionally enforces the cross-field rules below against every fixture. Integration tests own byte framing, sockets, timing, and state-machine command validity.

## General encoding

- UUID text is canonical lowercase `8-4-4-4-12` form.
- RFC 3339 wall times are UTC and contain exactly millisecond precision plus `Z`.
- Unknown additive fields are accepted only when the negotiated/public schema version permits them; v1 schema objects otherwise reject additional properties.

## Protocol negotiation

- `minimum_minor <= maximum_minor`.
- Negotiated minor is the highest member of the inclusive intersection for the shared major.
- Negotiated capabilities are a subset of both peers' advertised capabilities.

## Start and Configuration

- Effective Session Configuration has exactly one boundary:
  - `open_ended = true` and `target_rounds = null`, or
  - `open_ended = false` and integer `target_rounds >= 1`.
- Start overrides may be null to inherit. Explicit `open_ended = true` requires null target; explicit target implies finite mode.
- Preset name plus overrides resolve before Agent mutation.

## Snapshot state matrix

### Not running

- `agent_running = false`, `agent_state = not_running`, Agent/Session/Phase IDs and all Session/timing/configuration/Recovery fields are null.
- This shape is public CLI output only, never an Agent IPC snapshot.

### Idle

- `agent_running = true`, Agent ID present, `agent_state = idle`.
- Session/Phase/configuration/timing/Recovery fields are null.

### Session

- Agent, Session, and Phase IDs plus Configuration, completed Rounds, duration, remaining time, and Session start are present.
- Ready: Phase start and expected transition are null; remaining equals configured duration.
- Running: Phase start and expected transition are present.
- Paused: expected transition is null; remaining is positive unless a boundary race has already entered Recovery.
- Recovery is null.

### Recovery

- Agent ID and Recovery descriptor are present; `agent_state = recovery`.
- Accounting Recovery retains Session/Phase/Configuration fields with `session_state = blocked`.
- Migration/newer-schema Recovery has no Session/Phase fields.
- Database-corrupt Recovery may have blocked Session fields only when failure occurred during an active required write.
- Descriptor capabilities match the table in `database-design.md`.

## Responses

- Success has non-null result/data and null error.
- Failure has null result/data and non-null error.
- Public `command` names preserve distinct Recovery operations.
- Exit code and symbolic error code agree with `cli-contract.md`.
- Start, Status, Pause, Resume, Skip, Stop, Follow, Recovery Status, Recovery Retry, Recovery Discard, and Recovery Reset successes return a Session snapshot.
- Doctor success returns a Doctor result.
- Quit and Recovery Export successes return an Action result; Recovery Export has a non-null path.
- The semantic validator correlates each IPC response to its request fixture and rejects a result family not permitted for that command.

## Events

- Sequence starts at zero for each stream and increases by one without gaps among emitted non-coalesced events. Replaced ticks do not consume visible sequence numbers.
- `initial_snapshot`: non-null snapshot, null error.
- `tick`: Running snapshot, null error, same or newer state revision.
- `transition`: non-null Session/Idle snapshot, null error.
- `session_ended`: Idle snapshot, null error.
- `agent_quitting`: terminal event; snapshot may be Idle or Recovery, error null.
- `backpressure`: terminal event with null snapshot and `follow_backpressure` error.
- `recovery_entered`: Recovery snapshot and null error; Follow remains connected.
- `recovery_resolved`: non-Recovery snapshot and null error.

## Recovery archives

- Manifest file paths are unique by `path`, relative, and restricted to the schema allowlist.
- `known_schema_json` has non-null understood database schema version and exactly one payload entry: `data.json`.
- `opaque_database` includes `pomo.sqlite`, excludes `data.json`, and may additionally include listed WAL/SHM sidecars.
- Every manifest size/hash matches the exact archived bytes.
- `data.json` uses the same finite/open-ended invariant as Session Configuration.
- `classic_last_started_sequence` carries Classic recency when present because Classic is not duplicated in the user Presets array.
- Preset IDs and contribution IDs are unique; default Preset ID exists in exported Presets or equals stable Classic ID.
- At most one contribution per source Phase has `completed_round = true`.
- `(source_phase_id, segment_index)` pairs are unique.

## Validator fixtures

For every invariant, retain at least one accepted and one rejected fixture. Fixture filenames identify schema version, family, and expected outcome; tests fail if a fixture is not exercised.
