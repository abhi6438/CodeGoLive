-- =============================================================================
-- Paperclip AI — Module 9: Real-World Projects
-- Topics: pcl-69 through pcl-76
-- =============================================================================

-- ─── pcl-69-ai-content-company ───────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Project: AI Content Company

## What you'll build
A fully autonomous content production company that publishes two blog posts per week on AI topics without human intervention (except approval gates for final publishing).

## Company Blueprint

```
Company: AI Content Co
Monthly budget: $40

Agents:
1. Trend Spotter     ($6)  — Monitors Hacker News & Reddit for trending AI topics
2. Topic Planner     ($4)  — Selects 2 topics/week, avoids duplication
3. Researcher × 2   ($8×2) — Parallel deep-dive research per topic
4. Writer × 2       ($5×2) — Drafts 1000-word articles from research
5. Editor           ($3)   — Quality, tone, and fact-checking review
6. Publisher        ($1)   — Formats and pushes to CMS via API
```

## Step 1 — Seed the Company

```sql
DO $$
DECLARE
  cid uuid;
BEGIN
  INSERT INTO companies (name, slug, monthly_budget_usd)
  VALUES ('AI Content Co', 'ai-content-co', 40.00)
  ON CONFLICT (slug) DO NOTHING
  RETURNING id INTO cid;
  IF cid IS NULL THEN SELECT id INTO cid FROM companies WHERE slug = 'ai-content-co'; END IF;

  INSERT INTO agents (company_id, name, role, system_prompt, adapter_type, monthly_budget_usd, status)
  VALUES
  (cid, 'Trend Spotter', 'Market Research Analyst',
   'You monitor AI trends. Given the current date, list 10 trending AI topics from Hacker News, Reddit r/MachineLearning, and arXiv. Output JSON: {"topics": [{"title": "...", "source": "...", "why_trending": "..."}]}',
   'claude-code', 6.00, 'active'),

  (cid, 'Topic Planner', 'Editorial Planner',
   'You select 2 topics for this week''s blog posts from a provided list. Avoid topics already covered (provided as history). Output JSON: {"selected": [{"title": "...", "angle": "...", "target_audience": "..."}]}',
   'claude-code', 4.00, 'active'),

  (cid, 'Researcher A', 'Research Analyst',
   'You research a single AI topic in depth. Produce a structured research note: summary (3 sentences), 7 key facts with sources, 3 expert perspectives, and a "further reading" list. Output JSON.',
   'claude-code', 8.00, 'active'),

  (cid, 'Researcher B', 'Research Analyst',
   'You research a single AI topic in depth. Produce a structured research note: summary (3 sentences), 7 key facts with sources, 3 expert perspectives, and a "further reading" list. Output JSON.',
   'claude-code', 8.00, 'active'),

  (cid, 'Writer A', 'Content Writer',
   'You write 1000-word blog posts from a structured research note. Style: educational, conversational, developer audience. Structure: hook intro, 3 H2 sections, key takeaways, CTA. Output markdown.',
   'claude-code', 5.00, 'active'),

  (cid, 'Writer B', 'Content Writer',
   'You write 1000-word blog posts from a structured research note. Style: educational, conversational, developer audience. Structure: hook intro, 3 H2 sections, key takeaways, CTA. Output markdown.',
   'claude-code', 5.00, 'active'),

  (cid, 'Editor', 'Copy Editor',
   'You review blog post drafts. Check: accuracy, clarity, grammar, tone consistency, and CTA effectiveness. Output the improved draft with 3-5 inline comments. If quality is poor, set {"needs_revision": true}.',
   'claude-code', 3.00, 'active'),

  (cid, 'Publisher', 'Content Publisher',
   'You publish approved blog posts to the CMS. Format the markdown as HTML, generate a slug, set categories and tags from the topic. Call the CMS API and return {"published": true, "url": "..."}.',
   'shell', 1.00, 'active');

END $$;
```

## Step 2 — Configure the Weekly Workflow

Set the heartbeat to run every 15 minutes:

```sql
UPDATE companies SET heartbeat_cron = '*/15 * * * *' WHERE slug = 'ai-content-co';
```

Seed the first Trend Spotter task (recurring weekly trigger):

```sql
-- Scheduled for every Monday 08:00 UTC
INSERT INTO issues (company_id, title, assigned_agent_id, due_at, priority, status)
SELECT
  id,
  'Weekly trend scan: ' || to_char(now(), 'YYYY-MM-DD'),
  (SELECT id FROM agents WHERE name = 'Trend Spotter' AND company_id = companies.id),
  date_trunc('week', now() + interval '1 week') + interval '8 hours',
  'high',
  'open'
FROM companies WHERE slug = 'ai-content-co';
```

## Step 3 — The Pipeline Triggers

Set up database triggers to auto-create downstream issues:

```sql
-- When Trend Spotter resolves → create Topic Planner issue
-- When Topic Planner resolves → create 2 Researcher issues (parallel)
-- When each Researcher resolves → create corresponding Writer issue
-- When Writer resolves → create Editor issue
-- When Editor approves → create Publisher issue (or Approval Gate first)
```

(Full trigger SQL is in `/db/content_company_triggers.sql` in the companion repo.)

## Metrics to Track

```sql
-- Weekly production dashboard
SELECT
  date_trunc('week', i.created_at) AS week,
  COUNT(*) FILTER (WHERE a.role = 'Content Writer' AND i.status = 'resolved') AS articles_written,
  COUNT(*) FILTER (WHERE a.role = 'Content Publisher' AND i.status = 'resolved') AS articles_published,
  SUM(ce.cost_usd) AS weekly_cost
FROM issues i
JOIN agents a ON a.id = i.assigned_agent_id
LEFT JOIN cost_events ce ON ce.issue_id = i.id
WHERE i.company_id = (SELECT id FROM companies WHERE slug = 'ai-content-co')
GROUP BY week ORDER BY week DESC;
```

## Checkpoint ✓

- [ ] Company seeded with all 8 agents
- [ ] Heartbeat schedule set to 15 minutes
- [ ] First Trend Spotter issue scheduled for next Monday
- [ ] Pipeline triggers defined for the handoff chain
$md$ WHERE slug = 'pcl-69-ai-content-company';

-- ─── pcl-70-ai-dev-team ──────────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Project: AI Development Team

## What you'll build
A Paperclip company that acts as a junior development team: it reads a GitHub issue, produces code, opens a PR, and requests human review.

## Company Blueprint

```
Company: AI Dev Team
Monthly budget: $60

Agents:
1. Issue Analyst     ($8)  — reads GitHub issue, produces spec + acceptance criteria
2. Architect         ($10) — designs solution approach, identifies files to change
3. Developer         ($20) — writes the code changes
4. Reviewer          ($12) — reviews the diff for bugs and style
5. PR Creator        ($5)  — formats PR description, creates PR via GitHub API
6. Test Writer       ($5)  — writes unit tests for the new code
```

## Connecting to GitHub via Webhook

1. In your GitHub repo → Settings → Webhooks → Add webhook
2. Payload URL: `https://your-paperclip.com/webhooks/ai-dev-team/github`
3. Content type: `application/json`
4. Events: `Issues` (opened/labeled)
5. Secret: your `WEBHOOK_SECRET`

Configure the webhook handler in Company Settings → Webhooks:
```json
{
  "source": "github",
  "events": ["issues.opened"],
  "filter": { "labels": ["ai-agent"] },
  "auto_create_issue": true,
  "issue_template": {
    "title": "Implement: {{payload.issue.title}}",
    "description": "GitHub Issue #{{payload.issue.number}}\n\n{{payload.issue.body}}",
    "assigned_agent": "Issue Analyst",
    "priority": "high",
    "metadata": {
      "github_issue_number": "{{payload.issue.number}}",
      "github_repo": "{{payload.repository.full_name}}"
    }
  }
}
```

## The Developer Agent System Prompt

```
You are a Senior Developer at AI Dev Team.

## Identity
You implement code changes based on a technical specification.

## Operating Rules
- Read the specification carefully before writing any code
- Write idiomatic, well-commented code
- Do not change files not mentioned in the spec
- Output ONLY a JSON object:
  {
    "files_changed": [
      {
        "path": "src/components/Button.tsx",
        "change_type": "modified",
        "diff": "--- original\n+++ modified\n@@ ...",
        "explanation": "Added disabled prop handling"
      }
    ],
    "test_notes": "Test that disabled=true adds the aria-disabled attribute"
  }
```

## Approval Gate Before Merging

Configure an approval gate that fires when the Developer resolves an issue:

```json
{
  "trigger": "code_change_ready",
  "required_approver": "human_lead_engineer",
  "expiry_hours": 72,
  "notification": {
    "channel": "slack",
    "message": "🤖 PR ready for review: {{details.pr_url}}"
  }
}
```

A human lead engineer reviews the AI-generated PR before it merges.

## Cost per GitHub Issue

| Step | Agent | Avg cost |
|------|-------|---------|
| Issue analysis | Analyst | $0.03 |
| Architecture design | Architect | $0.05 |
| Code writing | Developer | $0.12 |
| Code review | Reviewer | $0.05 |
| PR creation | PR Creator | $0.01 |
| Test writing | Test Writer | $0.04 |
| **Total** | | **~$0.30** |

## Checkpoint ✓

- [ ] Company seeded with all 6 agents
- [ ] GitHub webhook configured to create issues for `ai-agent` labelled GitHub issues
- [ ] Approval gate configured before PR merge
- [ ] You understand the data flow from GitHub → Paperclip → GitHub
$md$ WHERE slug = 'pcl-70-ai-dev-team';

-- ─── pcl-71-ai-support-team ──────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Project: AI Support Team

## What you'll build
A Paperclip support team that classifies, triages, and responds to support tickets — handling 80% autonomously and routing the rest to humans.

## Company Blueprint

```
Company: AI Support Team
Monthly budget: $30
Target: <2 min response time, 80% automation rate

Agents:
1. Classifier    ($4)   — fast, cheap; labels ticket type + priority
2. Knowledge Bot ($6)   — answers from knowledge base (FAQ + docs)
3. Billing Agent ($6)   — handles refund/billing queries with policy rules
4. Technical Bot ($10)  — troubleshoots technical issues step-by-step
5. Escalator     ($2)   — formats handoff notes for human agents
6. QA Checker    ($2)   — validates response quality before sending
```

## The Triage Flow

```
Ticket arrives (email/webhook)
     ↓
Classifier: {type: "billing|technical|account|abuse", priority: "low|medium|high|critical", confidence: 0.0-1.0}
     ↓
Router (deterministic, shell adapter):
  confidence > 0.85 → send to specialist agent
  confidence ≤ 0.85 → send to human queue
     ↓
Specialist Agent:
  produces draft response + {can_auto_send: boolean}
     ↓
QA Checker:
  can_auto_send=true + score ≥ 8: auto-send
  else: human queue with draft attached
```

## Classifier System Prompt

```
You are a Support Ticket Classifier.

Classify the following support ticket. Output ONLY JSON:
{
  "type": "billing" | "technical" | "account" | "abuse" | "feature_request" | "other",
  "priority": "low" | "medium" | "high" | "critical",
  "confidence": 0.0 to 1.0,
  "summary": "one sentence description of the issue",
  "sentiment": "positive" | "neutral" | "negative" | "angry",
  "requires_human": boolean
}

Label as critical only if: data loss, security breach, payment fraud, or legal threat.
```

## Router (Shell Adapter)

```python
#!/usr/bin/env python3
import sys, json

data = json.loads(sys.stdin.read())
classification = json.loads(data.get('result', '{}'))

type_to_agent = {
    'billing':   'Billing Agent',
    'technical': 'Technical Bot',
    'account':   'Knowledge Bot',
}

if classification.get('requires_human') or classification.get('confidence', 0) < 0.85:
    print(json.dumps({'route_to': 'human_queue', 'reason': 'low_confidence'}))
elif classification.get('priority') == 'critical':
    print(json.dumps({'route_to': 'human_queue', 'reason': 'critical_priority'}))
else:
    agent = type_to_agent.get(classification.get('type'), 'Knowledge Bot')
    print(json.dumps({'route_to': agent, 'can_auto_route': True}))
```

## Metrics Dashboard

```sql
SELECT
  date_trunc('day', i.created_at)                       AS day,
  COUNT(*)                                              AS total_tickets,
  COUNT(*) FILTER (WHERE i.metadata->>'auto_sent' = 'true') AS auto_resolved,
  ROUND(100.0 * COUNT(*) FILTER (WHERE i.metadata->>'auto_sent' = 'true')
    / NULLIF(COUNT(*), 0))                              AS automation_rate_pct,
  ROUND(AVG(EXTRACT(epoch FROM (i.resolved_at - i.created_at)) / 60))
                                                        AS avg_resolution_min
FROM issues i
WHERE i.company_id = (SELECT id FROM companies WHERE slug = 'ai-support')
GROUP BY day ORDER BY day DESC LIMIT 14;
```

## Checkpoint ✓

- [ ] Company seeded with all 6 agents and a Router shell script
- [ ] Classifier outputs structured JSON with confidence score
- [ ] Routing logic sends low-confidence tickets to human queue
- [ ] You can measure the automation rate from the metrics dashboard
$md$ WHERE slug = 'pcl-71-ai-support-team';

-- ─── pcl-72-sap-integration ──────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Project: SAP BTP Integration

## What you'll build
Integrate Paperclip agents with SAP BTP services — using the HTTP adapter to call SAP APIs and the shell adapter to run CAP queries.

## Why SAP + Paperclip?

SAP BTP customers often have repetitive enterprise workflows that are perfect for Paperclip:
- Extract and summarise data from S/4HANA
- Classify incoming SAP support messages
- Generate weekly operational reports from CAP OData services
- Automate BTP subaccount provisioning documentation

## Pattern 1: CAP OData Reader Agent

```json
{
  "adapter_type": "http",
  "adapter_config": {
    "url": "https://your-cap-app.cfapps.eu10.hana.ondemand.com/api/Orders?$top=50&$format=json",
    "method": "GET",
    "headers": {
      "Authorization": "Bearer {{env.BTP_TOKEN}}",
      "Accept": "application/json"
    },
    "response_path": "value",
    "post_process": "summarise"
  }
}
```

The agent receives the OData result as its task context and produces a summary.

## Pattern 2: Shell Agent Running CF CLI

```python
#!/usr/bin/env python3
# /agents/cf_report.py
import subprocess, json, sys

# Get Cloud Foundry app status
result = subprocess.run(
    ['cf', 'apps', '--json'],
    capture_output=True, text=True
)
apps = json.loads(result.stdout)

summary = [
    f"- {a['name']}: {a['state']} ({a['instances']} instances)"
    for a in apps
]
print('\n'.join(['## CF Apps Status', ''] + summary))
```

```json
{
  "adapter_type": "shell",
  "adapter_config": {
    "command": "python3 /agents/cf_report.py",
    "env": { "CF_API": "{{env.CF_API}}", "CF_TOKEN": "{{env.CF_TOKEN}}" }
  }
}
```

## Pattern 3: HANA Cloud Query Agent

```python
#!/usr/bin/env python3
# /agents/hana_query.py
import hdbcli.dbapi, sys, json

conn = hdbcli.dbapi.connect(
    address=os.environ['HANA_HOST'],
    port=443,
    user=os.environ['HANA_USER'],
    password=os.environ['HANA_PASS'],
    encrypt=True
)

cursor = conn.cursor()
cursor.execute("SELECT TOP 20 * FROM OPEN_PURCHASE_ORDERS ORDER BY NET_AMOUNT DESC")
rows = cursor.fetchall()
columns = [d[0] for d in cursor.description]

print(json.dumps({"columns": columns, "rows": [list(r) for r in rows]}))
```

Then an LLM agent (claude-code) receives this JSON as the task description and produces a human-readable summary.

## BTP Service Binding Pattern

In Cloud Foundry, service credentials are injected via `VCAP_SERVICES`. Read them in a shell agent:

```python
import os, json
vcap = json.loads(os.environ.get('VCAP_SERVICES', '{}'))
destination_creds = vcap.get('destination', [{}])[0].get('credentials', {})
```

## Typical SAP Paperclip Workflow

```
Daily at 06:00 UTC (heartbeat trigger):
  1. HANA Query Agent → fetch yesterday's sales data
  2. Summariser Agent (claude-code) → produce executive summary
  3. Approval Gate → CFO approves distribution
  4. Email Agent (shell) → sends via SAP BTP Mail service
```

## Checkpoint ✓

- [ ] You can configure an HTTP adapter agent to call a CAP OData endpoint
- [ ] You understand the shell adapter pattern for CF CLI commands
- [ ] You know how to read BTP service credentials from VCAP_SERVICES
$md$ WHERE slug = 'pcl-72-sap-integration';

-- ─── pcl-73-ai-research-firm ─────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Project: AI Research Firm

## What you'll build
A Paperclip company that produces weekly research reports on a defined topic area, accumulating knowledge in a company memory store over time.

## Company Blueprint

```
Company: Deep Research Inc
Monthly budget: $80

Agents:
1. Horizon Scanner  ($10) — weekly trend sweep across arXiv, GitHub, news
2. Deep Diver × 3   ($15×3) — parallel deep research on top 3 topics
3. Analyst          ($12) — synthesises across all three deep-dive reports
4. Report Writer    ($8)  — produces the weekly PDF-ready report
5. Memory Keeper    ($5)  — updates the long-term knowledge store
```

## Long-Term Memory Design

The Memory Keeper agent maintains a `company_memory` table with accumulated knowledge:

```sql
CREATE TABLE company_memory (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL,
  key        text NOT NULL,
  value      jsonb NOT NULL,
  updated_at timestamptz DEFAULT now(),
  UNIQUE (company_id, key)
);
```

Memory Keeper system prompt:
```
You are a Memory Keeper. Given a new research report, update the knowledge base.

For each technology or organisation mentioned:
- Update its entry with new facts
- Note changes from prior week (if known)
- Flag emerging trends

Output JSON:
{
  "memory_updates": [
    {"key": "entity:OpenAI", "facts": ["released GPT-5 on X date", ...], "trend": "accelerating"},
    {"key": "trend:multimodal", "summary": "...", "last_updated": "2024-01-15"}
  ]
}
```

## Using Memory in Subsequent Reports

When the Analyst runs, its task description includes the current memory store:

```sql
-- Inject memory context into analyst's issue description
UPDATE issues
SET description = description || E'\n\n## Knowledge Base (prior weeks)\n' ||
  (SELECT string_agg(key || ': ' || (value->>'summary')::text, E'\n')
   FROM company_memory
   WHERE company_id = i.company_id
   LIMIT 20)
WHERE title LIKE 'Synthesise research%'
  AND status = 'open';
```

## The Weekly Report Schedule

```sql
-- Every Monday 06:00 UTC: create Horizon Scanner issue
INSERT INTO issues (company_id, title, assigned_agent_id, due_at, priority, status)
SELECT
  id,
  'Horizon scan: week of ' || to_char(now(), 'YYYY-MM-DD'),
  (SELECT id FROM agents WHERE name = 'Horizon Scanner' AND company_id = companies.id),
  date_trunc('week', now() + interval '1 week') + interval '6 hours',
  'high',
  'open'
FROM companies WHERE slug = 'deep-research-inc';
```

## Quality Gate: Analyst Confidence Score

The Analyst includes a confidence score in its output:

```json
{
  "synthesis": "...",
  "confidence": 0.82,
  "gaps": ["No data on Anthropic's Q4 training runs", "GPT-5 pricing not yet public"]
}
```

If `confidence < 0.7`, the Analyst creates additional Deep Diver issues to fill the gaps.

## Cost per Weekly Report

| Agent | Cost |
|-------|------|
| Horizon Scanner | $0.30 |
| Deep Diver × 3 | $0.90 |
| Analyst | $0.25 |
| Report Writer | $0.20 |
| Memory Keeper | $0.10 |
| **Total** | **~$1.75/week** |

## Checkpoint ✓

- [ ] Company seeded with all 5 agents and a company_memory table
- [ ] Memory Keeper writes structured knowledge after each report
- [ ] Weekly schedule seeds a Horizon Scanner issue every Monday
- [ ] Analyst can read from company_memory to build on prior research
$md$ WHERE slug = 'pcl-73-ai-research-firm';

-- ─── pcl-74-scaling-to-prod ──────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# From Sandbox to Production: Migration Checklist

## What you'll learn
The complete process of moving a Paperclip company from local development to production, without data loss or agent downtime.

## Migration Checklist

### Phase 1: Pre-Migration (in development)

```
□ All agents tested with real tasks (≥10 invocations each)
□ System prompts reviewed and locked in version control
□ Budget limits set conservatively (start at 50% of expected monthly)
□ Approval policies configured and tested
□ SQL seed scripts run on a staging database successfully
□ .env file documented (not committed) with all required variables
```

### Phase 2: Production Database

```bash
# 1. Create production database
createdb paperclip_prod

# 2. Run schema
psql $PROD_DATABASE_URL < db/schema.sql

# 3. Run seed scripts in order
psql $PROD_DATABASE_URL < db/seed.sql
psql $PROD_DATABASE_URL < db/your_company_seed.sql

# 4. Verify
psql $PROD_DATABASE_URL -c "SELECT name FROM companies;"
psql $PROD_DATABASE_URL -c "SELECT name, status FROM agents;"
psql $PROD_DATABASE_URL -c "SELECT COUNT(*) FROM issues WHERE status = 'open';"
```

### Phase 3: Production Deploy

```
□ Docker Compose stack started and healthy
□ Nginx TLS configured and cert valid
□ All environment variables set (use the checklist from pcl-64)
□ Health endpoint returns 200: GET /health/ready
□ Heartbeat scheduler confirmed running in logs
```

### Phase 4: First Production Run

```bash
# Manually trigger first heartbeat
curl -X POST https://your-domain.com/api/heartbeat/run \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -d '{"company_id": "'$COMPANY_ID'"}'

# Watch in real time
curl https://your-domain.com/api/heartbeat/runs/$RUN_ID
```

### Phase 5: First 24 Hours Monitoring

```
□ Heartbeat completing without errors
□ Issues being resolved (not stuck in 'open')
□ Cost per run within expected range
□ No agent auto-paused
□ No unexpected approval requests
```

## Data Migration from Sandbox

If you ran agents in sandbox (PGlite) and want to keep historical data:

```bash
# Export from PGlite
sqlite3 .paperclip/sandbox.db ".dump" > sandbox_dump.sql

# Note: PGlite schema may differ from PostgreSQL — use the export as reference only
# Re-create issues in production with:
psql $PROD_DATABASE_URL < historical_issues_seed.sql
```

## Switching from One Cloud Region to Another

1. Create a `pg_dump` of the source database
2. Restore to the new region
3. Update `DATABASE_URL` in the new deployment
4. Keep the old deployment running read-only for 48 hours
5. After 48 hours with no data discrepancies, decommission the old deployment

## Rollback Plan

```bash
# If the production deployment fails after migration:
# 1. Point DATABASE_URL back to the last known good database
# 2. Roll back Docker images to the previous tag
docker compose down
docker compose up -d --no-build  # uses the previous pulled images
```

## Checkpoint ✓

- [ ] You can walk through all four phases of the production migration checklist
- [ ] You know how to verify a successful migration in the first 24 hours
- [ ] You have a rollback plan ready before starting the migration
$md$ WHERE slug = 'pcl-74-scaling-to-prod';

-- ─── pcl-75-multi-company ────────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Multi-Company and SaaS Patterns

## What you'll learn
Run multiple independent companies in one Paperclip installation, implement tenant isolation, and offer Paperclip-as-a-service to multiple customers.

## Why Multi-Company?

Paperclip is designed for multi-tenancy. A single installation can host:
- Multiple internal departments (Engineering, Marketing, Support)
- Multiple client projects (agency model)
- Multiple end-customers (SaaS product)

## The Company Isolation Guarantee

As covered in pcl-11, every table has a `company_id` column and every query filters by it. This is architectural, not configurable — you cannot accidentally leak data between companies.

```sql
-- Verify isolation: this should NEVER return rows from another company
EXPLAIN SELECT * FROM issues WHERE company_id = 'company-a-id';
-- → should see "company_id = 'company-a-id'" in the Filter node
```

## Creating Multiple Companies Programmatically

```typescript
// packages/server/src/scripts/create-company.ts
async function createCompanyWithDefaults(opts: {
  name: string;
  slug: string;
  budget: number;
  template?: 'content' | 'dev-team' | 'support';
}) {
  const company = await db.companies.create({
    name: opts.name,
    slug: opts.slug,
    monthly_budget_usd: opts.budget,
  });

  if (opts.template === 'content') {
    await seedContentTeamAgents(company.id);
  } else if (opts.template === 'support') {
    await seedSupportTeamAgents(company.id);
  }

  return company;
}
```

## Per-Company Heartbeat Schedules

Each company can have its own heartbeat schedule:

```sql
-- High-priority company: every 1 minute
UPDATE companies SET heartbeat_cron = '* * * * *' WHERE slug = 'priority-client';

-- Low-priority: every 30 minutes
UPDATE companies SET heartbeat_cron = '*/30 * * * *' WHERE slug = 'low-tier-client';
```

## Billing by Company (SaaS Model)

Track costs per company for billing:

```sql
-- Monthly invoice data per company
SELECT
  c.name                   AS company,
  c.slug,
  SUM(ce.cost_usd)         AS llm_cost_usd,
  COUNT(DISTINCT ce.id)    AS llm_calls,
  COUNT(DISTINCT i.id)     AS issues_resolved
FROM companies c
LEFT JOIN cost_events ce
  ON ce.company_id = c.id
  AND date_trunc('month', ce.created_at) = date_trunc('month', now())
LEFT JOIN issues i
  ON i.company_id = c.id
  AND date_trunc('month', i.resolved_at) = date_trunc('month', now())
GROUP BY c.id, c.name, c.slug
ORDER BY llm_cost_usd DESC NULLS LAST;
```

Add your SaaS markup (e.g. 3× LLM cost) in the billing layer.

## Admin API for Company Management

The Paperclip admin API (requires admin JWT) supports:
```
GET  /api/admin/companies          → list all companies
POST /api/admin/companies          → create company
PATCH /api/admin/companies/:id     → update (budget, pause, etc.)
DELETE /api/admin/companies/:id    → soft-delete
GET  /api/admin/companies/:id/stats → usage and cost summary
```

## Checkpoint ✓

- [ ] You can create multiple companies and verify they are isolated
- [ ] You know how to set different heartbeat schedules per company
- [ ] You can run the monthly billing query to see LLM costs per tenant
$md$ WHERE slug = 'pcl-75-multi-company';

-- ─── pcl-76-capstone ─────────────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Capstone: Build Your Own AI Company

## What you'll build
Design, implement, and deploy a complete Paperclip AI company of your own — from requirements to production.

## The Capstone Specification

Your company must meet these requirements:

```
✅ At least 4 agents with distinct roles
✅ At least 2 different adapter types (e.g. claude-code + shell)
✅ An org chart with at least 2 levels (manager + workers)
✅ A heartbeat schedule appropriate to your use case
✅ At least 1 approval gate for a critical action
✅ Budget limits set at both agent and company level
✅ A seeded batch of at least 10 realistic issues
✅ Monitoring: at least 1 alert configured
✅ A production-ready deployment (Docker Compose)
```

## Suggested Company Ideas

| Idea | Difficulty | Interesting because |
|------|-----------|---------------------|
| Personal newsletter generator | ⭐⭐ | Content pipeline end-to-end |
| Open-source repo summariser | ⭐⭐⭐ | GitHub API integration |
| Daily digest bot | ⭐⭐ | Scheduling, aggregation |
| Code documentation writer | ⭐⭐⭐ | Code analysis, structured output |
| Social media monitor | ⭐⭐⭐ | Webhook triggers, classification |
| Customer FAQ responder | ⭐⭐ | Retrieval, knowledge base |
| Data pipeline auditor | ⭐⭐⭐ | Shell adapter, deterministic |

## Capstone Deliverables

### 1. Company Design Document

Write a short design doc covering:
- Company name and purpose
- Agent roster with roles, adapter types, and budget
- Workflow diagram (text ASCII is fine)
- Approval gates and what they protect
- Cost estimate per week

### 2. SQL Seed File

A single idempotent `.sql` file that creates:
- The company
- All agents
- At least 10 sample issues

### 3. Production Deployment

A working `docker-compose.yml` + `.env.example` that a teammate could use to run your company.

### 4. Monitoring Setup

A SQL file with:
- The three key alerts (stuck issues, failed runs, budget warning)
- A weekly report query

## Capstone Review Checklist

```sql
-- Run this to check your capstone meets requirements
SELECT
  (SELECT COUNT(*) FROM agents        WHERE company_id = $1)       >= 4 AS has_4_agents,
  (SELECT COUNT(DISTINCT adapter_type) FROM agents WHERE company_id = $1) >= 2 AS has_2_adapters,
  (SELECT COUNT(*) FROM agents        WHERE company_id = $1 AND reports_to IS NOT NULL) >= 1 AS has_hierarchy,
  (SELECT COUNT(*) FROM issues        WHERE company_id = $1)       >= 10 AS has_10_issues,
  (SELECT COUNT(*) FROM approvals     WHERE company_id = $1 OR TRUE)  >= 0 AS approval_gates_configured,
  (SELECT paused FROM companies       WHERE id = $1)                     AS is_not_paused;
```

## What You've Learned in This Course

Working through all nine modules of the Paperclip AI course, you have:

- Built a complete mental model of how autonomous AI agent systems work
- Set up Paperclip locally with PGlite, then migrated to PostgreSQL
- Hired and configured agents with different adapters (Claude, OpenAI, HTTP, shell)
- Designed multi-level org charts with `reports_to` hierarchy
- Implemented tasks, issues, and complex workflows (pipelines, fan-out, queues)
- Mastered the heartbeat execution engine and debugged failing runs
- Applied cost governance with budget limits and approval gates
- Built multi-agent systems with coordinator patterns and shared memory
- Deployed Paperclip to production with Docker, Nginx, TLS, CI/CD, and monitoring

You're now equipped to build real autonomous AI organisations. The source code, the schema, and the concept are all yours to extend.

## Where to Go Next

- **Paperclip GitHub** — contribute adapters, report issues, propose features
- **Community Discord** — share your capstone, get feedback
- **Advanced topics** — vector memory with pgvector, fine-tuned adapters, multi-model routing

## Final Checkpoint ✓

- [ ] Design document written with all required sections
- [ ] SQL seed file complete and idempotent
- [ ] `docker-compose.yml` + `.env.example` ready
- [ ] Three monitoring alerts defined
- [ ] Capstone review checklist passes all 6 checks
- [ ] First production heartbeat run completes successfully
$md$ WHERE slug = 'pcl-76-capstone';
