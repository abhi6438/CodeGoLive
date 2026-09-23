-- =============================================================================
-- Paperclip AI — Module 2: Your First AI Company
-- Topics: pcl-10 through pcl-18
-- =============================================================================

-- ─── pcl-10-create-company ───────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Creating Your First AI Company

## What you'll learn
By the end of this lesson you will have created a company record in Paperclip AI, understand what a "company" represents in the data model, and be ready to hire your first agent.

## What is a "Company"?

In Paperclip AI a **company** is the top-level organizational boundary. Everything — agents, tasks, issues, approvals, cost events — belongs to exactly one company. The `company_id` column appears on every table and every query filters by it, giving you hard multi-tenancy in a single database.

```
companies
├── agents        (the workers)
├── issues        (the work queue)
├── heartbeat_runs (execution log)
├── approvals     (human sign-off)
└── cost_events   (spending ledger)
```

Think of it like a Stripe account: the boundary is conceptual but the enforcement is real.

## Creating a Company via the UI

1. Start Paperclip AI (`pnpm dev` from the repo root — both API and frontend start together).
2. Open **http://localhost:5173** in your browser.
3. Click **"New Company"** in the top nav.
4. Fill in:
   - **Name** — e.g. `Acme Automations`
   - **Slug** — auto-generated from name; must be URL-safe
   - **Monthly budget** — set a safe ceiling like `$10.00` for now
5. Click **Create**.

The UI redirects you to the company dashboard. The URL contains the company `id` — keep it handy.

## Creating a Company via the API

```bash
curl -X POST http://localhost:3100/api/companies \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Acme Automations",
    "slug": "acme-automations",
    "monthly_budget_usd": 10.00
  }'
```

Response:
```json
{
  "id": "01929f3a-...",
  "name": "Acme Automations",
  "slug": "acme-automations",
  "monthly_budget_usd": "10.00",
  "created_at": "2024-01-15T10:30:00Z"
}
```

Save the `id` — you'll reference it when hiring agents and seeding tasks.

## Creating a Company in SQL (seed scripts)

For repeatable environments, use an upsert:

```sql
INSERT INTO public.companies (name, slug, monthly_budget_usd)
VALUES ('Acme Automations', 'acme-automations', 10.00)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  monthly_budget_usd = EXCLUDED.monthly_budget_usd
RETURNING id;
```

## The Company Schema At a Glance

| Column | Type | Purpose |
|--------|------|---------|
| `id` | uuid | Primary key, auto-generated |
| `name` | text | Display name |
| `slug` | text | URL-safe identifier (unique) |
| `monthly_budget_usd` | numeric | Spending cap; triggers auto-pause |
| `paused` | boolean | Set by circuit-breaker when budget exceeded |
| `created_at` | timestamptz | Record creation time |

## Checkpoint ✓

- [ ] Company created and visible in the dashboard
- [ ] You can see the company `id` in the URL or API response
- [ ] Monthly budget is set to a safe limit for development
$md$ WHERE slug = 'pcl-10-create-company';

-- ─── pcl-11-company-schema ───────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# The Company Schema in Depth

## What you'll learn
A thorough reference for the `companies` table, how Paperclip AI enforces the `company_id` boundary across every query, and what multi-tenancy means in practice.

## The Full `companies` Table

```sql
CREATE TABLE public.companies (
  id                 uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  name               text        NOT NULL,
  slug               text        NOT NULL UNIQUE,
  monthly_budget_usd numeric(10,2) NOT NULL DEFAULT 0,
  paused             boolean     NOT NULL DEFAULT false,
  created_at         timestamptz NOT NULL DEFAULT now()
);
```

Paperclip AI keeps this lean on purpose. The company record is the anchor, not the configuration store — settings live on agents, tasks, and cost policies.

## The `company_id` Boundary

Every subordinate table carries a `company_id` foreign key:

```sql
-- agents
ALTER TABLE public.agents
  ADD COLUMN company_id uuid NOT NULL REFERENCES public.companies(id);

-- issues
ALTER TABLE public.issues
  ADD COLUMN company_id uuid NOT NULL REFERENCES public.companies(id);

-- heartbeat_runs
ALTER TABLE public.heartbeat_runs
  ADD COLUMN company_id uuid NOT NULL REFERENCES public.companies(id);
```

The application layer enforces this at two points:

**1. On write** — every INSERT passes `company_id` from the authenticated context. The API never lets a caller set an arbitrary `company_id`; it reads it from the session/JWT.

**2. On read** — every SELECT adds `WHERE company_id = $current_company_id`. This is done by a helper function used in all repository files:

```typescript
// packages/server/src/lib/db/repos/base.ts
export function withCompany<T extends { company_id: string }>(
  qb: SelectQueryBuilder<T>,
  companyId: string
) {
  return qb.where('company_id', '=', companyId);
}
```

## Why This Matters

Without the boundary, a bug in a multi-company system can leak Agent A's tasks to Company B's queries. Paperclip AI makes this impossible at the repository layer — even if the HTTP route forgot to filter, the base query builder enforces it.

For development with a single company this is transparent. For production SaaS it means you can safely run many companies in one database.

## Checking the Boundary in Practice

```bash
# See all companies (admin/dev only)
psql $DATABASE_URL -c "SELECT id, name, slug, paused FROM companies;"

# Count items per company
psql $DATABASE_URL -c "
  SELECT c.name,
         COUNT(DISTINCT a.id) AS agents,
         COUNT(DISTINCT i.id) AS issues
  FROM companies c
  LEFT JOIN agents a ON a.company_id = c.id
  LEFT JOIN issues i ON i.company_id = c.id
  GROUP BY c.name;"
```

## The `paused` Flag

When cumulative spend for the month exceeds `monthly_budget_usd`, the heartbeat system sets `paused = true`. While paused:
- No new heartbeat runs start for this company
- Existing agent tasks are not picked up
- Approval workflows are unaffected (humans can still sign off)
- The UI shows a banner prompting you to raise the budget or wait for month rollover

To manually resume during development:
```sql
UPDATE companies SET paused = false WHERE slug = 'acme-automations';
```

## Checkpoint ✓

- [ ] You can describe what `company_id` enforces and where it is applied
- [ ] You understand the `paused` flag and how to reset it
- [ ] You can query company stats from the database
$md$ WHERE slug = 'pcl-11-company-schema';

-- ─── pcl-12-hire-first-agent ─────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Hiring Your First Agent

## What you'll learn
Create an agent record, understand every field in the `agents` table, and connect the agent to an adapter so the heartbeat can invoke it.

## What is an Agent?

An **agent** in Paperclip AI is a persistent row in the database that represents one autonomous worker. It stores:
- What the agent is supposed to do (role, system prompt)
- Which adapter to use to invoke it (Claude Code, OpenAI, HTTP…)
- Its cost limits and current status
- Its position in the org chart (`reports_to`)

Agents don't run continuously. They are invoked by the heartbeat on each tick when there is unclaimed work.

## Hiring via the UI

1. Open your company dashboard → **Agents** → **Hire Agent**.
2. Fill in:
   - **Name** — e.g. `Researcher`
   - **Role** — e.g. `Research Analyst`
   - **System prompt** — the standing instruction this agent always receives
   - **Adapter** — choose `claude-code` for local dev
   - **Monthly budget** — start with `$5.00`
3. Click **Hire**.

## Hiring via the API

```bash
curl -X POST http://localhost:3100/api/companies/${COMPANY_ID}/agents \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Researcher",
    "role": "Research Analyst",
    "system_prompt": "You are a research analyst. When given a topic, produce a concise 3-paragraph summary with key facts and sources.",
    "adapter_type": "claude-code",
    "monthly_budget_usd": 5.00
  }'
```

## Hiring via SQL (seed scripts)

```sql
INSERT INTO public.agents (
  company_id, name, role, system_prompt, adapter_type, monthly_budget_usd, status
)
VALUES (
  '01929f3a-...',   -- your company id
  'Researcher',
  'Research Analyst',
  'You are a research analyst. When given a topic, produce a concise 3-paragraph summary.',
  'claude-code',
  5.00,
  'active'
)
ON CONFLICT (company_id, name) DO UPDATE SET
  role = EXCLUDED.role,
  system_prompt = EXCLUDED.system_prompt;
```

## The `agents` Table Reference

| Column | Type | Notes |
|--------|------|-------|
| `id` | uuid | PK |
| `company_id` | uuid | FK → companies |
| `name` | text | Display name, unique per company |
| `role` | text | Job title shown in org chart |
| `system_prompt` | text | Standing instruction |
| `adapter_type` | text | `claude-code`, `openai`, `http`, `shell` |
| `adapter_config` | jsonb | Adapter-specific config (model, url, etc.) |
| `monthly_budget_usd` | numeric | Per-agent spend cap |
| `status` | text | `active`, `paused`, `terminated` |
| `reports_to` | uuid | FK → agents (manager), nullable |
| `created_at` | timestamptz | |

## After Hiring

Once an agent exists it will be picked up by the heartbeat on the next tick — **but only if there are open issues assigned to it**. In the next lesson you'll create your first task to give the agent something to do.

## Checkpoint ✓

- [ ] Agent created and visible in the Agents list
- [ ] Agent has a system prompt, an adapter, and a monthly budget
- [ ] You understand the difference between `adapter_type` and `adapter_config`
$md$ WHERE slug = 'pcl-12-hire-first-agent';

-- ─── pcl-13-agent-prompts ────────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Designing Agent System Prompts

## What you'll learn
Write effective system prompts for Paperclip agents, understand the prompt injection Paperclip adds automatically, and avoid common pitfalls.

## How Paperclip Assembles the Full Prompt

When the heartbeat invokes an agent it does **not** send only your system prompt. It assembles a full prompt object:

```
[system_prompt from agents table]
+
[task context injected by Paperclip]:
  - Issue title and description
  - Deliverable specification
  - Tool list (if adapter supports tools)
  - Cost budget remaining
  - Response format instructions (JSON schema)
```

Your system prompt is the **standing instruction** — who the agent is and what it values. The task context is appended fresh each invocation.

## Anatomy of a Good System Prompt

```
You are {role} at {company_name}.

## Identity
{one sentence about what you do}

## Values
- {value 1}
- {value 2}

## Operating rules
- {rule 1}
- {rule 2}

## Output format
{description of how you must respond — but keep this brief;
 Paperclip adds its own JSON schema requirement}
```

### Example: Research Analyst

```
You are a Research Analyst at Acme Automations.

## Identity
You produce concise, well-sourced research summaries on any topic.

## Values
- Accuracy over speed: flag when you are uncertain
- Cite your sources with URLs when possible
- Be concise: 3 paragraphs maximum per summary

## Operating rules
- Never fabricate facts or statistics
- If a topic is ambiguous, state your interpretation before answering
- Always end with "Further reading:" and 2–3 URLs
```

### Example: Code Reviewer

```
You are a Senior Code Reviewer at Acme Automations.

## Identity
You review pull requests and flag security issues, performance problems, and style violations.

## Values
- Security first: any credential leak or injection risk is severity CRITICAL
- Be specific: cite line numbers and explain WHY something is wrong
- Be constructive: every criticism includes a suggested fix

## Operating rules
- Review only the diff provided; do not speculate about unseen code
- Use severity levels: CRITICAL / HIGH / MEDIUM / LOW / INFO
```

## What NOT to Put in the System Prompt

| Avoid | Reason |
|-------|--------|
| JSON format instructions | Paperclip injects its own schema |
| "Your budget is $X" | Paperclip injects remaining budget |
| Specific task descriptions | Task context is injected per invocation |
| "You are invoked every N minutes" | Heartbeat details are internal |

## Updating a System Prompt

Changes take effect on the **next heartbeat tick** — there is no warm cache to invalidate.

```bash
curl -X PATCH http://localhost:3100/api/companies/${COMPANY_ID}/agents/${AGENT_ID} \
  -H "Content-Type: application/json" \
  -d '{"system_prompt": "Updated prompt text..."}'
```

## Testing Prompts Without Running the Heartbeat

Use the agent test endpoint to invoke the adapter directly with a test task:

```bash
curl -X POST http://localhost:3100/api/companies/${COMPANY_ID}/agents/${AGENT_ID}/test \
  -H "Content-Type: application/json" \
  -d '{"task": "Summarize the key features of PostgreSQL row-level security."}'
```

This bypasses the issue queue and heartbeat so you can iterate on prompts quickly.

## Checkpoint ✓

- [ ] Your agent has a system prompt following the Identity / Values / Rules structure
- [ ] You understand what Paperclip injects automatically
- [ ] You have tested the prompt using the `/test` endpoint
$md$ WHERE slug = 'pcl-13-agent-prompts';

-- ─── pcl-14-first-heartbeat ──────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Watching Your First Heartbeat

## What you'll learn
Create an issue (task) for your agent, trigger or wait for the heartbeat, and read the resulting `heartbeat_runs` log to understand what happened.

## Step 1 — Create an Issue

Before the heartbeat has work to do you need at least one open issue assigned to your agent.

```bash
curl -X POST http://localhost:3100/api/companies/${COMPANY_ID}/issues \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Research: PostgreSQL row-level security",
    "description": "Produce a 3-paragraph summary of PostgreSQL RLS, with key use cases and an example policy.",
    "assigned_agent_id": "'${AGENT_ID}'",
    "priority": "medium"
  }'
```

The issue is created with `status = 'open'`.

## Step 2 — Trigger the Heartbeat Manually

In development you don't want to wait for the cron schedule. Use the manual trigger:

```bash
curl -X POST http://localhost:3100/api/heartbeat/run \
  -H "Content-Type: application/json" \
  -d '{"company_id": "'${COMPANY_ID}'"}'
```

You'll see a response like:
```json
{
  "run_id": "01929f3a-...",
  "company_id": "...",
  "agents_invoked": 1,
  "issues_claimed": 1,
  "status": "running"
}
```

## Step 3 — Watch the Run

```bash
# Poll for status
curl http://localhost:3100/api/heartbeat/runs/${RUN_ID}
```

```json
{
  "id": "...",
  "status": "completed",
  "agents_invoked": 1,
  "issues_resolved": 1,
  "total_cost_usd": "0.023",
  "started_at": "...",
  "finished_at": "..."
}
```

## Step 4 — Read the Issue Result

```bash
curl http://localhost:3100/api/companies/${COMPANY_ID}/issues/${ISSUE_ID}
```

The `result` field contains the agent's markdown output. The issue `status` should now be `resolved`.

## What the Heartbeat Did (Internal Flow)

```
1. Lock company row (SELECT FOR UPDATE SKIP LOCKED)
2. Check company is not paused / over budget
3. Find open issues with assigned agents that are active
4. For each issue: atomic checkout (UPDATE status='in_progress' RETURNING)
5. Invoke adapter (claude-code invoke) with assembled prompt
6. Receive structured JSON response
7. Update issue: status='resolved', result=response.output
8. Record cost_event: tokens used, cost in USD
9. Record heartbeat_run: summary stats
10. Release lock
```

## Reading Heartbeat Logs in the Database

```sql
SELECT
  hr.id,
  hr.status,
  hr.agents_invoked,
  hr.issues_resolved,
  hr.total_cost_usd,
  hr.started_at,
  hr.finished_at,
  (hr.finished_at - hr.started_at) AS duration
FROM heartbeat_runs hr
WHERE hr.company_id = 'your-company-id'
ORDER BY hr.started_at DESC
LIMIT 10;
```

## Checkpoint ✓

- [ ] Issue created and visible with `status = 'open'`
- [ ] Heartbeat triggered and completed without error
- [ ] Issue is now `status = 'resolved'` with a result
- [ ] A `heartbeat_runs` row exists with cost and timing data
$md$ WHERE slug = 'pcl-14-first-heartbeat';

-- ─── pcl-15-reading-activity ─────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Reading Agent Activity Logs

## What you'll learn
Navigate the Activity feed in the UI, query `heartbeat_runs` and `cost_events` directly, and build a picture of what your agents have been doing.

## The Activity Feed in the UI

Open **Company Dashboard → Activity**. The feed shows:

- Each heartbeat run as a timeline event
- Issues claimed and resolved per run
- Cost per run
- Error events if an adapter failed
- Approval requests (created or resolved)

Click any run to expand it and see which agent handled which issue.

## Querying `heartbeat_runs`

```sql
-- Last 20 runs with duration
SELECT
  id,
  status,
  agents_invoked,
  issues_resolved,
  total_cost_usd,
  EXTRACT(epoch FROM (finished_at - started_at))::int AS seconds,
  started_at
FROM heartbeat_runs
WHERE company_id = 'your-company-id'
ORDER BY started_at DESC
LIMIT 20;
```

### Status Values

| Status | Meaning |
|--------|---------|
| `running` | Heartbeat currently in progress |
| `completed` | All agents invoked, run finished cleanly |
| `failed` | Unhandled error during execution |
| `skipped` | Company paused or no open issues |

## Querying `cost_events`

Every adapter invocation that incurs a cost records a row:

```sql
SELECT
  ce.agent_id,
  a.name AS agent_name,
  ce.model,
  ce.input_tokens,
  ce.output_tokens,
  ce.cost_usd,
  ce.created_at
FROM cost_events ce
JOIN agents a ON a.id = ce.agent_id
WHERE ce.company_id = 'your-company-id'
ORDER BY ce.created_at DESC
LIMIT 20;
```

### Monthly Spend by Agent

```sql
SELECT
  a.name,
  SUM(ce.cost_usd) AS month_total_usd,
  SUM(ce.input_tokens + ce.output_tokens) AS total_tokens
FROM cost_events ce
JOIN agents a ON a.id = ce.agent_id
WHERE ce.company_id = 'your-company-id'
  AND ce.created_at >= date_trunc('month', now())
GROUP BY a.name
ORDER BY month_total_usd DESC;
```

## Reading Issue History

```sql
SELECT
  i.title,
  i.status,
  i.priority,
  a.name AS agent,
  i.created_at,
  i.resolved_at,
  LEFT(i.result, 200) AS result_preview
FROM issues i
LEFT JOIN agents a ON a.id = i.assigned_agent_id
WHERE i.company_id = 'your-company-id'
ORDER BY i.created_at DESC
LIMIT 20;
```

## Exporting Activity as CSV

```bash
psql $DATABASE_URL -c "\COPY (
  SELECT hr.id, hr.status, hr.total_cost_usd, hr.started_at
  FROM heartbeat_runs hr
  WHERE hr.company_id = 'your-company-id'
) TO '/tmp/activity.csv' CSV HEADER"
```

## Checkpoint ✓

- [ ] You can read the Activity feed in the UI and interpret each event
- [ ] You can query `heartbeat_runs` and see duration and cost per run
- [ ] You can query `cost_events` and see per-agent monthly spend
$md$ WHERE slug = 'pcl-15-reading-activity';

-- ─── pcl-16-agent-dashboard ──────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# The Agent Dashboard

## What you'll learn
Navigate every section of the Agent detail view in the Paperclip UI, understand what each metric means, and use the dashboard to diagnose agent health.

## Accessing the Agent Dashboard

From the Company Dashboard → **Agents** → click an agent name. The Agent Dashboard has five tabs:

| Tab | Contents |
|-----|----------|
| **Overview** | Status, role, adapter, budget gauge |
| **Activity** | Per-run history for this agent |
| **Issues** | Open, in-progress, and resolved issues |
| **Cost** | Daily/monthly spend chart |
| **Settings** | Edit prompt, adapter config, budget |

## Overview Tab

### Status Badge

| Badge | Meaning |
|-------|---------|
| 🟢 Active | Agent will be invoked next heartbeat |
| 🟡 Paused | Per-agent budget exceeded; auto-paused |
| 🔴 Terminated | Permanently removed from rotation |

### Budget Gauge

A progress bar showing `current_month_spend / monthly_budget_usd`. When it reaches 100% the agent auto-pauses. You can raise the budget in Settings without restarting anything.

### Adapter Card

Shows `adapter_type` and key `adapter_config` fields (model name, endpoint URL). Never shows raw API keys — those are masked.

## Activity Tab

A chronological list of every heartbeat invocation for this agent. Each entry shows:
- Issue title that was worked
- Duration (adapter invoke time)
- Tokens used and cost in USD
- Result status: `resolved`, `escalated`, `failed`

Clicking an entry expands the full adapter response.

## Issues Tab

Three columns:
- **Open** — issues assigned to this agent waiting to be picked up
- **In Progress** — currently being worked (during a heartbeat run)
- **Resolved** — completed issues with results

## Cost Tab

A bar chart of daily spend. Useful for spotting a day when an agent ran many expensive tasks. Below the chart is a table with cumulative totals by week and month.

## Diagnosing Common Problems

### Agent has 0 activity
- Check the company is not paused (`companies.paused`)
- Check the agent status is `active`
- Check there are open issues assigned to this agent
- Check the heartbeat cron is running (`pnpm dev` starts it)

### Agent keeps failing
- Open an Activity entry and read the error
- Common causes: adapter API key invalid, model name typo, network timeout
- Fix in Settings → Adapter Config, then re-queue the issue

### Agent spending too fast
- Lower `monthly_budget_usd` in Settings
- Check system prompt is not generating huge outputs
- Switch to a cheaper model in adapter config

## Checkpoint ✓

- [ ] You can navigate all five tabs of the Agent Dashboard
- [ ] You understand the status badge and budget gauge
- [ ] You know how to diagnose an agent with zero activity
$md$ WHERE slug = 'pcl-16-agent-dashboard';

-- ─── pcl-17-company-settings ─────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Company Settings Reference

## What you'll learn
Every configurable option in the Company Settings panel, what it affects at runtime, and best practices for development vs production.

## Opening Company Settings

Company Dashboard → **Settings** (gear icon, top-right). Settings are grouped into four sections.

## General

| Setting | Type | Effect |
|---------|------|--------|
| Company name | text | Display only; does not change slug |
| Slug | text | Read-only after creation; used in URLs |
| Monthly budget | decimal | Global ceiling; triggers company-wide pause |

**Tip**: Set a low monthly budget (`$10–$20`) in development. Raise it when you move to production. The budget resets on the 1st of each month.

## Heartbeat Schedule

| Setting | Default | Notes |
|---------|---------|-------|
| Cron expression | `*/5 * * * *` | Every 5 minutes |
| Enabled | true | Disable to pause all automatic execution |
| Max concurrent agents | 5 | How many agents can run in parallel per tick |

**Cron examples:**

```
*/5 * * * *    — every 5 minutes (default)
*/15 * * * *   — every 15 minutes (lighter on costs)
0 * * * *      — hourly
0 9-17 * * 1-5 — business hours only (9am–5pm Mon–Fri UTC)
```

Disable the heartbeat schedule when you want to trigger runs manually during development.

## Approval Policies

Approval gates are defined at the company level. Each policy specifies a **trigger condition** and a **required approver**.

Default policies:
```
hire_agent       → requires: human_admin
terminate_agent  → requires: human_admin
budget_increase  → requires: human_admin
strategy_change  → requires: human_admin
```

You can add custom policies for domain-specific actions:
```json
{
  "trigger": "publish_content",
  "condition": "word_count > 2000",
  "required_approver": "human_editor"
}
```

## Notification Webhooks

Paperclip can POST event notifications to an external URL:

| Event | Payload includes |
|-------|-----------------|
| `heartbeat.completed` | run stats, cost |
| `agent.paused` | agent id, reason |
| `approval.created` | approval id, trigger, details |
| `issue.resolved` | issue id, agent, result preview |

```json
{
  "webhook_url": "https://your-app.com/webhooks/paperclip",
  "webhook_secret": "whsec_...",
  "events": ["heartbeat.completed", "approval.created"]
}
```

The secret is used to sign the payload with HMAC-SHA256 — verify it on your end.

## Resetting Company State (Development)

To start fresh without deleting the company:

```sql
-- Clear all issues and runs but keep agents
DELETE FROM cost_events   WHERE company_id = 'your-id';
DELETE FROM heartbeat_runs WHERE company_id = 'your-id';
UPDATE issues SET status = 'open', result = NULL WHERE company_id = 'your-id';
UPDATE companies SET paused = false WHERE id = 'your-id';
```

## Checkpoint ✓

- [ ] You understand what monthly budget controls and when it resets
- [ ] You can configure a custom heartbeat schedule
- [ ] You know what approval policies are and what the defaults protect
$md$ WHERE slug = 'pcl-17-company-settings';

-- ─── pcl-18-mini-company-project ─────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Mini-Project: Your First Functioning AI Company

## What you'll build
A small but complete AI company with two agents, ten seeded tasks, and a working heartbeat — all running in local sandbox mode. By the end you will have watched end-to-end autonomous task completion.

## Company Spec

```
Company: Demo Corp
Monthly budget: $15.00

Agent 1: Researcher
  Role: Research Analyst
  Adapter: claude-code
  Budget: $8.00
  Prompt: See below

Agent 2: Summariser
  Role: Executive Summariser
  Adapter: claude-code
  Budget: $5.00
  Prompt: See below
```

## Step 1 — Create the Company

```sql
INSERT INTO public.companies (name, slug, monthly_budget_usd)
VALUES ('Demo Corp', 'demo-corp', 15.00)
ON CONFLICT (slug) DO NOTHING;
```

## Step 2 — Hire the Agents

```sql
DO $$
DECLARE
  cid uuid;
  a1  uuid;
  a2  uuid;
BEGIN
  SELECT id INTO cid FROM companies WHERE slug = 'demo-corp';

  INSERT INTO agents (company_id, name, role, system_prompt, adapter_type, monthly_budget_usd, status)
  VALUES (cid, 'Researcher', 'Research Analyst',
    'You are a Research Analyst. When given a topic, produce a clear 2-paragraph summary with 3 key facts.',
    'claude-code', 8.00, 'active')
  ON CONFLICT (company_id, name) DO NOTHING
  RETURNING id INTO a1;
  IF a1 IS NULL THEN SELECT id INTO a1 FROM agents WHERE company_id = cid AND name = 'Researcher'; END IF;

  INSERT INTO agents (company_id, name, role, system_prompt, adapter_type, monthly_budget_usd, status)
  VALUES (cid, 'Summariser', 'Executive Summariser',
    'You are an Executive Summariser. Given a research note, distill it to exactly 3 bullet points for a busy executive.',
    'claude-code', 5.00, 'active')
  ON CONFLICT (company_id, name) DO NOTHING;
END $$;
```

## Step 3 — Seed Ten Issues

```sql
DO $$
DECLARE
  cid uuid;
  a1  uuid;
BEGIN
  SELECT id INTO cid FROM companies WHERE slug = 'demo-corp';
  SELECT id INTO a1  FROM agents WHERE company_id = cid AND name = 'Researcher';

  INSERT INTO issues (company_id, title, description, assigned_agent_id, priority, status)
  SELECT cid, t.title, t.desc, a1, 'medium', 'open'
  FROM (VALUES
    ('What is LangGraph?',     'Research the LangGraph library and its use cases.'),
    ('What is CrewAI?',        'Research CrewAI and compare it to LangGraph.'),
    ('What is AutoGen?',       'Research Microsoft AutoGen framework.'),
    ('What is Agency Swarm?',  'Research Agency Swarm and its agent role model.'),
    ('What is Llama Index?',   'Research LlamaIndex for RAG applications.'),
    ('What is Haystack?',      'Research deepset Haystack pipeline framework.'),
    ('What is LangSmith?',     'Research LangSmith for LLM observability.'),
    ('What is Weights & Biases?', 'Research W&B for ML experiment tracking.'),
    ('What is Helicone?',      'Research Helicone for LLM usage analytics.'),
    ('What is PromptLayer?',   'Research PromptLayer for prompt versioning.')
  ) AS t(title, desc)
  ON CONFLICT DO NOTHING;
END $$;
```

## Step 4 — Run the Heartbeat Five Times

```bash
for i in 1 2 3 4 5; do
  curl -s -X POST http://localhost:3100/api/heartbeat/run \
    -H "Content-Type: application/json" \
    -d '{"company_id": "'${COMPANY_ID}'"}' | jq '.issues_resolved'
  sleep 2
done
```

## Step 5 — Review Results

```sql
SELECT
  i.title,
  i.status,
  LEFT(i.result, 120) AS preview
FROM issues i
JOIN companies c ON c.id = i.company_id
WHERE c.slug = 'demo-corp'
ORDER BY i.resolved_at DESC;
```

## What to Observe

- Issues are picked up one at a time (atomic checkout)
- Each resolved issue has a result from the Researcher agent
- `cost_events` shows token usage per invocation
- The company has not exceeded its budget

## Stretch Goal

Modify the seed so the Summariser picks up resolved Researcher issues and produces executive bullets. You'll need to add a second pass that creates a new issue for each resolved Researcher result.

## Checkpoint ✓

- [ ] Both agents created and visible in the dashboard
- [ ] Ten issues seeded and all resolved after heartbeat runs
- [ ] Cost events recorded and total within budget
- [ ] You can read agent results from the issues table
$md$ WHERE slug = 'pcl-18-mini-company-project';
