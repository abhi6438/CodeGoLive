-- =============================================================================
-- Paperclip AI — Module 7: Multi-Agent Orchestration
-- Topics: pcl-53 through pcl-60
-- =============================================================================

-- ─── pcl-53-coordinator-pattern ──────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# The Coordinator Pattern

## What you'll learn
Design a coordinator agent that manages a team of specialists, implement the pattern in Paperclip, and understand its strengths and failure modes.

## What Is the Coordinator Pattern?

A **coordinator** is an agent whose job is not to do work directly, but to:
1. Accept a high-level goal
2. Decompose it into concrete subtasks
3. Assign subtasks to specialist agents
4. Monitor progress and assemble the final result

```
High-Level Goal
     │
     ▼
[Coordinator Agent]
  ├─► [Specialist A] → result A
  ├─► [Specialist B] → result B
  └─► [Specialist C] → result C
     │
     ▼
[Coordinator Agent] assembles final report
```

## Coordinator System Prompt

```
You are a Task Coordinator at Acme Corp.

## Identity
You receive high-level project goals and decompose them into specific subtasks for specialist agents.

## Operating Rules
- Always output a JSON task plan, never prose
- Each subtask must be self-contained with a clear deliverable
- Assign each subtask to exactly one agent_role
- Keep subtask descriptions under 200 words

## Output Format
{
  "project_title": "...",
  "subtasks": [
    {
      "title": "...",
      "description": "...",
      "agent_role": "...",
      "priority": "medium",
      "depends_on": []
    }
  ]
}
```

## Implementing Auto-Subtask Creation

Enable in Company Settings → Workflows → **Auto-create subtasks from structured JSON results**.

When enabled, Paperclip parses the coordinator's result JSON and:
1. Creates one `issues` row per subtask entry
2. Assigns each to an agent matching `agent_role`
3. Sets `parent_issue_id` to the coordinator's issue
4. Sets `status = 'open'` (or waits for `depends_on` issues to resolve first)

## The Coordinator's Second Role: Assembly

After all subtasks are resolved, the coordinator receives a second invocation with all subtask results compiled in the task prompt:

```
All subtasks have been completed. Here are the results:

SUBTASK 1 — Research: [result text]
SUBTASK 2 — Analysis: [result text]
SUBTASK 3 — Writing: [result text]

Please assemble these into a final coherent report.
```

## Failure Modes

| Failure | Impact | Mitigation |
|---------|--------|-----------|
| Coordinator produces invalid JSON | No subtasks created | Add JSON validation in post-processor |
| Subtask assigned to non-existent role | Issue stuck | Use explicit `assigned_agent_id` instead of `agent_role` |
| Assembly step before all subtasks done | Incomplete result | Use `depends_on` trigger in workflow config |

## Checkpoint ✓

- [ ] You can write a coordinator agent system prompt that produces structured JSON
- [ ] You understand how auto-subtask creation works
- [ ] You know the three main coordinator failure modes and their mitigations
$md$ WHERE slug = 'pcl-53-coordinator-pattern';

-- ─── pcl-54-agent-teams ──────────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Building Agent Teams

## What you'll learn
Design a complete agent team with clear roles, set up coordination and communication, and implement a content production team as a worked example.

## Team Design Principles

1. **One agent, one role** — avoid "Swiss Army knife" agents; specialists outperform generalists in Paperclip
2. **Clear input/output contract** — each agent knows exactly what it receives and what it must produce
3. **Minimal redundancy** — don't create two agents that do the same thing; use priority instead
4. **Budget proportional to importance** — give the most critical agents the largest budget

## The Content Production Team

```
Content Team (company budget: $50/month)
├── Editor-in-Chief  ($15)  — decides topics, coordinates team
├── Researcher       ($15)  — gathers facts and sources
├── Writer           ($12)  — drafts content from research
├── Editor           ($5)   — reviews and improves drafts
└── SEO Analyst      ($3)   — adds keywords and meta descriptions
```

### SQL Setup

```sql
DO $$
DECLARE
  cid uuid;
  eic uuid;
  res uuid;
  wri uuid;
  edi uuid;
  seo uuid;
BEGIN
  SELECT id INTO cid FROM companies WHERE slug = 'content-co';

  -- Editor-in-Chief (coordinator)
  INSERT INTO agents (company_id, name, role, system_prompt, adapter_type, monthly_budget_usd, status)
  VALUES (cid, 'EiC', 'Editor-in-Chief',
    'You are the Editor-in-Chief. You plan the content calendar and coordinate the writing team. Output subtask plans as JSON.',
    'claude-code', 15.00, 'active')
  RETURNING id INTO eic;

  -- Researcher
  INSERT INTO agents (company_id, name, role, system_prompt, adapter_type, monthly_budget_usd, status, reports_to)
  VALUES (cid, 'Researcher', 'Research Analyst',
    'You are a Research Analyst. Given a topic, produce a structured research note with 5 key facts, 3 expert quotes (sourced), and a list of 10 related keywords.',
    'claude-code', 15.00, 'active', eic)
  RETURNING id INTO res;

  -- Writer
  INSERT INTO agents (company_id, name, role, system_prompt, adapter_type, monthly_budget_usd, status, reports_to)
  VALUES (cid, 'Writer', 'Content Writer',
    'You are a Content Writer. Given a research note, write a 800-word blog post with an engaging introduction, 3 body sections, and a conclusion with CTA.',
    'claude-code', 12.00, 'active', eic)
  RETURNING id INTO wri;

  -- Editor
  INSERT INTO agents (company_id, name, role, system_prompt, adapter_type, monthly_budget_usd, status, reports_to)
  VALUES (cid, 'Editor', 'Copy Editor',
    'You are a Copy Editor. Review the draft for clarity, grammar, and factual accuracy. Return the improved draft with inline comments.',
    'claude-code', 5.00, 'active', eic)
  RETURNING id INTO edi;

  -- SEO Analyst
  INSERT INTO agents (company_id, name, role, system_prompt, adapter_type, monthly_budget_usd, status, reports_to)
  VALUES (cid, 'SEO', 'SEO Analyst',
    'You are an SEO Analyst. Given a finished article, produce: a meta title (60 chars max), meta description (155 chars max), and 5 keyword tags.',
    'claude-code', 3.00, 'active', eic)
  RETURNING id INTO seo;
END $$;
```

## Communication via Issue Descriptions

Agents communicate through issue content. The writer receives the researcher's output as the issue description:

```sql
-- After researcher resolves, create a writer issue with researcher output
INSERT INTO issues (company_id, title, description, assigned_agent_id, parent_issue_id)
SELECT
  i.company_id,
  'Write: ' || REPLACE(i.title, 'Research: ', ''),
  'Research notes:\n\n' || i.result,
  (SELECT id FROM agents WHERE role = 'Content Writer' AND company_id = i.company_id LIMIT 1),
  i.parent_issue_id
FROM issues i
WHERE i.id = 'researcher-issue-id'
  AND i.status = 'resolved';
```

## Checkpoint ✓

- [ ] You have designed a five-agent content team with clear roles and budgets
- [ ] You understand how agents communicate via issue descriptions
- [ ] You can write SQL to create the full team with `reports_to` hierarchy
$md$ WHERE slug = 'pcl-54-agent-teams';

-- ─── pcl-55-parallel-work ────────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Parallel Work: Running Agents Simultaneously

## What you'll learn
Design tasks that run in parallel, understand the practical concurrency limits, and build a parallel research pattern.

## Parallelism in Paperclip

Within a single heartbeat tick, Paperclip invokes all active agents simultaneously (up to `max_concurrent_agents`). This means **parallel execution is free** — you don't need special configuration. Simply assign work to multiple agents, and the heartbeat runs them in parallel.

## The Parallel Research Pattern

Goal: research 10 topics simultaneously, then merge results.

```sql
DO $$
DECLARE
  cid      uuid;
  parent   uuid;
  res_id   uuid;
  topics   text[] := ARRAY[
    'LangGraph', 'CrewAI', 'AutoGen', 'LlamaIndex', 'Haystack',
    'LangSmith', 'Weights & Biases', 'Helicone', 'PromptLayer', 'Arize'
  ];
  t        text;
BEGIN
  SELECT id INTO cid FROM companies WHERE slug = 'research-co';
  SELECT id INTO res_id FROM agents WHERE name = 'Researcher' AND company_id = cid;

  -- Create a parent "meta-research" issue
  INSERT INTO issues (company_id, title, status)
  VALUES (cid, 'AI Tooling Landscape Research', 'in_progress')
  RETURNING id INTO parent;

  -- Create one subtask per topic
  FOREACH t IN ARRAY topics LOOP
    INSERT INTO issues (company_id, title, description, assigned_agent_id, parent_issue_id, status)
    VALUES (
      cid,
      'Research: ' || t,
      'Produce a 2-paragraph summary of ' || t || ' covering: purpose, key features, typical use case, and licensing.',
      res_id,
      parent,
      'open'
    );
  END LOOP;
END $$;
```

With `max_concurrent_agents = 10`, all 10 research tasks run in the same heartbeat tick (~30 seconds vs 300 seconds sequential).

## Parallel with Different Agents

Assign different topics to different specialist agents for true parallel specialisation:

```sql
-- Assign API-focused topics to API Specialist, OSS to OSS Specialist
INSERT INTO issues (company_id, title, assigned_agent_id, status)
SELECT
  'cid',
  'Research: ' || t.topic,
  CASE
    WHEN t.category = 'api_service' THEN (SELECT id FROM agents WHERE name = 'API Specialist')
    ELSE                                  (SELECT id FROM agents WHERE name = 'OSS Specialist')
  END,
  'open'
FROM (VALUES
  ('LangSmith',       'api_service'),
  ('Helicone',        'api_service'),
  ('LangGraph',       'oss'),
  ('CrewAI',          'oss')
) AS t(topic, category);
```

## Monitoring Parallel Progress

```sql
-- See parallel subtask completion in real time
SELECT
  i.title,
  i.status,
  a.name  AS agent,
  i.resolved_at
FROM issues i
JOIN issues parent ON parent.id = i.parent_issue_id
LEFT JOIN agents a ON a.id = i.assigned_agent_id
WHERE parent.title = 'AI Tooling Landscape Research'
ORDER BY i.status, i.created_at;
```

## Rate Limit Considerations

With 10 parallel Claude invocations, you may hit API rate limits. Options:
- Use different models for different agents (separate rate limit buckets)
- Set `max_concurrent_agents = 5` and let the remaining 5 run in the next tick
- Use the `http` adapter pointing at a self-hosted model for unlimited parallelism

## Checkpoint ✓

- [ ] You can create 10 parallel subtasks that run in the same heartbeat tick
- [ ] You understand that parallel execution is automatic, not special configuration
- [ ] You know the rate limit issue and how to work around it
$md$ WHERE slug = 'pcl-55-parallel-work';

-- ─── pcl-56-handoff-protocols ────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Handoff Protocols Between Agents

## What you'll learn
Design clean handoff interfaces between agents, standardise the data format that passes from one agent to the next, and handle failed handoffs.

## The Handoff Problem

When Agent A finishes work and Agent B continues from where A left off, B needs A's output in a predictable format. If A writes free-form prose, B has to parse it — fragile and error-prone.

The solution: define a **handoff schema** for each agent's output.

## Defining a Handoff Schema

Add to the agent's system prompt:

```
## Output Format
You MUST return a JSON object with this exact schema. No prose, no markdown fencing — raw JSON only.

{
  "summary": "string (2-3 sentences)",
  "key_facts": ["string", ...],  // 3-5 items
  "sources": [{"title": "string", "url": "string"}],  // 1-5 items
  "confidence": "high" | "medium" | "low",
  "next_steps": ["string", ...]  // optional
}
```

Paperclip stores this in `issues.result_structured` (JSONB) when the result is valid JSON:

```typescript
// Heartbeat post-processes the result
if (isValidJson(result.output)) {
  await db.issues.update(issueId, {
    result: result.output,
    result_structured: JSON.parse(result.output),
  });
}
```

## Consuming the Handoff in the Next Agent

When creating the writer's issue, extract fields from the researcher's `result_structured`:

```sql
-- Writer issue description built from researcher's structured output
INSERT INTO issues (company_id, title, description, assigned_agent_id, parent_issue_id)
SELECT
  i.company_id,
  'Write article from research: ' || topic,
  'Summary: ' || (i.result_structured->>'summary') || E'\n\n' ||
  'Key facts: ' || (i.result_structured->'key_facts')::text || E'\n\n' ||
  'Write a 700-word article covering the key facts above.',
  writer_id,
  i.parent_issue_id
FROM issues i
WHERE i.title = 'Research: ' || topic
  AND i.status = 'resolved';
```

## Validating Handoff Data

Add a validation step between agents:

```typescript
function validateResearchHandoff(result: string): ResearchOutput {
  const data = JSON.parse(result);
  if (!data.summary || !Array.isArray(data.key_facts)) {
    throw new Error('Invalid research handoff: missing required fields');
  }
  return data as ResearchOutput;
}
```

If validation fails, the issue is marked `escalated` and a human reviews the raw output before the next agent proceeds.

## Handoff via Issue Metadata

For structured data that doesn't need to be in the description prose:

```sql
UPDATE issues
SET metadata = jsonb_set(
  COALESCE(metadata, '{}'),
  '{handoff}',
  result_structured
)
WHERE id = 'researcher-issue-id';
```

The next agent's issue can reference `metadata->'handoff'` directly.

## Checkpoint ✓

- [ ] You can add a JSON output schema to an agent's system prompt
- [ ] You understand `result_structured` and how it differs from `result`
- [ ] You can write a SQL query that reads from one agent's structured output to create the next agent's issue
$md$ WHERE slug = 'pcl-56-handoff-protocols';

-- ─── pcl-57-conflict-resolution ──────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Conflict Resolution in Multi-Agent Systems

## What you'll learn
Identify the three types of conflicts that arise in multi-agent systems, implement resolution strategies for each, and design conflict-resistant workflows.

## The Three Conflict Types

### 1. Resource Conflicts
Two agents try to work on the same logical resource (edit the same document, update the same database row).

### 2. Output Conflicts
Two agents produce contradictory outputs that must be merged (two researchers cite conflicting facts).

### 3. Authority Conflicts
An agent tries to take an action that another agent (its manager) has not authorised.

## Resolving Resource Conflicts

Paperclip prevents resource conflicts through atomic checkout — two agents cannot claim the same issue. But if both are working on the same *external* resource (e.g., a Google Doc), you need an application-level lock.

**Pattern: issue-as-lock**

Create a dedicated "lock issue" that must be resolved before work begins:

```sql
-- Agent A claims the lock issue first
INSERT INTO issues (company_id, title, assigned_agent_id, priority, status)
VALUES ('cid', 'LOCK: Document edit session', 'agent-a-id', 'critical', 'open');

-- Agent A's work issue has depends_on: lock issue
-- Only created after lock is resolved
```

## Resolving Output Conflicts

When two agents produce contradictory facts, a third "arbiter" agent resolves the conflict:

```
Researcher A → fact: "X was founded in 2015"
Researcher B → fact: "X was founded in 2017"
             ↓
Arbiter Agent (receives both outputs):
  → Fact-checks using primary sources
  → Picks the correct version
  → Notes the discrepancy in metadata
```

```sql
-- Create arbiter issue after both researchers resolve
INSERT INTO issues (company_id, title, description, assigned_agent_id, status)
VALUES (
  'cid',
  'Resolve conflicting research',
  'Agent A says: ' || a_result || '\n\nAgent B says: ' || b_result ||
  '\n\nVerify and resolve the conflict.',
  arbiter_id,
  'open'
);
```

## Resolving Authority Conflicts

An agent proposes an action that requires manager approval. The approval gate handles this automatically:

```
Worker Agent: "I need to purchase $200 of API credits"
  → Creates approval request (trigger: 'expenditure_request')
  → Manager Agent (or human) reviews
  → On approval: worker proceeds
  → On rejection: worker receives rejection reason
```

Add this to the worker's system prompt:
```
If your task requires spending money, hiring help, or external resources,
output {"request_approval": true, "reason": "...", "amount_usd": X}
instead of proceeding directly.
```

## Designing Conflict-Resistant Workflows

| Design choice | Why it reduces conflict |
|--------------|------------------------|
| Immutable task assignments | Once assigned, ownership is clear |
| Structured handoffs (JSON) | No ambiguity in what was passed |
| Approval gates for critical actions | Authority is explicit |
| One agent per resource at a time | Resource locks prevent contention |

## Checkpoint ✓

- [ ] You can describe the three conflict types with a concrete example of each
- [ ] You understand the issue-as-lock pattern for resource conflicts
- [ ] You know how an arbiter agent resolves output conflicts
$md$ WHERE slug = 'pcl-57-conflict-resolution';

-- ─── pcl-58-shared-memory ────────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Shared Memory: How Agents Share Context

## What you'll learn
Implement shared memory between agents using the `metadata` JSONB field, a dedicated memory table, and the issue result chain pattern.

## The Problem: Agents Are Stateless

By default, each agent invocation is fresh — it receives only the current issue's system prompt and description. Agents in a team can't naturally "remember" what their colleagues found.

## Pattern 1: Issue Result Chain

The simplest shared memory: each subsequent issue description includes the previous agent's result.

```sql
-- After researcher resolves, create writer issue with researcher's output
INSERT INTO issues (company_id, title, description, assigned_agent_id, parent_issue_id)
SELECT
  i.company_id,
  'Write: ' || topic,
  '--- RESEARCH NOTES ---\n' || i.result || '\n\n--- WRITING TASK ---\nWrite a 700-word article based on the research above.',
  writer_id,
  i.parent_issue_id
FROM issues i WHERE ...;
```

Limitation: only passes one previous result. Breaks down for complex multi-agent chains.

## Pattern 2: Company Memory Table

A shared key-value store all agents in a company can read from via their task prompts:

```sql
CREATE TABLE company_memory (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  key        text NOT NULL,
  value      jsonb NOT NULL,
  created_by uuid REFERENCES agents(id),
  updated_at timestamptz DEFAULT now(),
  UNIQUE (company_id, key)
);
```

Agents write to memory by including a `memory_write` key in their JSON output:

```json
{
  "result": "The article is written...",
  "memory_write": {
    "brand_voice_guidelines": "Professional but approachable; use active voice; avoid jargon"
  }
}
```

The heartbeat's post-processor detects `memory_write` and upserts:

```typescript
if (result.memory_write) {
  for (const [key, value] of Object.entries(result.memory_write)) {
    await db.company_memory.upsert({ company_id, key, value });
  }
}
```

Agents read memory by having it injected into their task prompts at invocation time.

## Pattern 3: Parent Issue Metadata

For project-scoped shared memory, use the parent issue's `metadata` JSONB:

```sql
-- Researcher stores findings in parent metadata
UPDATE issues
SET metadata = jsonb_set(
  COALESCE(metadata, '{}'),
  '{research_findings}',
  result_structured
)
WHERE id = parent_issue_id;
```

All sibling agents can read from the parent issue by joining on `parent_issue_id`.

## Memory Scope

| Pattern | Scope | Best for |
|---------|-------|---------|
| Issue result chain | Single pipeline run | Sequential handoffs |
| Company memory | All agents, all time | Brand guidelines, persistent knowledge |
| Parent metadata | One project/task | Project-specific context |

## Checkpoint ✓

- [ ] You can implement the issue result chain for simple handoffs
- [ ] You understand how the company memory table works and when to use it
- [ ] You know the three memory scopes and which to choose
$md$ WHERE slug = 'pcl-58-shared-memory';

-- ─── pcl-59-real-examples ────────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Real Multi-Agent Examples

## What you'll learn
Walk through three complete multi-agent systems, including their agent definitions, workflow design, and coordination patterns.

## Example 1: The Blog Factory

**Goal**: Autonomously produce 5 blog posts per week on trending AI topics.

```
Monitor Agent (daily, shell adapter)
  → fetches trending topics from HackerNews API
  → creates 5 Research issues

Researcher × 5 (parallel, claude-code)
  → each researches one topic
  → produces structured JSON with facts + sources

Writer × 5 (parallel, claude-code)
  → each writes 700-word draft from research notes
  → produces HTML draft

Editor (sequential, claude-code)
  → reviews each draft for quality
  → approved → SEO Agent
  → rejected → back to Writer with feedback

SEO Agent × N (claude-code)
  → adds meta title, description, tags
  → approved → Publisher (shell)

Publisher (shell adapter)
  → POSTs to WordPress/Ghost API
  → records published URL in issue metadata
```

**7 agents, ~$2.50 per post, fully autonomous after setup.**

## Example 2: The Code Review Bot

**Goal**: Review every PR on a GitHub repository.

```
GitHub Webhook → Paperclip webhook trigger
  → creates 1 issue per PR opened

Code Reviewer Agent (claude-code)
  → receives PR diff in issue description
  → produces structured review JSON:
    {severity, findings: [{file, line, issue, suggestion}]}

Approval Gate (if severity = 'critical')
  → notifies human lead engineer
  → human approves merge or requests changes

GitHub Commenter (shell adapter)
  → posts review findings as PR comments via GitHub API
  → labels PR based on severity
```

**2 agents + 1 approval gate, ~$0.08 per PR review.**

## Example 3: The Support Triage Team

**Goal**: Handle incoming support emails autonomously for 80% of tickets.

```
Classifier Agent (gpt-4o-mini, high volume, low cost)
  → classifies: billing / technical / account / abuse
  → priority: critical / high / medium / low

Router (shell adapter, deterministic)
  → routes to specialist queue based on classification

Billing Specialist (claude-code)
Technical Specialist (claude-code)
Account Specialist (claude-code)
  → each drafts a resolution email
  → confidence > 0.9: auto-send
  → confidence < 0.9: escalate to human

Human Queue (approval gate)
  → human reviews and sends manually
```

**5 agents, 80% automation rate, ~$0.003 per ticket.**

## Key Patterns Used

| Pattern | Used in |
|---------|---------|
| Webhook trigger | Code Review Bot, Support Triage |
| Parallel execution | Blog Factory (5 parallel researchers) |
| Sequential pipeline | Blog Factory (research → write → edit) |
| Approval gate | Code Review Bot, Support Triage |
| Shell adapter for integrations | Publisher, GitHub Commenter |
| Classifier + Router | Support Triage |

## Checkpoint ✓

- [ ] You can describe the Blog Factory's agent structure from memory
- [ ] You understand how the Code Review Bot uses a webhook trigger + approval gate
- [ ] You can estimate cost per unit for each example
$md$ WHERE slug = 'pcl-59-real-examples';

-- ─── pcl-60-scaling-agents ───────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Scaling Agent Teams

## What you'll learn
Strategies for scaling a Paperclip company from 5 agents to 50, understand the database and API rate limit constraints, and plan for horizontal scaling.

## What Scales Automatically

In Paperclip, the following scale without configuration changes:

- **Issue volume**: PostgreSQL handles millions of rows; `FOR UPDATE SKIP LOCKED` stays efficient up to hundreds of concurrent claims
- **Agent count**: more agents = more parallel invocations per tick
- **Companies**: each company is isolated; adding 100 companies doesn't affect another
- **Historical data**: `heartbeat_runs` and `cost_events` grow indefinitely; archive strategy covers this (pcl-50)

## The API Rate Limit Ceiling

The real scaling constraint is LLM API rate limits:

| Provider | Default rate limit |
|---------|-------------------|
| Anthropic | Varies by tier; starts ~50K tokens/min |
| OpenAI | Varies by tier; starts ~500K tokens/min |
| Groq | Very high; good for parallel scaling |
| Ollama | Hardware-limited |

**Strategy**: distribute agents across multiple API keys / providers:

```json
// Some agents use claude-code, others use openai, others use groq
// Each uses a different API key → different rate limit bucket
{ "agent_1_adapter": "claude-code", "agent_2_adapter": "openai", "agent_3_adapter": "groq" }
```

## Database Scaling

For high-volume production (>10K issues/day):

1. **Add indexes**:
```sql
CREATE INDEX CONCURRENTLY idx_issues_status_company
  ON issues (company_id, status, priority, created_at)
  WHERE status = 'open';

CREATE INDEX CONCURRENTLY idx_cost_events_month
  ON cost_events (company_id, date_trunc('month', created_at));
```

2. **Partition `cost_events` by month** (once >10M rows):
```sql
-- Range partitioning
CREATE TABLE cost_events_2024_01 PARTITION OF cost_events
FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
```

3. **Read replicas** for reporting queries — never run analytics against the primary.

## Horizontal Scaling the API Server

Run multiple instances of the Paperclip API server:

- Each instance runs its own heartbeat scheduler
- The `FOR UPDATE SKIP LOCKED` pattern ensures no double-work across instances
- Use a load balancer (Nginx, Traefik) in front

```
Load Balancer
├── API Server 1 (heartbeat + API requests)
├── API Server 2 (heartbeat + API requests)
└── API Server 3 (heartbeat + API requests)
         ↓
    PostgreSQL (single primary, read replicas)
```

## Scaling Checklist

```
□ Indexes on (company_id, status) for issues table
□ Indexes on (company_id, created_at) for cost_events
□ Multiple API key providers to spread rate limits
□ Read replica for reporting dashboards
□ Heartbeat interval tuned to task volume (not "every 1 min")
□ max_concurrent_agents set per company
□ Archive strategy for old runs and cost events
```

## Checkpoint ✓

- [ ] You can describe the database indexes needed for high-volume operation
- [ ] You understand how to spread load across multiple LLM API providers
- [ ] You know the horizontal scaling architecture for multiple API server instances
$md$ WHERE slug = 'pcl-60-scaling-agents';
