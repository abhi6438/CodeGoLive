-- ============================================================
-- CRITICAL CONTENT FIXES — Developer Quickstart & Setup
-- Run in Supabase SQL Editor AFTER the original topic inserts
-- ============================================================


-- ── Fix 1: Topic 700 — Node 18 is EOL, update to Node 20/22 ──

UPDATE topics
SET content_md = replace(content_md,
  'If both return a version number (Node 18+ is ideal), you can skip the Node install topic.',
  'If both return a version number (**Node 20 LTS or 22 LTS** is recommended — Node 18 reached End of Life in April 2025), you can skip the Node install topic.'
)
WHERE slug = 'dev-qs-prereqs-check';


-- ── Fix 2: Topic 701 — nvm pinned version is stale ──────────

UPDATE topics
SET content_md = replace(content_md,
  'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash',
  '# Install nvm (always installs the latest stable release)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/HEAD/install.sh | bash'
)
WHERE slug = 'dev-qs-nodejs-install';

-- Also fix the Node version recommendation
UPDATE topics
SET content_md = replace(content_md,
  'node --version   # should print v20.x.x or v22.x.x',
  'node --version   # should print v20.x.x (Maintenance LTS) or v22.x.x (Active LTS)'
)
WHERE slug = 'dev-qs-nodejs-install';


-- ── Fix 3: Topic 710 — wrong npm create command ──────────────

UPDATE topics
SET content_md = replace(content_md,
  '## Alternative — using the @ui5/cli directly

```bash
npm create fiori-app my-first-app
# follow the prompts
```',
  '## Alternative — CLI without VS Code

```bash
npx @sap/create-fiori-app my-first-app
# follow the interactive prompts
```

This runs the same wizard as the VS Code generator but from the terminal — useful in CI or when you prefer the command line.'
)
WHERE slug = 'dev-qs-ui5-generate';


-- ── Fix 4: Topic 713 — remove webpack:// reference ──────────

UPDATE topics
SET content_md = replace(content_md,
  '1. Open DevTools (`F12`) → **Sources** tab
2. Navigate to `webpack://` or find your controller file under `localhost:8080`
3. Click the line number where you want to pause
4. Trigger the action in the UI — execution pauses at your breakpoint',
  '1. Open DevTools (`F12`) → **Sources** tab
2. Expand the `localhost:8080` origin in the left file tree → your `webapp/` folder appears with all your `.js` and `.xml` files

> SAPUI5 uses `@ui5/cli`, not webpack — there is no `webpack://` virtual filesystem.

3. Open a controller (e.g. `webapp/controller/Main.controller.js`)
4. Click the line number in the gutter to set a breakpoint
5. Trigger the action in the UI — execution pauses at your breakpoint'
)
WHERE slug = 'dev-qs-ui5-debug';


-- ── Fix 5: Topic 723 — SELECT not imported in debug console ──

UPDATE topics
SET content_md = replace(content_md,
  '```js
const db = cds.db
await db.run(SELECT.from(''my.namespace.Products''))
```',
  '```js
// SELECT is on cds.ql — destructure it first
const { SELECT } = cds.ql
const db = cds.db
await db.run(SELECT.from(''my.namespace.Products''))
```'
)
WHERE slug = 'dev-qs-cap-node-debug';


-- ── Fix 6: Topic 730 — Windows PATH typo ─────────────────────

UPDATE topics
SET content_md = replace(content_md,
  '3. Edit **Path** → Add `%JAVA_HOME%in`',
  '3. Edit **Path** → Add `%JAVA_HOME%\bin`'
)
WHERE slug = 'dev-qs-cap-java-prereqs';


-- ── Fix 7: Topic 750 — outdated HANA MTA resource type ───────

UPDATE topics
SET content_md = replace(content_md,
  '  - name: bookshop-hana
    type: com.sap.xs.hana
    parameters:
      service: hana
      service-plan: hdi-shared',
  '  - name: bookshop-hana
    type: org.cloudfoundry.managed-service
    parameters:
      service: hana
      service-plan: hdi-shared'
)
WHERE slug = 'dev-qs-mta-overview';

-- Fix the same in the minimal mta.yaml example
UPDATE topics
SET content_md = replace(content_md,
  '  - name: my-cap-db
    type: com.sap.xs.hana
    parameters:
      service: hana
      service-plan: hdi-shared',
  '  - name: my-cap-db
    type: org.cloudfoundry.managed-service
    parameters:
      service: hana
      service-plan: hdi-shared'
)
WHERE slug = 'dev-qs-mta-overview';


-- ── Verify all 7 fixes applied ────────────────────────────────

SELECT slug,
  CASE
    WHEN slug = 'dev-qs-prereqs-check'    THEN content_md LIKE '%Node 20 LTS%'
    WHEN slug = 'dev-qs-nodejs-install'   THEN content_md NOT LIKE '%v0.39.7%'
    WHEN slug = 'dev-qs-ui5-generate'     THEN content_md LIKE '%npx @sap/create-fiori-app%'
    WHEN slug = 'dev-qs-ui5-debug'        THEN content_md NOT LIKE '%webpack://%'
    WHEN slug = 'dev-qs-cap-node-debug'   THEN content_md LIKE '%const { SELECT } = cds.ql%'
    WHEN slug = 'dev-qs-cap-java-prereqs' THEN content_md LIKE '%JAVA_HOME%\\bin%'
    WHEN slug = 'dev-qs-mta-overview'     THEN content_md NOT LIKE '%com.sap.xs.hana%'
  END AS fix_applied
FROM topics
WHERE slug IN (
  'dev-qs-prereqs-check',
  'dev-qs-nodejs-install',
  'dev-qs-ui5-generate',
  'dev-qs-ui5-debug',
  'dev-qs-cap-node-debug',
  'dev-qs-cap-java-prereqs',
  'dev-qs-mta-overview'
)
ORDER BY slug;
