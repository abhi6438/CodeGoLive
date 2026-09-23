-- =============================================================================
-- paperclip_m25_content.sql
-- Module 2.5: Paperclip as Your Dev Assistant — full lesson content
-- Run AFTER paperclip_m25_seed.sql
-- =============================================================================

-- ─── pcl-dev-assistant-intro ─────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Paperclip as a Dev Assistant — the Mental Model

## What you'll learn
Understand why "dev assistant" tasks are fundamentally different from research tasks, and how the claude-code adapter turns Paperclip into something that can actually write, edit, and test code in your project.

---

## Two kinds of Paperclip tasks

Every issue you create in Paperclip falls into one of two categories:

| | Research / Analysis task | Dev task |
|---|---|---|
| **Output** | Text, summaries, plans | Changed files in a real codebase |
| **Adapter** | `openai`, `http`, `shell` | `claude-code` |
| **Agent "sees"** | Only the prompt | Your actual source files |
| **Result** | Markdown in `result` column | File diffs + explanation |
| **Risk** | Low — no side effects | Medium — edits real code |

A research task says: *"Summarise PostgreSQL RLS in 3 paragraphs."*

A dev task says: *"Add a `GET /api/users/:id/profile` endpoint in `src/routes/users.ts` that returns `id`, `name`, and `email` from the users table. Add a unit test in `src/routes/users.test.ts`."*

The second task results in **actual file changes** you can `git diff` and review.

---

## Why the claude-code adapter is different

The `claude-code` adapter is not just another LLM call. Under the hood it:

1. Launches a Claude Code process in your project directory (`workingDir`)
2. Gives Claude Code full tool access — `Read`, `Write`, `Edit`, `Bash`
3. Passes your issue description as the initial prompt
4. Captures everything Claude Code does (files read, files written, commands run)
5. Returns a structured result with the list of changed files and a summary

```
Issue description
      ↓
claude-code adapter
      ↓
  workingDir: ~/projects/my-app
      ↓
  Claude Code (has Read / Write / Edit / Bash tools)
      ↓
  Reads relevant files → makes changes → runs tests
      ↓
Result: { summary, changedFiles: [...], testsRan: true }
```

This is what makes Paperclip a dev assistant rather than a chatbot.

---

## What Paperclip does NOT do (yet)

- It does **not** open a pull request automatically (you do that after reviewing)
- It does **not** push to git (all changes stay local until you commit)
- It does **not** have context of your entire git history by default (you can give it context in the issue description)
- It does **not** run your CI pipeline (you run it after reviewing the changes)

Think of Paperclip as an agent that **works in your local checkout** and hands the result back to you for review. You stay in control of what gets committed.

---

## The dev assistant loop

```
You write an issue
      ↓
Heartbeat triggers the claude-code adapter
      ↓
Agent reads your files, makes changes, runs tests
      ↓
Issue marked resolved — result contains changed files + summary
      ↓
You run: git diff
      ↓
Accept → git add / commit / push
Reject → add a follow-up issue with corrections
```

This loop is the core of everything in this module.

---

## Checkpoint ✓

- What is the key difference between a research task and a dev task in Paperclip?
- Which adapter handles real file changes?
- What tools does the claude-code adapter give to the agent?
- Who decides what gets committed to git — Paperclip, or you?
$md$ WHERE slug = 'pcl-dev-assistant-intro';


-- ─── pcl-dev-local-full-setup ────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Full Local Setup for Dev Mode

## What you'll learn
Install every prerequisite, run Paperclip locally alongside your target project, and verify the agent can actually reach your codebase before you write a single task.

---

## Prerequisites checklist

Before starting, confirm these are installed:

```bash
# Node.js 20+
node --version   # must be >= 20.0.0

# pnpm (Paperclip's package manager)
pnpm --version   # must be >= 8.0.0
# Install: npm install -g pnpm

# Git
git --version

# Claude Code CLI (needed by the claude-code adapter)
claude --version
# Install: npm install -g @anthropic-ai/claude-code

# Verify Claude is authenticated
claude auth status
# If not: claude auth login
```

> **Why Claude Code CLI?** The `claude-code` adapter shells out to the `claude` binary in your PATH. It is not an API call — it runs the full Claude Code agent locally, which gives it real file access.

---

## Step 1 — Clone and run Paperclip

```bash
# Clone Paperclip
git clone https://github.com/paperclipai/paperclip.git
cd paperclip

# Install dependencies
pnpm install

# Copy the environment template
cp .env.example .env
```

Edit `.env` — minimum required values for dev mode:

```bash
# .env
DATABASE_URL=           # Leave blank — PGlite is used in dev mode automatically
ANTHROPIC_API_KEY=sk-ant-...   # Your Anthropic API key (claude-code adapter needs this)

# Optional but useful
PAPERCLIP_LOG_LEVEL=debug      # See everything happening in the heartbeat
HEARTBEAT_INTERVAL_MS=30000    # 30s between ticks in dev (default is 60s)
```

Start the full stack:

```bash
pnpm dev
```

You should see:
```
[migrations] 8 tables ready
[server] Paperclip API listening on http://localhost:3100
[web] Vite dev server running at http://localhost:5173
[scheduler] Heartbeat tick scheduled every 60s
```

---

## Step 2 — Locate your target project

Your "target project" is the codebase you want agents to work on. It must be a directory on the same machine running Paperclip.

```bash
# Example: a Node.js/Express project
ls ~/projects/my-api/
# src/  package.json  tsconfig.json  .env  ...

# Make note of the absolute path — you'll need it in Step 4
echo ~/projects/my-api
# /Users/you/projects/my-api
```

> The target project does NOT need to be running. The agent reads and writes files directly — it doesn't need a live server.

---

## Step 3 — Initialise git in your target project (if not already)

The agent will make file changes. Git lets you review them cleanly with `git diff`.

```bash
cd ~/projects/my-api

# If not already a git repo:
git init
git add .
git commit -m "initial commit before paperclip agent work"

# Create a dedicated branch for agent work
git checkout -b paperclip-agent
```

Working on a dedicated branch keeps agent changes isolated from your main branch until you're ready to merge.

---

## Step 4 — Configure the claude-code adapter in Paperclip

Open `apps/server/src/adapters/claude-code/config.ts` (or the equivalent in your version — check `src/adapters/`):

```typescript
// apps/server/src/adapters/claude-code/config.ts
export const claudeCodeAdapterConfig = {
  // Absolute path to the project the agent will work in
  workingDir: process.env.AGENT_WORKING_DIR ?? '',

  // Maximum time (ms) before the adapter times out a run
  timeoutMs: 300_000, // 5 minutes — increase for large tasks

  // Whether to run in dry-run mode (agent reads files but won't write)
  dryRun: process.env.AGENT_DRY_RUN === 'true',
};
```

Add `AGENT_WORKING_DIR` to your `.env`:

```bash
# .env
AGENT_WORKING_DIR=/Users/you/projects/my-api
```

Restart Paperclip after editing `.env`:

```bash
# Ctrl+C to stop pnpm dev, then:
pnpm dev
```

---

## Step 5 — Verify agent access

Use the dry-run endpoint to confirm the adapter can see your project without making any changes:

```bash
curl -X POST http://localhost:3100/api/adapters/claude-code/test \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "List the top-level files and directories in this project.",
    "dry_run": true
  }'
```

Expected response:

```json
{
  "status": "ok",
  "working_dir": "/Users/you/projects/my-api",
  "output": "The project contains: src/, package.json, tsconfig.json, README.md, .env ...",
  "files_read": ["package.json", "tsconfig.json"],
  "files_written": []
}
```

If you see `"status": "error"` with `working_dir not set` — check that `AGENT_WORKING_DIR` is in `.env` and you restarted `pnpm dev`.

---

## Full setup checklist

- [ ] Node 20+, pnpm, Git, Claude Code CLI all installed
- [ ] `claude auth status` shows authenticated
- [ ] `pnpm dev` starts without errors — server on 3100, web on 5173
- [ ] Target project has an initial git commit on a `paperclip-agent` branch
- [ ] `AGENT_WORKING_DIR` set in `.env` pointing to the target project
- [ ] Dry-run test returns `"status": "ok"` with files listed

---

## Checkpoint ✓

- Why does the `claude-code` adapter require the Claude Code CLI instead of a direct API call?
- What does `AGENT_DRY_RUN=true` protect you from?
- Why is it recommended to work on a separate `paperclip-agent` git branch?
- What does the `/api/adapters/claude-code/test` endpoint verify?
$md$ WHERE slug = 'pcl-dev-local-full-setup';


-- ─── pcl-connect-your-repo ───────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Connecting the claude-code Adapter to Your Repository

## What you'll learn
Configure the `claude-code` adapter properly so agents can read and write files in your project, understand what the agent has access to, and set safety limits so it doesn't do unexpected things.

---

## How workingDir works

`workingDir` is the root directory the agent operates inside. When the agent runs:

- `Read("src/routes/users.ts")` → reads `/your/project/src/routes/users.ts`
- `Write("src/routes/users.ts", ...)` → writes to `/your/project/src/routes/users.ts`
- `Bash("npm test")` → runs in `/your/project/`

The agent cannot escape `workingDir`. Paths like `../../etc/passwd` are blocked by Claude Code's own sandboxing.

---

## The adapter config file

The claude-code adapter reads its config from two places: the `.env` file (for secrets and paths) and the adapter config object in source (for behaviour tuning).

```typescript
// apps/server/src/adapters/claude-code/index.ts (simplified)
import { claudeCodeAdapterConfig } from './config';

export const claudeCodeAdapter: Adapter = {
  async invoke(task: AdapterTask): Promise<AdapterResult> {
    const { workingDir, timeoutMs } = claudeCodeAdapterConfig;

    const result = await runClaudeCode({
      prompt: buildPrompt(task),   // combines issue title + description + context
      workingDir,
      timeoutMs,
      env: {
        ANTHROPIC_API_KEY: process.env.ANTHROPIC_API_KEY,
      },
    });

    return {
      output: result.summary,
      changedFiles: result.changedFiles,
      cost: result.cost,
    };
  },
};
```

---

## Providing project context to the agent

The agent only knows what's in the prompt plus what it reads from files. You can improve results significantly by adding a `CLAUDE.md` file to your project root — Claude Code reads it automatically at the start of every session:

```markdown
<!-- ~/projects/my-api/CLAUDE.md -->
# Project Context for Paperclip Agents

## Stack
- Node.js 20 + TypeScript
- Express 4 for routing
- Drizzle ORM + PostgreSQL
- Vitest for tests

## Key directories
- `src/routes/` — all Express route handlers
- `src/db/schema.ts` — Drizzle schema (source of truth for all tables)
- `src/db/queries/` — reusable query functions
- `tests/` — Vitest test files

## Conventions
- All route files export a single Express Router
- Every new endpoint needs a test in `tests/<route>.test.ts`
- Use `db.query.<table>.findMany(...)` not raw SQL
- TypeScript strict mode is on — no `any`

## Running tests
npm test             # all tests
npm test -- --watch  # watch mode
```

> A good `CLAUDE.md` is the most effective way to improve agent output quality. Think of it as onboarding documentation for your AI team members.

---

## Restricting what the agent can do

You can configure the adapter to limit agent permissions:

```typescript
// config.ts
export const claudeCodeAdapterConfig = {
  workingDir: process.env.AGENT_WORKING_DIR ?? '',
  timeoutMs: 300_000,

  // Prevent the agent from running shell commands (file read/write only)
  disableBash: process.env.AGENT_DISABLE_BASH === 'true',

  // Paths the agent must NOT modify (relative to workingDir)
  readOnlyPaths: [
    '.env',
    '.env.production',
    'secrets/',
    'certs/',
  ],

  // File extensions the agent can write to (undefined = all)
  writeableExtensions: ['.ts', '.tsx', '.js', '.json', '.md', '.css'],
};
```

Add to `.env`:

```bash
# For read-only exploratory agents:
AGENT_DISABLE_BASH=true
```

---

## Multi-project setup (advanced)

If you want different agents working on different projects, configure per-agent `workingDir` by storing it on the agent record itself:

```sql
-- Add workingDir to agent config (stored in the `config` JSONB column)
UPDATE agents
SET config = jsonb_set(
  COALESCE(config, '{}'),
  '{workingDir}',
  '"/Users/you/projects/my-api"'
)
WHERE slug = 'backend-dev-agent';
```

Then in the adapter, read from the agent config first, falling back to the global env:

```typescript
const workingDir =
  task.agent.config?.workingDir ??
  process.env.AGENT_WORKING_DIR ??
  '';
```

This lets you hire a "frontend agent" pointing at your React app and a "backend agent" pointing at your API — both running in the same Paperclip instance.

---

## Checkpoint ✓

- What does `workingDir` control, and can the agent escape it?
- What file does Claude Code read automatically for project context?
- Name two ways to restrict what the agent is allowed to do.
- How would you configure two agents to work on two different projects?
$md$ WHERE slug = 'pcl-connect-your-repo';


-- ─── pcl-dev-task-anatomy ────────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Anatomy of a Great Dev Task

## What you'll learn
Write issues that reliably produce good code on the first attempt — the title, description, acceptance criteria, file context, and scope patterns that work.

---

## The anatomy of a dev issue

```
┌─────────────────────────────────────────────────────┐
│  title          One-line summary — imperative voice  │
│  description    What to build + where + constraints  │
│  context        Relevant files, existing patterns    │
│  acceptance     How to know it's done correctly      │
│  scope          What NOT to change                   │
└─────────────────────────────────────────────────────┘
```

All of this lives in the `description` field of the issue (the `title` alone is not enough for code tasks).

---

## A weak issue vs a strong issue

**Weak — the agent will probably miss:**
```json
{
  "title": "Add user profile endpoint",
  "description": "Add an API endpoint for user profiles"
}
```
Problems: no file path, no response shape, no test requirement, no constraints.

**Strong — the agent has everything it needs:**
```json
{
  "title": "Add GET /api/users/:id/profile endpoint",
  "description": "## Task\nAdd a new route handler in `src/routes/users.ts`.\n\n## Endpoint spec\n- Method: GET\n- Path: /api/users/:id/profile\n- Auth: require JWT (use the `requireAuth` middleware already on other routes)\n- Response: `{ id, name, email, createdAt }` from the `users` table\n- 404 if user not found\n\n## Acceptance criteria\n- [ ] Route is registered in `src/app.ts`\n- [ ] Handler is in `src/routes/users.ts` following existing patterns\n- [ ] Test added in `tests/users.test.ts` covering 200 and 404 cases\n- [ ] `npm test` passes\n\n## Do not change\n- Do not modify the users table schema\n- Do not change other existing routes"
}
```

---

## The five elements in detail

### 1. Title — imperative, specific
Use the HTTP method + path for API tasks, or the component + action for UI tasks:

```
✓  Add GET /api/orders/:id/items endpoint
✓  Refactor UserCard component to use Tailwind classes
✓  Fix bug: pagination resets on filter change in ProductList
✗  Fix the bug
✗  Improve API
```

### 2. What to build + where
Always name the exact files. Agents perform better when they know where to look:

```markdown
Add a new file `src/services/email.ts` that exports a `sendWelcomeEmail(userId: string)` function.
Update `src/routes/auth.ts` to call `sendWelcomeEmail` after successful registration (line ~45, after `await createUser(...)`).
```

### 3. Constraints — what NOT to touch
This is as important as what to build:

```markdown
## Do not change
- Do not modify `src/db/schema.ts`
- Do not change the existing `POST /api/auth/register` response shape
- Do not add new npm packages
```

### 4. Acceptance criteria — checkboxes
Frame these as things the agent can verify:

```markdown
## Acceptance criteria
- [ ] `src/services/email.ts` exists and exports `sendWelcomeEmail`
- [ ] `npm test` passes (no new failing tests)
- [ ] TypeScript compiles with no errors (`npx tsc --noEmit`)
- [ ] The function is called in `src/routes/auth.ts`
```

### 5. Context — relevant files and patterns
Tell the agent where to look for existing patterns to follow:

```markdown
## Context
- See `src/services/sms.ts` for an example of a similar service pattern
- Auth middleware is in `src/middleware/auth.ts`
- Existing email config is in `src/config.ts` under the `email` key
```

---

## Task sizing — how much to put in one issue

| Task size | Example | Typical duration |
|-----------|---------|-----------------|
| **XS** | Fix a typo in an error message | < 1 min |
| **S** | Add a single endpoint with test | 2–5 min |
| **M** | Add a CRUD resource (4 endpoints + tests) | 5–15 min |
| **L** | Migrate a module to a new pattern | 15–30 min |
| **XL** | Add a full feature across multiple files | 30–60 min |

> Start with S and M tasks. XL tasks often produce harder-to-review diffs and are more likely to miss acceptance criteria. Break them down.

---

## Quick templates

**Bug fix:**
```markdown
## Bug
Describe what is broken and how to reproduce it.
File: `src/...`  Line: ~42

## Expected behaviour
What should happen.

## Fix approach
Suggested fix (or leave blank for agent to determine).

## Acceptance criteria
- [ ] The reproduction steps no longer trigger the bug
- [ ] Existing tests still pass
```

**New feature:**
```markdown
## Feature
What to build.

## Files to create/modify
- Create: `src/...`
- Modify: `src/...`

## Spec
Detailed requirements, API shape, or UI behaviour.

## Acceptance criteria
- [ ] ...
- [ ] npm test passes
```

---

## Checkpoint ✓

- Name the five elements of a strong dev issue.
- Why is "Do not change" as important as "What to build"?
- What is the recommended maximum task size when starting out with Paperclip?
- Where do you put acceptance criteria — the `title` or `description` field?
$md$ WHERE slug = 'pcl-dev-task-anatomy';


-- ─── pcl-dev-first-code-task ─────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Your First Real Code Task — End to End

## What you'll learn
Go from zero to watching the agent make a real file change in your project — creating the issue, triggering the heartbeat, monitoring the run, and reading the result.

---

## Before you start

Confirm from the previous topics:
- [ ] Paperclip is running (`pnpm dev`)
- [ ] `AGENT_WORKING_DIR` points to your project
- [ ] Your project is on the `paperclip-agent` git branch
- [ ] A company and a claude-code agent have been created (Module 2)

Set these shell variables for convenience:

```bash
export BASE=http://localhost:3100/api
export COMPANY_ID=<your-company-id>
export AGENT_ID=<your-claude-code-agent-id>
```

---

## Step 1 — Capture the current git state

Before any agent work, record the baseline so you can diff cleanly:

```bash
cd ~/projects/my-api
git status          # should be clean
git log --oneline -3
# e3a9f1c initial commit before paperclip agent work
```

---

## Step 2 — Create a real dev issue

Use a concrete task from your actual project. For this walkthrough we'll add a health-check endpoint — a small, safe, verifiable change:

```bash
curl -X POST $BASE/companies/$COMPANY_ID/issues \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Add GET /health endpoint",
    "description": "## Task\nAdd a health-check endpoint to the Express app.\n\n## Spec\n- Method: GET\n- Path: /health\n- Response: `{ status: \"ok\", uptime: <process.uptime()>, timestamp: <Date.now()> }`\n- No auth required\n- Register in `src/app.ts`\n\n## Acceptance criteria\n- [ ] Endpoint responds with 200\n- [ ] Response matches the shape above\n- [ ] `npm test` passes\n\n## Do not change\n- Do not modify any existing routes\n- Do not change package.json",
    "assigned_agent_id": "'$AGENT_ID'",
    "priority": "medium"
  }'
```

Note the `id` in the response:
```json
{ "id": "01929f3a-xxxx", "status": "open", "title": "Add GET /health endpoint" }
```

```bash
export ISSUE_ID=01929f3a-xxxx
```

---

## Step 3 — Trigger the heartbeat manually

Don't wait for the cron tick — trigger it now:

```bash
curl -X POST $BASE/heartbeat/run \
  -H "Content-Type: application/json" \
  -d '{"company_id": "'$COMPANY_ID'"}'
```

Response:
```json
{
  "run_id": "01929f40-yyyy",
  "status": "running",
  "agents_invoked": 1,
  "issues_claimed": 1
}
```

```bash
export RUN_ID=01929f40-yyyy
```

---

## Step 4 — Watch it run in real time

Poll the run status while the agent works:

```bash
watch -n 2 "curl -s $BASE/heartbeat/runs/$RUN_ID | python3 -m json.tool"
```

You'll see `status` move through:
```
"running" → "running" → "completed"
```

While it's running, tail the Paperclip server logs in the other terminal:
```
[adapter:claude-code] Invoking agent on /Users/you/projects/my-api
[adapter:claude-code] Agent reading: src/app.ts
[adapter:claude-code] Agent reading: src/routes/
[adapter:claude-code] Agent writing: src/routes/health.ts
[adapter:claude-code] Agent editing: src/app.ts
[adapter:claude-code] Agent running: npm test
[adapter:claude-code] Run complete. 2 files changed. Cost: $0.031
```

---

## Step 5 — Read the issue result

```bash
curl -s $BASE/companies/$COMPANY_ID/issues/$ISSUE_ID | python3 -m json.tool
```

```json
{
  "id": "...",
  "status": "resolved",
  "result": "Added GET /health endpoint...\n\nFiles changed:\n- src/routes/health.ts (created)\n- src/app.ts (modified, line 23)",
  "result_structured": {
    "summary": "Added health endpoint returning status, uptime, and timestamp",
    "changedFiles": [
      { "path": "src/routes/health.ts", "action": "created" },
      { "path": "src/app.ts", "action": "modified" }
    ],
    "testsRan": true,
    "testsPassed": true
  },
  "cost_usd": "0.031"
}
```

---

## Step 6 — See the actual file changes

```bash
cd ~/projects/my-api
git diff
```

You should see something like:

```diff
diff --git a/src/app.ts b/src/app.ts
index 3b2f1c9..a7e4d21 100644
--- a/src/app.ts
+++ b/src/app.ts
@@ -12,6 +12,7 @@ import { authRouter } from './routes/auth';
+import { healthRouter } from './routes/health';

 app.use('/api/auth', authRouter);
+app.use('/health', healthRouter);

diff --git a/src/routes/health.ts b/src/routes/health.ts
new file mode 100644
--- /dev/null
+++ b/src/routes/health.ts
@@ -0,0 +1,12 @@
+import { Router } from 'express';
+
+export const healthRouter = Router();
+
+healthRouter.get('/', (req, res) => {
+  res.json({
+    status: 'ok',
+    uptime: process.uptime(),
+    timestamp: Date.now(),
+  });
+});
```

The agent created a new file and wired it up — exactly what the issue asked for.

---

## Step 7 — Verify it works

```bash
cd ~/projects/my-api
npm test
npm run dev &       # start the server
curl http://localhost:3000/health
# {"status":"ok","uptime":2.3,"timestamp":1748000000000}
```

---

## Checkpoint ✓

- [ ] Issue created and heartbeat triggered
- [ ] Run completed with `status: "resolved"`
- [ ] `git diff` shows new/modified files matching the issue spec
- [ ] Tests pass, endpoint responds correctly
- What does `result_structured.changedFiles` contain?
- How do you monitor a run in real time via the API?
$md$ WHERE slug = 'pcl-dev-first-code-task';


-- ─── pcl-review-agent-work ───────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Reviewing What the Agent Did

## What you'll learn
Build a reliable review workflow: `git diff`, reading structured results, running tests, and deciding whether to accept, reject, or request a revision.

---

## The review mindset

Treat agent-authored code the same way you'd treat a pull request from a junior developer — read every changed line, check it matches the spec, and verify the tests actually cover the behaviour.

Your review checklist:
1. Does the diff match what the issue asked for?
2. Did the agent change anything outside the specified scope?
3. Do the tests run and pass?
4. Does the code follow existing patterns in the project?
5. Are there any obvious bugs, security issues, or missing error handling?

---

## Reading the diff

```bash
cd ~/projects/my-api

# All changes since your last commit
git diff

# Only staged changes (after git add)
git diff --staged

# Summary — files changed and line counts
git diff --stat

# A specific file
git diff src/routes/health.ts
```

For larger changes, use your editor's diff view:

```bash
# VS Code
code --diff src/app.ts

# Or open the project and use the Source Control panel
code .
```

---

## Reading the structured result

The `result_structured` JSONB field gives you a machine-readable summary:

```bash
curl -s $BASE/companies/$COMPANY_ID/issues/$ISSUE_ID \
  | python3 -c "import sys,json; r=json.load(sys.stdin); print(json.dumps(r['result_structured'], indent=2))"
```

```json
{
  "summary": "Added health endpoint",
  "changedFiles": [
    { "path": "src/routes/health.ts", "action": "created",  "linesAdded": 12, "linesRemoved": 0 },
    { "path": "src/app.ts",           "action": "modified", "linesAdded": 2,  "linesRemoved": 0 }
  ],
  "commandsRun": ["npm test"],
  "testsRan": true,
  "testsPassed": true,
  "errors": []
}
```

If `testsPassed` is `false` or `errors` is non-empty — the agent tried but hit a problem. Read the `result` text field for the full explanation.

---

## Three review outcomes

### ✅ Accept — commit the changes

```bash
cd ~/projects/my-api

# Review one more time
git diff --stat

# Stage all agent changes
git add -A

# Commit with a clear message referencing the issue
git commit -m "feat: add GET /health endpoint

Paperclip issue: pcl-issue-01929f3a
Agent: claude-code-agent"

# Optionally push to your branch
git push origin paperclip-agent
```

---

### ✏️ Revise — the change is close but needs adjustment

If the diff is mostly right but missing something (no test, wrong field name, etc.), you have two options:

**Option A — Edit manually and commit:**
```bash
# Fix the issue yourself
vim src/routes/health.ts
git add -A
git commit -m "feat: add /health endpoint (with manual fix for missing error handling)"
```

**Option B — Create a follow-up issue for the agent:**
```bash
curl -X POST $BASE/companies/$COMPANY_ID/issues \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Fix: /health endpoint missing error handling",
    "description": "The health endpoint in `src/routes/health.ts` was just added but is missing a try/catch. If `process.uptime()` throws for any reason the server will crash.\n\nAdd a try/catch and return `{ status: \"error\", message: err.message }` with a 500 status code.\n\n## Acceptance criteria\n- [ ] try/catch wraps the handler\n- [ ] npm test passes",
    "assigned_agent_id": "'$AGENT_ID'",
    "priority": "high"
  }'
```

---

### ❌ Reject — discard all agent changes

```bash
cd ~/projects/my-api

# Discard all uncommitted changes
git checkout -- .
git clean -fd          # remove untracked files

# Verify clean state
git status             # should say "nothing to commit"
```

Update the issue status so it's tracked:

```bash
curl -X PATCH $BASE/companies/$COMPANY_ID/issues/$ISSUE_ID \
  -H "Content-Type: application/json" \
  -d '{"status": "rejected", "rejection_note": "Wrong approach — used raw SQL instead of Drizzle ORM"}'
```

---

## Common review red flags

| What you see | What to do |
|---|---|
| Agent modified a file outside the scope | Discard or manually revert that file with `git checkout -- path/to/file` |
| Tests were added but don't actually test the new code | Accept the feature, create a follow-up issue to improve tests |
| TypeScript errors (`npx tsc --noEmit` fails) | Fix or create follow-up issue |
| Agent used a different library/pattern than the rest of the codebase | Accept if functionally correct, create follow-up to refactor |
| `npm test` fails | Always reject or fix before committing |

---

## Checkpoint ✓

- What does `git diff --stat` show you?
- What are the three possible outcomes of a review and what do you do for each?
- If an agent change is 90% correct but missing a test, which option is better — manual fix or follow-up issue?
- How do you discard all agent changes and return to a clean state?
$md$ WHERE slug = 'pcl-review-agent-work';


-- ─── pcl-dev-feedback-loop ───────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Building an Iterative Dev Feedback Loop

## What you'll learn
Set up a sustainable working rhythm with Paperclip: branch strategy, chaining tasks, refining prompts when the agent misses, and breaking large features into agent-sized pieces.

---

## The core loop

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│   Write issue  →  Trigger heartbeat  →  Agent works        │
│         ↑                                       ↓          │
│   Refine prompt                          Review diff        │
│   (if reject)                                   ↓          │
│                                          Accept → commit    │
│                                          Reject → discard   │
│                                          Revise → follow-up │
└─────────────────────────────────────────────────────────────┘
```

Most developers find this loop becomes second nature after 3–5 tasks.

---

## Branch strategy

Keep agent work isolated with a clear branch pattern:

```bash
# One branch per feature or ticket
git checkout -b paperclip/add-user-profile-api

# Do all agent tasks for this feature on this branch
# (create issues, trigger heartbeats, commit accepted changes)

# When the feature is done, merge or PR into main
git checkout main
git merge --no-ff paperclip/add-user-profile-api
```

> Using the `paperclip/` prefix makes it easy to spot agent branches in your git log.

---

## Chaining tasks — building a feature in steps

For anything bigger than an S task, break it into a chain:

```
Feature: User profile API with avatar upload

Task 1: Add users table migration (schema only)
        ↓ accept ↓
Task 2: Add GET /api/users/:id profile endpoint
        ↓ accept ↓
Task 3: Add PATCH /api/users/:id update endpoint
        ↓ accept ↓
Task 4: Add POST /api/users/:id/avatar upload endpoint
        ↓ accept ↓
Task 5: Add integration tests covering all four endpoints
```

Create Task 2 only after Task 1 is accepted and committed — the agent for Task 2 will read the migration file that Task 1 created.

```bash
# After accepting and committing Task 1:
git diff HEAD~1 --stat
# db/migrations/0005_add_users.ts    +45

# Now create Task 2 with context about what Task 1 added
curl -X POST $BASE/companies/$COMPANY_ID/issues \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Add GET /api/users/:id profile endpoint",
    "description": "## Context\nMigration `db/migrations/0005_add_users.ts` was just added with a `users` table containing: id, name, email, avatar_url, created_at.\n\n## Task\nAdd the profile endpoint...",
    ...
  }'
```

---

## Refining prompts when the agent misses

When an agent produces the wrong result, resist the urge to just retry the same prompt. Diagnose first:

| Symptom | Root cause | Fix |
|---------|-----------|-----|
| Agent used a different pattern to the rest of the code | No example provided | Add "See `src/routes/orders.ts` for the pattern to follow" |
| Agent modified files outside scope | Scope was implicit | Add explicit "Do not change" section |
| Agent created the right code but in the wrong file | File path not specified | Give exact file paths |
| Agent wrote tests but they don't run | Test runner not mentioned | Add "Run `npm test` to verify" to acceptance criteria |
| Agent solution is correct but uses a package not in package.json | No constraint on packages | Add "Do not add new npm packages" |

Example improvement:

```
Before:
"Add input validation to the registration endpoint"

After:
"Add input validation to the POST /api/auth/register endpoint in `src/routes/auth.ts`.
Use the existing `zod` package (already in package.json) — see `src/routes/products.ts`
line 12 for an example of how we use zod validation on this route.
Return 400 with `{ error: 'Invalid input', details: [...] }` on validation failure.
Do not change the success response shape."
```

---

## Using `CLAUDE.md` to reduce prompt boilerplate

If you find yourself repeating the same context in every issue ("use Drizzle ORM, not raw SQL", "follow the pattern in src/routes/orders.ts"), move it to `CLAUDE.md`:

```markdown
<!-- CLAUDE.md additions -->
## Code standards for Paperclip agents
- Always use Drizzle ORM for database queries — no raw SQL
- Follow the pattern in `src/routes/orders.ts` for new route files
- Every new endpoint needs a test — run `npm test` before finishing
- Do not add new npm packages without checking with the team first
- TypeScript strict mode: no `any`, no non-null assertions without a comment
```

Once this is in `CLAUDE.md`, you don't need to repeat it in every issue.

---

## Velocity tips

**Work on one task at a time.** The heartbeat can process multiple issues in parallel, but for dev tasks you want to review and commit each one before the next agent run reads the updated codebase.

```bash
# After committing Task 1:
curl -X POST $BASE/heartbeat/run -d '{"company_id": "'$COMPANY_ID'"}'
# This now picks up Task 2, which can see the files Task 1 created
```

**Use the agent's `result` as documentation.** The structured result text is a natural commit message, PR description, or changelog entry:

```bash
# Get the result text
curl -s $BASE/companies/$COMPANY_ID/issues/$ISSUE_ID | \
  python3 -c "import sys,json; print(json.load(sys.stdin)['result'])"
```

**Keep a task backlog.** Write 5–10 issues in advance (they'll sit as `open`). The heartbeat will pick them up in priority order.

---

## Checkpoint ✓

- Why should you chain tasks sequentially (one accepted before the next starts)?
- Name three root causes of an agent producing the wrong result, and the fix for each.
- What is `CLAUDE.md` and how does it reduce issue-writing boilerplate?
- What branch naming convention keeps agent work clearly visible in git log?
$md$ WHERE slug = 'pcl-dev-feedback-loop';


-- ─── pcl-dev-real-project ────────────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# End-to-End Walkthrough: Build a Feature with Paperclip

## What you'll learn
Go from feature idea to committed code using the full Paperclip dev-assistant workflow. We'll add a **"recent activity" feed** to a Node.js/Express + PostgreSQL API — a realistic feature touching migrations, routes, tests, and a small service layer.

---

## The feature

**"Recent Activity Feed"** — an endpoint that returns the last 20 actions a user has taken (logins, profile updates, password changes), pulled from an `activity_log` table.

We'll do it in five agent tasks.

---

## Task 0 — Preparation

```bash
# Start on a clean branch
cd ~/projects/my-api
git checkout main
git pull
git checkout -b paperclip/activity-feed

# Confirm Paperclip is running
curl -s http://localhost:3100/api/health | python3 -m json.tool

# Set shell vars
export BASE=http://localhost:3100/api
export COMPANY_ID=<id>
export AGENT_ID=<claude-code-agent-id>
```

---

## Task 1 — Database migration

```bash
curl -X POST $BASE/companies/$COMPANY_ID/issues \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Add activity_log table migration",
    "description": "## Task\nCreate a new Drizzle ORM migration that adds an `activity_log` table.\n\n## Schema\n```\nactivity_log\n  id          uuid primary key default gen_random_uuid()\n  user_id     uuid not null references users(id) on delete cascade\n  action      text not null   -- e.g. \"login\", \"profile_update\", \"password_change\"\n  metadata    jsonb           -- optional context\n  created_at  timestamptz not null default now()\n```\nAdd an index on `(user_id, created_at DESC)` for the feed query.\n\n## Files\n- Create migration in `db/migrations/` following the existing numbering pattern\n- Update `src/db/schema.ts` to export the new table definition\n\n## Acceptance criteria\n- [ ] Migration file created with correct SQL\n- [ ] Schema exported from `src/db/schema.ts`\n- [ ] `npm run db:migrate` runs without errors\n- [ ] `npm test` passes\n\n## Do not change\n- Do not modify any existing tables",
    "assigned_agent_id": "'$AGENT_ID'",
    "priority": "high"
  }'
```

**Review:** Check the migration SQL is correct, the schema export is clean, `npm run db:migrate` ran. Accept and commit.

```bash
git add -A
git commit -m "feat: add activity_log table migration

Paperclip agent task 1/5 — activity feed feature"
```

---

## Task 2 — Service layer

```bash
curl -X POST $BASE/companies/$COMPANY_ID/issues \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Add ActivityService with logActivity and getRecentActivity methods",
    "description": "## Context\nMigration added `activity_log` table (id, user_id, action, metadata, created_at). Schema is exported from `src/db/schema.ts` as `activityLog`.\n\n## Task\nCreate `src/services/activity.ts` with two exported functions:\n\n### logActivity(userId: string, action: string, metadata?: Record<string, unknown>): Promise<void>\nInserts a row into activity_log.\n\n### getRecentActivity(userId: string, limit = 20): Promise<ActivityEntry[]>\nReturns the last `limit` entries for the user, ordered by created_at DESC.\nReturn type: `{ id: string, action: string, metadata: unknown, createdAt: Date }[]`\n\n## Patterns\n- Use Drizzle ORM (`db.insert`, `db.select`) — see `src/services/user.ts` for examples\n- No raw SQL\n\n## Acceptance criteria\n- [ ] `src/services/activity.ts` created and exported\n- [ ] Both functions typed correctly with no `any`\n- [ ] Unit tests in `tests/activity.service.test.ts`\n- [ ] `npm test` passes",
    "assigned_agent_id": "'$AGENT_ID'",
    "priority": "high"
  }'
```

**Review:** Check Drizzle usage, types, tests. Accept and commit.

---

## Task 3 — Route handler

```bash
curl -X POST $BASE/companies/$COMPANY_ID/issues \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Add GET /api/users/:id/activity endpoint",
    "description": "## Context\n`src/services/activity.ts` now exports `getRecentActivity(userId, limit)`.\n\n## Task\nAdd a new route to `src/routes/users.ts`:\n- Method: GET\n- Path: /api/users/:id/activity\n- Auth: requireAuth middleware (already used in this file)\n- Authorization: users can only fetch their own activity (req.user.id must equal params.id)\n- Query param: `?limit=20` (max 50, default 20)\n- Response: `{ activity: ActivityEntry[] }`\n- 403 if user tries to access another user'\''s activity\n- 404 if user not found\n\n## Acceptance criteria\n- [ ] Route added to `src/routes/users.ts`\n- [ ] Registered in `src/app.ts`\n- [ ] Integration test in `tests/users.test.ts`\n- [ ] `npm test` passes",
    "assigned_agent_id": "'$AGENT_ID'",
    "priority": "high"
  }'
```

**Review:** Check auth, 403 enforcement, test coverage. Accept and commit.

---

## Task 4 — Wire up activity logging

```bash
curl -X POST $BASE/companies/$COMPANY_ID/issues \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Log activity events on login, profile update, and password change",
    "description": "## Context\n`src/services/activity.ts` exports `logActivity(userId, action, metadata?)`.\n\n## Task\nCall `logActivity` at three points (do not await — fire and forget to avoid slowing the response):\n1. `src/routes/auth.ts` — after successful login: `logActivity(user.id, \"login\", { ip: req.ip })`\n2. `src/routes/users.ts` PATCH handler — after profile update: `logActivity(user.id, \"profile_update\")`\n3. `src/routes/auth.ts` — after password change: `logActivity(user.id, \"password_change\")`\n\n## Acceptance criteria\n- [ ] All three call sites added\n- [ ] Calls are fire-and-forget (void, no await)\n- [ ] `npm test` passes\n\n## Do not change\n- Do not modify the response shape of any existing endpoint",
    "assigned_agent_id": "'$AGENT_ID'",
    "priority": "medium"
  }'
```

**Review:** Confirm fire-and-forget pattern (no awaiting), no response changes. Accept and commit.

---

## Task 5 — End-to-end integration test

```bash
curl -X POST $BASE/companies/$COMPANY_ID/issues \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Add end-to-end test: login generates an activity entry visible in the feed",
    "description": "## Task\nAdd a test in `tests/activity.integration.test.ts` that:\n1. Creates a test user\n2. Logs in (POST /api/auth/login)\n3. Fetches the activity feed (GET /api/users/:id/activity)\n4. Asserts that exactly one `login` entry exists in the response\n\nUse the existing test setup helpers in `tests/helpers.ts`.\n\n## Acceptance criteria\n- [ ] Test exists and covers the full flow\n- [ ] `npm test` passes (all tests, not just the new one)",
    "assigned_agent_id": "'$AGENT_ID'",
    "priority": "medium"
  }'
```

**Review:** Run the test yourself, confirm the integration test works. Accept and commit.

---

## Final commit and review

```bash
# Review the full feature diff
git diff main

# Run all tests one last time
npm test

# Merge or raise a PR
git checkout main
git merge --no-ff paperclip/activity-feed -m "feat: add recent activity feed

5 tasks completed via Paperclip dev assistant:
- activity_log table migration
- ActivityService (logActivity + getRecentActivity)
- GET /api/users/:id/activity endpoint
- Activity logging on login, profile update, password change
- End-to-end integration test"
```

---

## What you just did

You built a complete, tested feature across migrations, service layer, routes, and integration tests — using Paperclip as your dev assistant — without writing a single line of code yourself. You wrote **task descriptions** instead of **code**, and reviewed diffs instead of debugging from scratch.

This is the Paperclip dev-assistant workflow at full speed.

---

## Checkpoint ✓

- Why are tasks chained sequentially rather than triggered in parallel for dev work?
- What is "fire and forget" and why is it used for the activity logging calls?
- How did `CLAUDE.md` reduce the amount you needed to write in each issue description?
- What git workflow keeps the full feature history clean and reviewable?
$md$ WHERE slug = 'pcl-dev-real-project';
