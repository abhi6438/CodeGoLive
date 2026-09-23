-- =============================================================================
-- Paperclip AI Course Seed — 9 Modules, 79 Topics
-- Module numbers 300–308 (SAP BTP uses 1xx, SAP AI uses 1xx, CAP uses 2xx)
-- Run this file, then add topic content via separate content SQL files
-- =============================================================================

-- ─── 1. COURSE ───────────────────────────────────────────────────────────────
INSERT INTO public.courses (id, title, subtitle, description, status, icon, accent_color, accent_light, tags, level, estimated_hours, order_index)
VALUES (
  'paperclip',
  'Paperclip AI',
  'Build Zero-Human Companies with AI Agent Orchestration',
  'A zero-to-hero course on building and running autonomous AI agent organizations using the open-source Paperclip AI platform. Covers the heartbeat execution model, adapter interface, cost governance, multi-agent orchestration patterns, and production deployment — from local sandbox to a fully governed, Docker-hosted AI company.',
  'coming_soon',
  '📎',
  '#3B82F6',
  '#EBF4FF',
  ARRAY['AI Agents', 'TypeScript', 'PostgreSQL', 'Node.js', 'Automation', 'LLM Ops'],
  'Intermediate → Advanced',
  45,
  3
)
ON CONFLICT (id) DO UPDATE SET
  title           = EXCLUDED.title,
  subtitle        = EXCLUDED.subtitle,
  description     = EXCLUDED.description,
  status          = EXCLUDED.status,
  icon            = EXCLUDED.icon,
  accent_color    = EXCLUDED.accent_color,
  accent_light    = EXCLUDED.accent_light,
  tags            = EXCLUDED.tags,
  level           = EXCLUDED.level,
  estimated_hours = EXCLUDED.estimated_hours,
  order_index     = EXCLUDED.order_index;

-- ─── 2. MODULES + TOPICS ─────────────────────────────────────────────────────
DO $$
DECLARE
  m1 uuid; m2 uuid; m3 uuid; m4 uuid; m5 uuid;
  m6 uuid; m7 uuid; m8 uuid; m9 uuid;
BEGIN

  -- MODULE 1: Foundations (300)
  INSERT INTO public.modules (number, title, subtitle, order_index, course_id)
  VALUES (300, 'Foundations', 'Architecture, domain model, installation, and sandbox setup', 1, 'paperclip')
  ON CONFLICT (number) DO UPDATE SET title = EXCLUDED.title, subtitle = EXCLUDED.subtitle, course_id = EXCLUDED.course_id
  RETURNING id INTO m1;
  IF m1 IS NULL THEN SELECT id INTO m1 FROM public.modules WHERE number = 300; END IF;

  -- MODULE 2: Your First AI Company (301)
  INSERT INTO public.modules (number, title, subtitle, order_index, course_id)
  VALUES (301, 'Your First AI Company', 'Create a company, hire an agent, and run your first heartbeat', 2, 'paperclip')
  ON CONFLICT (number) DO UPDATE SET title = EXCLUDED.title, subtitle = EXCLUDED.subtitle, course_id = EXCLUDED.course_id
  RETURNING id INTO m2;
  IF m2 IS NULL THEN SELECT id INTO m2 FROM public.modules WHERE number = 301; END IF;

  -- MODULE 3: Agents & Org Charts (302)
  INSERT INTO public.modules (number, title, subtitle, order_index, course_id)
  VALUES (302, 'Agents & Org Charts', 'Adapter types, org hierarchy, and building custom adapters', 3, 'paperclip')
  ON CONFLICT (number) DO UPDATE SET title = EXCLUDED.title, subtitle = EXCLUDED.subtitle, course_id = EXCLUDED.course_id
  RETURNING id INTO m3;
  IF m3 IS NULL THEN SELECT id INTO m3 FROM public.modules WHERE number = 302; END IF;

  -- MODULE 4: Tasks, Issues & Workflows (303)
  INSERT INTO public.modules (number, title, subtitle, order_index, course_id)
  VALUES (303, 'Tasks, Issues & Workflows', 'Issue model, atomic checkout, delegation, and workflow patterns', 4, 'paperclip')
  ON CONFLICT (number) DO UPDATE SET title = EXCLUDED.title, subtitle = EXCLUDED.subtitle, course_id = EXCLUDED.course_id
  RETURNING id INTO m4;
  IF m4 IS NULL THEN SELECT id INTO m4 FROM public.modules WHERE number = 303; END IF;

  -- MODULE 5: The Heartbeat System (304)
  INSERT INTO public.modules (number, title, subtitle, order_index, course_id)
  VALUES (304, 'The Heartbeat System', 'Scheduling, execution flow, concurrency, and debugging runs', 5, 'paperclip')
  ON CONFLICT (number) DO UPDATE SET title = EXCLUDED.title, subtitle = EXCLUDED.subtitle, course_id = EXCLUDED.course_id
  RETURNING id INTO m5;
  IF m5 IS NULL THEN SELECT id INTO m5 FROM public.modules WHERE number = 304; END IF;

  -- MODULE 6: Cost & Governance (305)
  INSERT INTO public.modules (number, title, subtitle, order_index, course_id)
  VALUES (305, 'Cost & Governance', 'Budget limits, approval gates, audit trail, and compliance', 6, 'paperclip')
  ON CONFLICT (number) DO UPDATE SET title = EXCLUDED.title, subtitle = EXCLUDED.subtitle, course_id = EXCLUDED.course_id
  RETURNING id INTO m6;
  IF m6 IS NULL THEN SELECT id INTO m6 FROM public.modules WHERE number = 305; END IF;

  -- MODULE 7: Multi-Agent Orchestration (306)
  INSERT INTO public.modules (number, title, subtitle, order_index, course_id)
  VALUES (306, 'Multi-Agent Orchestration', 'Coordinator/worker patterns, agent teams, and scaling', 7, 'paperclip')
  ON CONFLICT (number) DO UPDATE SET title = EXCLUDED.title, subtitle = EXCLUDED.subtitle, course_id = EXCLUDED.course_id
  RETURNING id INTO m7;
  IF m7 IS NULL THEN SELECT id INTO m7 FROM public.modules WHERE number = 306; END IF;

  -- MODULE 8: Production & Deployment (307)
  INSERT INTO public.modules (number, title, subtitle, order_index, course_id)
  VALUES (307, 'Production & Deployment', 'Docker, PostgreSQL, Nginx, secrets, monitoring, and CI/CD', 8, 'paperclip')
  ON CONFLICT (number) DO UPDATE SET title = EXCLUDED.title, subtitle = EXCLUDED.subtitle, course_id = EXCLUDED.course_id
  RETURNING id INTO m8;
  IF m8 IS NULL THEN SELECT id INTO m8 FROM public.modules WHERE number = 307; END IF;

  -- MODULE 9: Real-World Projects (308)
  INSERT INTO public.modules (number, title, subtitle, order_index, course_id)
  VALUES (308, 'Real-World Projects', 'Content companies, dev teams, support agents, and the capstone', 9, 'paperclip')
  ON CONFLICT (number) DO UPDATE SET title = EXCLUDED.title, subtitle = EXCLUDED.subtitle, course_id = EXCLUDED.course_id
  RETURNING id INTO m9;
  IF m9 IS NULL THEN SELECT id INTO m9 FROM public.modules WHERE number = 308; END IF;

  -- ── MODULE 1: FOUNDATIONS ────────────────────────────────────────────────

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m1,'pcl-00','pcl-how-it-works','How Paperclip Works — Core Workflow','Usage Loop',
    'The end-to-end daily-use loop: create company → hire agents → seed tasks → heartbeats fire → agents pick up tasks → review outputs → iterate. Builds the mental model before any code.',
    'Annotated workflow diagram showing all 6 stages',0,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m1,'pcl-00b','pcl-local-dev-setup','Local Development Environment Setup','Tooling & Config',
    'Full local dev walkthrough: Node 20+ via nvm, pnpm 9.15+, cloning the repo, .env configuration, recommended VS Code extensions (ESLint, Drizzle), hot-reload with pnpm dev, and verifying all services are healthy.',
    'Terminal screenshot showing all services green on startup',0,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m1,'pcl-00c','pcl-sandbox-mode','Working in Sandbox & Dev Mode (PGlite)','Embedded DB',
    'Using Paperclip''s embedded PGlite database as a zero-cost local sandbox: activation, where data lives on disk, running test heartbeats without real API calls, resetting sandbox state, and when to switch to real PostgreSQL.',
    'A reset-and-replay script that wipes sandbox state cleanly',0,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m1,'pcl-01','pcl-01-what-is-paperclip','What Is Paperclip AI?','Platform Overview',
    'Introduction to the platform, its goals, and the zero-human company vision. What Paperclip controls vs. what LLMs do — the control-plane vs. execution-plane distinction.',
    'One-page architecture overview showing Paperclip''s role',1,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m1,'pcl-02','pcl-02-zero-human-concept','The Zero-Human Company Concept','Vision & Philosophy',
    'What "zero-human" actually means in practice, why human approval gates are still built in, and the real-world spectrum from human-in-the-loop to fully autonomous.',
    'Comparison table: traditional company vs. zero-human company structure',2,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m1,'pcl-03','pcl-03-architecture-overview','System Architecture Overview','Four-Layer Stack',
    'React 19 + Vite frontend, Express REST API backend, PostgreSQL + Drizzle ORM persistence, and the adapter layer. How the four layers connect and where each concern lives.',
    'Layer diagram with request flow from UI to DB to adapter',3,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m1,'pcl-04','pcl-04-installation','Installation & Quick Start','Three Install Paths',
    'npx paperclipai onboard --yes for zero-config start, git clone + pnpm dev for contributors, and Docker Compose for isolated runs. Prerequisites: Node 20+, pnpm 9.15+.',
    'Working Paperclip instance reachable at localhost:3100',4,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m1,'pcl-05','pcl-05-project-structure','Project Structure Walkthrough','Monorepo Layout',
    'Monorepo layout: apps/web (React frontend), apps/server (Express API), packages/ (shared types and utilities). Key config files and what lives where.',
    'Annotated directory tree with one-line purpose per folder',5,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m1,'pcl-06','pcl-06-domain-model','Core Domain Model','7-Table Schema',
    'The seven database tables: companies, agents, issues, heartbeat_runs, cost_events, approvals, activity_log. ERD walkthrough, primary/foreign key relationships, and the company_id boundary.',
    'ERD diagram of all 7 tables with cardinality annotations',6,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m1,'pcl-07','pcl-07-tech-stack','Tech Stack Deep Dive','TypeScript & Drizzle',
    'TypeScript 96%, Node.js runtime, Drizzle ORM (type-safe queries, migrations), PGlite (embedded Wasm PostgreSQL for dev), Vite + React 19 frontend, and pnpm workspace.',
    'Dependency graph showing how packages relate',7,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m1,'pcl-08','pcl-08-config-environment','Configuration & Environment Variables','dotenv & Validation',
    'All .env variables: DATABASE_URL, ANTHROPIC_API_KEY, OPENAI_API_KEY, PORT, HEARTBEAT_INTERVAL. Config validation layer, per-environment overrides, and secrets-safe git practices.',
    '.env.example file with all variables documented inline',8,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m1,'pcl-09','pcl-09-first-run','Running Paperclip for the First Time','pnpm dev Walkthrough',
    'pnpm dev startup sequence, verifying the Express API at :3100, opening the React dashboard, confirming the Drizzle migration ran, and understanding the console output.',
    'Checklist: 5 health checks that confirm a clean first run',9,'draft')
  ON CONFLICT (slug) DO NOTHING;

  -- ── MODULE 2: YOUR FIRST AI COMPANY ─────────────────────────────────────

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m2,'pcl-10','pcl-10-create-company','Creating Your First Company','POST /api/companies',
    'POST /api/companies, required fields (name, timezone), the company_id boundary that scopes all downstream data, and viewing the new company in the dashboard.',
    'A live company record visible in the dashboard',1,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m2,'pcl-11','pcl-11-company-schema','Company Schema & Data Boundaries','Multi-Tenancy',
    'How company_id is enforced at query level to prevent cross-tenant data leaks, the role of foreign keys, and why every downstream entity inherits the boundary.',
    'SQL query demonstrating company-scoped isolation',2,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m2,'pcl-12','pcl-12-hire-first-agent','Hiring Your First Agent','POST /api/agents',
    'POST /api/agents: choosing an adapter type, setting the agent''s role name, writing the initial system prompt, and navigating the human approval gate that guards agent creation.',
    'Agent visible in dashboard with status: active',3,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m2,'pcl-13','pcl-13-agent-prompts','Crafting Effective Agent Prompts','Prompt Engineering',
    'System prompt design for agents: role clarity, explicit task scope, output format requirements, failure-handling instructions, and what to avoid to prevent runaway behavior.',
    'Three example prompts: bad → better → best with annotations',4,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m2,'pcl-14','pcl-14-first-heartbeat','Triggering Your First Heartbeat','Manual Trigger',
    'How to manually trigger a heartbeat run via the API, watching the execution log in real time, and understanding what the agent actually does during its work cycle.',
    'Heartbeat run record showing status: completed with output',5,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m2,'pcl-15','pcl-15-reading-activity','Reading the Activity Log','activity_log Table',
    'The activity_log table structure (actor, action, entity_type, entity_id, metadata, created_at), filtering by company/agent/date, and the dashboard''s real-time activity feed.',
    'SQL query returning last 24h of activity for one agent',6,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m2,'pcl-16','pcl-16-agent-dashboard','Using the Agent Dashboard','Frontend Tour',
    'Overview of the React frontend: company selector, agent list, issue board, heartbeat timeline, cost panel, and the activity feed. Key interactions and navigation patterns.',
    'Annotated screenshot of each major dashboard section',7,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m2,'pcl-17','pcl-17-company-settings','Company Settings & Preferences','Config & Webhooks',
    'Timezone setting, default heartbeat cadence, global monthly budget ceiling, notification webhook endpoints, and the company metadata JSONB field for custom config.',
    'Settings panel screenshot with all fields annotated',8,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m2,'pcl-18','pcl-18-mini-company-project','Project: Launch a Mini AI Company','End-to-End Lab',
    'Full end-to-end: create a company, hire one agent, seed 5 issues, trigger 3 heartbeats, and review the activity log. The first complete Paperclip workflow from blank slate to running agent.',
    'Activity log showing 3 completed heartbeat runs with task progress',9,'draft')
  ON CONFLICT (slug) DO NOTHING;

  -- ── MODULE 3: AGENTS & ORG CHARTS ───────────────────────────────────────

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m3,'pcl-19','pcl-19-agent-types','Agent Types & Roles','Adapter vs. Role',
    'Distinguishing agent by adapter type (how it executes) vs. organizational role (what it is responsible for). The same adapter can serve a manager or an individual contributor.',
    'Table mapping adapter types × org roles with example configurations',1,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m3,'pcl-20','pcl-20-adapter-interface','The Adapter Interface','TypeScript Contract',
    'The three-method contract every adapter must implement: invoke(task) → runId, status(runId) → RunStatus, cancel(runId) → void. TypeScript interface definition and why it''s designed this way.',
    'TypeScript interface code snippet with JSDoc for each method',2,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m3,'pcl-21','pcl-21-claude-code-adapter','Claude Code Adapter Deep Dive','CLI Spawn Pattern',
    'How the adapter spawns the claude CLI as a child process, passes task context via stdin/args, captures stdout, maps exit codes to run status, and handles token reporting.',
    'Annotated adapter source with each section explained',3,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m3,'pcl-22','pcl-22-openai-adapter','OpenAI Codex Adapter','API Client Pattern',
    'Configuration for GPT-4o and o1 models, token/context limit management, mapping chat completions to task outputs, and cost reporting via the cost_events table.',
    'Working agent config that routes tasks to GPT-4o',4,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m3,'pcl-23','pcl-23-http-adapter','HTTP Webhook Adapter','REST Integration',
    'Calling any external REST endpoint as an agent: request shape, polling strategy for async completion, timeout handling, and mapping HTTP response fields to Paperclip run status.',
    'Webhook adapter configured to call a real HTTP endpoint',5,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m3,'pcl-24','pcl-24-shell-adapter','Shell Process Adapter','Script Execution',
    'Running arbitrary shell commands or scripts as agents: sandboxing considerations, stdout/stderr capture, exit-code semantics, environment variable injection, and security best practices.',
    'Shell adapter that runs a Python data-processing script',6,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m3,'pcl-25','pcl-25-org-hierarchy','Building an Org Hierarchy','CEO → CTO → Engineer',
    'Using the reports_to field to model manager/IC relationships. Building a CEO → CTO → Engineer chain in Paperclip and visualizing the resulting org chart in the dashboard.',
    'A 3-level org chart created and visible in the dashboard',7,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m3,'pcl-26','pcl-26-reports-to','The reports_to Relationship','Self-Referential FK',
    'The self-referential foreign key on the agents table, cascading behavior on agent deletion, what it enables for task delegation routing, and querying the org tree recursively.',
    'Recursive CTE query that returns a full org-tree for one company',8,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m3,'pcl-27','pcl-27-custom-adapter','Building a Custom Adapter','Hands-On Lab',
    'Step-by-step: implement the Adapter TypeScript interface, register the new adapter in the factory, write a test heartbeat, and deploy a custom Slack-bot agent as a working example.',
    'A custom Slack adapter that posts daily summaries to a channel',9,'draft')
  ON CONFLICT (slug) DO NOTHING;

  -- ── MODULE 4: TASKS, ISSUES & WORKFLOWS ─────────────────────────────────

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m4,'pcl-28','pcl-28-issue-model','The Issue Domain Model','issues Table Schema',
    'All fields of the issues table: id, company_id, parent_id, title, description, status, assigned_agent_id, priority, metadata JSONB, created_at, updated_at. Field-by-field walkthrough.',
    'ER annotation of issues table with example row',1,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m4,'pcl-29','pcl-29-hierarchical-tasks','Hierarchical Tasks & Subtasks','Tree via parent_id',
    'Using parent_id for epic → story → task nesting. How agents create subtasks under their assigned issue. Recursive queries for full subtree traversal and depth limits.',
    'A 3-level task tree created via the API and queried recursively',2,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m4,'pcl-30','pcl-30-atomic-checkout','Atomic Task Checkout','Concurrency Safety',
    'The single UPDATE...RETURNING statement that atomically claims a task for one agent, preventing two agents from grabbing the same work under concurrent heartbeat runs. How the lock works.',
    'SQL demonstration: two concurrent SELECTs, only one claims the task',3,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m4,'pcl-31','pcl-31-task-lifecycle','Task Lifecycle & Status Transitions','State Machine',
    'Valid states: open → in_progress → completed / blocked / failed. Who can drive each transition, what writes to the audit log, and how to query historical state changes.',
    'State machine diagram with all valid transitions labeled',4,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m4,'pcl-32','pcl-32-delegation','Task Delegation Between Agents','Push vs. Pull',
    'How manager agents create subtasks and assign them downstream. Push delegation (manager assigns) vs. pull delegation (worker claims from open pool). Trade-offs and when to use each.',
    'Working 2-agent delegation: PM agent creates task, worker claims it',5,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m4,'pcl-33','pcl-33-priority-queues','Priority Queues & Scheduling','ORDER BY Logic',
    'The priority integer field, how agents select their next task (ORDER BY priority DESC, created_at ASC), starvation prevention for low-priority tasks, and manual priority bumping.',
    'Query showing priority-ordered task selection with tiebreaking',6,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m4,'pcl-34','pcl-34-bulk-seeding','Bulk Issue Seeding & Import','Batch API',
    'The REST endpoint for batch-creating issues, CSV import format, pre-populating a company''s backlog via curl/Postman, and idempotency patterns for re-runnable seeds.',
    'Shell script that seeds 20 issues from a CSV file',7,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m4,'pcl-35','pcl-35-workflow-patterns','Common Workflow Patterns','Design Patterns',
    'Pipeline (sequential stages), parallel fan-out (N agents simultaneously), review gate (output must be approved before next step), and escalation (auto-escalate blocked tasks to manager).',
    'Four annotated issue-tree diagrams, one per pattern',8,'draft')
  ON CONFLICT (slug) DO NOTHING;

  -- ── MODULE 5: THE HEARTBEAT SYSTEM ──────────────────────────────────────

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m5,'pcl-36','pcl-36-heartbeat-concept','The Heartbeat Concept Explained','Pull vs. Push',
    'Why Paperclip uses a scheduled heartbeat (pull) rather than event-driven webhooks (push), the tradeoffs in latency vs. simplicity, and the guarantee that no two heartbeats for one agent overlap.',
    'Timing diagram comparing event-driven vs. heartbeat execution',1,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m5,'pcl-37','pcl-37-cron-scheduling','Cron-Based Scheduling','Per-Agent Cron',
    'Cron expression syntax in Paperclip, setting per-agent schedules (*/5 * * * * vs 0 * * * *), the global cadence default, and how the scheduler service polls for due agents.',
    'Table of common cron expressions with human-readable descriptions',2,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m5,'pcl-38','pcl-38-execution-flow','Heartbeat Execution Flow','Step-by-Step',
    'Full execution sequence: trigger fires → eligible agents selected → adapter.invoke() called → status polled → result written to heartbeat_runs → cost_event recorded → activity logged.',
    'Sequence diagram covering all 7 steps of one heartbeat run',3,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m5,'pcl-39','pcl-39-heartbeat-runs','Heartbeat Run Records','heartbeat_runs Table',
    'Schema of heartbeat_runs: id, agent_id, company_id, started_at, completed_at, status, tokens_used, cost_usd, output_summary, error_message. How to query and interpret each field.',
    'Dashboard screenshot showing run timeline with cost per run',4,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m5,'pcl-40','pcl-40-concurrency','Concurrency & Lock Management','Advisory Locks',
    'How Paperclip prevents overlapping runs for the same agent using PostgreSQL advisory locks and row-level locking. What happens when a lock can''t be acquired and the fallback behavior.',
    'pg_locks query demonstrating lock acquisition during a heartbeat',5,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m5,'pcl-41','pcl-41-timeout-retry','Timeouts, Retries & Backoff','Resilience Patterns',
    'Per-adapter timeout configuration, exponential backoff on transient failures, maximum retry count, and dead-letter handling for permanently failed runs.',
    'Config snippet showing timeout and retry settings with annotated values',6,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m5,'pcl-42','pcl-42-debugging-runs','Debugging Failed Heartbeat Runs','Diagnosis Guide',
    'Reading run error logs in the dashboard, replaying a failed run via the API, using the --dry-run flag, and a reference table of common failure signatures per adapter type.',
    'Debugging checklist: 5 steps to diagnose any failed run',7,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m5,'pcl-43','pcl-43-persistent-sessions','Persistent Agent Sessions','Session Continuity',
    'How Claude Code adapter sessions maintain conversational context across heartbeat cycles, when and how to reset session state, and the tradeoff between continuity and drift.',
    'Side-by-side comparison: fresh session vs. persistent session output quality',8,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m5,'pcl-44','pcl-44-custom-triggers','Custom Triggers & Event-Driven Beats','Webhook Wakeup',
    'Wiring GitHub push events, Slack messages, or custom webhooks as non-cron triggers to wake an agent on demand. The trigger registration API and idempotency handling.',
    'GitHub Actions workflow that triggers a Paperclip heartbeat on PR open',9,'draft')
  ON CONFLICT (slug) DO NOTHING;

  -- ── MODULE 6: COST & GOVERNANCE ─────────────────────────────────────────

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m6,'pcl-45','pcl-45-cost-model','The Cost Model & cost_events Table','Spend Tracking',
    'Every token spend creates a cost_event row: amount_usd, agent_id, run_id, model, input_tokens, output_tokens, timestamp. How the server computes amount_usd from model pricing tables.',
    'Query returning total spend per agent for the current month',1,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m6,'pcl-46','pcl-46-budget-limits','Per-Agent Monthly Budget Limits','monthly_budget_usd',
    'Setting monthly_budget_usd on each agent, how the server aggregates SUM(amount_usd) from cost_events against the limit before each heartbeat, and the guard query.',
    'SQL guard query that returns agents over 80% of their monthly budget',2,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m6,'pcl-47','pcl-47-auto-pause','Auto-Pause on Budget Exhaustion','Circuit Breaker',
    'The guard that sets agent.status = ''paused'' when cumulative spend reaches the monthly budget, how the dashboard surfaces paused agents, and the manual-resume flow with owner approval.',
    'Demo: agent auto-pauses mid-month and resumes after approval',3,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m6,'pcl-48','pcl-48-approval-gates','Human Approval Gates','approvals Table',
    'Which actions require human sign-off: agent hiring, strategic pivots, agent termination, budget increases. The approvals table schema and how pending approvals block execution.',
    'Approval gate flow: action blocked → notification sent → human approves → unblocked',4,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m6,'pcl-49','pcl-49-approval-workflow','Approval Workflow Deep Dive','API & Notifications',
    'Creating pending approvals programmatically, the email/webhook notification on approval creation, the approve/reject REST endpoints, and the timeout-and-escalate pattern.',
    'End-to-end approval: create → notify → approve via API → unblock',5,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m6,'pcl-50','pcl-50-audit-trail','Audit Trail & Activity Log','Compliance Logging',
    'What events are automatically written to activity_log, the schema (actor, action, entity_type, entity_id, before/after snapshots, metadata), querying by time range, and CSV export.',
    'Query returning full audit trail for a single agent''s lifetime',6,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m6,'pcl-51','pcl-51-compliance-policies','Compliance Policies & Access Controls','RBAC',
    'Role-based access in the UI (read-only observer vs. full owner), API key scoping, how to lock down a company to read-only for external auditors, and policy enforcement at the API layer.',
    'Two API calls showing read-only vs. owner permission boundaries',7,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m6,'pcl-52','pcl-52-cost-reporting','Cost Reporting & Dashboards','Analytics Queries',
    'Daily and monthly cost summaries per agent and per company, the built-in cost chart views, writing custom cost queries, and exporting cost_events to CSV for finance teams.',
    'SQL view that produces a monthly cost report per agent',8,'draft')
  ON CONFLICT (slug) DO NOTHING;

  -- ── MODULE 7: MULTI-AGENT ORCHESTRATION ─────────────────────────────────

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m7,'pcl-53','pcl-53-coordinator-pattern','Coordinator / Worker Pattern','Design Pattern',
    'One coordinator agent breaks a goal into subtasks and assigns them; worker agents execute independently. Implementation walkthrough, the coordinator''s prompt design, and result aggregation.',
    'Working 3-agent coordinator/worker setup processing a real task',1,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m7,'pcl-54','pcl-54-agent-teams','Building Agent Teams','Team Grouping',
    'Grouping agents by function (engineering team, content team, support team), setting team-level budget envelopes, configuring team heartbeat cadences, and the dashboard team view.',
    'A 3-team company with per-team budgets configured',2,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m7,'pcl-55','pcl-55-parallel-work','Parallel Work Distribution','Fan-Out Pattern',
    'Seeding N identical task structures with different inputs so N agents process them in parallel during the same heartbeat window. Load balancing and result collection patterns.',
    '5 agents processing 5 independent tasks in one heartbeat cycle',3,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m7,'pcl-56','pcl-56-handoff-protocols','Agent Handoff Protocols','Message Passing',
    'How agent A signals completion to agent B: issue status transitions as signals, metadata JSONB as a message payload, and the activity_log as a shared event bus for handoffs.',
    'Handoff sequence: Agent A completes task, Agent B picks up continuation',4,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m7,'pcl-57','pcl-57-conflict-resolution','Conflict Resolution Strategies','Merge Patterns',
    'What happens when two agents produce conflicting outputs. Review gate patterns, human tiebreaker approvals, last-write-wins vs. merge strategies, and version-stamp conflicts.',
    'Conflict scenario with annotated resolution strategy for each case',5,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m7,'pcl-58','pcl-58-shared-memory','Shared Memory & Context Passing','JSONB Blackboard',
    'Using issue.metadata JSONB as a shared blackboard between agents, structured context schemas, avoiding metadata pollution in long-running workflows, and context size limits.',
    'Schema for a structured metadata payload passed between 3 agents',6,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m7,'pcl-59','pcl-59-real-examples','Real Orchestration Examples','Annotated Configs',
    'Three annotated real configurations: 3-agent content pipeline (research→write→edit), 5-agent dev team (PM→engineer×2→reviewer→merger), and a 2-agent review/publish loop.',
    'Three full configuration files with inline annotation',7,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m7,'pcl-60','pcl-60-scaling-agents','Scaling to 10+ Agents','Performance Guide',
    'PostgreSQL connection pooling requirements at scale, staggering heartbeat schedules to spread API load, memory growth patterns, cost explosion risks, and the practical upper limits.',
    'Performance benchmark table: 5, 10, 20 agents vs. DB connections and cost/day',8,'draft')
  ON CONFLICT (slug) DO NOTHING;

  -- ── MODULE 8: PRODUCTION & DEPLOYMENT ───────────────────────────────────

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m8,'pcl-61','pcl-61-docker-setup','Docker & Docker Compose Setup','Container Config',
    'The provided docker-compose.yml: services (server, web, postgres), volume mounts for data persistence, environment variable injection via .env files, and the build/up workflow.',
    'A running Paperclip stack via docker compose up',1,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m8,'pcl-62','pcl-62-postgres-prod','PostgreSQL in Production','Migration from PGlite',
    'Migrating from PGlite sandbox to a real PostgreSQL instance, running Drizzle migrations against the production DB, connection string format, pg-bouncer for connection pooling, and backup config.',
    'Migration script moving PGlite data to a PostgreSQL container',2,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m8,'pcl-63','pcl-63-nginx-proxy','Nginx Reverse Proxy','TLS & Routing',
    'Sample nginx.conf proxying the API (:3100) and React frontend (:5173) behind port 443, TLS termination with Let''s Encrypt Certbot, CORS headers, and WebSocket proxy settings.',
    'nginx.conf that routes /api/* to server and /* to frontend',3,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m8,'pcl-64','pcl-64-env-secrets','Environment Secrets Management','No Committed Keys',
    'Never committing API keys: Docker secrets, dotenv-vault for encrypted .env files, CI/CD environment variable injection (GitHub Actions secrets), and runtime secret rotation.',
    '.github/workflows/deploy.yml injecting secrets at deploy time',4,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m8,'pcl-65','pcl-65-monitoring','Monitoring & Alerting','Prometheus + Grafana',
    'Exposing a /metrics endpoint in Prometheus format, Grafana dashboard setup for heartbeat run counts, agent costs per hour, and error rate. PagerDuty/webhook alerting on anomalies.',
    'Grafana dashboard screenshot showing 3 key Paperclip metrics',5,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m8,'pcl-66','pcl-66-backup-restore','Backup & Restore Procedures','pg_dump Schedule',
    'Scheduled pg_dump via cron or pg_cron, S3/R2 upload for off-site storage, point-in-time restore walkthrough, and testing restore in a staging environment before needing it in production.',
    'Backup script and restore runbook as a single shell file',6,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m8,'pcl-67','pcl-67-security','Security Hardening','Least Privilege',
    'Least-privilege PostgreSQL users (read-only for metrics, write-only for agents), disabling debug/health endpoints in production, API rate limiting with express-rate-limit, and network segmentation.',
    'Security checklist: 8 hardening steps with before/after config',7,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m8,'pcl-68','pcl-68-ci-cd','CI/CD Pipeline for Agent Code','GitHub Actions',
    'GitHub Actions workflow: lint → TypeScript check → unit tests → Docker build → push to registry → SSH deploy → health-check gate. Rollback strategy on failed health check.',
    'Complete .github/workflows/deploy.yml for Paperclip',8,'draft')
  ON CONFLICT (slug) DO NOTHING;

  -- ── MODULE 9: REAL-WORLD PROJECTS ───────────────────────────────────────

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m9,'pcl-69','pcl-69-ai-content-company','Project: AI Content Company','4-Agent Pipeline',
    'Research agent scrapes and summarizes sources → Writer agent drafts → Editor agent revises → Publisher agent posts. One complete blog post produced per heartbeat cycle.',
    'Four-agent company running end-to-end and producing a real draft',1,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m9,'pcl-70','pcl-70-ai-dev-team','Project: AI Development Team','PM → Engineer → Reviewer',
    'PM agent writes specs → Engineer agent(s) implement → Reviewer agent reviews code → Merger agent opens PRs. Integration with a real GitHub repository via the HTTP adapter.',
    'A real GitHub PR opened by the Merger agent from agent-generated code',2,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m9,'pcl-71','pcl-71-ai-support-team','Project: AI Customer Support','Triage → Specialist',
    'Triage agent classifies incoming tickets by type and urgency → Specialist agents handle each category → Escalation agent routes tickets requiring human judgment.',
    'Support system processing 10 simulated tickets across 3 agents',3,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m9,'pcl-72','pcl-72-sap-integration','Project: SAP Integration Agents','HTTP Adapter + BTP',
    'Using the HTTP adapter to call SAP BTP service APIs, an agent that monitors a CAP service health endpoint and auto-files issues on failure, and a BTP workflow integration.',
    'Agent monitoring a BTP service and filing a GitHub issue on outage',4,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m9,'pcl-73','pcl-73-ai-research-firm','Project: AI Research Firm','Research → Synthesis',
    'Analyst agents scrape and summarize sources on a topic → Synthesis agent writes a structured report → Distribution agent emails it to a subscriber list on schedule.',
    'An auto-generated research brief delivered to an email address',5,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m9,'pcl-74','pcl-74-scaling-to-prod','Scaling Your Project to Production','Hardening Guide',
    'Taking a local prototype company to a hardened, monitored, cost-governed production deployment: the 10-step checklist covering every module''s production concerns in sequence.',
    'Production-readiness scorecard with pass/fail for each criterion',6,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m9,'pcl-75','pcl-75-multi-company','Multi-Company Architecture','Isolation Guarantees',
    'Running multiple independent companies in one Paperclip instance: company_id isolation guarantees, shared infrastructure costs, per-company billing separation, and UI multi-tenancy.',
    'Two companies in one instance with demonstrated data isolation',7,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m9,'pcl-76','pcl-76-capstone','Capstone: Build Your Zero-Human Company','Full Project',
    'The capstone: design your company''s org chart, hire 4+ agents across at least 2 adapter types, seed a real backlog of 20+ tasks, run for 7 days, and submit a cost + output analysis report.',
    '7-day run report: tasks completed, cost per agent, output quality assessment',8,'draft')
  ON CONFLICT (slug) DO NOTHING;

END $$;
