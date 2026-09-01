-- CodeGoLive — Final Assessment
-- Run AFTER schema.sql and certificates.sql
-- Creates assessment infrastructure and gates the certificate on a passing attempt.

-- =====================================================
-- 1. ASSESSMENT QUESTIONS TABLE
-- =====================================================
create table if not exists public.assessment_questions (
  id          uuid primary key default gen_random_uuid(),
  course_id   text not null default 'sap-btp',
  question    text not null,
  options     jsonb not null,           -- ["option A", "option B", "option C", "option D"]
  correct_option int not null check (correct_option between 0 and 3),
  explanation text not null,
  topic_slug  text not null,            -- used to build /course/{courseId}/{topicSlug} link
  order_num   int not null default 0
);

create index if not exists idx_aq_course on public.assessment_questions(course_id);

-- =====================================================
-- 2. ASSESSMENT ATTEMPTS TABLE
-- =====================================================
create table if not exists public.assessment_attempts (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references public.profiles(id) on delete cascade,
  course_id    text not null default 'sap-btp',
  score        int not null,            -- number of correct answers
  total        int not null,            -- total questions in this attempt
  passed       boolean not null,
  attempted_at timestamptz not null default now()
);

create index if not exists idx_attempts_user_course on public.assessment_attempts(user_id, course_id);

-- =====================================================
-- 3. MODIFY CERTIFICATE TRIGGER TO REQUIRE ASSESSMENT
-- =====================================================
-- Replace the old trigger function that only checked topic completion.
-- Now also requires at least one passed assessment attempt.

create or replace function public.maybe_issue_certificate()
returns trigger as $$
declare
  total_topics int;
  completed_count int;
  passed_assessment boolean;
begin
  -- Only act on completions
  if NEW.status <> 'completed' then
    return NEW;
  end if;

  select count(*) into total_topics from public.topics;
  select count(*) into completed_count
    from public.user_progress
    where user_id = NEW.user_id and status = 'completed';

  -- Check assessment (if table exists, require it; if not, skip gracefully)
  begin
    select exists(
      select 1 from public.assessment_attempts
      where user_id = NEW.user_id and passed = true
    ) into passed_assessment;
  exception when undefined_table then
    passed_assessment := true;  -- graceful fallback if table not yet created
  end;

  if completed_count >= total_topics and passed_assessment then
    insert into public.certificates (user_id)
    values (NEW.user_id)
    on conflict (user_id) do nothing;
  end if;

  return NEW;
end;
$$ language plpgsql security definer;

-- Recreate trigger (drop + create to pick up new function body)
drop trigger if exists on_progress_completed on public.user_progress;
create trigger on_progress_completed
  after insert or update on public.user_progress
  for each row execute procedure public.maybe_issue_certificate();

