-- CodeGoLive — Store per-question attempt answers for cross-device review
-- Run AFTER assessment_migration.sql

create table if not exists public.assessment_attempt_answers (
  id              uuid primary key default gen_random_uuid(),
  attempt_id      uuid not null references public.assessment_attempts(id) on delete cascade,
  question_id     uuid not null references public.assessment_questions(id),
  selected_option int  not null,
  is_correct      boolean not null,
  created_at      timestamptz not null default now()
);

create index if not exists idx_aaa_attempt on public.assessment_attempt_answers(attempt_id);
