-- Drop old arena tables (CASCADE removes dependent policies + indexes)
-- Run this BEFORE 001_arena_schema.sql if arena_matches already exists with old columns.

DROP TABLE IF EXISTS arena_spin_log        CASCADE;
DROP TABLE IF EXISTS arena_achievements    CASCADE;
DROP TABLE IF EXISTS arena_leaderboard     CASCADE;
DROP TABLE IF EXISTS arena_quests          CASCADE;
DROP TABLE IF EXISTS arena_challenges      CASCADE;
DROP TABLE IF EXISTS arena_team_members    CASCADE;
DROP TABLE IF EXISTS arena_teams           CASCADE;
DROP TABLE IF EXISTS arena_match_events    CASCADE;
DROP TABLE IF EXISTS arena_match_players   CASCADE;
DROP TABLE IF EXISTS arena_matches         CASCADE;

-- Also remove profile columns if they exist (they'll be re-added by 001)
ALTER TABLE profiles DROP COLUMN IF EXISTS arena_xp;
ALTER TABLE profiles DROP COLUMN IF EXISTS arena_ap;
ALTER TABLE profiles DROP COLUMN IF EXISTS arena_wins;
ALTER TABLE profiles DROP COLUMN IF EXISTS arena_streak;
ALTER TABLE profiles DROP COLUMN IF EXISTS last_arena_activity;
