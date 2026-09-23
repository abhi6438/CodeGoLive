-- =============================================================================
-- paperclip_m25_seed.sql
-- Module 2.5: Paperclip as Your Dev Assistant
-- Run AFTER paperclip_seed.sql
-- =============================================================================
-- This script:
--   1. Shifts existing modules 302-308 order_index up by 1 (making room at position 3)
--   2. Inserts the new module 3015 at order_index 3
--   3. Inserts 8 topic stubs for the new module
-- Safe to re-run (ON CONFLICT DO NOTHING on topics)
-- =============================================================================

DO $$
DECLARE
  m25 uuid;
  c_id text := 'paperclip';
BEGIN

  -- ── 1. Shift existing modules 302-308 up one position (idempotent) ──────────
  -- Only shift if module 3015 does not already exist at order_index 3
  -- (prevents double-shift on re-run)
  IF NOT EXISTS (
    SELECT 1 FROM public.modules WHERE number = 3015 AND course_id = c_id
  ) THEN
    UPDATE public.modules
    SET order_index = order_index + 1
    WHERE course_id = c_id
      AND number IN (302, 303, 304, 305, 306, 307, 308);
  END IF;

  -- ── 2. Insert new module 3015 at order_index 3 ────────────────────────────
  INSERT INTO public.modules (number, title, subtitle, order_index, course_id)
  VALUES (
    3015,
    'Paperclip as Your Dev Assistant',
    'Connect your real codebase, write dev tasks, watch agents edit files, and build an iterative feedback loop',
    3,
    c_id
  )
  ON CONFLICT (number) DO UPDATE
    SET title      = EXCLUDED.title,
        subtitle   = EXCLUDED.subtitle,
        order_index = EXCLUDED.order_index,
        course_id  = EXCLUDED.course_id
  RETURNING id INTO m25;

  IF m25 IS NULL THEN
    SELECT id INTO m25 FROM public.modules WHERE number = 3015;
  END IF;

  -- ── 3. Topic stubs ────────────────────────────────────────────────────────

  -- 3.1 Dev assistant intro
  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m25, 'pcl-da-01', 'pcl-dev-assistant-intro',
    'Paperclip as a Dev Assistant — the Mental Model',
    'Code Tasks vs Research Tasks',
    'Understand the difference between research-style tasks and real code tasks, and how the claude-code adapter bridges Paperclip and your codebase.',
    'Compare a research issue vs a dev issue side by side',
    1, 'draft')
  ON CONFLICT (slug) DO NOTHING;

  -- 3.2 Full local setup
  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m25, 'pcl-da-02', 'pcl-dev-local-full-setup',
    'Full Local Setup for Dev Mode',
    'Prerequisites & Config',
    'Install all prerequisites, clone both Paperclip and your target project, configure environment variables, and verify the full stack is running.',
    'Verify: Paperclip running + your project directory accessible to the agent',
    2, 'draft')
  ON CONFLICT (slug) DO NOTHING;

  -- 3.3 Connect your repo
  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m25, 'pcl-da-03', 'pcl-connect-your-repo',
    'Connecting the claude-code Adapter to Your Repository',
    'workingDir & Adapter Config',
    'Set workingDir in the claude-code adapter config so agents have access to your actual codebase. Covers permissions, .gitignore, and safety boundaries.',
    'Agent can read and write files inside your project directory',
    3, 'draft')
  ON CONFLICT (slug) DO NOTHING;

  -- 3.4 Dev task anatomy
  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m25, 'pcl-da-04', 'pcl-dev-task-anatomy',
    'Anatomy of a Great Dev Task',
    'Issue Writing for Code Work',
    'Learn how to write issues that produce good code: title, description, acceptance criteria, file context, and how to scope tasks so agents succeed on the first attempt.',
    'Write three real dev tasks for your own project',
    4, 'draft')
  ON CONFLICT (slug) DO NOTHING;

  -- 3.5 First code task end-to-end
  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m25, 'pcl-da-05', 'pcl-dev-first-code-task',
    'Your First Real Code Task — End to End',
    'Create → Trigger → See File Changes',
    'Walk through the complete cycle: create a dev issue, trigger the heartbeat, watch the agent edit files, and read the structured result with file diffs.',
    'Observe the agent making a real file change in your project',
    5, 'draft')
  ON CONFLICT (slug) DO NOTHING;

  -- 3.6 Review agent work
  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m25, 'pcl-da-06', 'pcl-review-agent-work',
    'Reviewing What the Agent Did',
    'git diff, Results & Approval',
    'Use git diff to inspect agent changes, read the structured result JSON, run tests, and decide whether to accept, reject, or request a revision.',
    'Successfully review and accept (or revise) an agent-authored change',
    6, 'draft')
  ON CONFLICT (slug) DO NOTHING;

  -- 3.7 Feedback loop
  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m25, 'pcl-da-07', 'pcl-dev-feedback-loop',
    'Building an Iterative Dev Feedback Loop',
    'Accept → Refine → Repeat',
    'Set up a sustainable rhythm: branch strategy, how to chain tasks, how to refine prompts when the agent misses, and when to break work into subtasks.',
    'Complete a 3-task chain on a real feature with the feedback loop',
    7, 'draft')
  ON CONFLICT (slug) DO NOTHING;

  -- 3.8 Real project walkthrough
  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m25, 'pcl-da-08', 'pcl-dev-real-project',
    'End-to-End Walkthrough: Build a Feature with Paperclip',
    'Full Dev-Assistant Session',
    'Guided walkthrough of adding a complete feature to a real Node.js/Express project: planning tasks, running agents, reviewing diffs, and shipping the change.',
    'Ship one real feature to your project using Paperclip agents',
    8, 'draft')
  ON CONFLICT (slug) DO NOTHING;

END $$;
