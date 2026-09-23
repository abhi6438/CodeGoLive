-- =============================================================================
-- Paperclip AI — Module 6: Cost & Governance
-- Topics: pcl-45 through pcl-52
-- =============================================================================

-- ─── pcl-45-cost-model ───────────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# The Cost Model: How Paperclip Tracks Spending

## What you'll learn
The complete `cost_events` table, how costs are calculated per model, and the two-layer budget system (per-agent and per-company).

## Every LLM Call Costs Money

Paperclip's cost model has one rule: **every adapter invocation that uses tokens creates a `cost_events` row**. This makes the audit trail complete and the budget enforcement reliable.

## The `cost_events` Table

```sql
CREATE TABLE public.cost_events (
  id               uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id       uuid        NOT NULL REFERENCES companies(id),
  agent_id         uuid        NOT NULL REFERENCES agents(id),
  heartbeat_run_id uuid        REFERENCES heartbeat_runs(id),
  issue_id         uuid        REFERENCES issues(id),
  model            text        NOT NULL,
  input_tokens     int         NOT NULL DEFAULT 0,
  output_tokens    int         NOT NULL DEFAULT 0,
  cost_usd         numeric(10,6) NOT NULL DEFAULT 0,
  created_at       timestamptz NOT NULL DEFAULT now()
);
```

## How Cost Is Calculated

Each adapter reports `inputTokens`, `outputTokens`, and `model`. Paperclip multiplies by the per-model rate in `pricing.ts`:

```typescript
// packages/server/src/lib/costs/pricing.ts
export type TokenPricing = { input: number; output: number }; // per 1K tokens

export const PRICING: Record<string, TokenPricing> = {
  'claude-opus-4-5':        { input: 0.015,   output: 0.075  },
  'claude-sonnet-4-5':      { input: 0.003,   output: 0.015  },
  'claude-haiku-3-5':       { input: 0.00025, output: 0.00125 },
  'gpt-4o':                 { input: 0.005,   output: 0.015  },
  'gpt-4o-mini':            { input: 0.00015, output: 0.0006 },
  'llama3-70b-8192':        { input: 0.00027, output: 0.00027 },
};

export function calculateCost(model: string, inputTokens: number, outputTokens: number): number {
  const pricing = PRICING[model];
  if (!pricing) return 0;
  return (inputTokens / 1000 * pricing.input) + (outputTokens / 1000 * pricing.output);
}
```

## The Two-Layer Budget System

```
Company budget ($50/month)
  ├── Agent: CEO         budget $20/month
  ├── Agent: Researcher  budget $15/month
  └── Agent: Writer      budget $10/month
```

**Agent-level enforcement**: before claiming a new issue, the heartbeat checks if the agent's MTD spend < `monthly_budget_usd`. If not, the agent is skipped (set to `paused`).

**Company-level enforcement**: when cumulative MTD company spend exceeds `companies.monthly_budget_usd`, the entire company is paused — no agents run until the month rolls over or the budget is raised.

## Querying MTD Spend

```sql
-- Current month spend per agent
SELECT
  a.name,
  a.monthly_budget_usd              AS budget,
  COALESCE(SUM(ce.cost_usd), 0)     AS spent,
  a.monthly_budget_usd
    - COALESCE(SUM(ce.cost_usd), 0) AS remaining,
  ROUND(100 * COALESCE(SUM(ce.cost_usd), 0)
    / NULLIF(a.monthly_budget_usd, 0)) AS pct_used
FROM agents a
LEFT JOIN cost_events ce
  ON ce.agent_id = a.id
  AND date_trunc('month', ce.created_at) = date_trunc('month', now())
WHERE a.company_id = 'your-company-id'
GROUP BY a.id, a.name, a.monthly_budget_usd
ORDER BY pct_used DESC NULLS LAST;
```

## Checkpoint ✓

- [ ] You can describe the `cost_events` table columns and their purpose
- [ ] You understand the two-layer (agent + company) budget system
- [ ] You can query MTD spend per agent with percentage used
$md$ WHERE slug = 'pcl-45-cost-model';

-- ─── pcl-46-budget-limits ────────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Setting and Adjusting Budget Limits

## What you'll learn
Best practices for setting initial budgets, how to raise or lower limits without downtime, and strategies for different organization sizes.

## Starting Safe

For a new company in development, start conservatively:

```sql
UPDATE companies
SET monthly_budget_usd = 15.00
WHERE slug = 'my-company';

-- Per-agent budgets that sum to 80% of company budget
UPDATE agents SET monthly_budget_usd = 5.00 WHERE name = 'Researcher';
UPDATE agents SET monthly_budget_usd = 4.00 WHERE name = 'Writer';
UPDATE agents SET monthly_budget_usd = 3.00 WHERE name = 'Editor';
-- Total agent budgets: $12 < company budget $15 ✓
```

Leave a 20% buffer between the sum of agent budgets and the company ceiling. This absorbs small overruns before triggering a company-wide pause.

## Estimating Budget

Rule of thumb per model per 1 000 tasks:

| Model | Avg tokens/task | Cost per 1K tasks |
|-------|----------------|------------------|
| claude-haiku-3-5 | 800 in / 400 out | ~$0.20 |
| claude-sonnet-4-5 | 800 in / 400 out | ~$2.40 + $6.00 = ~$8.40 |
| claude-opus-4-5 | 800 in / 400 out | ~$12 + $30 = ~$42 |
| gpt-4o-mini | 800 in / 400 out | ~$0.36 |

Start with Haiku or GPT-4o-mini for high-volume agents; upgrade to Opus/Sonnet only when quality demands it.

## Raising a Budget Live

```bash
# Via API — no restart needed
curl -X PATCH http://localhost:3100/api/companies/${COMPANY_ID} \
  -H "Content-Type: application/json" \
  -d '{"monthly_budget_usd": 50.00}'

# Unpause if the company was paused
curl -X PATCH http://localhost:3100/api/companies/${COMPANY_ID} \
  -H "Content-Type: application/json" \
  -d '{"paused": false}'
```

Changes take effect on the next heartbeat tick.

## Budget Alerts

Set up a webhook notification when spend reaches 80% of budget:

```json
{
  "webhook_url": "https://your-app.com/alerts",
  "events": ["budget.warning_80pct", "budget.exceeded"],
  "threshold_pct": 80
}
```

Or implement a scheduled SQL check:

```sql
-- Run this query daily; alert if any agent > 80% budget
SELECT name, monthly_budget_usd, spent, ROUND(pct_used) AS pct
FROM (
  SELECT a.name, a.monthly_budget_usd,
         SUM(ce.cost_usd) AS spent,
         100 * SUM(ce.cost_usd) / a.monthly_budget_usd AS pct_used
  FROM agents a
  JOIN cost_events ce ON ce.agent_id = a.id
    AND date_trunc('month', ce.created_at) = date_trunc('month', now())
  WHERE a.company_id = 'your-company-id'
  GROUP BY a.id, a.name, a.monthly_budget_usd
) t
WHERE pct_used >= 80;
```

## The Month Reset

On the 1st of each calendar month:
- All `cost_events` from the prior month are retained (audit trail)
- MTD spend is recalculated from scratch
- Paused agents automatically un-pause
- Company `paused` flag is reset if it was triggered only by budget

You can force an early reset in development:

```sql
-- Delete this month's cost events (dev only — destroys audit trail)
DELETE FROM cost_events
WHERE company_id = 'your-company-id'
  AND date_trunc('month', created_at) = date_trunc('month', now());

-- Unpause
UPDATE companies SET paused = false WHERE id = 'your-company-id';
UPDATE agents SET status = 'active'  WHERE company_id = 'your-company-id';
```

## Checkpoint ✓

- [ ] You can estimate a monthly budget for a given model and task volume
- [ ] You know how to raise a budget live without restarting
- [ ] You understand the automatic month reset behavior
$md$ WHERE slug = 'pcl-46-budget-limits';

-- ─── pcl-47-auto-pause ───────────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# The Auto-Pause Circuit Breaker

## What you'll learn
How Paperclip's auto-pause mechanism works at both the agent and company level, what triggers it, and how to resume safely.

## The Circuit Breaker Metaphor

Paperclip's budget enforcement is a circuit breaker: when spending exceeds the limit, the circuit "opens" (pauses) to prevent runaway costs. Once the situation is addressed (budget raised or month resets), the circuit "closes" (resumes).

```
Normal operation          →  Circuit closed (agents run)
MTD spend ≥ agent budget  →  Agent circuit opens (agent paused)
MTD spend ≥ company budget→  Company circuit opens (all agents paused)
Budget raised or month 1  →  Circuit closes (agents resume)
```

## Agent-Level Auto-Pause

Triggered when: `SUM(cost_events.cost_usd this month) >= agents.monthly_budget_usd`

When triggered:
```sql
UPDATE agents SET status = 'paused' WHERE id = 'agent-id';
```

The agent is skipped in all future heartbeat ticks until either:
- Budget is raised: `UPDATE agents SET monthly_budget_usd = 10 WHERE id = '...'`
- Agent is manually reactivated: `UPDATE agents SET status = 'active' WHERE id = '...'`
- Month resets (automatic)

## Company-Level Auto-Pause

Triggered when: `SUM(cost_events.cost_usd this month WHERE company_id=...) >= companies.monthly_budget_usd`

When triggered:
```sql
UPDATE companies SET paused = true WHERE id = 'company-id';
```

The heartbeat skips this company entirely — no agents run. Existing in-progress issues are allowed to complete (already claimed), but no new issues are claimed.

## Checking Pause State

```sql
SELECT
  c.name                    AS company,
  c.paused                  AS company_paused,
  c.monthly_budget_usd      AS company_budget,
  mtd.company_spend,
  ROUND(100 * mtd.company_spend / c.monthly_budget_usd) AS company_pct
FROM companies c
JOIN (
  SELECT company_id, SUM(cost_usd) AS company_spend
  FROM cost_events
  WHERE date_trunc('month', created_at) = date_trunc('month', now())
  GROUP BY company_id
) mtd ON mtd.company_id = c.id
WHERE c.id = 'your-company-id';
```

## Safe Resume Procedure

1. **Check why it paused** — was it a runaway agent or legitimate high usage?
2. **Review cost_events** — identify the expensive agent and task
3. **Adjust** — raise budget, fix prompt, or reduce frequency
4. **Unpause**:

```bash
# Raise budget
curl -X PATCH http://localhost:3100/api/companies/${COMPANY_ID} \
  -d '{"monthly_budget_usd": 100.00}'

# Unpause company
curl -X PATCH http://localhost:3100/api/companies/${COMPANY_ID} \
  -d '{"paused": false}'

# Reactivate paused agents
curl -X PATCH http://localhost:3100/api/companies/${COMPANY_ID}/agents/${AGENT_ID} \
  -d '{"status": "active"}'
```

5. **Monitor** — watch the next 3 heartbeat runs to confirm costs normalise.

## Hard Limit vs Soft Limit

Currently Paperclip implements a **hard limit** (stops completely at 100%). A soft limit (warn at 80%, stop at 100%) can be configured via the alert webhook described in pcl-46.

## Checkpoint ✓

- [ ] You can explain the two levels of auto-pause (agent + company)
- [ ] You know the SQL to check current pause state and MTD spend percentage
- [ ] You can safely resume a paused company after diagnosing the cause
$md$ WHERE slug = 'pcl-47-auto-pause';

-- ─── pcl-48-approval-gates ───────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Approval Gates: Human-in-the-Loop Control

## What you'll learn
The four default approval triggers, the `approvals` table schema, and how to configure custom approval policies for your organization.

## What Are Approval Gates?

Approval gates are moments where autonomous agent action is paused and a human (or higher-authority agent) must sign off before execution continues. They are the safety mechanism that lets you run autonomous agents while keeping critical decisions under human control.

## The Four Default Triggers

Paperclip ships with four built-in approval triggers that cannot be bypassed:

| Trigger | What requires approval |
|---------|----------------------|
| `hire_agent` | Creating a new agent in the company |
| `terminate_agent` | Setting an agent status to `terminated` |
| `budget_increase` | Raising `monthly_budget_usd` above current value |
| `strategy_change` | Modifying core company settings (webhook URLs, heartbeat schedule) |

These protect against runaway agents attempting to self-modify the company configuration.

## The `approvals` Table

```sql
CREATE TABLE public.approvals (
  id                    uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id            uuid        NOT NULL REFERENCES companies(id),
  trigger               text        NOT NULL,
  status                text        NOT NULL DEFAULT 'pending'
                                    CHECK (status IN ('pending','approved','rejected','expired')),
  requesting_agent_id   uuid        REFERENCES agents(id),
  reviewer_agent_id     uuid        REFERENCES agents(id),
  human_reviewer_email  text,
  details               jsonb,       -- what is being approved
  decision_note         text,        -- reviewer's comment
  created_at            timestamptz NOT NULL DEFAULT now(),
  expires_at            timestamptz,
  decided_at            timestamptz
);
```

## Creating a Custom Approval Policy

In Company Settings → Approval Policies → Add Policy:

```json
{
  "trigger": "publish_content",
  "condition": {
    "field": "word_count",
    "operator": "gt",
    "value": 1000
  },
  "required_approver": "human_editor",
  "expiry_hours": 48,
  "on_expire": "reject"
}
```

When a Writer agent finishes a 1200-word article, Paperclip:
1. Sets the issue to `status = 'escalated'` (not `resolved`)
2. Creates an `approvals` row with `trigger = 'publish_content'`
3. Notifies `human_editor` via webhook/email
4. If no decision within 48 hours, auto-rejects

## Querying Pending Approvals

```sql
SELECT
  ap.id,
  ap.trigger,
  ap.status,
  req.name   AS requested_by,
  ap.details,
  ap.created_at,
  ap.expires_at
FROM approvals ap
LEFT JOIN agents req ON req.id = ap.requesting_agent_id
WHERE ap.company_id = 'your-company-id'
  AND ap.status = 'pending'
ORDER BY ap.created_at ASC;
```

## Approving / Rejecting via API

```bash
# Approve
curl -X POST http://localhost:3100/api/companies/${COMPANY_ID}/approvals/${APPROVAL_ID}/approve \
  -d '{"note": "Looks good, content quality is acceptable"}'

# Reject
curl -X POST http://localhost:3100/api/companies/${COMPANY_ID}/approvals/${APPROVAL_ID}/reject \
  -d '{"note": "Title is misleading, needs rework"}'
```

On approval: the original action proceeds (issue resolved, agent hired, budget raised).
On rejection: the action is cancelled and the requesting agent receives the rejection note.

## Checkpoint ✓

- [ ] You can name the four default approval triggers and what they protect
- [ ] You understand the approval lifecycle: pending → approved/rejected/expired
- [ ] You can query pending approvals and approve/reject via the API
$md$ WHERE slug = 'pcl-48-approval-gates';

-- ─── pcl-49-approval-workflow ────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Building Approval Workflows

## What you'll learn
Design end-to-end approval workflows, chain approvals through multiple reviewers, and implement time-sensitive approval escalation.

## Single-Level Approval

The simplest case: agent creates work → human reviews → approved/rejected.

```
Writer Agent
  → resolves issue with draft
  → Paperclip creates approval (trigger: 'publish_content')
  → Human Editor notified via webhook
  → Human approves in Approvals UI
  → Issue status changes to 'verified'
  → Content published
```

## Two-Level Approval (Chained)

For sensitive decisions, require two approvers in sequence:

```json
{
  "trigger": "large_expenditure",
  "condition": { "field": "amount_usd", "operator": "gt", "value": 500 },
  "approvers": [
    { "level": 1, "role": "department_manager", "expiry_hours": 24 },
    { "level": 2, "role": "cfo",                "expiry_hours": 48 }
  ]
}
```

Level 2 approval request is only created after Level 1 is approved. If Level 1 rejects, Level 2 is never created.

## Parallel Approval (Any of N)

For content that any editor can approve:

```json
{
  "trigger": "publish_content",
  "approvers_any_of": ["editor_alice", "editor_bob", "editor_carol"],
  "expiry_hours": 24
}
```

First approver to click wins; others' pending approvals are cancelled.

## Implementing a Review Dashboard

```sql
-- Summary for the approval dashboard widget
SELECT
  COUNT(*) FILTER (WHERE status = 'pending')  AS pending,
  COUNT(*) FILTER (WHERE status = 'approved') AS approved_today,
  COUNT(*) FILTER (WHERE status = 'rejected') AS rejected_today,
  COUNT(*) FILTER (WHERE status = 'expired')  AS expired_today
FROM approvals
WHERE company_id = 'your-company-id'
  AND created_at >= date_trunc('day', now());
```

## Expiry Escalation

Configure what happens when an approval expires without a decision:

| `on_expire` | Behaviour |
|------------|-----------|
| `reject` | Issue cancelled, agent notified |
| `approve` | Issue auto-approved (use carefully!) |
| `escalate` | Re-create approval request for next-level approver |
| `notify` | Only send a reminder notification |

## Approval via Webhook (External Tools)

Integrate with Slack, email, or any tool:

```json
{
  "webhook_url": "https://hooks.slack.com/services/...",
  "events": ["approval.created"],
  "message_template": "🔔 Approval needed: {{details.title}}\n{{approve_url}}\n{{reject_url}}"
}
```

The `approve_url` and `reject_url` are pre-signed URLs valid for `expiry_hours` hours.

## Checkpoint ✓

- [ ] You can design a two-level chained approval workflow
- [ ] You understand the four `on_expire` behaviours
- [ ] You can set up Slack notifications for pending approvals
$md$ WHERE slug = 'pcl-49-approval-workflow';

-- ─── pcl-50-audit-trail ──────────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# The Audit Trail

## What you'll learn
Paperclip's complete audit trail — what is logged automatically, how to query it for compliance, and how to export it for external reporting.

## What Paperclip Logs Automatically

| Event | Table | Key fields |
|-------|-------|-----------|
| Every heartbeat run | `heartbeat_runs` | status, cost, timing |
| Every LLM call | `cost_events` | model, tokens, cost, agent |
| Every issue state change | `issues` | status, result, timestamps |
| Every approval | `approvals` | trigger, decision, reviewer, note |
| Every agent status change | `agents` (+ history table) | old/new status, changed_at |

## The Issue Audit Log

The `issues` table already contains the full story:

```sql
SELECT
  id,
  title,
  status,
  attempt_count,
  created_at,
  claimed_at,
  resolved_at,
  EXTRACT(epoch FROM (resolved_at - created_at)) / 60 AS minutes_to_resolve,
  LEFT(result, 100) AS result_preview
FROM issues
WHERE company_id = 'your-company-id'
ORDER BY created_at DESC;
```

## Agent Modification History

Paperclip records changes to agent configuration in a separate audit table:

```sql
-- If your schema has an agent_audit table:
SELECT
  aa.changed_at,
  aa.changed_field,
  aa.old_value,
  aa.new_value,
  aa.changed_by   -- 'heartbeat', 'api', or a user email
FROM agent_audit aa
WHERE aa.agent_id = 'your-agent-id'
ORDER BY aa.changed_at DESC;
```

## Compliance Export Query

For SOC2/ISO27001 evidence packages, export a full activity log:

```sql
COPY (
  SELECT
    'issue'            AS record_type,
    i.id::text         AS record_id,
    i.title            AS description,
    i.status,
    a.name             AS actor,
    i.created_at       AS occurred_at,
    i.resolved_at      AS completed_at
  FROM issues i
  LEFT JOIN agents a ON a.id = i.assigned_agent_id
  WHERE i.company_id = 'your-company-id'

  UNION ALL

  SELECT
    'approval',
    ap.id::text,
    ap.trigger,
    ap.status,
    COALESCE(ap.human_reviewer_email, req.name),
    ap.created_at,
    ap.decided_at
  FROM approvals ap
  LEFT JOIN agents req ON req.id = ap.requesting_agent_id
  WHERE ap.company_id = 'your-company-id'

  UNION ALL

  SELECT
    'cost_event',
    ce.id::text,
    ce.model || ': ' || ce.input_tokens || '+' || ce.output_tokens || ' tokens',
    'recorded',
    a.name,
    ce.created_at,
    NULL
  FROM cost_events ce
  JOIN agents a ON a.id = ce.agent_id
  WHERE ce.company_id = 'your-company-id'
    AND ce.created_at >= '2024-01-01'

  ORDER BY occurred_at
) TO '/tmp/audit_export.csv' CSV HEADER;
```

## Data Retention Policy

Paperclip never automatically deletes audit records. Implement your own retention policy:

```sql
-- Archive records older than 1 year to a cold storage table
INSERT INTO issues_archive SELECT * FROM issues
WHERE created_at < now() - interval '1 year'
  AND company_id = 'your-company-id';

DELETE FROM issues
WHERE created_at < now() - interval '1 year'
  AND company_id = 'your-company-id';
```

## Checkpoint ✓

- [ ] You can list the four tables that form Paperclip's audit trail
- [ ] You can run the compliance export query and understand each column
- [ ] You know how to implement a data retention archive
$md$ WHERE slug = 'pcl-50-audit-trail';

-- ─── pcl-51-compliance-policies ──────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Compliance Policies and Data Governance

## What you'll learn
Configure Paperclip for regulated industries, enforce data handling policies at the company level, and understand what controls Paperclip provides vs what you must implement yourself.

## What Paperclip Controls

| Control | Paperclip provides |
|---------|------------------|
| Multi-tenant isolation | `company_id` boundary on every table |
| Spending limits | Budget auto-pause at agent and company level |
| Human oversight | Approval gates with audit trail |
| Data encryption | At-rest encryption via Supabase/PostgreSQL; in-transit via TLS |
| Secret management | API keys via env vars, never stored in DB |
| Audit logging | Automatic logging of all agent actions and approvals |

## What You Must Implement

| Control | Your responsibility |
|---------|-------------------|
| User authentication | Supabase Auth, Auth0, or your own JWT |
| Role-based access | Which humans can see/manage which company |
| Data residency | Choose EU/US Supabase region or self-host |
| PII handling | Scrub PII from issue descriptions before seeding |
| Model data usage | Review Anthropic/OpenAI data usage policies |

## PII Scrubbing Before Issue Seeding

Never seed customer PII directly into `issues.description`:

```typescript
// Before creating an issue from a support ticket:
import { scrub } from './pii-scrubber';  // your scrubbing library

const safeDescription = scrub(ticket.body, {
  patterns: ['email', 'phone', 'credit_card', 'ssn'],
  replacement: '[REDACTED]'
});

await createIssue({ description: safeDescription });
```

## GDPR Deletion

For the right to erasure, implement a deletion cascade:

```sql
-- Remove all data for a specific user across all their activity
-- (assumes a user_id column on issues if users submit them directly)
DELETE FROM cost_events WHERE agent_id IN (SELECT id FROM agents WHERE /* user filter */);
DELETE FROM approvals   WHERE requesting_agent_id IN (...);
DELETE FROM issues      WHERE company_id = 'user-company-id';
DELETE FROM agents      WHERE company_id = 'user-company-id';
DELETE FROM companies   WHERE id = 'user-company-id';
```

## Model Usage Policies

Before using Anthropic or OpenAI in a regulated context:

- **Anthropic**: by default, API inputs/outputs are not used for training. Verify at [anthropic.com/legal](https://anthropic.com/legal)
- **OpenAI**: API data is not used for training by default. See [openai.com/policies](https://openai.com/policies)
- **Self-hosted (Ollama)**: no data leaves your infrastructure — ideal for HIPAA/GDPR sensitive workloads

For HIPAA environments: use the `http` adapter pointing at a self-hosted Ollama or a HIPAA BAA-covered service.

## Restricting Issue Content via Policy

Add input validation in your issue-creation API layer:

```typescript
// Reject issues whose descriptions match a PII pattern
function validateIssueContent(description: string) {
  const PII_REGEX = /\b\d{3}-\d{2}-\d{4}\b/; // SSN pattern
  if (PII_REGEX.test(description)) {
    throw new Error('Issue description contains PII; scrub before submitting');
  }
}
```

## Checkpoint ✓

- [ ] You can distinguish what Paperclip controls vs what you control
- [ ] You can implement a PII scrubbing step before issue seeding
- [ ] You know which model usage policy applies to your adapter choice
$md$ WHERE slug = 'pcl-51-compliance-policies';

-- ─── pcl-52-cost-reporting ───────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Cost Reporting and Optimisation

## What you'll learn
Build cost dashboards from `cost_events`, identify expensive agents and tasks, and apply four proven cost-reduction techniques.

## The Cost Dashboard Query

```sql
-- Monthly cost summary dashboard
WITH monthly AS (
  SELECT
    a.name                          AS agent,
    a.role,
    ce.model,
    COUNT(*)                        AS invocations,
    SUM(ce.input_tokens)            AS total_input_tokens,
    SUM(ce.output_tokens)           AS total_output_tokens,
    SUM(ce.cost_usd)                AS total_cost,
    AVG(ce.cost_usd)                AS avg_cost_per_call,
    a.monthly_budget_usd            AS budget,
    ROUND(100 * SUM(ce.cost_usd)
      / a.monthly_budget_usd)       AS pct_of_budget
  FROM cost_events ce
  JOIN agents a ON a.id = ce.agent_id
  WHERE ce.company_id = 'your-company-id'
    AND date_trunc('month', ce.created_at) = date_trunc('month', now())
  GROUP BY a.id, a.name, a.role, ce.model, a.monthly_budget_usd
)
SELECT *
FROM monthly
ORDER BY total_cost DESC;
```

## Identifying Expensive Tasks

```sql
-- Most expensive individual issues
SELECT
  i.title,
  a.name        AS agent,
  ce.model,
  ce.cost_usd,
  ce.input_tokens + ce.output_tokens AS total_tokens,
  i.created_at
FROM cost_events ce
JOIN issues i ON i.id = ce.issue_id
JOIN agents a ON a.id = ce.agent_id
WHERE ce.company_id = 'your-company-id'
ORDER BY ce.cost_usd DESC
LIMIT 20;
```

## Four Cost-Reduction Techniques

### 1. Switch to a Cheaper Model for Simple Tasks

Not every agent needs Opus. A classification or summarisation agent can often use Haiku at 1/100th the cost:

```json
{ "model": "claude-haiku-3-5" }   // $0.00025/1K input vs $0.015 for Opus
```

Savings: up to 98% for compatible tasks.

### 2. Trim the System Prompt

Every token in the system prompt is re-sent as input on every call. Audit your prompts:

```sql
SELECT name, length(system_prompt) AS prompt_chars
FROM agents
WHERE company_id = 'your-company-id'
ORDER BY prompt_chars DESC;
```

Reduce from 800 → 200 characters = 25% input token reduction per call.

### 3. Reduce Output Length

Instruct agents to be concise. Add to every system prompt:
```
Be concise. Maximum 3 paragraphs unless detail is explicitly requested.
```

### 4. Reduce Heartbeat Frequency

From every 5 minutes to every 15 minutes = 3x fewer invocations for low-urgency agents:

```sql
UPDATE companies
SET heartbeat_cron = '*/15 * * * *'
WHERE slug = 'my-company';
```

## Cost Forecast

```sql
-- Project end-of-month spend based on current burn rate
SELECT
  SUM(cost_usd)                  AS mtd_spend,
  SUM(cost_usd)
    / EXTRACT(day FROM now())
    * EXTRACT(day FROM date_trunc('month', now())
      + interval '1 month' - interval '1 day') AS projected_month_total
FROM cost_events
WHERE company_id = 'your-company-id'
  AND date_trunc('month', created_at) = date_trunc('month', now());
```

## Checkpoint ✓

- [ ] You can run the monthly cost dashboard query and interpret every column
- [ ] You can identify the top 20 most expensive individual tasks
- [ ] You can apply at least two of the four cost-reduction techniques
$md$ WHERE slug = 'pcl-52-cost-reporting';
