-- =============================================================================
-- Paperclip AI — Module 1: Foundations — Content
-- Run AFTER paperclip_seed.sql
-- =============================================================================

UPDATE public.topics SET status = 'published', content_md = $md$
# How Paperclip Works — Core Workflow

## What you'll learn

By the end of this lesson you'll understand the complete daily-use loop in Paperclip AI — from creating a company through to reviewing agent outputs — before touching any code.

---

## The six-stage loop

Every interaction with Paperclip follows the same repeating cycle:

```
1. Create Company
       ↓
2. Hire Agents
       ↓
3. Seed Issues (tasks)
       ↓
4. Heartbeats Fire  ←─────────────────┐
       ↓                               │
5. Agents Work                         │
       ↓                               │
6. Review Outputs ──────── iterate ────┘
```

Once you reach stage 4, the loop runs automatically on a schedule. Your job as the operator shifts from "doing work" to "reviewing work and adjusting direction."

---

## Stage 1 — Create a Company

A **Company** is the top-level container for everything in Paperclip. All agents, tasks, costs, and logs belong to exactly one company. Think of it as a separate workspace or tenant.

You create a company with a name and a timezone. The timezone drives when daily heartbeat windows fire.

---

## Stage 2 — Hire Agents

An **Agent** is a named worker with a role, a system prompt, and an adapter that tells Paperclip how to actually run it (Claude Code CLI, OpenAI API, a webhook, or a shell script).

When you "hire" an agent a human approval gate fires first — you have to confirm the hire. This is intentional: agent creation is a consequential action with real cost implications.

---

## Stage 3 — Seed Issues

**Issues** are tasks. They have a title, a description, a status (`open → in_progress → completed`), and optionally a parent issue for nesting subtasks.

You can create issues manually, bulk-import them via the API, or have a manager agent create them for worker agents to pick up.

---

## Stage 4 — Heartbeats Fire

A **heartbeat** is a scheduled trigger that wakes each agent according to its cron schedule. When a heartbeat fires for an agent, Paperclip:

1. Checks the agent isn't already running (concurrency lock)
2. Checks the agent's monthly budget hasn't been exceeded
3. Selects the highest-priority `open` issue assigned to the agent
4. Calls `adapter.invoke(issue)` — the adapter runs the actual AI work

---

## Stage 5 — Agents Work

The adapter does the work. For a Claude Code adapter this means spawning the `claude` CLI with the issue as context. For an OpenAI adapter it means calling the chat completions API. For an HTTP adapter it means POSTing to an external endpoint.

The adapter returns a `runId`. Paperclip polls `adapter.status(runId)` until the run completes, then captures the output and records the token cost.

---

## Stage 6 — Review Outputs

After each heartbeat run, Paperclip writes:
- A `heartbeat_runs` record with status, duration, token count, and cost
- A `cost_event` with the USD amount charged
- An `activity_log` entry describing what happened

You review these in the dashboard, check whether the agent moved issues forward, and decide whether to adjust the agent's prompt, add more tasks, or change the schedule.

---

## Key mental model

> Paperclip is a **control plane**, not an execution engine. It decides *what* agents work on and *when* — the actual intelligence lives inside the adapters (Claude, GPT, your own code).

---

## Checkpoint ✓

- What are the 6 stages of the Paperclip loop?
- What is a heartbeat?
- What is the difference between a Company, an Agent, and an Issue?
- What does an adapter do?
$md$ WHERE slug = 'pcl-how-it-works';


UPDATE public.topics SET status = 'published', content_md = $md$
# Local Development Environment Setup

## What you'll build

A fully working Paperclip AI development environment on your local machine — Node.js, pnpm, VS Code extensions, and a verified installation where all three services (API, frontend, database) start cleanly.

---

## Prerequisites

- macOS, Linux, or Windows (WSL2 recommended on Windows)
- 4 GB RAM minimum (8 GB recommended)
- Basic terminal comfort

---

## Step 1 — Install Node.js 20 via nvm

Paperclip requires **Node.js 20 LTS**. The easiest way to manage Node versions is nvm.

```bash
# macOS / Linux
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

# Restart terminal, then:
nvm install 20
nvm use 20
nvm alias default 20
```

**Verify:**
```bash
node --version   # v20.x.x
npm --version    # 10.x.x
```

> **Windows users:** Install [nvm-windows](https://github.com/coreybutler/nvm-windows) instead, then run the same `nvm install 20` command in PowerShell.

---

## Step 2 — Install pnpm 9.15+

Paperclip uses **pnpm** (not npm or yarn) as its package manager. pnpm is faster and uses a shared content-addressable store to avoid duplicate packages.

```bash
npm install -g pnpm@latest

# Verify
pnpm --version   # 9.15.x or higher
```

---

## Step 3 — Clone the repository

```bash
git clone https://github.com/paperclipai/paperclip.git
cd paperclip

# Install all workspace dependencies
pnpm install
```

pnpm will install packages for all three workspaces: `apps/server`, `apps/web`, and `packages/`.

---

## Step 4 — Configure environment variables

Copy the example env file and fill in your API keys:

```bash
cp .env.example .env
```

Open `.env` and set the values you need:

```env
# Required: at least one adapter key
ANTHROPIC_API_KEY=sk-ant-...       # for Claude Code adapter
OPENAI_API_KEY=sk-...              # for OpenAI adapter (optional)

# Database (defaults to PGlite in dev — no setup needed)
DATABASE_URL=                      # leave blank to use embedded PGlite

# Server
PORT=3100
HEARTBEAT_INTERVAL_MS=60000        # how often the scheduler ticks (1 min)

# Frontend
VITE_API_URL=http://localhost:3100
```

> **ANTHROPIC_API_KEY is the only truly required key** for the default Claude Code adapter. Everything else has a working default for local dev.

---

## Step 5 — Recommended VS Code extensions

Open VS Code in the project root (`code .`) and install:

| Extension | Why |
|-----------|-----|
| **ESLint** | Catches TypeScript and style issues as you type |
| **Prettier** | Formats code on save to match project style |
| **Drizzle ORM** | Schema introspection and query hints |
| **Thunder Client** | REST API testing inside VS Code |
| **GitLens** | Better git blame and history |

---

## Step 6 — Start the development servers

```bash
pnpm dev
```

This starts three processes in parallel:
1. `apps/server` — Express API on port **3100**
2. `apps/web` — Vite dev server on port **5173**
3. The Drizzle migration runs automatically on first start

**What healthy output looks like:**

```
[server] ✓ Database migrated (8 tables)
[server] ✓ Scheduler started — interval: 60s
[server] ✓ API listening on http://localhost:3100
[web]    ✓ Local:   http://localhost:5173/
```

> If you see any `EADDRINUSE` error, another process is on port 3100 or 5173. Run `lsof -i :3100` to find and kill it.

---

## Step 7 — Verify the 5 health checks

| Check | How |
|-------|-----|
| API is up | `curl http://localhost:3100/health` → `{"status":"ok"}` |
| DB migrated | Server log shows "8 tables" on startup |
| Frontend loads | Open http://localhost:5173 in browser |
| Scheduler running | Server log shows "Scheduler started" |
| No TS errors | `pnpm typecheck` exits with code 0 |

---

## Checkpoint ✓

- Node 20, pnpm 9.15+, and the repo are installed
- `.env` has your ANTHROPIC_API_KEY
- `pnpm dev` starts cleanly with all 3 services
- `curl localhost:3100/health` returns `{"status":"ok"}`
$md$ WHERE slug = 'pcl-local-dev-setup';


UPDATE public.topics SET status = 'published', content_md = $md$
# Working in Sandbox & Dev Mode (PGlite)

## What you'll learn

How Paperclip's embedded PGlite database works as a zero-cost local sandbox, how to run test heartbeats without spending real API credits, and when to switch to real PostgreSQL.

---

## What is PGlite?

**PGlite** is a full PostgreSQL engine compiled to WebAssembly that runs in-process — no separate database server required. When `DATABASE_URL` is blank in your `.env`, Paperclip automatically uses PGlite as its persistence layer.

This means:
- **Zero setup** — no Postgres install, no Docker, no connection strings
- **Full SQL compatibility** — every Paperclip query runs identically
- **Data lives on disk** — in `.paperclip/dev.db` in the project root

---

## Where sandbox data is stored

```
paperclip/
  .paperclip/
    dev.db          ← PGlite database file (all your sandbox data)
    dev.db-wal      ← write-ahead log (normal, auto-managed)
```

You can inspect this file with any SQLite-compatible viewer (e.g. the SQLite Viewer VS Code extension — PGlite files are SQLite-format compatible for reads).

---

## Running test heartbeats without API costs

The fastest way to iterate in the sandbox is to use the **dry-run** flag, which runs the heartbeat scheduling logic but calls a mock adapter instead of the real AI:

```bash
# Trigger a dry-run heartbeat for all active agents
curl -X POST http://localhost:3100/api/heartbeat/trigger \
  -H "Content-Type: application/json" \
  -d '{"dry_run": true}'
```

A dry-run:
- Selects tasks exactly as a real run would
- Creates `heartbeat_runs` records with `status: 'dry_run'`
- Does **not** call any adapter (no API cost)
- Writes to `activity_log` so you can verify routing logic

---

## Resetting sandbox state

When you want a clean slate:

**Option A — Delete just the database file:**
```bash
rm .paperclip/dev.db .paperclip/dev.db-wal
# Restart pnpm dev — Drizzle will re-run migrations automatically
```

**Option B — Reset via the API (keeps the server running):**
```bash
curl -X POST http://localhost:3100/api/dev/reset
# ⚠ Only available when NODE_ENV=development
```

Both options wipe all companies, agents, issues, and logs. The schema is recreated automatically on next startup.

---

## Switching from PGlite to real PostgreSQL

When you're ready for production — or when you want to share a persistent sandbox with teammates — swap to a real PostgreSQL instance:

```env
# .env
DATABASE_URL=postgresql://user:password@localhost:5432/paperclip_dev
```

Paperclip detects the `DATABASE_URL` and skips PGlite entirely. Drizzle runs the same migrations against the real database on startup.

> **No code changes needed** — the switch is purely configuration. All Drizzle queries work identically against PGlite and PostgreSQL.

---

## PGlite limitations to know

| Limitation | Impact |
|-----------|--------|
| Single-process only | Can't run two server instances pointing at the same PGlite file |
| No network access | Can't connect external tools (pgAdmin, DBeaver) directly — use the API instead |
| File lock | Stop `pnpm dev` before deleting `dev.db` |
| Not for production | PGlite is a dev/test tool only — always use real PostgreSQL in production |

---

## Sandbox workflow summary

```
Start pnpm dev (PGlite auto-created)
     ↓
Create test company + agents
     ↓
Trigger dry-run heartbeats (zero cost)
     ↓
Verify routing, logging, task selection
     ↓
Switch to real adapter for live testing
     ↓
Reset sandbox when done → rm dev.db
```

---

## Checkpoint ✓

- Where is the PGlite database file stored?
- How do you trigger a heartbeat without spending API credits?
- How do you reset the sandbox to a clean state?
- What single `.env` change switches from PGlite to real PostgreSQL?
$md$ WHERE slug = 'pcl-sandbox-mode';


UPDATE public.topics SET status = 'published', content_md = $md$
# What Is Paperclip AI?

## What you'll learn

What Paperclip AI is, the problem it solves, and the critical distinction between Paperclip as a control plane and the AI models it orchestrates.

---

## The problem Paperclip solves

AI models like Claude and GPT-4 are powerful but stateless — every conversation starts fresh. They have no memory of yesterday's work, no awareness of what other agents are doing, no budget limits, and no one checking whether they're actually making progress on a goal.

**Paperclip** is the layer that provides all of this:

| Without Paperclip | With Paperclip |
|-------------------|----------------|
| You manually prompt the AI each time | Agents run automatically on a schedule |
| No task tracking | Every task has a lifecycle and owner |
| No cost control | Per-agent monthly budget limits |
| No audit trail | Every action logged to the database |
| One person, one conversation | Multiple agents working in parallel |

---

## What Paperclip actually does

Paperclip is a **control plane** for AI agents. It answers four questions:

1. **Who** should work on this? (agent assignment)
2. **What** should they work on? (issue/task selection)
3. **When** should they work? (heartbeat scheduling)
4. **How much** can they spend? (budget governance)

The "how" — the actual thinking, writing, and coding — stays inside the AI model.

---

## The zero-human company vision

The original goal of Paperclip is to make it possible to run a company where every operational role is filled by an AI agent:

```
CEO Agent (strategy, priority)
  ├── CTO Agent (technical direction)
  │     ├── Engineer Agent A (backend tasks)
  │     └── Engineer Agent B (frontend tasks)
  └── Content Agent (marketing, docs)
```

Each agent has a role, a prompt defining its responsibilities, a schedule, and a budget. They coordinate through shared tasks (issues) rather than real-time conversation.

> **"Zero-human" doesn't mean unsupervised.** Human approval gates are built into the platform for high-stakes decisions: hiring agents, changing strategy, terminating agents, and budget increases all require a human to click approve.

---

## What Paperclip is NOT

- Not a chat interface (use Claude.ai or the Anthropic API directly for that)
- Not a model itself (it doesn't generate text — adapters call models)
- Not a workflow builder like n8n or Zapier (it's purpose-built for agent teams)
- Not an RPA tool (it works with AI, not GUI automation)

---

## The key components at a glance

| Component | What it is |
|-----------|-----------|
| **Company** | A workspace — all agents and tasks belong to one company |
| **Agent** | A named AI worker with a role, prompt, adapter, schedule, and budget |
| **Issue** | A task — title, description, status, priority, assignee |
| **Heartbeat** | A scheduled trigger that wakes an agent to do a work cycle |
| **Adapter** | The bridge to an AI model (Claude Code, OpenAI, HTTP, Shell) |
| **Activity Log** | The audit trail of everything that happened |

---

## Quick start reference

```bash
# Zero-config start (uses embedded PGlite, prompts for your API key)
npx paperclipai onboard --yes

# Developer start (full monorepo)
git clone https://github.com/paperclipai/paperclip.git
cd paperclip && pnpm install && pnpm dev

# Docker start
docker compose up
```

API runs at `http://localhost:3100`. Dashboard at `http://localhost:5173`.

---

## Checkpoint ✓

- What is a control plane vs. an execution plane?
- Name the four questions Paperclip answers for each work cycle
- What are the six key components of Paperclip?
- What does "zero-human company" actually mean in practice?
$md$ WHERE slug = 'pcl-01-what-is-paperclip';


UPDATE public.topics SET status = 'published', content_md = $md$
# The Zero-Human Company Concept

## What you'll learn

What "zero-human" means as a practical operating model, where human oversight is still required by design, and the spectrum from human-in-the-loop to fully autonomous.

---

## What does "zero-human" actually mean?

"Zero-human" does not mean "no humans involved." It means:

> **Humans set direction. Agents execute operations.**

A zero-human company (ZHC) is one where the day-to-day operational work — researching, writing, coding, reviewing, filing, routing — is done by AI agents without a human doing each task manually. Humans remain in the picture for:

- Approving significant decisions (hiring, firing, strategy)
- Reviewing outputs and adjusting direction
- Setting the budget and policies
- Handling situations the agents escalate

---

## The autonomy spectrum

Not every Paperclip deployment is fully autonomous. There's a spectrum:

```
Human-in-the-loop          Supervised automation          Zero-human
      │                            │                           │
Human approves              Human reviews outputs          Agents run,
every action                after each cycle               human checks
                                                           periodically
```

Most teams start at "supervised automation" and move toward zero-human as trust in their agent configurations grows.

---

## Where Paperclip always requires human approval

These actions are intentionally gated — they cannot be automated:

| Action | Why it's gated |
|--------|---------------|
| Hiring a new agent | Creates ongoing API cost and security surface |
| Terminating an agent | Irreversible, may disrupt work in progress |
| Strategy changes | High-level direction affects all downstream work |
| Budget increases | Direct financial commitment |
| Releasing blocked agents | An agent paused for exceeding budget |

These gates are enforced in the `approvals` table — the action creates a pending approval, a notification fires, and the action is blocked until a human approves or rejects it.

---

## The agent org chart model

Paperclip models the agent workforce as a real org chart using the `reports_to` field on agents. This isn't just visual — it drives delegation:

```
        CEO Agent
        /        \
  CTO Agent    CMO Agent
  /       \
Dev A    Dev B
```

The CEO agent can assign issues to the CTO, who breaks them into subtasks for Dev A and Dev B. The hierarchy makes accountability traceable — every task has an owner and that owner has a manager.

---

## What makes a good zero-human process?

Not every task is suitable for a ZHC. Good candidates share these properties:

✅ **Well-defined inputs** — the agent knows exactly what information it starts with  
✅ **Measurable output** — you can tell when the task is done and whether it's good  
✅ **Recoverable on failure** — a bad output can be corrected without catastrophic damage  
✅ **Routine but time-consuming** — things that don't need creativity but take human hours  

Poor candidates: tasks that require political judgment, legal liability, real-world physical action, or relationships that depend on human identity.

---

## A concrete example: AI content company

A small content business run on Paperclip:

| Agent | Role | Schedule |
|-------|------|----------|
| Research Agent | Finds 5 new topics daily using web search | 9am daily |
| Writer Agent | Picks one topic and writes a 1,000-word draft | 10am daily |
| Editor Agent | Reviews the draft, suggests improvements | 11am daily |
| Publisher Agent | Formats and publishes approved drafts | 2pm daily |

A human reviews the day's published content once in the evening, adjusts the Research Agent's topic prompts weekly, and approves any budget changes.

---

## Checkpoint ✓

- What is the difference between "zero-human" and "fully autonomous"?
- Name three actions that always require human approval in Paperclip
- What properties make a task suitable for a zero-human workflow?
- How does the `reports_to` field enable agent delegation?
$md$ WHERE slug = 'pcl-02-zero-human-concept';


UPDATE public.topics SET status = 'published', content_md = $md$
# System Architecture Overview

## What you'll learn

The four-layer architecture of Paperclip AI, how each layer communicates, and where to look when something goes wrong.

---

## The four layers

```
┌─────────────────────────────────────────┐
│  Layer 1: React 19 + Vite Frontend      │  Dashboard UI
│  localhost:5173                          │
└──────────────────┬──────────────────────┘
                   │ HTTP/REST
┌──────────────────▼──────────────────────┐
│  Layer 2: Express.js REST API            │  Business logic
│  localhost:3100                          │
└──────────────────┬──────────────────────┘
                   │ Drizzle ORM queries
┌──────────────────▼──────────────────────┐
│  Layer 3: PostgreSQL (or PGlite dev)    │  Persistence
│  7 tables, all scoped by company_id     │
└──────────────────┬──────────────────────┘
                   │ adapter.invoke()
┌──────────────────▼──────────────────────┐
│  Layer 4: Adapter Layer                  │  AI execution
│  Claude Code CLI / OpenAI API /          │
│  HTTP webhook / Shell process            │
└─────────────────────────────────────────┘
```

---

## Layer 1 — React Frontend

The frontend is a React 19 SPA built with Vite. It connects to the API via fetch calls and provides:

- Company and agent management UI
- Issue board (Kanban-style task view)
- Heartbeat run timeline
- Cost dashboard
- Approval inbox

The frontend is **read/write** through the REST API. It never touches the database directly.

**Key files:**
```
apps/web/
  src/
    pages/        ← one component per page (Dashboard, Agents, Issues, …)
    components/   ← shared UI pieces (AgentCard, IssueRow, CostChart, …)
    api/          ← typed fetch wrappers for every API endpoint
```

---

## Layer 2 — Express REST API

The API is a Node.js Express server. It handles:

- CRUD for all entities (companies, agents, issues, approvals)
- Heartbeat scheduling and execution orchestration
- Adapter invocation and status polling
- Cost event recording
- Activity log writes

Every request is validated and scoped to a company. The API never returns data from one company to a request authenticated for another.

**Key files:**
```
apps/server/
  src/
    routes/       ← one router per entity (agents.ts, issues.ts, …)
    services/     ← heartbeat.service.ts, cost.service.ts, …
    adapters/     ← claude.adapter.ts, openai.adapter.ts, …
    db/           ← drizzle schema and migration files
```

---

## Layer 3 — PostgreSQL / PGlite

The persistence layer uses **Drizzle ORM** — a TypeScript-first ORM that generates type-safe queries from your schema definition. No raw SQL in application code.

The schema has 7 tables:

| Table | Purpose |
|-------|---------|
| `companies` | Workspace/tenant root |
| `agents` | Agent definitions with adapter config and budget |
| `issues` | Tasks with hierarchy, priority, and status |
| `heartbeat_runs` | One record per agent work cycle |
| `cost_events` | One record per token spend |
| `approvals` | Pending human approval gates |
| `activity_log` | Immutable audit trail |

---

## Layer 4 — Adapter Layer

Adapters are the translation layer between Paperclip's abstract task model and a real execution environment. Every adapter implements three methods:

```typescript
interface Adapter {
  invoke(task: Task): Promise<string>      // start work, return runId
  status(runId: string): Promise<RunStatus> // check if done
  cancel(runId: string): Promise<void>      // abort if needed
}
```

Current adapters:
- `ClaudeCodeAdapter` — spawns the `claude` CLI as a child process
- `OpenAIAdapter` — calls the OpenAI chat completions API
- `HttpAdapter` — POSTs to an external webhook and polls for completion
- `ShellAdapter` — runs an arbitrary shell command or script

---

## Request flow example — triggering a heartbeat

```
User clicks "Run Now" in dashboard
   ↓
POST /api/heartbeat/trigger   (Layer 2)
   ↓
SELECT agents WHERE status='active' AND next_run_at <= NOW()   (Layer 3)
   ↓
SELECT issues WHERE assigned_to=agentId AND status='open' ORDER BY priority DESC   (Layer 3)
   ↓
adapter.invoke(issue)   (Layer 4)
   ↓
INSERT heartbeat_runs, cost_events, activity_log   (Layer 3)
   ↓
WebSocket push → dashboard updates in real time   (Layer 1)
```

---

## Checkpoint ✓

- Name the four layers and their responsibilities
- Which layer never touches the database directly?
- What does the adapter layer abstract?
- Where in the file structure would you find the heartbeat service?
$md$ WHERE slug = 'pcl-03-architecture-overview';


UPDATE public.topics SET status = 'published', content_md = $md$
# Installation & Quick Start

## What you'll build

A running Paperclip AI instance using the install path that fits your situation — zero-config onboarding, developer clone, or Docker Compose.

---

## Prerequisites

- Node.js 20+ (`node --version`)
- pnpm 9.15+ (`pnpm --version`)
- An Anthropic API key (get one at [console.anthropic.com](https://console.anthropic.com))

---

## Path A — Zero-config onboarding (fastest)

If you just want to try Paperclip immediately without cloning anything:

```bash
npx paperclipai onboard --yes
```

This command:
1. Downloads the latest Paperclip server to a temp directory
2. Prompts for your `ANTHROPIC_API_KEY`
3. Starts the API on port 3100 and opens the dashboard
4. Creates a default company and a sample agent

**Best for:** Evaluating Paperclip, demos, proof of concept.  
**Not for:** Development, customization, or production.

---

## Path B — Developer clone (recommended)

For building with Paperclip or contributing to it:

```bash
# 1. Clone
git clone https://github.com/paperclipai/paperclip.git
cd paperclip

# 2. Install workspace dependencies
pnpm install

# 3. Configure
cp .env.example .env
# Edit .env — set ANTHROPIC_API_KEY at minimum

# 4. Start all services
pnpm dev
```

**Services that start:**

| Service | URL | Purpose |
|---------|-----|---------|
| API server | http://localhost:3100 | REST API + heartbeat scheduler |
| Web dashboard | http://localhost:5173 | React frontend |
| PGlite | (in-process) | Dev database, no setup needed |

---

## Path C — Docker Compose

For an isolated, production-like environment on your local machine:

```bash
git clone https://github.com/paperclipai/paperclip.git
cd paperclip

# Create your env file
cp .env.example .env
# Edit .env with your API keys

# Build and start all containers
docker compose up --build
```

Docker Compose starts:
- `paperclip-server` — API on port 3100
- `paperclip-web` — Frontend on port 5173
- `postgres` — Real PostgreSQL on port 5432 (data persisted in a Docker volume)

**Best for:** Teams, staging environments, reproducible dev setups.

---

## Verifying the installation

After any install path, confirm everything is healthy:

```bash
# 1. API health check
curl http://localhost:3100/health
# Expected: {"status":"ok","db":"connected","scheduler":"running"}

# 2. Check the dashboard loads
open http://localhost:5173
# You should see the Paperclip dashboard with a "Create Company" prompt
```

---

## Common setup errors

| Error | Cause | Fix |
|-------|-------|-----|
| `EADDRINUSE :3100` | Port already in use | `lsof -i :3100` then kill the process |
| `Invalid API key` | Wrong ANTHROPIC_API_KEY | Check console.anthropic.com → API Keys |
| `pnpm: command not found` | pnpm not installed | `npm install -g pnpm` |
| `Cannot find module` | pnpm install incomplete | `rm -rf node_modules && pnpm install` |
| DB migration error | Leftover dev.db from old version | `rm .paperclip/dev.db && pnpm dev` |

---

## Next steps after installation

Once running, your immediate next steps are:

1. Open the dashboard at http://localhost:5173
2. Create your first company (next module)
3. Set up `.env` with any additional adapter API keys you want (OpenAI, etc.)

---

## Checkpoint ✓

- Which install path is best for development vs. evaluation?
- What is the API health check endpoint?
- What does the Docker Compose setup add that Path B doesn't have?
- How do you fix an `EADDRINUSE` error on port 3100?
$md$ WHERE slug = 'pcl-04-installation';


UPDATE public.topics SET status = 'published', content_md = $md$
# Project Structure Walkthrough

## What you'll learn

The Paperclip monorepo layout, what each directory contains, and where to look when you want to change or extend specific behavior.

---

## Top-level structure

```
paperclip/
├── apps/
│   ├── server/          ← Express API + heartbeat scheduler
│   └── web/             ← React 19 + Vite frontend
├── packages/
│   └── shared/          ← TypeScript types shared between server and web
├── .env.example         ← environment variable template
├── .env                 ← your local config (git-ignored)
├── docker-compose.yml   ← container definitions for Docker path
├── package.json         ← workspace root (pnpm workspaces)
└── pnpm-workspace.yaml  ← declares apps/* and packages/* as workspaces
```

---

## apps/server — the API

```
apps/server/
├── src/
│   ├── index.ts            ← entry point: creates Express app, starts scheduler
│   ├── routes/             ← one router file per entity
│   │   ├── companies.ts    ← GET/POST/PATCH/DELETE /api/companies
│   │   ├── agents.ts       ← /api/agents
│   │   ├── issues.ts       ← /api/issues
│   │   ├── heartbeat.ts    ← /api/heartbeat/trigger, /api/heartbeat/runs
│   │   ├── approvals.ts    ← /api/approvals
│   │   └── activity.ts     ← /api/activity
│   ├── services/
│   │   ├── heartbeat.service.ts   ← core scheduler: selects agents, invokes adapters
│   │   ├── cost.service.ts        ← records cost_events, checks budgets
│   │   └── approval.service.ts    ← creates and resolves approval gates
│   ├── adapters/
│   │   ├── base.adapter.ts        ← the Adapter interface definition
│   │   ├── claude.adapter.ts      ← Claude Code CLI adapter
│   │   ├── openai.adapter.ts      ← OpenAI chat completions adapter
│   │   ├── http.adapter.ts        ← HTTP webhook adapter
│   │   └── shell.adapter.ts       ← shell process adapter
│   └── db/
│       ├── schema.ts              ← Drizzle ORM schema (all 7 tables)
│       ├── migrate.ts             ← runs migrations on startup
│       └── migrations/            ← SQL migration files (auto-generated)
├── package.json
└── tsconfig.json
```

**The most important file is `heartbeat.service.ts`** — it contains the core execution loop that the entire platform runs on.

---

## apps/web — the frontend

```
apps/web/
├── src/
│   ├── main.tsx            ← React entry point
│   ├── App.tsx             ← router setup (React Router v6)
│   ├── pages/
│   │   ├── Dashboard.tsx   ← company overview, agent cards
│   │   ├── Agents.tsx      ← agent list, hire/edit/pause
│   │   ├── Issues.tsx      ← issue board (Kanban)
│   │   ├── Runs.tsx        ← heartbeat run history + costs
│   │   └── Approvals.tsx   ← pending approvals inbox
│   ├── components/         ← reusable UI components
│   │   ├── AgentCard.tsx
│   │   ├── IssueRow.tsx
│   │   ├── CostChart.tsx
│   │   └── ApprovalGate.tsx
│   └── api/
│       └── client.ts       ← typed fetch wrapper for every endpoint
├── package.json
└── vite.config.ts
```

---

## packages/shared — shared types

```
packages/shared/
└── src/
    ├── types/
    │   ├── company.types.ts
    │   ├── agent.types.ts
    │   ├── issue.types.ts
    │   └── heartbeat.types.ts
    └── index.ts            ← re-exports everything
```

Both `apps/server` and `apps/web` import from `@paperclip/shared`. This ensures the TypeScript types for API request/response shapes are identical on both ends — no silent type drift.

---

## Where to look for common tasks

| Task | File to edit |
|------|-------------|
| Add a new API endpoint | `apps/server/src/routes/` |
| Change task selection logic | `apps/server/src/services/heartbeat.service.ts` |
| Add a new adapter type | `apps/server/src/adapters/` |
| Change the DB schema | `apps/server/src/db/schema.ts` + run `pnpm db:generate` |
| Add a new dashboard page | `apps/web/src/pages/` + register in `App.tsx` |
| Add a shared type | `packages/shared/src/types/` |

---

## Checkpoint ✓

- What is the purpose of `packages/shared`?
- Which file contains the core heartbeat execution loop?
- Where would you add a new REST endpoint?
- How do you add a new adapter type?
$md$ WHERE slug = 'pcl-05-project-structure';


UPDATE public.topics SET status = 'published', content_md = $md$
# Core Domain Model

## What you'll learn

The seven database tables that power Paperclip, how they relate to each other, and what every field means.

---

## The seven tables

```
companies
    │ 1:N
    ├── agents (with self-ref reports_to)
    │       │ 1:N
    │       └── heartbeat_runs
    │               │ 1:N
    │               └── cost_events
    ├── issues (self-ref parent_id)
    ├── approvals
    └── activity_log
```

Every table except `activity_log` has a `company_id` foreign key. This is the multi-tenancy boundary — a query for one company can never accidentally return another company's data.

---

## companies

The root entity. Everything belongs to a company.

| Column | Type | Description |
|--------|------|-------------|
| `id` | uuid | Primary key |
| `name` | text | Display name |
| `timezone` | text | e.g. `America/New_York` — drives heartbeat windows |
| `monthly_budget_usd` | decimal | Global ceiling across all agents |
| `metadata` | jsonb | Arbitrary config (webhook URLs, custom fields) |
| `created_at` | timestamptz | — |

---

## agents

An agent is a named AI worker with a role, execution config, and budget.

| Column | Type | Description |
|--------|------|-------------|
| `id` | uuid | Primary key |
| `company_id` | uuid → companies | Data boundary |
| `name` | text | e.g. `"Senior Engineer"` |
| `role` | text | Role description used in prompts |
| `system_prompt` | text | Full system prompt for this agent |
| `adapter_type` | enum | `claude_code \| openai \| http \| shell` |
| `adapter_config` | jsonb | Adapter-specific settings (model, url, etc.) |
| `reports_to` | uuid → agents | Self-referential FK for org chart |
| `status` | enum | `active \| paused \| terminated` |
| `cron_schedule` | text | When heartbeats fire, e.g. `0 9 * * *` |
| `monthly_budget_usd` | decimal | Max spend per calendar month |
| `created_at` | timestamptz | — |

---

## issues

Tasks. The core unit of work in Paperclip.

| Column | Type | Description |
|--------|------|-------------|
| `id` | uuid | Primary key |
| `company_id` | uuid | Data boundary |
| `parent_id` | uuid → issues | Self-ref for subtask nesting |
| `assigned_agent_id` | uuid → agents | Who should work on this |
| `title` | text | Short task title |
| `description` | text | Full task details, context, requirements |
| `status` | enum | `open \| in_progress \| blocked \| completed \| failed` |
| `priority` | integer | Higher = more urgent. Default 0 |
| `metadata` | jsonb | Agent-to-agent message passing |
| `created_at` | timestamptz | — |
| `updated_at` | timestamptz | Auto-updated on any change |

---

## heartbeat_runs

One record per agent work cycle. The primary observability surface.

| Column | Type | Description |
|--------|------|-------------|
| `id` | uuid | Primary key |
| `agent_id` | uuid → agents | Which agent ran |
| `company_id` | uuid | Data boundary |
| `issue_id` | uuid → issues | Which task was worked on |
| `started_at` | timestamptz | When the adapter was invoked |
| `completed_at` | timestamptz | When the adapter returned |
| `status` | enum | `running \| completed \| failed \| dry_run` |
| `tokens_used` | integer | Input + output tokens combined |
| `cost_usd` | decimal | Computed from model pricing |
| `output_summary` | text | Truncated agent output for the dashboard |
| `error_message` | text | Set on failure |

---

## cost_events

Immutable spend record. One per heartbeat run (or per API call for granular adapters).

| Column | Type | Description |
|--------|------|-------------|
| `id` | uuid | Primary key |
| `company_id` | uuid | Data boundary |
| `agent_id` | uuid → agents | Who spent |
| `run_id` | uuid → heartbeat_runs | Which run caused this cost |
| `model` | text | e.g. `claude-3-5-sonnet-20241022` |
| `input_tokens` | integer | Prompt tokens |
| `output_tokens` | integer | Completion tokens |
| `amount_usd` | decimal | Exact cost in USD |
| `created_at` | timestamptz | — |

---

## approvals

Pending human decisions that block agent actions.

| Column | Type | Description |
|--------|------|-------------|
| `id` | uuid | Primary key |
| `company_id` | uuid | Data boundary |
| `action_type` | text | `hire_agent \| terminate_agent \| strategy_change \| budget_increase` |
| `payload` | jsonb | The full context for the decision |
| `status` | enum | `pending \| approved \| rejected \| expired` |
| `created_at` | timestamptz | — |
| `resolved_at` | timestamptz | When a human acted |

---

## activity_log

Append-only audit trail. Never updated, only inserted.

| Column | Type | Description |
|--------|------|-------------|
| `id` | uuid | Primary key |
| `company_id` | uuid | Data boundary |
| `actor_type` | text | `agent \| human \| system` |
| `actor_id` | uuid | Agent or user who performed the action |
| `action` | text | e.g. `issue.status_changed`, `agent.paused` |
| `entity_type` | text | `issue \| agent \| company \| approval` |
| `entity_id` | uuid | The affected record |
| `before` | jsonb | Snapshot before the change |
| `after` | jsonb | Snapshot after the change |
| `created_at` | timestamptz | — |

---

## Checkpoint ✓

- Which foreign key enforces the multi-tenancy boundary across all tables?
- What is the `reports_to` column on agents used for?
- What is the difference between `heartbeat_runs` and `cost_events`?
- Why is `activity_log` append-only?
$md$ WHERE slug = 'pcl-06-domain-model';


UPDATE public.topics SET status = 'published', content_md = $md$
# Tech Stack Deep Dive

## What you'll learn

Every major technology in the Paperclip stack, why it was chosen, and what you need to know about each one before writing any code.

---

## Language — TypeScript

Paperclip is **96% TypeScript**. TypeScript adds static typing to JavaScript, which means the compiler catches type mismatches before they become runtime errors.

For Paperclip specifically, TypeScript is critical because:
- The `@paperclip/shared` package defines types used by both server and frontend — a change to an API response type breaks the frontend immediately at compile time, not at runtime
- Adapter interfaces are typed contracts — you can't implement a broken adapter without the compiler telling you

```bash
# Check types across the whole monorepo
pnpm typecheck
```

---

## Runtime — Node.js 20 LTS

Node.js 20 is the current Long-Term Support release. Paperclip uses:

- **Native ESM modules** (import/export, not require)
- **Top-level await** in startup scripts
- **Fetch API** (no need for node-fetch)
- **Node child_process** for the Claude Code adapter (spawning the CLI)

---

## Package manager — pnpm

**pnpm** (Performant npm) uses a content-addressable store where each package version is stored once on disk and hard-linked into each project's `node_modules`. This means:

- `pnpm install` is faster than `npm install` (especially after the first install)
- Disk usage is much lower on a machine with multiple Node projects
- Workspaces (monorepo support) are first-class

```bash
pnpm install          # install all workspace dependencies
pnpm --filter server dev  # run dev only in apps/server
pnpm -r typecheck     # run typecheck in all workspaces
```

---

## API framework — Express.js

Express is the minimal HTTP framework for the API server. Paperclip keeps it simple:

- Each entity has a router file in `src/routes/`
- Middleware handles JSON body parsing, CORS, and request logging
- No decorators or framework magic — just `router.get()`, `router.post()`, etc.

This makes the code easy to follow and easy to extend with new routes.

---

## ORM — Drizzle

**Drizzle ORM** is a TypeScript-first ORM that generates type-safe queries from a schema definition file.

```typescript
// Schema definition (apps/server/src/db/schema.ts)
export const agents = pgTable('agents', {
  id: uuid('id').primaryKey().defaultRandom(),
  companyId: uuid('company_id').references(() => companies.id),
  name: text('name').notNull(),
  status: text('status', { enum: ['active', 'paused', 'terminated'] }).notNull(),
  // ...
});

// Type-safe query — TypeScript knows the exact shape of the result
const activeAgents = await db
  .select()
  .from(agents)
  .where(eq(agents.status, 'active'));
// activeAgents is typed as typeof agents.$inferSelect[]
```

Drizzle generates SQL migration files when you change the schema:

```bash
pnpm db:generate   # generate migration from schema diff
pnpm db:migrate    # apply pending migrations
```

---

## Dev database — PGlite

**PGlite** is a PostgreSQL engine compiled to WebAssembly that runs in-process. Paperclip uses it automatically in development when `DATABASE_URL` is not set.

Key facts:
- Stores data in a single file (`.paperclip/dev.db`)
- Full PostgreSQL SQL compatibility (same queries as production)
- Zero setup — no Docker, no service to start
- Not suitable for production (single-process, no network access)

---

## Frontend — React 19 + Vite

The dashboard is a React 19 SPA. Notable choices:

| Technology | Why |
|-----------|-----|
| **Vite** | Near-instant HMR (hot module replacement) during development |
| **React Router v6** | Client-side routing for the dashboard pages |
| **React Query (TanStack)** | Server state management — handles caching, refetch, loading states |
| **Recharts** | Cost and run timeline charts |

---

## Project tooling

| Tool | Purpose |
|------|---------|
| **ESLint** | Code style enforcement |
| **Prettier** | Code formatting |
| **Vitest** | Unit testing (same syntax as Jest) |
| **tsx** | Runs TypeScript files directly in Node without a compile step |

---

## Checkpoint ✓

- Why is TypeScript important for the `@paperclip/shared` package specifically?
- What is the difference between PGlite (dev) and PostgreSQL (prod)?
- What command generates a Drizzle migration after a schema change?
- Why does Paperclip use pnpm instead of npm?
$md$ WHERE slug = 'pcl-07-tech-stack';


UPDATE public.topics SET status = 'published', content_md = $md$
# Configuration & Environment Variables

## What you'll learn

Every environment variable Paperclip uses, how the config validation layer works, and best practices for managing secrets safely.

---

## The .env file

Copy the template to get started:

```bash
cp .env.example .env
```

Never commit `.env` to git — it's in `.gitignore` by default. Only commit `.env.example` with placeholder values.

---

## All environment variables

### Required

```env
ANTHROPIC_API_KEY=sk-ant-api03-...
```

Required if you use the Claude Code adapter (the default). Get your key at [console.anthropic.com](https://console.anthropic.com) → API Keys.

---

### Optional adapter keys

```env
OPENAI_API_KEY=sk-proj-...
```

Only needed if you configure agents with `adapter_type: 'openai'`.

---

### Database

```env
DATABASE_URL=
```

Leave **blank** to use the embedded PGlite dev database (recommended for local development).

Set to a PostgreSQL connection string for staging/production:
```env
DATABASE_URL=postgresql://user:password@localhost:5432/paperclip
```

Paperclip detects which to use based on whether this value is set.

---

### Server

```env
PORT=3100
NODE_ENV=development
```

| Variable | Default | Notes |
|----------|---------|-------|
| `PORT` | `3100` | API server port |
| `NODE_ENV` | `development` | Set to `production` to disable dev-only endpoints like `/api/dev/reset` |

---

### Scheduler

```env
HEARTBEAT_INTERVAL_MS=60000
```

How often (in milliseconds) the scheduler polls for agents whose `next_run_at` has passed. Default is 60 seconds. Lower this in development to speed up testing:

```env
HEARTBEAT_INTERVAL_MS=5000   # poll every 5 seconds in dev
```

> **Warning:** Setting this below 5000ms can cause thundering-herd behavior — multiple runs starting before the previous ones complete.

---

### Frontend

```env
VITE_API_URL=http://localhost:3100
```

The URL the React frontend uses to call the API. In production, set this to your public API domain:

```env
VITE_API_URL=https://api.yourdomain.com
```

> Vite only exposes variables prefixed with `VITE_` to the browser bundle. All other `.env` variables stay server-side only.

---

### Notifications (optional)

```env
WEBHOOK_NOTIFICATION_URL=https://hooks.slack.com/services/...
```

If set, Paperclip POSTs a JSON payload here when an approval gate is created, an agent is auto-paused for budget, or a run fails. Works with Slack incoming webhooks, Discord webhooks, or any HTTP endpoint.

---

## Config validation

Paperclip validates required environment variables at startup in `apps/server/src/config.ts`:

```typescript
const config = {
  anthropicApiKey: process.env.ANTHROPIC_API_KEY,
  port: parseInt(process.env.PORT ?? '3100'),
  nodeEnv: process.env.NODE_ENV ?? 'development',
  // ...
};

// Throws at startup if required keys are missing
if (!config.anthropicApiKey) {
  throw new Error('ANTHROPIC_API_KEY is required. Set it in your .env file.');
}
```

This means missing config fails fast at startup rather than silently at runtime during the first heartbeat.

---

## .env.example — what to commit

```env
# .env.example — commit this file, never .env

ANTHROPIC_API_KEY=           # Required: sk-ant-...
OPENAI_API_KEY=              # Optional: sk-...

DATABASE_URL=                # Leave blank for PGlite dev mode

PORT=3100
NODE_ENV=development
HEARTBEAT_INTERVAL_MS=60000

VITE_API_URL=http://localhost:3100
WEBHOOK_NOTIFICATION_URL=    # Optional: Slack/Discord webhook
```

Keep all variable names present in `.env.example` with empty values and a comment — this serves as documentation for anyone setting up the project.

---

## Checkpoint ✓

- Which is the only truly required environment variable?
- How does Paperclip choose between PGlite and PostgreSQL?
- Why does the frontend only see variables prefixed with `VITE_`?
- What happens if `ANTHROPIC_API_KEY` is missing at startup?
$md$ WHERE slug = 'pcl-08-config-environment';


UPDATE public.topics SET status = 'published', content_md = $md$
# Running Paperclip for the First Time

## What you'll do

Start the dev servers, walk through the startup sequence output, verify all services are healthy, and understand what every log line means.

---

## Start the servers

```bash
cd paperclip
pnpm dev
```

This runs `turbo dev` under the hood, which starts all three workspace packages in parallel with interleaved output.

---

## Reading the startup output

A healthy startup looks like this (colours will vary by terminal):

```
[server] > paperclip-server@0.1.0 dev
[server] > tsx watch src/index.ts

[web]    > paperclip-web@0.1.0 dev
[web]    > vite

[server] Connecting to database...
[server] ✓ Using PGlite (dev mode) — data stored at .paperclip/dev.db
[server] Running database migrations...
[server] ✓ Migration complete — 8 tables ready

[web]      VITE v5.x.x  ready in 312 ms
[web]      ➜  Local:   http://localhost:5173/

[server] ✓ Heartbeat scheduler started — interval: 60s
[server] ✓ No agents active — scheduler idle
[server] ✓ API listening on http://localhost:3100
```

**What each line means:**

| Log line | What it tells you |
|----------|------------------|
| `Using PGlite` | No DATABASE_URL set — using embedded dev DB |
| `Migration complete — 8 tables ready` | Schema is up to date |
| `VITE ready` | Frontend compiled and HMR active |
| `Scheduler started — interval: 60s` | Heartbeat loop is running |
| `No agents active — scheduler idle` | Nothing to run yet (expected on first start) |
| `API listening on :3100` | Server is ready for requests |

---

## 5 health checks

Run these in a second terminal tab to verify everything is working:

### 1. API health
```bash
curl http://localhost:3100/health
# Expected:
# {"status":"ok","db":"connected","scheduler":"running","uptime":12.3}
```

### 2. Dashboard loads
Open [http://localhost:5173](http://localhost:5173) in your browser.  
You should see the Paperclip dashboard with a prompt to create your first company.

### 3. TypeScript has no errors
```bash
pnpm typecheck
# Expected: exits with code 0 (no output = success)
```

### 4. Database is accessible
```bash
curl http://localhost:3100/api/companies
# Expected: {"data":[],"total":0}  (empty — no companies yet)
```

### 5. Scheduler is running
```bash
curl http://localhost:3100/api/heartbeat/status
# Expected: {"running":true,"interval_ms":60000,"next_tick_in_ms":47230}
```

---

## Common first-run issues

**Server starts but immediately restarts in a loop:**
```
[server] Error: ANTHROPIC_API_KEY is required
```
Fix: Add `ANTHROPIC_API_KEY=sk-ant-...` to your `.env` file.

---

**Port already in use:**
```
[server] Error: listen EADDRINUSE :::3100
```
Fix:
```bash
lsof -i :3100   # find the process
kill -9 <PID>   # kill it
```

---

**`pnpm dev` stalls after "Running migrations":**
This usually means a stale lock on `dev.db`. Fix:
```bash
# Kill pnpm dev (Ctrl+C)
rm .paperclip/dev.db .paperclip/dev.db-wal
pnpm dev
```

---

## Hot reload in action

Both the server and the frontend support hot reload:

- **Frontend (Vite HMR):** Save any file in `apps/web/src/` and the browser updates instantly without a page reload
- **Server (tsx watch):** Save any file in `apps/server/src/` and the server restarts automatically (in ~500ms)

> During server restart, any in-progress heartbeat run is aborted. This is expected in development — the next scheduled tick will retry the run.

---

## What to do next

Now that everything is running:

1. Open the dashboard: http://localhost:5173
2. Move to **Module 2** to create your first company and hire your first agent

---

## Checkpoint ✓

- What does the "8 tables ready" migration log line confirm?
- How do you verify the heartbeat scheduler is running without the dashboard?
- What is the fix for a stale PGlite lock?
- How does hot reload behave differently for the frontend vs. the server?
$md$ WHERE slug = 'pcl-09-first-run';

