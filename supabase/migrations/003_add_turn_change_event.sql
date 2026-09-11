-- Add 'turn_change' to the arena_match_events event_type check constraint
-- Run this in Supabase SQL Editor

ALTER TABLE arena_match_events
  DROP CONSTRAINT IF EXISTS arena_match_events_event_type_check;

ALTER TABLE arena_match_events
  ADD CONSTRAINT arena_match_events_event_type_check
  CHECK (event_type IN ('chat', 'taunt', 'score_update', 'match_end', 'reaction', 'turn_change'));
