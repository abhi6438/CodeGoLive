-- Arena level, activity streak, and last activity date columns
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS activity_streak_days INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS last_activity_date   DATE,
  ADD COLUMN IF NOT EXISTS arena_level          INT NOT NULL DEFAULT 1;

-- Backfill arena_level from existing arena_xp
UPDATE profiles
SET arena_level = GREATEST(1, FLOOR(SQRT(COALESCE(arena_xp, 0) / 50.0))::INT + 1)
WHERE arena_xp IS NOT NULL AND arena_xp > 0;
