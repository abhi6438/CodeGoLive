-- =============================================================================
-- Paperclip AI — Module 4: Tasks, Issues & Workflows
-- Topics: pcl-28 through pcl-35
-- =============================================================================

-- ─── pcl-28-issue-model ──────────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# The Issue Model: Paperclip's Work Queue

## What you'll learn
Every field in the `issues` table, the six status states an issue moves through, and how issues relate to agents and heartbeat runs.

## Issues Are the Unit of Work

In Paperclip AI everything an agent does is represented as an **issue** — a persistent row in the database that describes a task, tracks its lifecycle, and records the result. This is the central design decision: work is durable and auditable by default.

## The Full `issues` Table

```sql
CREATE TABLE public.issues (
  id                  uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id          uuid        NOT NULL REFERENCES companies(id),
  title               text        NOT NULL,
  description         text,
  status              text        NOT NULL DEFAULT 'open'
                                  CHECK (status IN ('open','claimed','in_progress','resolved','escalated','cancelled')),
  priority            text        NOT NULL DEFAULT 'medium'
                                  CHECK (priority IN ('low','medium','high','critical')),
  assigned_agent_id   uuid        REFERENCES agents(id),
  parent_issue_id     uuid        REFERENCES issues(id),    -- for subtasks
  result              text,                                  -- agent output
  result_structured   jsonb,                                 -- parsed result
  heartbeat_run_id    uuid        REFERENCES heartbeat_runs(id),
  attempt_count       int         NOT NULL DEFAULT 0,
  max_attempts        int         NOT NULL DEFAULT 3,
  created_at          timestamptz NOT NULL DEFAULT now(),
  claimed_at          timestamptz,
  resolved_at         timestamptz,
  due_at              timestamptz,
  metadata            jsonb
);
```

## Status Lifecycle

```
open
 │
 ├─ claimed      (heartbeat has selected this issue; agent about to run)
 │
 ├─ in_progress  (adapter invoke called; waiting for result)
 │
 ├─ resolved     (agent returned output; work done)
 │
 ├─ escalated    (agent could not complete; requires human or manager review)
 │
 └─ cancelled    (manually cancelled; will not be retried)
```

The transition `open → claimed → in_progress` happens within a single heartbeat tick using the atomic checkout pattern (covered in detail in pcl-30).

## Priority Queue Ordering

Issues are claimed in priority order within each heartbeat tick:

```sql
-- Simplified version of the heartbeat query
SELECT *
FROM issues
WHERE company_id = $1
  AND status = 'open'
  AND assigned_agent_id = $2
ORDER BY
  CASE priority
    WHEN 'critical' THEN 1
    WHEN 'high'     THEN 2
    WHEN 'medium'   THEN 3
    WHEN 'low'      THEN 4
  END,
  created_at ASC
LIMIT 1
FOR UPDATE SKIP LOCKED;
```

## The `parent_issue_id` Field

Issues can have subtasks. Set `parent_issue_id` to create a hierarchy:

```sql
-- Parent: write a blog post
INSERT INTO issues (company_id, title, assigned_agent_id)
VALUES ('...', 'Write a blog post about PostgreSQL', '...')
RETURNING id;

-- Child tasks
INSERT INTO issues (company_id, title, parent_issue_id, assigned_agent_id)
VALUES
  ('...', 'Research: gather 5 key PostgreSQL facts',          'parent-id', 'researcher-id'),
  ('...', 'Outline: create 5-section blog outline',           'parent-id', 'planner-id'),
  ('...', 'Draft: write full blog post from outline',         'parent-id', 'writer-id');
```

## The `metadata` Field

Store arbitrary structured data alongside an issue without schema changes:

```sql
UPDATE issues SET metadata = jsonb_build_object(
  'source',     'slack',
  'channel_id', 'C01234',
  'requester',  'alice@company.com',
  'tags',       ARRAY['blog', 'technical']
)
WHERE id = 'issue-id';
```

## Checkpoint ✓

- [ ] You can name all six status values and the transitions between them
- [ ] You understand `parent_issue_id` and how to create subtask hierarchies
- [ ] You know how priority affects claim order in the heartbeat
$md$ WHERE slug = 'pcl-28-issue-model';

-- ─── pcl-29-hierarchical-tasks ───────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Hierarchical Tasks and Subtask Patterns

## What you'll learn
Design multi-step workflows using parent/child issue relationships, implement a manager-delegates-to-workers pattern, and query task progress across a hierarchy.

## The Delegation Pattern

The most common hierarchical pattern: a high-level issue is assigned to a manager agent, which breaks it into subtasks and assigns each subtask to a specialist worker agent.

### Step 1 — Create the Parent Issue

```sql
INSERT INTO issues (company_id, title, description, assigned_agent_id, priority)
VALUES (
  'company-id',
  'Build launch checklist for v2.0',
  'Create a complete launch readiness checklist covering engineering, marketing, and support.',
  'manager-agent-id',
  'high'
)
RETURNING id;
-- returns: parent_id = 'abc-123'
```

### Step 2 — Manager Agent Breaks It Down

The manager agent's system prompt instructs it to decompose parent tasks. Its result (stored in `issues.result`) contains a JSON array of subtasks, which a Paperclip post-processor automatically creates as child issues:

```json
{
  "subtasks": [
    {
      "title": "Engineering: verify all tests pass",
      "agent_role": "Backend Developer",
      "priority": "critical"
    },
    {
      "title": "Marketing: prepare launch announcement",
      "agent_role": "Content Writer",
      "priority": "high"
    }
  ]
}
```

Enable subtask decomposition in Company Settings → Workflows → **Auto-create subtasks from structured results**.

### Step 3 — Workers Pick Up Subtasks

In the next heartbeat tick, each worker agent (Backend Dev, Content Writer) finds its assigned subtask in the open queue and works it.

## Querying Task Progress

```sql
-- Parent issue with subtask completion counts
SELECT
  parent.title,
  parent.status            AS parent_status,
  COUNT(child.id)          AS total_subtasks,
  COUNT(child.id) FILTER (WHERE child.status = 'resolved')  AS done,
  COUNT(child.id) FILTER (WHERE child.status = 'open')      AS open,
  COUNT(child.id) FILTER (WHERE child.status = 'in_progress') AS running
FROM issues parent
LEFT JOIN issues child ON child.parent_issue_id = parent.id
WHERE parent.company_id = 'your-company-id'
  AND parent.parent_issue_id IS NULL  -- only top-level
GROUP BY parent.id, parent.title, parent.status
ORDER BY parent.created_at DESC;
```

## Recursive Hierarchy Query

For deeply nested tasks (grandparent → parent → child):

```sql
WITH RECURSIVE task_tree AS (
  -- Base: top-level issues
  SELECT id, title, status, parent_issue_id, 0 AS depth
  FROM issues
  WHERE company_id = 'your-company-id'
    AND parent_issue_id IS NULL

  UNION ALL

  -- Recursive: children
  SELECT i.id, i.title, i.status, i.parent_issue_id, tt.depth + 1
  FROM issues i
  JOIN task_tree tt ON tt.id = i.parent_issue_id
)
SELECT repeat('  ', depth) || title AS indented_title, status
FROM task_tree
ORDER BY depth, title;
```

## Auto-Closing Parents

Configure a trigger to resolve the parent issue automatically when all children are resolved:

```sql
CREATE OR REPLACE FUNCTION close_parent_if_all_children_done()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  -- If all siblings are resolved, resolve the parent
  IF NOT EXISTS (
    SELECT 1 FROM issues
    WHERE parent_issue_id = NEW.parent_issue_id
      AND status NOT IN ('resolved', 'cancelled')
  ) THEN
    UPDATE issues SET status = 'resolved', resolved_at = now()
    WHERE id = NEW.parent_issue_id;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER auto_close_parent
AFTER UPDATE OF status ON issues
FOR EACH ROW
WHEN (NEW.status = 'resolved' AND NEW.parent_issue_id IS NOT NULL)
EXECUTE FUNCTION close_parent_if_all_children_done();
```

## Checkpoint ✓

- [ ] You can create a parent issue and seed subtasks against it
- [ ] You can query per-parent subtask completion counts
- [ ] You understand how auto-close triggers work
$md$ WHERE slug = 'pcl-29-hierarchical-tasks';

-- ─── pcl-30-atomic-checkout ──────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Atomic Task Checkout: Preventing Double Work

## What you'll learn
How Paperclip uses a single `UPDATE...RETURNING` statement to claim tasks without race conditions, why this works under concurrent heartbeat runs, and how to verify it in your own queries.

## The Problem: Two Heartbeats, One Task

Without coordination, two concurrent heartbeat runs could both query for open issues, both find the same task, and both invoke the same agent — resulting in duplicate work and double billing.

## The Solution: Single-Statement Claim

Paperclip uses PostgreSQL's atomic update:

```sql
UPDATE issues
SET
  status     = 'claimed',
  claimed_at = now()
WHERE id = (
  SELECT id
  FROM issues
  WHERE company_id   = $1
    AND assigned_agent_id = $2
    AND status       = 'open'
  ORDER BY
    CASE priority
      WHEN 'critical' THEN 1 WHEN 'high' THEN 2
      WHEN 'medium'   THEN 3 WHEN 'low'  THEN 4
    END, created_at ASC
  LIMIT 1
  FOR UPDATE SKIP LOCKED   -- ← the key clause
)
RETURNING *;
```

### Why This Is Safe

`FOR UPDATE SKIP LOCKED` acquires a row-level lock on the selected row. Any concurrent transaction attempting `FOR UPDATE` on the same row will **skip** it rather than waiting. This means:

- Transaction A claims row 5 (locks it)
- Transaction B runs the same query, skips row 5, claims row 6 instead
- No deadlock, no wait, no duplicate work

The claim is atomic: the `SELECT` and `UPDATE` happen in a single statement — there is no window between "I found it" and "I locked it."

## Verifying No Duplicates

After running multiple concurrent heartbeats in development:

```sql
-- Check for any issue that was claimed more than once in the same run
SELECT issue_id, COUNT(*) AS claim_count
FROM heartbeat_run_items   -- a view or junction table if your schema has one
GROUP BY issue_id
HAVING COUNT(*) > 1;

-- Or check for issues resolved multiple times
SELECT id, title, attempt_count
FROM issues
WHERE attempt_count > 1
  AND company_id = 'your-company-id'
ORDER BY attempt_count DESC;
```

The `attempt_count` column is incremented each time an issue enters `in_progress`. A value above 1 means the issue was retried (due to failure), not duplicated.

## The `attempt_count` Guard

```sql
-- Heartbeat also checks max_attempts before claiming
UPDATE issues
SET status = 'claimed', claimed_at = now(), attempt_count = attempt_count + 1
WHERE id = (
  SELECT id FROM issues
  WHERE ...
    AND attempt_count < max_attempts   -- ← guard
  FOR UPDATE SKIP LOCKED
)
RETURNING *;
```

When `attempt_count >= max_attempts`, the issue is moved to `escalated` rather than retried:

```sql
UPDATE issues
SET status = 'escalated'
WHERE status = 'open'
  AND attempt_count >= max_attempts
  AND company_id = $1;
```

## Testing Concurrency Locally

```bash
# Run 3 heartbeats simultaneously
for i in 1 2 3; do
  curl -s -X POST http://localhost:3100/api/heartbeat/run \
    -H "Content-Type: application/json" \
    -d '{"company_id": "'${COMPANY_ID}'"}' &
done
wait

# Verify: each issue resolved exactly once
psql $DATABASE_URL -c "
  SELECT attempt_count, COUNT(*) FROM issues
  WHERE company_id = '${COMPANY_ID}'
  GROUP BY attempt_count;"
```

## Checkpoint ✓

- [ ] You can explain why `FOR UPDATE SKIP LOCKED` prevents double-work
- [ ] You understand `attempt_count` vs `max_attempts` and the escalation path
- [ ] You can run concurrent heartbeats and verify no duplicates
$md$ WHERE slug = 'pcl-30-atomic-checkout';

-- ─── pcl-31-task-lifecycle ───────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# The Full Task Lifecycle

## What you'll learn
Trace an issue from creation to resolution through every state transition, understand what records are created at each step, and build a timeline view from the database.

## Complete State Machine

```
CREATED
  │  INSERT INTO issues (status='open')
  ▼
OPEN
  │  Heartbeat claims it: UPDATE status='claimed'
  ▼
CLAIMED
  │  Adapter invoke starts: UPDATE status='in_progress'
  ▼
IN_PROGRESS
  │
  ├─ Adapter succeeds ──────────► RESOLVED
  │    UPDATE status='resolved', result=..., resolved_at=now()
  │    INSERT INTO cost_events (...)
  │
  ├─ Adapter fails, retry ──────► OPEN (attempt_count++)
  │    UPDATE status='open'
  │
  ├─ Max attempts exceeded ─────► ESCALATED
  │    UPDATE status='escalated'
  │    INSERT INTO approvals (trigger='task_failed', ...)
  │
  └─ Manual cancel ─────────────► CANCELLED
       UPDATE status='cancelled'
```

## What Each Transition Creates

| Transition | Database records created |
|-----------|------------------------|
| `open` → `claimed` | `issues.claimed_at` set |
| `claimed` → `in_progress` | `heartbeat_runs` row updated with this issue |
| `in_progress` → `resolved` | `issues.result` set; `cost_events` row inserted |
| `in_progress` → `escalated` | `approvals` row inserted |

## Building a Timeline View

```sql
SELECT
  'Created'                        AS event,
  i.created_at                     AS occurred_at,
  NULL                             AS details
FROM issues i WHERE i.id = 'issue-id'

UNION ALL

SELECT
  'Claimed by heartbeat',
  i.claimed_at,
  'Heartbeat run: ' || i.heartbeat_run_id::text
FROM issues i WHERE i.id = 'issue-id' AND i.claimed_at IS NOT NULL

UNION ALL

SELECT
  'Resolved',
  i.resolved_at,
  'Cost: $' || ce.cost_usd::text
FROM issues i
JOIN cost_events ce ON ce.issue_id = i.id
WHERE i.id = 'issue-id' AND i.resolved_at IS NOT NULL

ORDER BY occurred_at;
```

## Retry Behaviour in Detail

When an adapter call fails (exception thrown or non-zero exit), the heartbeat:

1. Sets `issues.status = 'open'` and increments `attempt_count`
2. Logs the error in `heartbeat_runs.error_detail` (JSON array)
3. Does NOT immediately retry — the issue re-enters the open queue
4. Next heartbeat tick will pick it up again (if `attempt_count < max_attempts`)

This means a failed issue is retried on the **next heartbeat tick**, not immediately. For a 5-minute heartbeat with `max_attempts = 3`, a repeatedly-failing issue will be retried at T+5m and T+10m before escalating.

## Adjusting Retry Limits Per Issue

```sql
-- Give a complex issue more retries
UPDATE issues
SET max_attempts = 5
WHERE id = 'issue-id';

-- Reset a stuck issue
UPDATE issues
SET status = 'open', attempt_count = 0
WHERE id = 'issue-id';
```

## Checkpoint ✓

- [ ] You can draw the full state machine from memory
- [ ] You understand what database records are created at each transition
- [ ] You know how to reset a stuck issue and adjust retry limits
$md$ WHERE slug = 'pcl-31-task-lifecycle';

-- ─── pcl-32-delegation ───────────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Task Delegation Patterns

## What you'll learn
Three delegation patterns used in real Paperclip companies: fan-out, sequential pipeline, and manager-as-router.

## Pattern 1: Fan-Out

One parent task splits into N parallel subtasks. All subtasks can run in the same or different heartbeat ticks (Paperclip processes multiple agents per tick).

```
Parent: "Write a complete technical blog post"
  ├── Subtask A: Research (→ Researcher)
  ├── Subtask B: SEO keywords (→ SEO Agent)
  └── Subtask C: Title options (→ Copywriter)
```

SQL seed:
```sql
DO $$
DECLARE parent_id uuid;
BEGIN
  INSERT INTO issues (company_id, title, assigned_agent_id, status)
  VALUES ('cid', 'Write blog post: Intro to RAG', 'manager-id', 'resolved')
  RETURNING id INTO parent_id;
  -- Manager is pre-resolved; subtasks are the real work

  INSERT INTO issues (company_id, title, parent_issue_id, assigned_agent_id, status)
  VALUES
    ('cid', 'Research: gather 5 RAG facts',   parent_id, 'researcher-id', 'open'),
    ('cid', 'SEO: find 10 keyword targets',    parent_id, 'seo-id',        'open'),
    ('cid', 'Copywriting: draft 5 title ideas', parent_id, 'writer-id',    'open');
END $$;
```

All three subtasks are `open` simultaneously — the heartbeat can claim them in parallel (one per tick if `max_concurrent_agents = 3`).

## Pattern 2: Sequential Pipeline

Each step depends on the previous. Implemented by creating each subtask only after the previous resolves — either via a trigger or a coordinator agent.

```
Step 1: Researcher → result stored in issues.result
Step 2: Writer uses Researcher result (reads from parent/sibling)
Step 3: Editor uses Writer result
```

Trigger approach — create step 2 when step 1 resolves:
```sql
CREATE OR REPLACE FUNCTION create_pipeline_next()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  -- When step 1 resolves, create step 2
  IF NEW.title LIKE 'Step 1:%' AND NEW.status = 'resolved' THEN
    INSERT INTO issues (company_id, title, parent_issue_id, assigned_agent_id,
                        description, status)
    VALUES (
      NEW.company_id,
      'Step 2: Write draft from research',
      NEW.parent_issue_id,
      (SELECT id FROM agents WHERE role = 'Writer' AND company_id = NEW.company_id LIMIT 1),
      'Research notes: ' || LEFT(NEW.result, 500),
      'open'
    );
  END IF;
  RETURN NEW;
END;
$$;
```

## Pattern 3: Manager as Router

A manager agent reads the incoming task and creates the right subtasks dynamically. The manager's system prompt tells it to output a JSON subtask list:

```
You are a Task Router. Given a high-level task, decompose it into specific subtasks.
Output ONLY valid JSON in this format:
{
  "subtasks": [
    {"title": "...", "agent_role": "...", "priority": "medium"}
  ]
}
```

Paperclip parses the JSON result and auto-creates issues for each subtask, assigned to agents matching `agent_role`.

## Choosing a Pattern

| Pattern | When to use |
|---------|------------|
| Fan-out | Independent parallel work, no data dependency |
| Sequential pipeline | Each step needs previous step's output |
| Manager as router | Dynamic task decomposition, unknown structure upfront |

## Checkpoint ✓

- [ ] You can implement fan-out by seeding parallel subtasks
- [ ] You understand the sequential pipeline trigger approach
- [ ] You know when a manager-as-router is the right choice
$md$ WHERE slug = 'pcl-32-delegation';

-- ─── pcl-33-priority-queues ──────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Priority Queues and Scheduling

## What you'll learn
How priority ordering works in the heartbeat queue, how to use `due_at` for time-based scheduling, and how to implement a fair-use queue across multiple agents.

## The Four Priority Levels

```
critical → processed first
high     → before medium
medium   → default
low      → when nothing else is waiting
```

Within the same priority level, issues are claimed in `created_at ASC` order (FIFO).

## Setting Priority

```bash
# Via API
curl -X POST http://localhost:3100/api/companies/${COMPANY_ID}/issues \
  -d '{"title": "...", "priority": "critical", "assigned_agent_id": "..."}'

# Via SQL
INSERT INTO issues (company_id, title, priority, assigned_agent_id, status)
VALUES ('cid', 'URGENT: fix broken API endpoint', 'critical', 'dev-id', 'open');
```

## Time-Based Scheduling with `due_at`

Issues with a `due_at` timestamp are not claimed until that time arrives. This enables scheduling:

```sql
-- Schedule a daily report issue for 09:00 UTC tomorrow
INSERT INTO issues (company_id, title, assigned_agent_id, due_at, status)
VALUES (
  'cid',
  'Generate daily activity report',
  'reporter-id',
  (now() + interval '1 day')::date + interval '9 hours',
  'open'
);
```

The heartbeat query adds:
```sql
AND (due_at IS NULL OR due_at <= now())
```

This makes scheduled issues invisible to the queue until their time.

## Recurring Tasks

Paperclip does not have a built-in cron for issues, but you can create recurring issues using a "scheduler agent":

```
Scheduler Agent (shell adapter, runs every heartbeat tick):
  - Checks if a 'daily report' issue exists for today
  - If not, creates one
  - Low priority, lightweight
```

Or seed recurring issues directly:

```sql
-- Create 7 daily report issues for the coming week
INSERT INTO issues (company_id, title, assigned_agent_id, due_at, priority, status)
SELECT
  'cid',
  'Daily report: ' || to_char(d, 'YYYY-MM-DD'),
  'reporter-id',
  d + interval '9 hours',
  'low',
  'open'
FROM generate_series(now()::date, now()::date + interval '6 days', interval '1 day') AS d;
```

## Fair-Use Queuing Across Agents

By default, the heartbeat processes one issue per agent per tick. With many agents and many issues, this is naturally fair. To limit an agent to N issues per tick:

```sql
-- In adapter_config, add:
{
  "max_issues_per_tick": 2
}
```

Or limit at the company level in heartbeat settings.

## Monitoring Queue Depth

```sql
SELECT
  a.name,
  COUNT(*) FILTER (WHERE i.priority = 'critical') AS critical,
  COUNT(*) FILTER (WHERE i.priority = 'high')     AS high,
  COUNT(*) FILTER (WHERE i.priority = 'medium')   AS medium,
  COUNT(*) FILTER (WHERE i.priority = 'low')      AS low,
  COUNT(*)                                         AS total
FROM issues i
JOIN agents a ON a.id = i.assigned_agent_id
WHERE i.company_id = 'your-company-id'
  AND i.status = 'open'
GROUP BY a.name
ORDER BY total DESC;
```

## Checkpoint ✓

- [ ] You can create issues with different priorities and observe claim order
- [ ] You understand `due_at` and can schedule a future issue
- [ ] You can query queue depth per agent
$md$ WHERE slug = 'pcl-33-priority-queues';

-- ─── pcl-34-bulk-seeding ─────────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Bulk-Seeding Issues from External Data

## What you'll learn
Load large batches of issues from CSV files, JSON feeds, or external APIs — practical patterns for populating a real work queue.

## Why Bulk Seeding

When you connect Paperclip to a real data source (a support ticket system, a content backlog, a code review queue), you need to import tens or hundreds of issues at a time, not create them one by one.

## Loading from a CSV

Given `tasks.csv`:
```csv
title,description,priority
"Review PR #42","Check for security issues in auth module","high"
"Write test for payment flow","Unit tests for checkout","medium"
"Update docs: API endpoints","Reflect new v2 routes","low"
```

```sql
-- Create a staging table
CREATE TEMP TABLE task_import (
  title       text,
  description text,
  priority    text
);

-- Load CSV
\COPY task_import FROM '/tmp/tasks.csv' CSV HEADER;

-- Insert into issues, assigned to the right agent
INSERT INTO issues (company_id, title, description, priority, assigned_agent_id, status)
SELECT
  'your-company-id',
  ti.title,
  ti.description,
  ti.priority,
  (SELECT id FROM agents WHERE role = 'Backend Developer' AND company_id = 'your-company-id' LIMIT 1),
  'open'
FROM task_import ti
ON CONFLICT DO NOTHING;
```

## Loading from a JSON Array

```bash
# tasks.json: [{"title":"...", "priority":"high"}, ...]
psql $DATABASE_URL << 'SQL'
INSERT INTO issues (company_id, title, priority, assigned_agent_id, status)
SELECT
  'your-company-id',
  (item->>'title')::text,
  COALESCE((item->>'priority')::text, 'medium'),
  (SELECT id FROM agents WHERE role = 'Researcher' LIMIT 1),
  'open'
FROM jsonb_array_elements(pg_read_file('/tmp/tasks.json')::jsonb) AS item
ON CONFLICT DO NOTHING;
SQL
```

## Loading from the API with a Script

```typescript
// scripts/seed-issues.ts
import fs from 'fs';

const COMPANY_ID = process.env.COMPANY_ID!;
const AGENT_ID   = process.env.AGENT_ID!;
const API_BASE   = 'http://localhost:3100';

const tasks = JSON.parse(fs.readFileSync('tasks.json', 'utf8'));

for (const task of tasks) {
  const res = await fetch(`${API_BASE}/api/companies/${COMPANY_ID}/issues`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      title:             task.title,
      description:       task.description,
      priority:          task.priority ?? 'medium',
      assigned_agent_id: AGENT_ID,
    }),
  });
  const data = await res.json();
  console.log(`Created: ${data.id} — ${task.title}`);
}
```

## Avoiding Duplicate Seeds

Use idempotent seeding with a unique key from your source:

```sql
-- Store external ID in metadata
INSERT INTO issues (company_id, title, metadata, status)
VALUES ('cid', 'Task from Jira PROJ-42', '{"jira_id": "PROJ-42"}', 'open')
ON CONFLICT ((metadata->>'jira_id')) DO NOTHING;

-- Requires a partial unique index:
CREATE UNIQUE INDEX idx_issues_jira_id
ON issues ((metadata->>'jira_id'))
WHERE metadata->>'jira_id' IS NOT NULL;
```

## Checkpoint ✓

- [ ] You can load issues from a CSV file using `\COPY` and an INSERT/SELECT
- [ ] You understand how to use `metadata` for idempotent external-ID seeding
- [ ] You can write a TypeScript bulk-seed script
$md$ WHERE slug = 'pcl-34-bulk-seeding';

-- ─── pcl-35-workflow-patterns ────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Real-World Workflow Patterns

## What you'll learn
Six proven workflow patterns that real Paperclip companies use, with SQL and configuration examples for each.

## Pattern 1: The Research Pipeline

```
Input issue → Researcher → Writer → Editor → Final output
```

Each step reads the previous step's `result` and produces its own. Implemented as a sequential pipeline (trigger-based, covered in pcl-32).

**Useful for:** blog posts, reports, research briefs, documentation.

## Pattern 2: The Review Loop

```
Writer creates draft → Editor reviews →
  approved: mark resolved
  rejected: Writer revises
```

```sql
-- Review loop: editor flags rejection in result JSON
-- {"status": "rejected", "feedback": "needs more examples"}
-- Trigger creates a revision issue

CREATE OR REPLACE FUNCTION handle_review_result() RETURNS TRIGGER AS $$
DECLARE
  result_json jsonb;
BEGIN
  result_json := NEW.result::jsonb;
  IF result_json->>'status' = 'rejected' THEN
    INSERT INTO issues (company_id, title, description, assigned_agent_id, parent_issue_id, status)
    VALUES (
      NEW.company_id,
      'Revision: ' || (SELECT title FROM issues WHERE id = NEW.parent_issue_id),
      'Editor feedback: ' || (result_json->>'feedback'),
      (SELECT assigned_agent_id FROM issues WHERE id = NEW.parent_issue_id),
      NEW.parent_issue_id,
      'open'
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

## Pattern 3: The Quality Gate

Before any output is marked "done," it passes through a quality-check agent:

```
Worker resolves issue → Quality Agent checks result →
  pass: final status = 'verified'
  fail: back to worker as revision
```

Enable in Company Settings → Workflows → **Quality gate agent**.

## Pattern 4: The Inbox Processor

A high-volume agent continuously processes a feed of incoming items (emails, support tickets, social mentions):

```sql
-- Feed items are inserted as issues by an external webhook
-- Processor agent claims them in FIFO order, classifies/responds
INSERT INTO issues (company_id, title, metadata, priority, assigned_agent_id)
VALUES (
  'cid',
  'Support ticket: ' || ticket_id,
  jsonb_build_object('ticket_id', ticket_id, 'channel', 'email'),
  'medium',
  'support-agent-id'
);
```

## Pattern 5: The Monitoring Loop

An agent runs on a schedule, checks an external condition, and creates action issues when something needs attention:

```
Monitor Agent (every 5 min) → checks metrics API →
  if error_rate > 5%: create CRITICAL issue for On-Call Agent
```

## Pattern 6: The Cost-Aware Downgrade

When budget is low, automatically switch from expensive to cheap models:

```sql
-- View: agents with <20% budget remaining
CREATE VIEW budget_strained_agents AS
SELECT a.id, a.name,
       SUM(ce.cost_usd) AS spent,
       a.monthly_budget_usd,
       ROUND(100 * SUM(ce.cost_usd) / a.monthly_budget_usd) AS pct_used
FROM agents a
JOIN cost_events ce ON ce.agent_id = a.id
WHERE ce.created_at >= date_trunc('month', now())
GROUP BY a.id
HAVING ROUND(100 * SUM(ce.cost_usd) / a.monthly_budget_usd) >= 80;
```

Pair with a shell agent that patches `adapter_config.model` to a cheaper model.

## Checkpoint ✓

- [ ] You can describe at least three of the six workflow patterns
- [ ] You understand the review loop trigger pattern
- [ ] You know how the quality gate differs from the review loop
$md$ WHERE slug = 'pcl-35-workflow-patterns';
