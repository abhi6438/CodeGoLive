-- CodeGoLive — Certificates
-- Run this AFTER schema.sql. Creates the certificates table and the
-- function that auto-issues a cert when a learner completes all 17 topics.

create table if not exists public.certificates (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  issued_at timestamptz not null default now(),
  unique (user_id)  -- one cert per user
);

-- Index for fast per-user lookup
create index if not exists idx_certificates_user on public.certificates(user_id);

-- =========================================================
-- AUTO-ISSUE CERT when a user completes all 17 topics
-- =========================================================
create or replace function public.maybe_issue_certificate()
returns trigger as $$
declare
  total_topics int;
  completed_count int;
begin
  -- Only act on completions
  if NEW.status <> 'completed' then
    return NEW;
  end if;

  select count(*) into total_topics from public.topics;
  select count(*) into completed_count
    from public.user_progress
    where user_id = NEW.user_id and status = 'completed';

  if completed_count >= total_topics then
    insert into public.certificates (user_id)
    values (NEW.user_id)
    on conflict (user_id) do nothing;
  end if;

  return NEW;
end;
$$ language plpgsql security definer;

drop trigger if exists on_progress_completed on public.user_progress;
create trigger on_progress_completed
  after insert or update on public.user_progress
  for each row execute procedure public.maybe_issue_certificate();
