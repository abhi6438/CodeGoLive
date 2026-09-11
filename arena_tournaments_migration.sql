-- Arena Tournaments: Single-elimination bracket system
-- Run this in Supabase SQL editor

CREATE TABLE IF NOT EXISTS arena_tournaments (
    id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    host_id      UUID        NOT NULL REFERENCES auth.users(id),
    room_code    TEXT        NOT NULL UNIQUE,
    topic_id     TEXT        NOT NULL DEFAULT 'sap-btp',
    max_questions INT        NOT NULL DEFAULT 10,
    max_players  INT         NOT NULL DEFAULT 4,  -- 4 or 8
    status       TEXT        NOT NULL DEFAULT 'waiting', -- waiting | active | finished
    current_round INT        NOT NULL DEFAULT 0,
    winner_id    UUID        REFERENCES auth.users(id),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    started_at   TIMESTAMPTZ,
    finished_at  TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS arena_tournament_players (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id   UUID        NOT NULL REFERENCES arena_tournaments(id) ON DELETE CASCADE,
    user_id         UUID        NOT NULL REFERENCES auth.users(id),
    seed            INT,               -- random bracket seed (1-based)
    is_host         BOOLEAN     NOT NULL DEFAULT false,
    is_eliminated   BOOLEAN     NOT NULL DEFAULT false,
    eliminated_round INT,              -- which round they lost in
    final_position  INT,               -- 1 = champion
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(tournament_id, user_id)
);

CREATE TABLE IF NOT EXISTS arena_tournament_matches (
    id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id  UUID        NOT NULL REFERENCES arena_tournaments(id) ON DELETE CASCADE,
    match_id       UUID        REFERENCES arena_matches(id),
    round          INT         NOT NULL,
    bracket_slot   INT         NOT NULL, -- 0-indexed slot within the round
    player1_id     UUID        REFERENCES auth.users(id),
    player2_id     UUID        REFERENCES auth.users(id),
    winner_id      UUID        REFERENCES auth.users(id),
    status         TEXT        NOT NULL DEFAULT 'pending', -- pending | active | finished
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE arena_tournaments         ENABLE ROW LEVEL SECURITY;
ALTER TABLE arena_tournament_players  ENABLE ROW LEVEL SECURITY;
ALTER TABLE arena_tournament_matches  ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to read/write (backend handles auth via JWT)
CREATE POLICY "auth_all_tournaments"
    ON arena_tournaments FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_all_tournament_players"
    ON arena_tournament_players FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_all_tournament_matches"
    ON arena_tournament_matches FOR ALL TO authenticated USING (true) WITH CHECK (true);
