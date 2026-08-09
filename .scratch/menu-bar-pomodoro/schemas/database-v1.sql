PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;
PRAGMA synchronous = FULL;

CREATE TABLE presets (
    id TEXT PRIMARY KEY NOT NULL,
    name TEXT NOT NULL,
    normalized_name TEXT NOT NULL UNIQUE,
    is_builtin INTEGER NOT NULL DEFAULT 0 CHECK (is_builtin IN (0, 1)),
    focus_seconds INTEGER NOT NULL CHECK (focus_seconds BETWEEN 1 AND 86400),
    short_break_seconds INTEGER NOT NULL CHECK (short_break_seconds BETWEEN 1 AND 86400),
    long_break_seconds INTEGER NOT NULL CHECK (long_break_seconds BETWEEN 1 AND 86400),
    long_break_every INTEGER NOT NULL CHECK (long_break_every >= 1),
    open_ended INTEGER NOT NULL CHECK (open_ended IN (0, 1)),
    target_rounds INTEGER CHECK (target_rounds >= 1),
    auto_start_focus INTEGER NOT NULL CHECK (auto_start_focus IN (0, 1)),
    auto_start_breaks INTEGER NOT NULL CHECK (auto_start_breaks IN (0, 1)),
    last_started_sequence INTEGER UNIQUE CHECK (last_started_sequence >= 1),
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    CHECK (
        (open_ended = 1 AND target_rounds IS NULL) OR
        (open_ended = 0 AND target_rounds IS NOT NULL)
    )
);

CREATE TABLE app_state (
    singleton_id INTEGER PRIMARY KEY NOT NULL CHECK (singleton_id = 1),
    default_preset_id TEXT NOT NULL REFERENCES presets(id) ON DELETE RESTRICT,
    next_recency_sequence INTEGER NOT NULL DEFAULT 1 CHECK (next_recency_sequence >= 1)
);

CREATE TABLE focus_contributions (
    id TEXT PRIMARY KEY NOT NULL,
    source_phase_id TEXT NOT NULL,
    segment_index INTEGER NOT NULL CHECK (segment_index >= 0),
    elapsed_milliseconds INTEGER NOT NULL CHECK (elapsed_milliseconds > 0),
    local_date TEXT NOT NULL CHECK (length(local_date) = 10),
    timezone_identifier TEXT NOT NULL,
    utc_offset_seconds INTEGER NOT NULL CHECK (utc_offset_seconds BETWEEN -64800 AND 64800),
    completed_round INTEGER NOT NULL CHECK (completed_round IN (0, 1)),
    finalized_at TEXT NOT NULL,
    UNIQUE (source_phase_id, segment_index)
);

CREATE INDEX focus_contributions_local_date_idx
    ON focus_contributions(local_date);

CREATE UNIQUE INDEX focus_contributions_one_completed_round_idx
    ON focus_contributions(source_phase_id)
    WHERE completed_round = 1;

CREATE TRIGGER prevent_builtin_preset_update
BEFORE UPDATE OF
    name,
    normalized_name,
    is_builtin,
    focus_seconds,
    short_break_seconds,
    long_break_seconds,
    long_break_every,
    open_ended,
    target_rounds,
    auto_start_focus,
    auto_start_breaks,
    created_at,
    updated_at
ON presets
WHEN OLD.is_builtin = 1
BEGIN
    SELECT RAISE(ABORT, 'built-in preset cannot be updated');
END;

CREATE TRIGGER prevent_builtin_preset_delete
BEFORE DELETE ON presets
WHEN OLD.is_builtin = 1
BEGIN
    SELECT RAISE(ABORT, 'built-in preset cannot be deleted');
END;

INSERT INTO presets (
    id,
    name,
    normalized_name,
    is_builtin,
    focus_seconds,
    short_break_seconds,
    long_break_seconds,
    long_break_every,
    open_ended,
    target_rounds,
    auto_start_focus,
    auto_start_breaks,
    last_started_sequence,
    created_at,
    updated_at
) VALUES (
    '00000000-0000-0000-0000-000000000001',
    'Classic',
    'classic',
    1,
    1500,
    300,
    900,
    4,
    0,
    4,
    0,
    1,
    NULL,
    '1970-01-01T00:00:00.000Z',
    '1970-01-01T00:00:00.000Z'
);

INSERT INTO app_state (
    singleton_id,
    default_preset_id,
    next_recency_sequence
) VALUES (
    1,
    '00000000-0000-0000-0000-000000000001',
    1
);