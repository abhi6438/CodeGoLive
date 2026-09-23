-- =============================================================================
-- Paperclip AI — Module 5: The Heartbeat System
-- Topics: pcl-36 through pcl-44
-- =============================================================================

-- ─── pcl-36-heartbeat-concept ────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# The Heartbeat: Paperclip's Engine

## What you'll learn
The mental model behind the heartbeat system, why Paperclip chose a cron-based pull model instead of event-driven push, and what happens inside one heartbeat tick.

## The Core Idea

The heartbeat is a scheduled job — a clock tick — that wakes up every N minutes and asks: "Is there any open work? If so, dispatch agents to handle it."

```
Every 5 minutes:
  ┌─ Is company paused? → skip
  ├─ Is budget exceeded? → pause company, skip
  ├─ Find open issues per active agent
  │   ├─ Claim one issue per agent (atomic checkout)
  │   ├─ Invoke adapter (LLM call or script)
  │   └─ Record result + cost
  └─ Log heartbeat run stats
```

This is a **pull model**: agents don't run continuously; they are awakened by the clock. The work queue is the source of truth, not in-memory state.

## Pull vs Push: Why Paperclip Chose Pull

| Pull (heartbeat) | Push (event-driven) |
|-----------------|---------------------|
| Simple: one cron job | Complex: message broker, event bus |
| Durable: work survives restarts | At-risk: unprocessed events lost on crash |
| Observable: every run logged | Hard to trace: events flow through brokers |
| Rate-limited by design | Risk of thundering herd |
| Slightly higher latency (max: tick interval) | Low latency |

For autonomous background agents, latency of a few minutes is acceptable. Durability and observability matter more.

## One Tick in Detail

```
T=0:00  Cron fires → POST /internal/heartbeat/tick
T=0:00  Lock company row (SELECT FOR UPDATE)
T=0:00  Check: paused? over budget? → continue
T=0:01  Query open issues for each active agent
T=0:01  For each issue found:
          Atomic checkout (UPDATE...RETURNING)
          Assemble prompt (system + task)
          Invoke adapter
T=0:30  Adapter returns (LLM call took ~29s)
T=0:30  Update issue: status=resolved, result=output
T=0:30  Insert cost_event
T=0:31  Update heartbeat_run: agents=1, issues=1, cost=$0.02
T=0:31  Unlock company
T=5:00  Next tick fires
```

## What "Active Agent" Means

An agent is eligible for the heartbeat tick if:
- `status = 'active'`
- `monthly_spend_this_month < monthly_budget_usd`
- Company is not paused

## The Heartbeat Is Idempotent

If two heartbeat ticks overlap (e.g. the cron runs again before the first tick finishes), the atomic checkout prevents double-work. The second tick claims different issues or skips if none are open.

## Checkpoint ✓

- [ ] You can explain the pull model and why Paperclip chose it
- [ ] You can trace what happens during one heartbeat tick
- [ ] You understand when an agent is considered eligible
$md$ WHERE slug = 'pcl-36-heartbeat-concept';

-- ─── pcl-37-cron-scheduling ──────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Configuring the Heartbeat Schedule

## What you'll learn
Set a custom cron expression for your company's heartbeat, understand how Paperclip implements the cron internally, and choose the right interval for your use case.

## The Default Schedule

Out of the box, Paperclip runs the heartbeat every 5 minutes:
```
*/5 * * * *
```

This is a reasonable default for development and moderate-traffic production. Adjust it in Company Settings → Heartbeat Schedule.

## Cron Expression Reference

```
┌──────────── minute (0-59)
│  ┌─────────── hour (0-23)
│  │  ┌──────── day of month (1-31)
│  │  │  ┌───── month (1-12)
│  │  │  │  ┌── day of week (0-6, Sun=0)
│  │  │  │  │
*  *  *  *  *
```

### Common Patterns

| Expression | Meaning |
|-----------|---------|
| `*/5 * * * *` | Every 5 minutes (default) |
| `*/1 * * * *` | Every minute (dev/testing only) |
| `*/15 * * * *` | Every 15 minutes (conservative) |
| `0 * * * *` | Every hour on the hour |
| `0 9-17 * * 1-5` | Business hours only (9am–5pm, Mon–Fri) |
| `0 0 * * *` | Daily at midnight |
| `0 6 * * 1` | Weekly, Monday at 6am |

## Business-Hours-Only Operation

If agents are expensive to run and the tasks aren't urgent, confine the heartbeat to business hours:

```
0 9-17 * * 1-5
```

Issues created outside business hours queue up and are processed when the heartbeat resumes at 09:00 Monday.

**Important**: check timezones. Paperclip stores and evaluates cron expressions in UTC. Convert your local timezone:
- UTC+1 (BST): business hours 9am–5pm BST = 8am–4pm UTC → `0 8-16 * * 1-5`
- UTC-5 (EST): 9am–5pm EST = 2pm–10pm UTC → `0 14-22 * * 1-5`

## How Paperclip Implements the Cron

Internally, `pnpm dev` starts the API server and also schedules the heartbeat using `node-cron`:

```typescript
// packages/server/src/lib/heartbeat/scheduler.ts
import cron from 'node-cron';

export function startHeartbeatScheduler(company: Company) {
  const expression = company.heartbeat_cron ?? '*/5 * * * *';
  cron.schedule(expression, async () => {
    await runHeartbeatTick(company.id);
  });
}
```

In production (Docker/PM2) the same scheduler runs inside the server process. You do not need an external cron daemon.

## Disabling the Heartbeat

Set `heartbeat_enabled = false` in Company Settings to pause all automatic execution. Issues continue to queue; runs can still be triggered manually via the API.

## Manual Trigger vs Cron

| Method | When to use |
|--------|------------|
| Cron schedule | Normal operation; automatic processing |
| Manual trigger via API | Development, testing, one-off runs |
| Manual trigger via UI | Debug a specific issue; check agent output |

## Checkpoint ✓

- [ ] You can write a cron expression for business-hours-only operation
- [ ] You understand UTC conversion for your timezone
- [ ] You know how to disable the schedule without deleting the company
$md$ WHERE slug = 'pcl-37-cron-scheduling';

-- ─── pcl-38-execution-flow ───────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Heartbeat Execution Flow: Code Walkthrough

## What you'll learn
Follow the heartbeat source code from the cron trigger through the adapter call to the database write, understanding each layer's responsibility.

## Entry Point

```
packages/server/src/lib/heartbeat/
├── scheduler.ts    ← registers the cron
├── runner.ts       ← orchestrates one tick
├── dispatcher.ts   ← assigns issues to agents
└── recorder.ts     ← writes runs and cost events
```

## Step 1 — scheduler.ts

```typescript
export async function startHeartbeatScheduler() {
  const companies = await db.companies.findAll({ where: { paused: false } });
  for (const company of companies) {
    const expr = company.heartbeat_cron ?? DEFAULT_CRON;
    cron.schedule(expr, () => runHeartbeatTick(company.id));
  }
}
```

Runs once at server startup; schedules one cron job per active company.

## Step 2 — runner.ts

```typescript
export async function runHeartbeatTick(companyId: string) {
  // 1. Create the run record
  const run = await db.heartbeat_runs.create({
    company_id: companyId,
    status: 'running',
    started_at: new Date(),
  });

  try {
    // 2. Check company state
    const company = await db.companies.findOneOrFail(companyId);
    if (company.paused) {
      await recorder.skip(run.id, 'company_paused');
      return;
    }

    // 3. Dispatch
    const stats = await dispatcher.dispatchAll(companyId, run.id);

    // 4. Record completion
    await recorder.complete(run.id, stats);
  } catch (err) {
    await recorder.fail(run.id, err);
  }
}
```

## Step 3 — dispatcher.ts

```typescript
export async function dispatchAll(companyId: string, runId: string) {
  const agents = await db.agents.findAll({
    where: { company_id: companyId, status: 'active' },
  });

  const results = await Promise.allSettled(
    agents.map(agent => dispatchOne(agent, companyId, runId))
  );

  return aggregateStats(results);
}

async function dispatchOne(agent, companyId, runId) {
  // Atomic checkout
  const issue = await claimNextIssue(agent.id, companyId);
  if (!issue) return { claimed: 0, resolved: 0, cost: 0 };

  // Assemble prompt and invoke
  const adapter = createAdapter(agent);
  const task    = assembleTask(agent, issue);
  const result  = await adapter.invoke(task);

  // Write outcome
  await resolveIssue(issue.id, result);
  await recorder.recordCost(agent.id, companyId, runId, result.cost);

  return { claimed: 1, resolved: 1, cost: result.cost?.costUsd ?? 0 };
}
```

## Step 4 — recorder.ts

```typescript
export async function recordCost(agentId, companyId, runId, cost) {
  if (!cost) return;
  await db.cost_events.create({
    agent_id:      agentId,
    company_id:    companyId,
    heartbeat_run_id: runId,
    model:         cost.model,
    input_tokens:  cost.inputTokens,
    output_tokens: cost.outputTokens,
    cost_usd:      cost.costUsd,
  });
}
```

## Key Architectural Choices

**Promise.allSettled** — agents run in parallel. If one agent's adapter throws, the others still complete. The run records partial failures.

**No global transaction** — each issue claim and resolution is its own transaction. This prevents one slow adapter from holding a lock on the entire company.

**Idempotent run ID** — the run ID is created before any work starts, so partial failures can be resumed or replayed.

## Checkpoint ✓

- [ ] You can describe the four source files and each one's role
- [ ] You understand why `Promise.allSettled` is used instead of `Promise.all`
- [ ] You know why there is no single global transaction across a tick
$md$ WHERE slug = 'pcl-38-execution-flow';

-- ─── pcl-39-heartbeat-runs ───────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Reading and Querying Heartbeat Runs

## What you'll learn
The complete `heartbeat_runs` schema, useful queries for monitoring performance and cost over time, and how to correlate runs with specific issues and agents.

## The `heartbeat_runs` Table

```sql
CREATE TABLE public.heartbeat_runs (
  id               uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id       uuid        NOT NULL REFERENCES companies(id),
  status           text        NOT NULL DEFAULT 'running'
                               CHECK (status IN ('running','completed','failed','skipped')),
  agents_invoked   int         NOT NULL DEFAULT 0,
  issues_claimed   int         NOT NULL DEFAULT 0,
  issues_resolved  int         NOT NULL DEFAULT 0,
  issues_failed    int         NOT NULL DEFAULT 0,
  total_cost_usd   numeric(10,4) NOT NULL DEFAULT 0,
  error_detail     jsonb,      -- array of error objects if status='failed'
  skip_reason      text,       -- 'company_paused', 'no_open_issues', etc.
  started_at       timestamptz NOT NULL DEFAULT now(),
  finished_at      timestamptz
);
```

## Key Queries

### Last 7 Days of Run History

```sql
SELECT
  DATE(started_at)                         AS date,
  COUNT(*)                                 AS total_runs,
  SUM(issues_resolved)                     AS issues_done,
  SUM(total_cost_usd)                      AS daily_cost,
  AVG(EXTRACT(epoch FROM (finished_at - started_at)))::int AS avg_seconds
FROM heartbeat_runs
WHERE company_id = 'your-company-id'
  AND started_at >= now() - interval '7 days'
GROUP BY DATE(started_at)
ORDER BY date DESC;
```

### Failed Runs with Error Detail

```sql
SELECT
  id,
  started_at,
  error_detail,
  skip_reason
FROM heartbeat_runs
WHERE company_id = 'your-company-id'
  AND status IN ('failed', 'skipped')
ORDER BY started_at DESC
LIMIT 20;
```

### Cost Trend Over Time

```sql
SELECT
  date_trunc('hour', started_at) AS hour,
  SUM(total_cost_usd)            AS cost_per_hour,
  SUM(issues_resolved)           AS issues_per_hour
FROM heartbeat_runs
WHERE company_id = 'your-company-id'
  AND started_at >= now() - interval '24 hours'
GROUP BY hour
ORDER BY hour;
```

### Runs That Resolved at Least One Issue

```sql
SELECT
  id,
  agents_invoked,
  issues_resolved,
  total_cost_usd,
  EXTRACT(epoch FROM (finished_at - started_at))::int AS seconds
FROM heartbeat_runs
WHERE company_id = 'your-company-id'
  AND issues_resolved > 0
ORDER BY started_at DESC
LIMIT 10;
```

### Monthly Summary

```sql
SELECT
  to_char(date_trunc('month', started_at), 'YYYY-MM') AS month,
  COUNT(*)                 AS total_runs,
  SUM(issues_resolved)     AS issues_resolved,
  SUM(total_cost_usd)      AS total_cost,
  COUNT(*) FILTER (WHERE status = 'failed') AS failed_runs
FROM heartbeat_runs
WHERE company_id = 'your-company-id'
GROUP BY month
ORDER BY month DESC;
```

## Correlating Runs to Issues

```sql
-- Which heartbeat run resolved a specific issue?
SELECT hr.id, hr.started_at, hr.total_cost_usd
FROM heartbeat_runs hr
JOIN issues i ON i.heartbeat_run_id = hr.id
WHERE i.id = 'your-issue-id';
```

## Checkpoint ✓

- [ ] You can query the last 7 days of run history with cost per day
- [ ] You can find failed runs and read their error details
- [ ] You know how to correlate a specific issue to the run that resolved it
$md$ WHERE slug = 'pcl-39-heartbeat-runs';

-- ─── pcl-40-concurrency ──────────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Concurrency: Multiple Agents Per Tick

## What you'll learn
How Paperclip runs multiple agents in parallel within a single tick, configure concurrency limits, and understand the performance trade-offs.

## Default Concurrency

By default, Paperclip invokes all active agents in parallel within one tick using `Promise.allSettled`. With five active agents, all five adapter calls start simultaneously.

```
Tick T=0:00
  Agent A invoke ──────────────────► complete T=0:28
  Agent B invoke ──────────────────► complete T=0:31
  Agent C invoke ──────────────────► complete T=0:15
  Agent D invoke ──────────────────► complete T=0:42
  Agent E invoke ──────────────────► complete T=0:35
Tick T=0:42 (overall completion time = slowest agent)
```

The tick's completion time equals the **slowest agent**, not the sum of all durations.

## Maximum Concurrent Agents

Control how many agents run in parallel:

Company Settings → Heartbeat → **Max concurrent agents** (default: 10).

Or in the heartbeat config:

```typescript
// Limit to 3 parallel adapters
const semaphore = new Semaphore(maxConcurrentAgents ?? 10);

await Promise.allSettled(
  agents.map(agent =>
    semaphore.acquire().then(release =>
      dispatchOne(agent, ...).finally(release)
    )
  )
);
```

## When to Limit Concurrency

| Situation | Recommended limit |
|-----------|------------------|
| Free-tier API keys (strict rate limits) | 1–2 |
| Production with standard API keys | 5–10 (default) |
| Self-hosted models (Ollama on a single GPU) | 1 |
| Multiple cloud providers, generous rate limits | 20+ |

## Rate Limit Handling

When the LLM API returns 429 (rate limit), the adapter throws and the issue is marked as failed + retried next tick. Set a lower concurrency limit to stay within your API quota.

For `claude-code` adapter specifically: Anthropic rate limits are per-API-key and per-model. Using different models (claude-haiku vs claude-opus) for different agents can double your effective throughput.

## Per-Agent Parallelism

By default each agent claims one issue per tick. To let an agent claim and process multiple issues in one tick:

```json
{
  "adapter_config": {
    "max_issues_per_tick": 3
  }
}
```

This is useful for a "light" agent doing quick classification tasks. Do not use it for expensive LLM agents unless you're confident about budget.

## Monitoring Concurrency

```sql
-- See max concurrent adapters in a given run
SELECT
  id,
  agents_invoked,
  issues_claimed,
  ROUND(
    EXTRACT(epoch FROM (finished_at - started_at)) / NULLIF(agents_invoked, 0)
  ) AS avg_seconds_per_agent,
  EXTRACT(epoch FROM (finished_at - started_at)) AS total_seconds
FROM heartbeat_runs
WHERE company_id = 'your-company-id'
ORDER BY started_at DESC
LIMIT 5;
```

## Checkpoint ✓

- [ ] You understand that agents run in parallel within one tick
- [ ] You can configure `max_concurrent_agents` for rate-limited APIs
- [ ] You know when `max_issues_per_tick > 1` is appropriate
$md$ WHERE slug = 'pcl-40-concurrency';

-- ─── pcl-41-timeout-retry ────────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Timeout and Retry Configuration

## What you'll learn
Configure adapter timeouts, understand the automatic retry mechanism, and decide when to escalate vs retry a failed issue.

## Adapter Timeout

Each adapter accepts a `timeout_ms` config. If the adapter call takes longer than this, it is killed and the issue is marked failed:

```json
{
  "adapter_config": {
    "timeout_ms": 45000   // 45 seconds
  }
}
```

**Defaults by adapter:**

| Adapter | Default timeout |
|---------|----------------|
| `claude-code` | 60 000 ms |
| `openai` | 30 000 ms |
| `http` | 30 000 ms |
| `shell` | 30 000 ms |

## What Happens on Timeout

1. Adapter throws a `TimeoutError`
2. Issue status set back to `'open'`, `attempt_count++`
3. Error recorded in `heartbeat_runs.error_detail`
4. Next tick will retry (if `attempt_count < max_attempts`)

## The `max_attempts` Field

Per issue, default 3:

```sql
-- More forgiving for flaky external services
UPDATE issues SET max_attempts = 5 WHERE id = 'issue-id';

-- One-shot only (no retry on failure)
UPDATE issues SET max_attempts = 1 WHERE id = 'issue-id';
```

When `attempt_count >= max_attempts` on a failure, the issue moves to `'escalated'` instead of back to `'open'`.

## Global Retry Config

Set a company-level default for `max_attempts`:

```json
{
  "default_max_attempts": 3,
  "retry_delay_ms": 0    // 0 = retry immediately next tick
}
```

A non-zero `retry_delay_ms` requires the heartbeat to wait before retrying — useful with a 1-minute heartbeat to avoid hammering a flaky API.

## Implementing Exponential Back-off

For HTTP adapters calling external services, implement back-off in the adapter:

```typescript
const delays = [1000, 5000, 15000]; // ms

for (let i = 0; i < 3; i++) {
  try {
    return await callExternalService(task);
  } catch (err) {
    if (i === 2) throw err;
    await sleep(delays[i]);
  }
}
```

Keep total retry time under `timeout_ms` or the outer timeout will fire.

## When to Escalate Instead of Retry

Set `max_attempts = 1` for tasks where retrying is pointless:
- Deterministic transformations (a CSV format error won't self-heal)
- Uniqueness-constrained writes (retrying will just fail again)
- Human-in-the-loop tasks (always route to approval)

## Checkpoint ✓

- [ ] You can set per-adapter timeout and explain what happens on expiry
- [ ] You understand `max_attempts` and when escalation replaces retry
- [ ] You know how to implement back-off inside an HTTP adapter
$md$ WHERE slug = 'pcl-41-timeout-retry';

-- ─── pcl-42-debugging-runs ───────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Debugging Heartbeat Runs

## What you'll learn
Systematic approach to diagnosing heartbeat failures, reading error details from the database, and reproducing adapter errors locally.

## The Debugging Checklist

When a heartbeat run fails or an issue stays stuck in `'open'`:

```
1. Check heartbeat_runs.status and error_detail
2. Check issues.attempt_count vs max_attempts
3. Check agent status (active / paused)
4. Check company paused flag
5. Check API key environment variables
6. Reproduce the adapter call locally
7. Check adapter logs (for shell/http adapters)
```

## Step 1 — Read the Run Error

```sql
SELECT
  id,
  status,
  error_detail,
  skip_reason,
  started_at,
  finished_at
FROM heartbeat_runs
WHERE company_id = 'your-company-id'
  AND status IN ('failed', 'skipped')
ORDER BY started_at DESC
LIMIT 5;
```

`error_detail` is a JSONB array — each element represents one agent failure:

```json
[
  {
    "agent_id": "...",
    "agent_name": "Researcher",
    "issue_id": "...",
    "error": "TimeoutError: adapter invoke exceeded 60000ms",
    "attempt": 2
  }
]
```

## Step 2 — Check Issue State

```sql
SELECT
  id, title, status, attempt_count, max_attempts
FROM issues
WHERE company_id = 'your-company-id'
  AND status IN ('open', 'escalated')
ORDER BY attempt_count DESC;
```

Issues with `attempt_count = max_attempts` and `status = 'escalated'` have given up and need human review.

## Step 3 — Reproduce the Adapter Call

For `claude-code`:
```bash
# Get the system prompt and a failing issue's description
SYSTEM=$(psql $DATABASE_URL -t -c "SELECT system_prompt FROM agents WHERE name='Researcher' LIMIT 1")
TASK=$(psql $DATABASE_URL -t -c "SELECT description FROM issues WHERE id='failing-issue-id'")

# Invoke directly
echo "${SYSTEM}\n\n${TASK}" | claude --model claude-opus-4-5 --output-format json
```

For `http` adapter:
```bash
curl -X POST http://your-endpoint/api/generate \
  -H "Content-Type: application/json" \
  -d '{"prompt": "test prompt", "model": "llama3"}'
```

## Step 4 — Read the Server Logs

In development, the API server logs each heartbeat tick:

```
[HEARTBEAT] company=acme tick=started
[HEARTBEAT] agent=Researcher issue=pcl-001 status=claimed
[HEARTBEAT] agent=Researcher adapter=invoke started
[ADAPTER:claude-code] spawn pid=12345
[ADAPTER:claude-code] exit code=1 stderr="ENOENT: claude not found"
[HEARTBEAT] agent=Researcher issue=pcl-001 status=failed attempt=1/3
[HEARTBEAT] company=acme tick=completed agents=1 resolved=0 failed=1
```

## Common Errors and Fixes

| Error | Fix |
|-------|-----|
| `ENOENT: claude not found` | `npm install -g @anthropic-ai/claude-code` |
| `401 Unauthorized` | Verify `ANTHROPIC_API_KEY` in `.env` |
| `429 Too Many Requests` | Reduce `max_concurrent_agents` |
| `JSON parse error` | Check adapter `--output-format json` flag |
| `company_paused` (skip) | Check monthly budget; reset: `UPDATE companies SET paused=false` |
| `no_open_issues` (skip) | Seed issues or verify agent assignment |

## Checkpoint ✓

- [ ] You can query `heartbeat_runs.error_detail` and interpret the JSON
- [ ] You can reproduce a failing `claude-code` adapter call in the terminal
- [ ] You know the five most common errors and their fixes
$md$ WHERE slug = 'pcl-42-debugging-runs';

-- ─── pcl-43-persistent-sessions ──────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Persistent Agent Sessions

## What you'll learn
What persistent sessions are, how they differ from stateless invocations, and when to use them for agents that need memory across tasks.

## Stateless vs Persistent

By default, every heartbeat invocation is **stateless**: the agent receives the system prompt + task description, returns an answer, and forgets everything. The next invocation starts fresh.

**Persistent sessions** maintain conversation history across invocations. The agent remembers what it did before — useful for agents that build on previous work.

## When to Use Persistent Sessions

| Stateless (default) | Persistent session |
|--------------------|-------------------|
| Independent research tasks | Long-running project work |
| Classification / labelling | Code reviews across multiple PRs |
| Content generation | Ongoing customer interactions |
| High volume, low cost | Lower volume, context-rich |

## Enabling Persistent Sessions

In `adapter_config`:

```json
{
  "adapter_type": "claude-code",
  "adapter_config": {
    "model": "claude-opus-4-5",
    "session_mode": "persistent",
    "session_ttl_hours": 24
  }
}
```

With `session_mode = 'persistent'`, Paperclip:
1. Creates a session ID on first invocation
2. Stores the conversation history in the database (or in-memory for sandbox)
3. Passes prior turns as context on subsequent invocations
4. Expires the session after `session_ttl_hours` of inactivity

## Session Storage

For `claude-code` persistent sessions, history is stored in:

**Sandbox (PGlite):**
```
.paperclip/sessions/{agent_id}/{session_id}.json
```

**Production (PostgreSQL):**
```sql
CREATE TABLE agent_sessions (
  id         uuid PRIMARY KEY,
  agent_id   uuid NOT NULL REFERENCES agents(id),
  company_id uuid NOT NULL,
  history    jsonb NOT NULL DEFAULT '[]',
  created_at timestamptz DEFAULT now(),
  last_used  timestamptz DEFAULT now(),
  expires_at timestamptz
);
```

## Viewing Session History

```bash
# Via API
curl http://localhost:3100/api/companies/${COMPANY_ID}/agents/${AGENT_ID}/sessions

# Response:
{
  "sessions": [{
    "id": "sess_...",
    "message_count": 12,
    "created_at": "...",
    "last_used": "...",
    "expires_at": "..."
  }]
}
```

## Clearing a Session

When you want the agent to start fresh (e.g. after a project phase ends):

```bash
curl -X DELETE \
  http://localhost:3100/api/companies/${COMPANY_ID}/agents/${AGENT_ID}/sessions/${SESSION_ID}
```

## Token Budget Considerations

Persistent sessions increase token consumption because prior turns count as input tokens. Monitor with:

```sql
SELECT
  date_trunc('day', ce.created_at) AS day,
  SUM(ce.input_tokens)  AS total_input,
  SUM(ce.output_tokens) AS total_output,
  SUM(ce.cost_usd)      AS daily_cost
FROM cost_events ce
WHERE ce.agent_id = 'your-agent-id'
GROUP BY day
ORDER BY day DESC;
```

If input tokens grow linearly each day, the session context window is accumulating history. Set a lower `session_ttl_hours` or implement context summarization.

## Checkpoint ✓

- [ ] You understand the difference between stateless and persistent invocations
- [ ] You can enable persistent sessions via `adapter_config`
- [ ] You know how to clear a session and why growing input tokens indicate accumulation
$md$ WHERE slug = 'pcl-43-persistent-sessions';

-- ─── pcl-44-custom-triggers ──────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Custom Heartbeat Triggers

## What you'll learn
Supplement the cron schedule with event-based triggers — fire the heartbeat when a webhook arrives, a database row changes, or a human presses a button.

## Why Custom Triggers

The cron heartbeat runs every N minutes regardless of whether work exists. Custom triggers let you react in near-real-time:

- A support ticket arrives → immediately process it
- A PR is opened in GitHub → immediately start code review
- A row is inserted in an external database → immediately classify it

## Trigger Types

Paperclip supports three trigger types beyond the cron:

| Type | How it fires |
|------|-------------|
| **Webhook trigger** | External system POSTs to a Paperclip endpoint |
| **Database trigger** | PostgreSQL NOTIFY → heartbeat listen |
| **Manual trigger** | API call or UI button |

## Webhook Trigger

Register a webhook URL per company. External systems POST to it:

```bash
# Your GitHub Actions workflow posts to this URL on PR opened:
curl -X POST https://your-paperclip.com/webhooks/your-company/github \
  -H "X-Hub-Signature-256: sha256=..." \
  -d '{"action": "opened", "pull_request": {"number": 42, ...}}'
```

Paperclip verifies the signature, extracts relevant data, creates an issue, and immediately fires a heartbeat tick for the company.

Configuration in Company Settings → Webhooks → New Webhook:
```json
{
  "source": "github",
  "events": ["pull_request.opened"],
  "auto_create_issue": true,
  "issue_template": {
    "title": "Review PR #{{payload.pull_request.number}}",
    "assigned_agent": "code-reviewer",
    "priority": "high"
  }
}
```

## Database NOTIFY Trigger

For internal Paperclip-to-Paperclip automation, use PostgreSQL's NOTIFY system:

```sql
-- When a new row is inserted into an external table, notify Paperclip
CREATE OR REPLACE FUNCTION notify_paperclip_on_ticket()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_notify(
    'paperclip_trigger',
    json_build_object(
      'company_id', 'your-company-id',
      'event', 'ticket_created',
      'ticket_id', NEW.id,
      'subject', NEW.subject
    )::text
  );
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_ticket_insert
AFTER INSERT ON support_tickets
FOR EACH ROW EXECUTE FUNCTION notify_paperclip_on_ticket();
```

Paperclip listens on the `paperclip_trigger` channel:

```typescript
// packages/server/src/lib/heartbeat/listener.ts
db.listen('paperclip_trigger', async (payload) => {
  const data = JSON.parse(payload);
  await createIssueAndFire(data);
});
```

## Manual Trigger API

You already know this one — useful for CI/CD pipelines or developer tooling:

```bash
# Fire heartbeat for a specific company
curl -X POST http://localhost:3100/api/heartbeat/run \
  -H "Content-Type: application/json" \
  -d '{"company_id": "'${COMPANY_ID}'"}'
```

Add it to a GitHub Actions step to process CI results immediately:

```yaml
- name: Notify Paperclip
  run: |
    curl -X POST ${{ secrets.PAPERCLIP_URL }}/api/heartbeat/run \
      -H "Content-Type: application/json" \
      -d '{"company_id": "${{ secrets.COMPANY_ID }}"}'
```

## Checkpoint ✓

- [ ] You can describe all three custom trigger types
- [ ] You understand how webhook triggers create issues and fire the heartbeat
- [ ] You can write a PostgreSQL NOTIFY function for internal triggering
$md$ WHERE slug = 'pcl-44-custom-triggers';
