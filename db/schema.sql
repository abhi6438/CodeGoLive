-- CodeGoLive - core schema
-- Run this in the Supabase SQL editor (or via `supabase db push`).
-- Assumes Supabases built-in auth.users table for authentication (no backticks, plain identifier).

-- =========================================================
-- USERS (profile extension on top of Supabase auth.users)
-- =========================================================
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null,
  avatar_url text,
  role text not null default 'learner' check (role in ('learner', 'moderator', 'admin')),
  created_at timestamptz not null default now()
);

-- =========================================================
-- COURSE CONTENT
-- =========================================================
create table if not exists public.modules (
  id uuid primary key default gen_random_uuid(),
  number int not null unique,          -- 0..5
  title text not null,
  subtitle text,
  order_index int not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.topics (
  id uuid primary key default gen_random_uuid(),
  module_id uuid not null references public.modules(id) on delete cascade,
  number text not null unique,          -- "0", "1", "16" ...
  slug text not null unique,            -- "3-crud-test"
  title text not null,
  focus text,
  description text,
  video_url text,
  github_url text,
  deliverable_note text,
  content_md text,                      -- explanation + code blocks + structure + image markdown
  order_index int not null default 0,
  locale text not null default 'en',
  created_at timestamptz not null default now()
);

create table if not exists public.topic_prerequisites (
  topic_id uuid not null references public.topics(id) on delete cascade,
  requires_topic_id uuid not null references public.topics(id) on delete cascade,
  primary key (topic_id, requires_topic_id)
);

create table if not exists public.content_images (
  id uuid primary key default gen_random_uuid(),
  topic_id uuid not null references public.topics(id) on delete cascade,
  url text not null,
  caption text,
  uploaded_at timestamptz not null default now()
);

-- =========================================================
-- PROGRESS / GATING
-- =========================================================
create table if not exists public.user_progress (
  user_id uuid not null references public.profiles(id) on delete cascade,
  topic_id uuid not null references public.topics(id) on delete cascade,
  status text not null default 'not_started' check (status in ('not_started','in_progress','completed')),
  completed_at timestamptz,
  primary key (user_id, topic_id)
);

-- =========================================================
-- TAGS (topic labels, free-form, searchable)
-- =========================================================
create table if not exists public.tags (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  usage_count int not null default 0
);

-- =========================================================
-- Q&A: QUESTIONS / ANSWERS / REPLIES
-- =========================================================
create table if not exists public.questions (
  id uuid primary key default gen_random_uuid(),
  topic_id uuid references public.topics(id) on delete set null, -- NULL = general "Ask Anything" question
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  body text not null,
  deleted boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.question_tags (
  question_id uuid not null references public.questions(id) on delete cascade,
  tag_id uuid not null references public.tags(id) on delete cascade,
  primary key (question_id, tag_id)
);

create table if not exists public.answers (
  id uuid primary key default gen_random_uuid(),
  question_id uuid not null references public.questions(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  body text not null,
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  auto_flagged boolean not null default false,
  accepted boolean not null default false,
  deleted boolean not null default false,
  moderator_note text,
  created_at timestamptz not null default now()
);

create table if not exists public.replies (
  id uuid primary key default gen_random_uuid(),
  answer_id uuid not null references public.answers(id) on delete cascade,
  parent_reply_id uuid references public.replies(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  body text not null,
  mentions uuid[] not null default '{}',
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  auto_flagged boolean not null default false,
  deleted boolean not null default false,
  moderator_note text,
  created_at timestamptz not null default now()
);

-- =========================================================
-- VOTES (one per user per target)
-- =========================================================
create table if not exists public.votes (
  user_id uuid not null references public.profiles(id) on delete cascade,
  target_type text not null check (target_type in ('answer','reply')),
  target_id uuid not null,
  value int not null default 1 check (value in (1, -1)),
  created_at timestamptz not null default now(),
  primary key (user_id, target_type, target_id)
);

-- =========================================================
-- NOTIFICATIONS (in-app only for v1)
-- =========================================================
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  type text not null check (type in ('answered','mentioned','accepted')),
  source_id uuid,                      -- id of the answer/reply that triggered it
  read boolean not null default false,
  created_at timestamptz not null default now()
);

-- =========================================================
-- INDEXES
-- =========================================================
create index if not exists idx_topics_module on public.topics(module_id);
create index if not exists idx_questions_topic on public.questions(topic_id);
create index if not exists idx_answers_question on public.answers(question_id);
create index if not exists idx_answers_status on public.answers(status);
create index if not exists idx_replies_answer on public.replies(answer_id);
create index if not exists idx_replies_status on public.replies(status);
create index if not exists idx_notifications_user on public.notifications(user_id, read);

-- full-text search
alter table public.questions add column if not exists search_vector tsvector
  generated always as (to_tsvector('english', coalesce(title,'') || ' ' || coalesce(body,''))) stored;
create index if not exists idx_questions_search on public.questions using gin(search_vector);

alter table public.topics add column if not exists search_vector tsvector
  generated always as (to_tsvector('english', coalesce(title,'') || ' ' || coalesce(description,'') || ' ' || coalesce(content_md,''))) stored;
create index if not exists idx_topics_search on public.topics using gin(search_vector);

-- =========================================================
-- ROW LEVEL SECURITY (baseline - tighten per-table as needed)
-- =========================================================
alter table public.profiles enable row level security;
alter table public.questions enable row level security;
alter table public.answers enable row level security;
alter table public.replies enable row level security;
alter table public.votes enable row level security;
alter table public.user_progress enable row level security;
alter table public.notifications enable row level security;

-- Public read of approved/undeleted content
create policy "profiles are viewable by everyone" on public.profiles for select using (true);
create policy "questions are viewable by everyone" on public.questions for select using (deleted = false);
create policy "approved answers are viewable by everyone" on public.answers for select using (status = 'approved' and deleted = false);
create policy "approved replies are viewable by everyone" on public.replies for select using (status = 'approved' and deleted = false);

-- Authenticated users can insert their own content
create policy "users can insert their own questions" on public.questions for insert with check (auth.uid() = user_id);
create policy "users can insert their own answers" on public.answers for insert with check (auth.uid() = user_id);
create policy "users can insert their own replies" on public.replies for insert with check (auth.uid() = user_id);
create policy "users can vote as themselves" on public.votes for all using (auth.uid() = user_id);
create policy "users manage their own progress" on public.user_progress for all using (auth.uid() = user_id);
create policy "users see their own notifications" on public.notifications for select using (auth.uid() = user_id);

-- NOTE: moderation (viewing pending, approve/reject) is done via the FastAPI
-- backend using the service_role key, which bypasses RLS by design.

-- =========================================================
-- AUTO-CREATE PROFILE ROW ON SIGNUP
-- =========================================================
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, display_name, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email, '@', 1)),
    'learner'
  );
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

