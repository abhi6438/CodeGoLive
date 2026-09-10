-- Module 12 topics for dev-quickstart


INSERT INTO topics (module_id, number, slug, title, focus, description, content_md, order_index, status) VALUES (
  (SELECT id FROM modules WHERE course_id = 'dev-quickstart' AND number = '12'),
  '750',
  'dev-qs-mta-overview',
  'MTA Overview & mta.yaml',
  'Understand Multi-Target Applications and write a basic mta.yaml',
  'Learn what an MTA is, why BTP uses it, and write a minimal mta.yaml that packages a CAP backend and optional Fiori frontend together.',
  '# MTA Overview & mta.yaml

## What is an MTA?

A **Multi-Target Application (MTA)** is SAP''s packaging format for BTP applications. It bundles multiple modules (a CAP backend, a Fiori UI, an AppRouter, service bindings) into a single deployable archive (`.mtar` file).

Think of it as a Docker Compose file for BTP — one file describes the whole stack.

## Why MTA?

- **Single deploy command** — `mta deploy` deploys everything in the right order
- **Declarative service bindings** — services are wired automatically
- **Environment-specific config** — one mta.yaml, different values per landscape

## Anatomy of mta.yaml

```yaml
_schema-version: "3.1"
ID: bookshop
version: 1.0.0
description: Bookshop CAP application

modules:
  # ── 1. CAP backend ─────────────────────────────────────────
  - name: bookshop-srv
    type: nodejs
    path: gen/srv              # built output from cds build
    parameters:
      buildpack: nodejs_buildpack
      memory: 256M
      disk-quota: 512M
    requires:
      - name: bookshop-hana   # service binding
      - name: bookshop-xsuaa
    provides:
      - name: srv-api
        properties:
          srv-url: ${default-url}

  # ── 2. HANA Deployer ───────────────────────────────────────
  - name: bookshop-db-deployer
    type: hdb
    path: gen/db
    requires:
      - name: bookshop-hana

  # ── 3. AppRouter ───────────────────────────────────────────
  - name: bookshop-app
    type: approuter.nodejs
    path: app/router
    requires:
      - name: bookshop-xsuaa
      - name: srv-api
        group: destinations
        properties:
          name: srv-api
          url: ~{srv-url}
          forwardAuthToken: true

resources:
  # ── Service instances ──────────────────────────────────────
  - name: bookshop-hana
    type: com.sap.xs.hana
    parameters:
      service: hana
      service-plan: hdi-shared

  - name: bookshop-xsuaa
    type: org.cloudfoundry.managed-service
    parameters:
      service: xsuaa
      service-plan: application
      path: ./xs-security.json
```

## Key concepts

| Element | What it does |
|---------|-------------|
| `modules` | Deployable units (apps, deployers) |
| `resources` | BTP services to create or bind |
| `requires` | Declares a dependency on another module or resource |
| `provides` | Exports a property (like a URL) for other modules to consume |
| `parameters` | CF/BTP configuration (memory, buildpack, service plan) |

## Minimal mta.yaml for CAP Node.js only

If you just want to deploy the backend without a UI:

```yaml
_schema-version: "3.1"
ID: my-cap-app
version: 1.0.0

modules:
  - name: my-cap-srv
    type: nodejs
    path: gen/srv
    requires:
      - name: my-cap-db

  - name: my-cap-db-deployer
    type: hdb
    path: gen/db
    requires:
      - name: my-cap-db

resources:
  - name: my-cap-db
    type: com.sap.xs.hana
    parameters:
      service: hana
      service-plan: hdi-shared
```
',
  0,
  'published'
);


INSERT INTO topics (module_id, number, slug, title, focus, description, content_md, order_index, status) VALUES (
  (SELECT id FROM modules WHERE course_id = 'dev-quickstart' AND number = '12'),
  '751',
  'dev-qs-mta-build-deploy',
  'Build & Deploy Your MTA',
  'Use cds build and mbt to produce an .mtar archive and deploy it',
  'Run cds build to compile the CDS model, use mbt to package the MTA archive, and deploy with cf deploy. Understand what each step produces.',
  '# Build & Deploy Your MTA

Deploying a CAP app to BTP is a three-step process: compile → package → deploy.

## Step 1 — Install the MTA Build Tool

```bash
npm install -g mbt
mbt --version   # 1.x.x
```

## Step 2 — Run cds build

`cds build` compiles your `.cds` model into deployable artifacts:

```bash
cds build --production
```

This creates a `gen/` folder:

```
gen/
├── srv/        ← compiled Node.js service (ready for CF push)
│   ├── package.json
│   └── ...
└── db/         ← compiled HANA artifacts (hdbcds, hdbtable)
    └── src/
```

Always run `cds build` before packaging — the `gen/` folder is what gets deployed, not your source.

## Step 3 — Build the MTA archive

```bash
mbt build
```

This reads `mta.yaml`, runs any build commands, and produces:

```
mta_archives/
└── my-cap-app_1.0.0.mtar    ← the deployable archive
```

The `.mtar` is a ZIP file containing all modules and their manifests.

## Step 4 — Deploy to Cloud Foundry

```bash
# Install the CF MTA plugin (once)
cf install-plugin multiapps

# Deploy
cf deploy mta_archives/my-cap-app_1.0.0.mtar
```

The deployer:
1. Creates service instances listed in `resources` (if they don''t exist)
2. Uploads each module
3. Binds services to apps
4. Starts apps in dependency order

## Monitor the deployment

```bash
cf deploy mta_archives/my-cap-app_1.0.0.mtar --retries 0 -f
```

Flags:
- `--retries 0` — fail fast instead of retrying
- `-f` — skip confirmation prompt (for CI/CD)

## Check deployment status

```bash
cf mtas          # list all MTAs in current space
cf mta my-cap-app  # details of one MTA
```

## Full build + deploy script

Save as `deploy.sh`:

```bash
#!/bin/bash
set -e

echo "▶ Building CDS model..."
cds build --production

echo "▶ Packaging MTA..."
mbt build

echo "▶ Deploying to BTP..."
cf deploy mta_archives/*.mtar -f

echo "✅ Done!"
```

```bash
chmod +x deploy.sh
./deploy.sh
```
',
  1,
  'published'
);


INSERT INTO topics (module_id, number, slug, title, focus, description, content_md, order_index, status) VALUES (
  (SELECT id FROM modules WHERE course_id = 'dev-quickstart' AND number = '12'),
  '752',
  'dev-qs-btp-logs-env',
  'Reading Logs & Environment Variables',
  'Use cf logs and cf env to diagnose production issues on BTP',
  'Stream live logs from a deployed BTP app, read recent logs after a crash, and inspect environment variables to debug binding and config issues.',
  '# Reading Logs & Environment Variables on BTP

Once your app is deployed, the `cf` CLI is your window into what''s happening in production.

## List your apps

```bash
cf apps
```

Output:

```
name             requested state   instances   memory   disk   urls
bookshop-srv     started           1/1         256M     512M   bookshop-srv.cfapps.eu10.hana.ondemand.com
bookshop-app     started           1/1         128M     256M   bookshop.cfapps.eu10.hana.ondemand.com
```

## Stream live logs

```bash
cf logs bookshop-srv
```

Every log line from your app appears in real time. Press `Ctrl+C` to stop.

## Read recent logs (after a crash)

```bash
cf logs bookshop-srv --recent
```

This shows the last ~1000 log lines. Useful for finding the error that caused a crash.

## Filter logs

```bash
cf logs bookshop-srv --recent | grep -i error
cf logs bookshop-srv --recent | grep "cds -"
```

## Common log patterns

| Log line | Meaning |
|----------|---------|
| `[APP/PROC/WEB] OUT [cds] - server listening on...` | App started successfully |
| `[APP/PROC/WEB] ERR Error: connect ECONNREFUSED` | Can''t reach a bound service |
| `[CELL/0] OUT Exit status 137` | App ran out of memory (increase `memory` in mta.yaml) |
| `[STG/0] ERR npm ERR! ...` | Build failed during staging |

## Inspect environment variables

```bash
cf env bookshop-srv
```

This prints all environment variables, including:

```json
{
  "VCAP_SERVICES": {
    "hana": [{
      "credentials": {
        "host": "...",
        "port": "443",
        "user": "DEPLOY_USER_...",
        "password": "..."
      }
    }],
    "xsuaa": [...]
  },
  "VCAP_APPLICATION": {
    "application_name": "bookshop-srv",
    "space_name": "dev"
  }
}
```

`VCAP_SERVICES` is how Cloud Foundry passes service credentials to your app. CAP reads this automatically — no manual wiring needed.

## Check app events (crash history)

```bash
cf events bookshop-srv
```

Shows a timeline of start, stop, crash, and scale events.

## Restart vs Restage

| Command | When to use |
|---------|------------|
| `cf restart bookshop-srv` | App is hanging or unhealthy; same code, same env |
| `cf restage bookshop-srv` | Environment variables changed (new binding, new env var) |
| `cf push` / `cf deploy` | Code changed — need a new deployment |

## Scale up if the app keeps crashing

```bash
cf scale bookshop-srv -m 512M   # double the memory
cf scale bookshop-srv -i 2      # run 2 instances
```
',
  2,
  'published'
);
