-- Arena Schema — matches column names used by backend/app/routers/arena.py
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1. arena_matches
CREATE TABLE IF NOT EXISTS arena_matches (
  id                     uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  host_id                uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  opponent_id            uuid REFERENCES profiles(id) ON DELETE SET NULL,
  status                 text NOT NULL DEFAULT 'waiting'
                           CHECK (status IN ('waiting','active','finished','cancelled')),
  room_code              text UNIQUE NOT NULL,
  topic_id               text NOT NULL DEFAULT 'sap-btp',
  max_questions          int  NOT NULL DEFAULT 10,
  question_ids           jsonb         DEFAULT '[]',
  current_question_index int           DEFAULT 0,
  started_at             timestamptz,
  finished_at            timestamptz,
  winner_id              uuid REFERENCES profiles(id) ON DELETE SET NULL,
  created_at             timestamptz NOT NULL DEFAULT now()
);

-- 2. arena_match_players
CREATE TABLE IF NOT EXISTS arena_match_players (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id       uuid NOT NULL REFERENCES arena_matches(id) ON DELETE CASCADE,
  user_id        uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  is_host        boolean NOT NULL DEFAULT false,
  score_xp       int NOT NULL DEFAULT 0,
  score_ap       int NOT NULL DEFAULT 0,
  streak         int NOT NULL DEFAULT 0,
  correct_count  int NOT NULL DEFAULT 0,
  total_answered int NOT NULL DEFAULT 0,
  joined_at      timestamptz NOT NULL DEFAULT now(),
  UNIQUE(match_id, user_id)
);

-- 3. arena_match_events
CREATE TABLE IF NOT EXISTS arena_match_events (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id    uuid NOT NULL REFERENCES arena_matches(id) ON DELETE CASCADE,
  user_id     uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  event_type  text NOT NULL
                CHECK (event_type IN ('chat','taunt','score_update','match_end','reaction','turn_change')),
  payload     jsonb NOT NULL DEFAULT '{}',
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- 4. arena_teams
CREATE TABLE IF NOT EXISTS arena_teams (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id   uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name       text NOT NULL,
  badge      text NOT NULL DEFAULT '🛡️',
  total_xp   int NOT NULL DEFAULT 0,
  wins       int NOT NULL DEFAULT 0,
  losses     int NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(name)
);

-- 5. arena_team_members
CREATE TABLE IF NOT EXISTS arena_team_members (
  id        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id   uuid NOT NULL REFERENCES arena_teams(id) ON DELETE CASCADE,
  user_id   uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  role      text NOT NULL DEFAULT 'member' CHECK (role IN ('owner','member')),
  joined_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(team_id, user_id)
);

-- 6. arena_challenges
CREATE TABLE IF NOT EXISTS arena_challenges (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  from_user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  to_user_id   uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  status       text NOT NULL DEFAULT 'pending'
                 CHECK (status IN ('pending','accepted','declined','expired')),
  topic_id     text NOT NULL,
  match_id     uuid REFERENCES arena_matches(id) ON DELETE SET NULL,
  expires_at   timestamptz NOT NULL DEFAULT (now() + interval '24 hours'),
  created_at   timestamptz NOT NULL DEFAULT now()
);

-- 7. arena_quests  (key + metric match the service catalog dict keys)
CREATE TABLE IF NOT EXISTS arena_quests (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  type        text NOT NULL CHECK (type IN ('daily','weekly')),
  key         text NOT NULL,
  title       text NOT NULL,
  description text NOT NULL,
  target      int  NOT NULL,
  progress    int  NOT NULL DEFAULT 0,
  xp_reward   int  NOT NULL,
  ap_reward   int  NOT NULL,
  metric      text NOT NULL DEFAULT '',
  claimed_at  timestamptz,
  resets_at   timestamptz NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- 8. arena_achievements
CREATE TABLE IF NOT EXISTS arena_achievements (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  badge_key   text NOT NULL,
  rarity      text NOT NULL DEFAULT 'common'
                CHECK (rarity IN ('common','rare','epic','legendary')),
  unlocked_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(user_id, badge_key)
);

-- 9. arena_leaderboard
CREATE TABLE IF NOT EXISTS arena_leaderboard (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  week_start   date NOT NULL,
  xp_this_week int NOT NULL DEFAULT 0,
  wins         int NOT NULL DEFAULT 0,
  rank         int,
  prize_ap     int NOT NULL DEFAULT 0,
  created_at   timestamptz NOT NULL DEFAULT now(),
  UNIQUE(user_id, week_start)
);

-- 10. arena_spin_log
CREATE TABLE IF NOT EXISTS arena_spin_log (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  prize_type  text NOT NULL,
  prize_label text NOT NULL,
  prize_value int NOT NULL DEFAULT 0,
  is_free     boolean NOT NULL DEFAULT true,
  spun_at     timestamptz NOT NULL DEFAULT now()
);

-- Profile columns
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS arena_xp            int NOT NULL DEFAULT 0;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS arena_ap            int NOT NULL DEFAULT 0;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS arena_wins          int NOT NULL DEFAULT 0;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS arena_streak        int NOT NULL DEFAULT 0;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS last_arena_activity timestamptz;

-- Indexes
CREATE INDEX IF NOT EXISTS idx_arena_matches_status     ON arena_matches(status);
CREATE INDEX IF NOT EXISTS idx_arena_matches_room_code  ON arena_matches(room_code);
CREATE INDEX IF NOT EXISTS idx_arena_matches_host       ON arena_matches(host_id);
CREATE INDEX IF NOT EXISTS idx_arena_mp_match           ON arena_match_players(match_id);
CREATE INDEX IF NOT EXISTS idx_arena_mp_user            ON arena_match_players(user_id);
CREATE INDEX IF NOT EXISTS idx_arena_me_match           ON arena_match_events(match_id);
CREATE INDEX IF NOT EXISTS idx_arena_me_created         ON arena_match_events(created_at);
CREATE INDEX IF NOT EXISTS idx_arena_quests_user        ON arena_quests(user_id, type, resets_at);
CREATE INDEX IF NOT EXISTS idx_arena_lb_week            ON arena_leaderboard(week_start, xp_this_week DESC);
CREATE INDEX IF NOT EXISTS idx_arena_spin_user          ON arena_spin_log(user_id, spun_at DESC);
CREATE INDEX IF NOT EXISTS idx_arena_ach_user           ON arena_achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_arena_ch_to_user         ON arena_challenges(to_user_id, status);

-- RLS
ALTER TABLE arena_matches       ENABLE ROW LEVEL SECURITY;
ALTER TABLE arena_match_players ENABLE ROW LEVEL SECURITY;
ALTER TABLE arena_match_events  ENABLE ROW LEVEL SECURITY;
ALTER TABLE arena_teams         ENABLE ROW LEVEL SECURITY;
ALTER TABLE arena_team_members  ENABLE ROW LEVEL SECURITY;
ALTER TABLE arena_challenges    ENABLE ROW LEVEL SECURITY;
ALTER TABLE arena_quests        ENABLE ROW LEVEL SECURITY;
ALTER TABLE arena_achievements  ENABLE ROW LEVEL SECURITY;
ALTER TABLE arena_leaderboard   ENABLE ROW LEVEL SECURITY;
ALTER TABLE arena_spin_log      ENABLE ROW LEVEL SECURITY;

-- arena_matches
CREATE POLICY "am_sel"  ON arena_matches FOR SELECT TO authenticated USING (true);
CREATE POLICY "am_ins"  ON arena_matches FOR INSERT TO authenticated WITH CHECK (host_id = auth.uid());
CREATE POLICY "am_upd"  ON arena_matches FOR UPDATE TO authenticated USING (host_id = auth.uid());

-- arena_match_players
CREATE POLICY "amp_sel" ON arena_match_players FOR SELECT TO authenticated USING (true);
CREATE POLICY "amp_ins" ON arena_match_players FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY "amp_upd" ON arena_match_players FOR UPDATE TO authenticated USING (user_id = auth.uid());

-- arena_match_events (backend uses service_role so RLS bypassed; policy kept for direct client use)
CREATE POLICY "ame_sel" ON arena_match_events FOR SELECT TO authenticated USING (true);
CREATE POLICY "ame_ins" ON arena_match_events FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());

-- arena_teams
CREATE POLICY "at_sel"  ON arena_teams FOR SELECT TO authenticated USING (true);
CREATE POLICY "at_ins"  ON arena_teams FOR INSERT TO authenticated WITH CHECK (owner_id = auth.uid());
CREATE POLICY "at_upd"  ON arena_teams FOR UPDATE TO authenticated USING (owner_id = auth.uid());
CREATE POLICY "at_del"  ON arena_teams FOR DELETE TO authenticated USING (owner_id = auth.uid());

-- arena_team_members
CREATE POLICY "atm_sel" ON arena_team_members FOR SELECT TO authenticated USING (true);
CREATE POLICY "atm_ins" ON arena_team_members FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY "atm_del" ON arena_team_members FOR DELETE TO authenticated USING (user_id = auth.uid());

-- arena_challenges
CREATE POLICY "ac_sel"  ON arena_challenges FOR SELECT TO authenticated USING (from_user_id = auth.uid() OR to_user_id = auth.uid());
CREATE POLICY "ac_ins"  ON arena_challenges FOR INSERT TO authenticated WITH CHECK (from_user_id = auth.uid());
CREATE POLICY "ac_upd"  ON arena_challenges FOR UPDATE TO authenticated USING (to_user_id = auth.uid() OR from_user_id = auth.uid());

-- arena_quests (backend inserts on behalf of user via service_role)
CREATE POLICY "aq_sel"  ON arena_quests FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "aq_upd"  ON arena_quests FOR UPDATE TO authenticated USING (user_id = auth.uid());

-- arena_achievements
CREATE POLICY "aach_sel" ON arena_achievements FOR SELECT TO authenticated USING (true);

-- arena_leaderboard
CREATE POLICY "alb_sel"  ON arena_leaderboard FOR SELECT TO authenticated USING (true);

-- arena_spin_log
CREATE POLICY "asl_sel"  ON arena_spin_log FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "asl_ins"  ON arena_spin_log FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
