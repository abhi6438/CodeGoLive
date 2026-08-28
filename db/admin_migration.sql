-- ============================================================
-- Zero to Deployed — Admin Console DB Migration
-- Run this in Supabase SQL Editor (Dashboard → SQL Editor)
-- ============================================================

-- 1. Create courses table
CREATE TABLE IF NOT EXISTS courses (
  id           TEXT PRIMARY KEY,          -- e.g. "sap-btp"
  title        TEXT NOT NULL,
  subtitle     TEXT,
  description  TEXT,
  status       TEXT NOT NULL DEFAULT 'coming_soon'
               CHECK (status IN ('available', 'coming_soon', 'archived')),
  icon         TEXT,
  accent_color TEXT,
  accent_light TEXT,
  tags         TEXT[],
  level        TEXT,
  estimated_hours INTEGER,
  order_index  INTEGER NOT NULL DEFAULT 0,
  created_at   TIMESTAMPTZ DEFAULT now(),
  updated_at   TIMESTAMPTZ DEFAULT now()
);

-- 2. Seed the two existing courses from courses.js
INSERT INTO courses (id, title, subtitle, description, status, icon, accent_color, accent_light, tags, level, estimated_hours, order_index)
VALUES
  (
    'sap-btp',
    'SAP BTP & CAP Development',
    'Build cloud-native apps on SAP Business Technology Platform',
    'Go from zero to a fully deployed SAP BTP application. You''ll master SAPUI5 for the frontend, CAP for the backend, and deploy on BTP with CI/CD pipelines — all in one structured course.',
    'available',
    '🛠️',
    '#0070F3',
    '#e8f3ff',
    ARRAY['CAP', 'SAPUI5', 'BTP', 'Node.js'],
    'Beginner → Advanced',
    40,
    0
  ),
  (
    'sap-ai',
    'SAP AI Core & Generative AI',
    'Deploy and orchestrate AI models on SAP AI Core',
    'Learn to build and deploy Generative AI solutions using SAP AI Core and Gen AI Hub. Covers LLM orchestration, prompt engineering, and building AI-powered SAP applications with Python.',
    'coming_soon',
    '🤖',
    '#7C3AED',
    '#f0ebff',
    ARRAY['AI Core', 'Gen AI Hub', 'LLM', 'Python'],
    'Intermediate',
    25,
    1
  )
ON CONFLICT (id) DO NOTHING;

-- 3. Add course_id column to modules (if it doesn't exist)
ALTER TABLE modules ADD COLUMN IF NOT EXISTS course_id TEXT REFERENCES courses(id) ON DELETE SET NULL;

-- 4. Populate course_id on existing modules
--    (All current modules belong to sap-btp — change if needed)
UPDATE modules SET course_id = 'sap-btp' WHERE course_id IS NULL;

-- 5. Add status column to topics (if it doesn't exist)
ALTER TABLE topics ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'draft'
  CHECK (status IN ('published', 'draft'));

-- Mark all existing topics as published (they are live content)
UPDATE topics SET status = 'published' WHERE status = 'draft';

-- 6. Enable RLS on courses (allow public SELECT, admin-only write)
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "public can read courses"
  ON courses FOR SELECT USING (true);

CREATE POLICY "admin can manage courses"
  ON courses FOR ALL
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- 7. Confirm
SELECT 'courses' AS tbl, count(*) FROM courses
UNION ALL
SELECT 'modules with course_id', count(*) FROM modules WHERE course_id IS NOT NULL
UNION ALL
SELECT 'topics with status', count(*) FROM topics WHERE status IS NOT NULL;
