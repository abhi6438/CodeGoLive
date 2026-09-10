-- Run this once in the Supabase SQL Editor
-- Adds the estimated_minutes column to the topics table

ALTER TABLE topics
  ADD COLUMN IF NOT EXISTS estimated_minutes integer DEFAULT NULL;

-- Optional: verify the column was added
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'topics'
  AND column_name = 'estimated_minutes';
