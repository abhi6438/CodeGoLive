-- CodeGoLive — Row Level Security policies
-- Run this AFTER schema.sql succeeds. It is safe to re-run (policies use
-- "create policy if not exists" semantics via drop-if-exists + recreate).
-- Split into its own file so it can be tested independently without
-- risking the core schema run.

-- =========================================================
-- ENABLE RLS ON ALL PROTECTED TABLES
-- =========================================================
alter table public.profiles enable row level security;
alter table public.questions enable row level security;
alter table public.answers enable row level security;
alter table public.replies enable row level security;
alter table public.votes enable row level security;
alter table public.user_progress enable row level security;
alter table public.notifications enable row level security;
-- modules and topics are intentionally public-read (no RLS needed for reads;
-- writes only happen via FastAPI service_role key or admin SQL).

-- =========================================================
-- PUBLIC READ — approved / non-deleted content
-- =========================================================
drop policy if exists "profiles are viewable by everyone" on public.profiles;
create policy "profiles are viewable by everyone"
  on public.profiles for select using (true);

drop policy if exists "questions are viewable by everyone" on public.questions;
create policy "questions are viewable by everyone"
  on public.questions for select using (deleted = false);

drop policy if exists "approved answers are viewable by everyone" on public.answers;
create policy "approved answers are viewable by everyone"
  on public.answers for select using (status = 'approved' and deleted = false);

drop policy if exists "approved replies are viewable by everyone" on public.replies;
create policy "approved replies are viewable by everyone"
  on public.replies for select using (status = 'approved' and deleted = false);

-- =========================================================
-- AUTHENTICATED INSERTS (own content only)
-- =========================================================
drop policy if exists "users can insert their own questions" on public.questions;
create policy "users can insert their own questions"
  on public.questions for insert with check (auth.uid() = user_id);

drop policy if exists "users can insert their own answers" on public.answers;
create policy "users can insert their own answers"
  on public.answers for insert with check (auth.uid() = user_id);

drop policy if exists "users can insert their own replies" on public.replies;
create policy "users can insert their own replies"
  on public.replies for insert with check (auth.uid() = user_id);

drop policy if exists "users can vote as themselves" on public.votes;
create policy "users can vote as themselves"
  on public.votes for all using (auth.uid() = user_id);

drop policy if exists "users manage their own progress" on public.user_progress;
create policy "users manage their own progress"
  on public.user_progress for all using (auth.uid() = user_id);

drop policy if exists "users see their own notifications" on public.notifications;
create policy "users see their own notifications"
  on public.notifications for select using (auth.uid() = user_id);

-- =========================================================
-- ADMIN SELECT on profiles (needed once AdminTopics.jsx is
-- routed through FastAPI — the service_role key bypasses RLS,
-- but this policy covers the public-client path as a fallback).
-- =========================================================
drop policy if exists "admins can select all profiles" on public.profiles;
create policy "admins can select all profiles"
  on public.profiles for select
  using (
    auth.uid() in (
      select id from public.profiles where role in ('admin', 'moderator')
    )
  );

-- NOTE: moderation (viewing pending answers/replies, approve/reject) is done
-- via the FastAPI backend using the service_role key, which bypasses RLS by
-- design. No additional policies needed for those operations.
