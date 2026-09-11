-- Level & Activity Streak system
-- Run in Supabase SQL editor

ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS activity_streak_days INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS last_activity_date   DATE,
  ADD COLUMN IF NOT EXISTS arena_level          INT NOT NULL DEFAULT 1;

-- Backfill level for existing users from their current arena_xp
-- Level formula: floor(sqrt(xp / 50)) + 1
UPDATE profiles
SET arena_level = GREATEST(1, FLOOR(SQRT(COALESCE(arena_xp, 0) / 50.0))::INT + 1)
WHERE arena_xp IS NOT NULL AND arena_xp > 0;
