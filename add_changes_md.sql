-- Add "What Changed" field to topics
-- Run this in Supabase SQL Editor

ALTER TABLE topics ADD COLUMN IF NOT EXISTS changes_md TEXT;

-- Confirm
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'topics' AND column_name = 'changes_md';
