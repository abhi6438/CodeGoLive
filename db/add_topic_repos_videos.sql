-- ============================================================
-- Migration: multiple GitHub repos + videos per topic
-- Run in Supabase SQL Editor
-- ============================================================

-- 1. New tables
CREATE TABLE IF NOT EXISTS public.topic_github_repos (
  id           uuid primary key default gen_random_uuid(),
  topic_id     uuid not null references public.topics(id) on delete cascade,
  url          text not null,
  label        text,             -- e.g. "Starter Code", "Full Solution"
  language     text,             -- e.g. "python", "javascript", "abap"
  order_index  int not null default 0,
  created_at   timestamptz not null default now()
);

CREATE TABLE IF NOT EXISTS public.topic_videos (
  id              uuid primary key default gen_random_uuid(),
  topic_id        uuid not null references public.topics(id) on delete cascade,
  url             text not null,
  title           text,           -- e.g. "Part 1 — Setup"
  duration_minutes int,           -- e.g. 12
  order_index     int not null default 0,
  created_at      timestamptz not null default now()
);

-- 2. Indexes
CREATE INDEX IF NOT EXISTS idx_topic_github_repos_topic_id ON public.topic_github_repos(topic_id);
CREATE INDEX IF NOT EXISTS idx_topic_videos_topic_id ON public.topic_videos(topic_id);

-- 3. Migrate existing single github_url values
INSERT INTO public.topic_github_repos (topic_id, url, label, language, order_index)
SELECT
  id,
  github_url,
  'Full Solution',
  CASE
    WHEN github_url ILIKE '%_py%' OR github_url ILIKE '%python%' THEN 'python'
    WHEN github_url ILIKE '%_js%' OR github_url ILIKE '%javascript%' THEN 'javascript'
    ELSE 'python'
  END,
  0
FROM public.topics
WHERE github_url IS NOT NULL AND github_url <> ''
ON CONFLICT DO NOTHING;

-- 4. Migrate existing single video_url values
INSERT INTO public.topic_videos (topic_id, url, title, order_index)
SELECT id, video_url, 'Lesson Video', 0
FROM public.topics
WHERE video_url IS NOT NULL AND video_url <> ''
ON CONFLICT DO NOTHING;

-- 5. RLS: read public, write admin only
ALTER TABLE public.topic_github_repos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.topic_videos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "public read repos" ON public.topic_github_repos;
CREATE POLICY "public read repos" ON public.topic_github_repos FOR SELECT USING (true);

DROP POLICY IF EXISTS "public read videos" ON public.topic_videos;
CREATE POLICY "public read videos" ON public.topic_videos FOR SELECT USING (true);

DROP POLICY IF EXISTS "admin write repos" ON public.topic_github_repos;
CREATE POLICY "admin write repos" ON public.topic_github_repos
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

DROP POLICY IF EXISTS "admin write videos" ON public.topic_videos;
CREATE POLICY "admin write videos" ON public.topic_videos
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );
