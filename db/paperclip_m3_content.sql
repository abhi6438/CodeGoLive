-- =============================================================================
-- Paperclip AI — Module 3: Agents & Org Charts
-- Topics: pcl-19 through pcl-27
-- =============================================================================

-- ─── pcl-19-agent-types ──────────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Agent Types and Adapter Families

## What you'll learn
The four adapter families in Paperclip AI, when to choose each one, and how adapter type determines what an agent can actually do.

## The Adapter is the Brain

An agent row in the database is configuration — it has no compute of its own. The **adapter** is what turns an invocation into a real LLM call, shell command, or HTTP request. Paperclip ships four adapter families:

| Adapter | Invokes | Best for |
|---------|---------|----------|
| `claude-code` | Anthropic Claude via CLI subprocess | Code generation, research, long-form reasoning |
| `openai` | OpenAI Chat Completions API | GPT-4o tasks, function calling |
| `http` | Any REST endpoint | External AI services, your own models |
| `shell` | Local shell command | File processing, data transforms, scripts |

## The `claude-code` Adapter

The default for local development. It spawns a `claude-code` CLI subprocess, passes the assembled prompt as stdin, and captures structured JSON output.

```json
{
  "adapter_type": "claude-code",
  "adapter_config": {
    "model": "claude-opus-4-5",
    "max_tokens": 4096,
    "temperature": 0.3
  }
}
```

Requires the `ANTHROPIC_API_KEY` environment variable. Works in sandbox mode (PGlite) and production.

## The `openai` Adapter

Uses the OpenAI Chat Completions API.

```json
{
  "adapter_type": "openai",
  "adapter_config": {
    "model": "gpt-4o",
    "max_tokens": 2048,
    "api_key_env": "OPENAI_API_KEY"
  }
}
```

Set `api_key_env` to the name of the environment variable that holds the key — never put the key directly in `adapter_config`.

## The `http` Adapter

Calls any REST endpoint with a POST request. Useful for Ollama, local models, or your own inference server.

```json
{
  "adapter_type": "http",
  "adapter_config": {
    "url": "http://localhost:11434/api/generate",
    "headers": { "Content-Type": "application/json" },
    "body_template": "{\"model\": \"llama3\", \"prompt\": \"{{prompt}}\"}"
  }
}
```

The `{{prompt}}` placeholder is replaced with the assembled task prompt at invocation time.

## The `shell` Adapter

Runs a shell command with the task description passed as an argument or stdin.

```json
{
  "adapter_type": "shell",
  "adapter_config": {
    "command": "python3 /home/agents/researcher.py",
    "timeout_ms": 30000
  }
}
```

Useful for data pipeline agents that don't need an LLM at all.

## Choosing an Adapter

```
Need LLM reasoning?
├── Yes, prefer Anthropic → claude-code
├── Yes, prefer OpenAI    → openai
├── Yes, local model      → http (point at Ollama)
└── No, pure computation  → shell
```

## Mixing Adapters in One Company

You can have agents with different adapters in the same company. A common pattern:

- **Researcher** → `claude-code` (heavy reasoning)
- **Formatter** → `openai` (lightweight, GPT-3.5)
- **DataLoader** → `shell` (runs a Python ETL script, no LLM needed)

## Checkpoint ✓

- [ ] You can describe all four adapter types and when each applies
- [ ] You know where to set `adapter_config` without exposing API keys
- [ ] You understand that the adapter provides compute; the agent row is just config
$md$ WHERE slug = 'pcl-19-agent-types';

-- ─── pcl-20-adapter-interface ────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# The Adapter Interface

## What you'll learn
The three-method contract every Paperclip adapter must implement, what the heartbeat calls when, and how to read the TypeScript interface definition.

## The Contract

Every adapter in Paperclip AI implements exactly three methods:

```typescript
interface Adapter {
  /**
   * Invoke the underlying model/service with the assembled task prompt.
   * Returns a run ID the heartbeat can use to poll for status.
   */
  invoke(task: AdapterTask): Promise<AdapterInvokeResult>;

  /**
   * Check the status of a previously invoked run.
   * Returns 'running', 'completed', or 'failed'.
   */
  status(runId: string): Promise<AdapterRunStatus>;

  /**
   * Cancel a running invocation.
   */
  cancel(runId: string): Promise<void>;
}
```

## `AdapterTask`

The data the heartbeat assembles and passes to `invoke`:

```typescript
interface AdapterTask {
  runId:        string;      // Unique ID for this invocation
  agentId:      string;      // Which agent is being invoked
  systemPrompt: string;      // From agents.system_prompt
  taskPrompt:   string;      // Assembled from issue title + description
  budgetUsd:    number;      // Remaining budget for this agent
  companyId:    string;      // For multi-tenant logging
  metadata:     Record<string, unknown>; // Adapter-specific extras
}
```

## `AdapterInvokeResult`

What `invoke` returns immediately after starting work:

```typescript
interface AdapterInvokeResult {
  runId:   string;  // May be same as input runId or a new external run ID
  status:  'running' | 'completed' | 'failed';
  output?: string;  // Present if synchronous adapter completed immediately
  cost?:   AdapterCost;
}
```

Some adapters (like `claude-code`) complete synchronously and return `status: 'completed'` immediately with `output` populated. Async adapters (like a long-running `http` endpoint) return `status: 'running'` and the heartbeat polls with `status()`.

## `AdapterRunStatus`

```typescript
interface AdapterRunStatus {
  status:  'running' | 'completed' | 'failed';
  output?: string;   // Present when status is 'completed'
  error?:  string;   // Present when status is 'failed'
  cost?:   AdapterCost;
}

interface AdapterCost {
  inputTokens:  number;
  outputTokens: number;
  costUsd:      number;
  model:        string;
}
```

## Where the Interface Lives

```
packages/server/src/lib/adapters/
├── interface.ts          ← the three-method contract
├── claude-code.ts        ← implementation
├── openai.ts
├── http.ts
├── shell.ts
└── factory.ts            ← creates the right adapter from adapter_type
```

## The Factory Pattern

The heartbeat never instantiates adapters directly. It calls the factory:

```typescript
// factory.ts
export function createAdapter(agent: Agent): Adapter {
  switch (agent.adapter_type) {
    case 'claude-code': return new ClaudeCodeAdapter(agent.adapter_config);
    case 'openai':      return new OpenAIAdapter(agent.adapter_config);
    case 'http':        return new HttpAdapter(agent.adapter_config);
    case 'shell':       return new ShellAdapter(agent.adapter_config);
    default: throw new Error(`Unknown adapter type: ${agent.adapter_type}`);
  }
}
```

Adding a new adapter means implementing the interface and adding one case to the factory.

## Checkpoint ✓

- [ ] You can name the three methods of the adapter interface
- [ ] You understand `AdapterTask` and what the heartbeat assembles
- [ ] You know the difference between synchronous and async adapters
$md$ WHERE slug = 'pcl-20-adapter-interface';

-- ─── pcl-21-claude-code-adapter ──────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# The Claude Code Adapter In Depth

## What you'll learn
How the `claude-code` adapter works internally, its configuration options, error handling, and how to debug it when things go wrong.

## How It Works

The `claude-code` adapter spawns a child process that runs the `claude` CLI:

```typescript
const proc = spawn('claude', [
  '--model', config.model,
  '--max-tokens', String(config.max_tokens),
  '--output-format', 'json',
], {
  input: fullPrompt,  // system + task prompt piped to stdin
  timeout: config.timeout_ms ?? 60_000,
  env: { ...process.env, ANTHROPIC_API_KEY: config.api_key ?? process.env.ANTHROPIC_API_KEY }
});
```

The output is captured from stdout and parsed as JSON. The `claude` CLI's `--output-format json` flag returns a structured envelope:

```json
{
  "type": "result",
  "result": "...the agent's markdown response...",
  "usage": {
    "input_tokens": 312,
    "output_tokens": 847
  },
  "model": "claude-opus-4-5"
}
```

## Full `adapter_config` Reference

```json
{
  "model":       "claude-opus-4-5",   // required
  "max_tokens":  4096,               // default: 4096
  "temperature": 0.3,               // default: 0.7
  "timeout_ms":  60000,             // default: 60 000ms
  "api_key_env": "ANTHROPIC_API_KEY" // env var name; default: ANTHROPIC_API_KEY
}
```

## Synchronous Execution

The `claude-code` adapter is **synchronous** — it waits for the subprocess to finish before returning. This means:

- `invoke()` blocks until Claude responds
- Returns `status: 'completed'` (or `'failed'`) immediately
- `status()` and `cancel()` are no-ops (run already done)
- The heartbeat tick is serialized per agent in this adapter

For most use cases this is fine. If you need parallel Claude invocations, run multiple agents with the same adapter type — each gets its own subprocess.

## Error Scenarios

| Error | Cause | Fix |
|-------|-------|-----|
| `ENOENT: claude not found` | CLI not installed | `npm install -g @anthropic-ai/claude-code` |
| `401 Unauthorized` | Invalid API key | Check `ANTHROPIC_API_KEY` env var |
| `429 Too Many Requests` | Rate limit hit | Add retry logic or reduce heartbeat frequency |
| `SIGKILL (timeout)` | Response took >timeout_ms | Increase `timeout_ms` or shorten prompt |
| JSON parse error | CLI produced non-JSON output | Check `--output-format json` flag |

## Debugging a Failed Run

1. Find the failed heartbeat run in the Activity feed.
2. Click to expand — the `error` field shows the raw CLI output.
3. Or query directly:

```sql
SELECT error_detail
FROM heartbeat_runs
WHERE id = 'your-run-id';
```

4. To reproduce locally:

```bash
ANTHROPIC_API_KEY=your_key \
claude --model claude-opus-4-5 --output-format json \
  <<< "You are a researcher. Summarise PostgreSQL RLS in 2 paragraphs."
```

## Checkpoint ✓

- [ ] You understand the subprocess spawn model
- [ ] You can configure model, tokens, and timeout in `adapter_config`
- [ ] You know how to debug a failed Claude Code adapter run
$md$ WHERE slug = 'pcl-21-claude-code-adapter';

-- ─── pcl-22-openai-adapter ───────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# The OpenAI Adapter

## What you'll learn
Configure an OpenAI-backed agent, understand function calling support, and swap models between GPT-4o and GPT-3.5-turbo.

## Configuration

```json
{
  "adapter_type": "openai",
  "adapter_config": {
    "model":       "gpt-4o",
    "max_tokens":  2048,
    "temperature": 0.4,
    "api_key_env": "OPENAI_API_KEY",
    "timeout_ms":  45000
  }
}
```

Never put the key value directly in `adapter_config` — Paperclip reads the named environment variable at invocation time.

## How the Adapter Calls the API

The OpenAI adapter uses the Chat Completions endpoint:

```typescript
const response = await openai.chat.completions.create({
  model: config.model,
  messages: [
    { role: 'system',  content: task.systemPrompt },
    { role: 'user',    content: task.taskPrompt  }
  ],
  max_tokens:  config.max_tokens ?? 2048,
  temperature: config.temperature ?? 0.7,
});
```

## Model Selection Guide

| Model | Speed | Cost | Best for |
|-------|-------|------|----------|
| `gpt-4o` | Medium | $$$ | Complex reasoning, code, long context |
| `gpt-4o-mini` | Fast | $ | Summarisation, classification |
| `gpt-3.5-turbo` | Fast | $ | Simple text tasks, high volume |
| `o1-mini` | Slow | $$ | Multi-step math, logic |

For most Paperclip agents `gpt-4o-mini` offers the best cost/quality ratio.

## Switching a Running Agent's Model

You can update `adapter_config` live without restarting:

```bash
curl -X PATCH http://localhost:3100/api/companies/${COMPANY_ID}/agents/${AGENT_ID} \
  -H "Content-Type: application/json" \
  -d '{"adapter_config": {"model": "gpt-4o-mini", "max_tokens": 1024}}'
```

Changes take effect on the next heartbeat tick.

## Cost Tracking

The OpenAI adapter extracts `usage.prompt_tokens` and `usage.completion_tokens` from the API response and passes them to the cost ledger. Pricing per model is configured in `packages/server/src/lib/costs/pricing.ts`.

To add a new model's pricing:

```typescript
// pricing.ts
export const PRICING: Record<string, TokenPricing> = {
  'gpt-4o':      { input: 0.005, output: 0.015 },  // per 1K tokens
  'gpt-4o-mini': { input: 0.00015, output: 0.0006 },
  // add new entries here
};
```

## Checkpoint ✓

- [ ] You can create an OpenAI-backed agent with a safe `api_key_env` reference
- [ ] You understand how to choose between GPT-4o and GPT-4o-mini
- [ ] You know how to update the model without restarting the server
$md$ WHERE slug = 'pcl-22-openai-adapter';

-- ─── pcl-23-http-adapter ─────────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# The HTTP Adapter: Local and Custom Models

## What you'll learn
Use the HTTP adapter to connect Paperclip agents to Ollama, a custom inference server, or any REST-based AI service.

## When to Use the HTTP Adapter

- **Local models via Ollama** — run Llama 3, Mistral, or Phi-3 without cloud API costs
- **Azure OpenAI** — same API shape as OpenAI but different endpoint and auth
- **Your own fine-tuned model** — self-hosted FastAPI inference server
- **External AI services** — Cohere, Mistral AI Cloud, Groq, etc.

## Ollama Example

Start Ollama with Llama 3:
```bash
ollama pull llama3
ollama serve  # starts on localhost:11434
```

Configure the agent:
```json
{
  "adapter_type": "http",
  "adapter_config": {
    "url": "http://localhost:11434/api/generate",
    "method": "POST",
    "headers": { "Content-Type": "application/json" },
    "body_template": "{\"model\": \"llama3\", \"prompt\": \"{{system_prompt}}\\n\\n{{task_prompt}}\", \"stream\": false}",
    "response_path": "response"
  }
}
```

`response_path` is a dot-notation path to extract the text from the response JSON. For Ollama the full text is at `.response`.

## Azure OpenAI Example

```json
{
  "adapter_type": "http",
  "adapter_config": {
    "url": "https://my-resource.openai.azure.com/openai/deployments/gpt-4o/chat/completions?api-version=2024-02-01",
    "method": "POST",
    "headers": {
      "Content-Type": "application/json",
      "api-key": "{{env.AZURE_OPENAI_KEY}}"
    },
    "body_template": "{\"messages\": [{\"role\": \"system\", \"content\": \"{{system_prompt}}\"}, {\"role\": \"user\", \"content\": \"{{task_prompt}}\"}], \"max_tokens\": 2048}",
    "response_path": "choices.0.message.content"
  }
}
```

`{{env.VAR_NAME}}` substitutes the named environment variable at invocation time — keys never appear in the database.

## Template Variables

| Variable | Value |
|----------|-------|
| `{{system_prompt}}` | Agent's system prompt |
| `{{task_prompt}}` | Assembled task description |
| `{{run_id}}` | This invocation's run ID |
| `{{agent_id}}` | Agent's database ID |
| `{{env.VAR_NAME}}` | Environment variable |

## Async HTTP Adapters

If your endpoint is long-running and returns a job ID, configure `async_mode`:

```json
{
  "adapter_config": {
    "url": "https://my-service.com/jobs",
    "async_mode": true,
    "status_url": "https://my-service.com/jobs/{{run_id}}",
    "status_path": "job.status",
    "output_path": "job.result",
    "poll_interval_ms": 5000
  }
}
```

Paperclip polls `status_url` every `poll_interval_ms` until `status_path` is `"completed"` or `"failed"`, then reads the output from `output_path`.

## Checkpoint ✓

- [ ] You can configure an Ollama-backed agent using the HTTP adapter
- [ ] You understand template variables and how `{{env.VAR}}` keeps secrets safe
- [ ] You know the difference between sync and async HTTP adapters
$md$ WHERE slug = 'pcl-23-http-adapter';

-- ─── pcl-24-shell-adapter ────────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# The Shell Adapter: Script-Based Agents

## What you'll learn
Build agents that run shell scripts or Python programs instead of calling an LLM, useful for data pipelines and deterministic processing steps.

## When Scripts Beat LLMs

Not every agent needs a language model. Use the shell adapter when:
- The task is fully deterministic (format conversion, data extraction, validation)
- You already have a working Python/Node script
- LLM costs need to be zero for high-frequency tasks
- You need to access local files or databases the LLM can't reach

## Basic Configuration

```json
{
  "adapter_type": "shell",
  "adapter_config": {
    "command": "python3 /home/agents/etl.py",
    "timeout_ms": 30000,
    "working_dir": "/home/agents"
  }
}
```

## How the Adapter Calls Your Script

The assembled task prompt is passed as the first command-line argument AND piped to stdin:

```bash
# Equivalent to what the adapter does:
echo "${TASK_PROMPT}" | python3 /home/agents/etl.py "${TASK_PROMPT}"
```

Your script reads from stdin (or `sys.argv[1]`) and writes the result to stdout. Exit code 0 = success, non-zero = failure.

## Example: CSV Summariser Agent

```python
#!/usr/bin/env python3
# /home/agents/csv_summariser.py
import sys
import json
import csv
import io

task = sys.stdin.read()
# Extract CSV path from task description (simple heuristic)
lines = task.split('\n')
csv_path = next((l.split(': ')[1] for l in lines if l.startswith('FILE:')), None)

if not csv_path:
    print("ERROR: No FILE: line found in task", file=sys.stderr)
    sys.exit(1)

with open(csv_path) as f:
    reader = csv.DictReader(f)
    rows = list(reader)

print(f"## CSV Summary\n")
print(f"- **Rows**: {len(rows)}")
print(f"- **Columns**: {', '.join(rows[0].keys()) if rows else 'empty'}")
print(f"- **First row**: {json.dumps(rows[0]) if rows else 'N/A'}")
```

Issue description format for this agent:
```
FILE: /data/sales_q1.csv
Summarise the structure and first row of this CSV file.
```

## Environment Variables in Shell Agents

```json
{
  "adapter_config": {
    "command": "node /home/agents/loader.js",
    "env": {
      "DB_URL": "{{env.DATABASE_URL}}",
      "API_KEY": "{{env.STRIPE_KEY}}"
    }
  }
}
```

## Cost Tracking for Shell Agents

Shell agents incur no token cost. A `cost_event` is still recorded with `cost_usd = 0` and `model = 'shell'`, so the audit trail stays complete.

## Checkpoint ✓

- [ ] You understand when a shell agent makes more sense than an LLM agent
- [ ] You can write a Python script that reads from stdin and writes to stdout
- [ ] You know how to pass environment variables safely to shell agents
$md$ WHERE slug = 'pcl-24-shell-adapter';

-- ─── pcl-25-org-hierarchy ────────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Building an Org Chart

## What you'll learn
Use the `reports_to` field to build a management hierarchy, understand how the org chart renders in the UI, and set up a simple CEO → Manager → Worker structure.

## The `reports_to` Field

The `agents` table has a self-referential foreign key:

```sql
ALTER TABLE public.agents
  ADD COLUMN reports_to uuid REFERENCES public.agents(id) ON DELETE SET NULL;
```

Setting `reports_to` to another agent's ID means "this agent reports to that one." The relationship is purely informational in the current Paperclip version — it drives the org chart visualization and approval routing but does not automatically route tasks.

## A Three-Level Hierarchy

```
CEO Agent (no reports_to)
├── Engineering Manager
│   ├── Backend Developer
│   └── Frontend Developer
└── Marketing Manager
    ├── Content Writer
    └── Social Media Agent
```

SQL setup:
```sql
DO $$
DECLARE
  cid  uuid;
  ceo  uuid;
  eng  uuid;
  mkt  uuid;
BEGIN
  SELECT id INTO cid FROM companies WHERE slug = 'demo-corp';

  -- Level 1: CEO
  INSERT INTO agents (company_id, name, role, system_prompt, adapter_type, monthly_budget_usd, status)
  VALUES (cid, 'CEO', 'Chief Executive Officer',
    'You are the CEO. You delegate tasks to department managers and review their reports.',
    'claude-code', 20.00, 'active')
  RETURNING id INTO ceo;

  -- Level 2: Managers
  INSERT INTO agents (company_id, name, role, system_prompt, adapter_type, monthly_budget_usd, status, reports_to)
  VALUES (cid, 'Eng Manager', 'Engineering Manager',
    'You manage the engineering team. You break down technical tasks and delegate to developers.',
    'claude-code', 10.00, 'active', ceo)
  RETURNING id INTO eng;

  INSERT INTO agents (company_id, name, role, system_prompt, adapter_type, monthly_budget_usd, status, reports_to)
  VALUES (cid, 'Mkt Manager', 'Marketing Manager',
    'You manage the marketing team. You plan campaigns and delegate content creation.',
    'claude-code', 10.00, 'active', ceo)
  RETURNING id INTO mkt;

  -- Level 3: Workers
  INSERT INTO agents (company_id, name, role, system_prompt, adapter_type, monthly_budget_usd, status, reports_to)
  VALUES
    (cid, 'Backend Dev', 'Backend Developer',
     'You write server-side code. Focus on correctness and security.',
     'claude-code', 5.00, 'active', eng),
    (cid, 'Frontend Dev', 'Frontend Developer',
     'You write React components. Focus on accessibility and performance.',
     'claude-code', 5.00, 'active', eng),
    (cid, 'Content Writer', 'Content Writer',
     'You write blog posts and documentation.',
     'claude-code', 3.00, 'active', mkt),
    (cid, 'Social Media', 'Social Media Agent',
     'You draft social media posts in a professional but engaging tone.',
     'claude-code', 2.00, 'active', mkt);
END $$;
```

## Viewing the Org Chart

In the Paperclip UI → Company Dashboard → **Org Chart** tab. The chart renders as an interactive tree using D3.js. Click any node to jump to that agent's dashboard.

## Querying the Hierarchy

```sql
-- Show all agents with their manager
SELECT
  a.name AS agent,
  a.role,
  m.name AS reports_to
FROM agents a
LEFT JOIN agents m ON m.id = a.reports_to
WHERE a.company_id = 'your-company-id'
ORDER BY m.name NULLS FIRST, a.name;
```

## Checkpoint ✓

- [ ] You have set up a three-level hierarchy with CEO, managers, and workers
- [ ] The org chart renders correctly in the UI
- [ ] You can query the hierarchy with a self-join
$md$ WHERE slug = 'pcl-25-org-hierarchy';

-- ─── pcl-26-reports-to ───────────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Reports-To Routing and Escalation

## What you'll learn
How `reports_to` influences approval routing and escalation paths, and how to set up a manager who reviews their team's work.

## Automatic Escalation

When an agent encounters a task that exceeds its authority (defined in approval policies), Paperclip routes the approval request to its manager — the agent in `reports_to`.

```
Worker Agent → creates approval request
  ↓ (if worker has no human approver configured)
Manager Agent → reviews and approves or rejects
  ↓ (if manager also has no authority)
CEO Agent → final human-equivalent authority
```

The escalation chain follows `reports_to` links until it finds an agent with `approver_type = 'human'` configured, or reaches a root agent (no `reports_to`).

## Configuring an Agent as an Approver

```sql
UPDATE agents
SET adapter_config = jsonb_set(
  COALESCE(adapter_config, '{}'::jsonb),
  '{approver_type}',
  '"human"'
)
WHERE name = 'CEO'
  AND company_id = 'your-company-id';
```

An agent with `approver_type = 'human'` pauses the escalation chain. Paperclip creates a pending approval record and notifies via webhook — a human reviews it in the Approvals UI.

## The Manager Review Pattern

A common pattern is to have managers review worker output before it is marked resolved:

1. Worker agent resolves an issue with a draft result
2. A policy triggers a review approval to the manager
3. Manager agent (or human) reviews the draft
4. On approval the issue status changes to `verified`

Configure this in Company Settings → Approval Policies:
```json
{
  "trigger": "issue_resolved",
  "condition": "result_word_count > 500",
  "required_approver": "manager",
  "approval_type": "content_review"
}
```

## Querying Pending Escalations

```sql
SELECT
  ap.id,
  ap.trigger,
  ap.status,
  req.name AS requested_by,
  rev.name AS reviewer,
  ap.created_at
FROM approvals ap
JOIN agents req ON req.id = ap.requesting_agent_id
LEFT JOIN agents rev ON rev.id = ap.reviewer_agent_id
WHERE ap.company_id = 'your-company-id'
  AND ap.status = 'pending'
ORDER BY ap.created_at;
```

## Circular Hierarchy Check

Paperclip prevents circular `reports_to` chains at write time:

```typescript
// Before saving, walk up the chain
async function checkCircular(agentId: string, reportsToId: string) {
  let current = reportsToId;
  while (current) {
    if (current === agentId) throw new Error('Circular hierarchy detected');
    const parent = await db.agents.findOne(current);
    current = parent?.reports_to ?? null;
  }
}
```

## Checkpoint ✓

- [ ] You understand how approval routing follows `reports_to`
- [ ] You can configure a root agent as a human-equivalent approver
- [ ] You can query pending approvals in the database
$md$ WHERE slug = 'pcl-26-reports-to';

-- ─── pcl-27-custom-adapter ───────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Building a Custom Adapter

## What you'll learn
Implement the three-method adapter interface to connect Paperclip to any AI service, including a worked example connecting to Groq's ultra-fast inference API.

## The Three Files You Need

```
packages/server/src/lib/adapters/
├── groq.ts         ← your implementation
├── interface.ts    ← the contract you implement
└── factory.ts      ← register your adapter here
```

## Step 1 — Implement the Interface

```typescript
// packages/server/src/lib/adapters/groq.ts
import Groq from 'groq-sdk';
import type { Adapter, AdapterTask, AdapterInvokeResult, AdapterRunStatus } from './interface';

interface GroqConfig {
  model: string;
  api_key_env?: string;
  max_tokens?: number;
}

export class GroqAdapter implements Adapter {
  private client: Groq;
  private config: GroqConfig;

  constructor(config: GroqConfig) {
    this.config = config;
    const apiKey = config.api_key_env
      ? process.env[config.api_key_env]
      : process.env.GROQ_API_KEY;
    this.client = new Groq({ apiKey });
  }

  async invoke(task: AdapterTask): Promise<AdapterInvokeResult> {
    const response = await this.client.chat.completions.create({
      model: this.config.model ?? 'llama3-70b-8192',
      messages: [
        { role: 'system', content: task.systemPrompt },
        { role: 'user',   content: task.taskPrompt  },
      ],
      max_tokens: this.config.max_tokens ?? 2048,
    });

    const output = response.choices[0]?.message?.content ?? '';
    const usage  = response.usage;

    return {
      runId:  task.runId,
      status: 'completed',
      output,
      cost: {
        inputTokens:  usage?.prompt_tokens    ?? 0,
        outputTokens: usage?.completion_tokens ?? 0,
        costUsd:      ((usage?.prompt_tokens ?? 0) * 0.000_000_27)
                    + ((usage?.completion_tokens ?? 0) * 0.000_000_27),
        model: this.config.model,
      },
    };
  }

  // Groq is synchronous, so status/cancel are no-ops
  async status(_runId: string): Promise<AdapterRunStatus> {
    return { status: 'completed' };
  }

  async cancel(_runId: string): Promise<void> {}
}
```

## Step 2 — Register in the Factory

```typescript
// factory.ts — add one case:
case 'groq': return new GroqAdapter(agent.adapter_config as GroqConfig);
```

## Step 3 — Add Pricing

```typescript
// packages/server/src/lib/costs/pricing.ts
export const PRICING: Record<string, TokenPricing> = {
  // ... existing entries
  'llama3-70b-8192':  { input: 0.00027, output: 0.00027 },
  'llama3-8b-8192':   { input: 0.00005, output: 0.00008 },
};
```

## Step 4 — Install the SDK

```bash
cd packages/server
pnpm add groq-sdk
```

## Step 5 — Use the New Adapter

```json
{
  "adapter_type": "groq",
  "adapter_config": {
    "model": "llama3-70b-8192",
    "api_key_env": "GROQ_API_KEY",
    "max_tokens": 2048
  }
}
```

## Checkpoint ✓

- [ ] You have implemented all three methods of the adapter interface
- [ ] Your adapter is registered in the factory and pricing config
- [ ] You can create an agent that uses your new adapter type
$md$ WHERE slug = 'pcl-27-custom-adapter';
