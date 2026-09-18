-- =============================================================================
-- SAP CAP Course — Module 7: Deployment & Production
-- Episodes cap-69 through cap-80
-- Idempotent: run after sap_cap_seed.sql
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- Episode 69 — MTA Introduction
-- ─────────────────────────────────────────────────────────────────────────────
UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 69 — MTA: Multi-Target Applications

## What you'll learn
- What an MTA is and why BTP uses it as the standard deployment unit
- The structure of `mta.yaml`: modules, resources, dependencies, and parameters
- How to convert a manual CF push workflow into a proper MTA descriptor
- How build parameters, requires/provides, and content deployers work
- How to validate your MTA with the MTA Build Tool (mbt)

## Why this matters
A real BTP application is not one Cloud Foundry app — it is a collection of parts: a Node.js CAP service, a React frontend, an AppRouter, and a set of bound services (XSUAA, HANA, Destination, Object Store). Deploying each part manually is error-prone and hard to reproduce. The MTA (Multi-Target Application) standard packages everything into a single deployable archive (`.mtar`) with a declarative descriptor. One command deploys or re-deploys the whole stack in the right order with the right bindings.

## MTA concepts

| Concept | What it is |
|---|---|
| Module | A deployable artifact — a CF app, a content deployer |
| Resource | A managed service or existing CF service |
| Dependency | A `requires` / `provides` edge between modules and resources |
| Parameter | A value injected into module/resource config at deploy time |
| `mta.yaml` | The declarative descriptor of the whole MTA |
| `.mtar` | The built archive containing all modules + the descriptor |

## Minimal `mta.yaml` for a CAP + SPA app

```yaml
_schema-version: '3.1'
ID: my-cap-app
version: 1.0.0
description: My CAP Application

modules:

  # ── CAP Service ─────────────────────────────────────────────────────────────
  - name: my-cap-app-srv
    type: nodejs
    path: .
    parameters:
      buildpack: nodejs_buildpack
      memory: 512M
      disk-quota: 1G
    build-parameters:
      builder: npm
      build-result: gen/srv
      ignore: [node_modules/, .env]
    requires:
      - name: my-xsuaa
      - name: my-hana
      - name: my-destination
    provides:
      - name: srv-api
        properties:
          srv-url: '${default-url}'

  # ── HTML5 App UI Deployer ────────────────────────────────────────────────────
  - name: my-cap-app-ui-deployer
    type: com.sap.application.content
    path: frontend
    requires:
      - name: my-html5-repo-host
        parameters:
          content-target: true
    build-parameters:
      build-result: dist
      requires:
        - name: my-cap-app-ui
          artifacts:
            - dist.zip
          target-path: resources/

  # ── AppRouter ───────────────────────────────────────────────────────────────
  - name: my-cap-app-approuter
    type: approuter.nodejs
    path: approuter
    parameters:
      memory: 256M
      disk-quota: 256M
    requires:
      - name: my-xsuaa
      - name: my-html5-runtime
      - name: my-destination
      - name: srv-api
        group: destinations
        properties:
          name: cap-backend
          url: '~{srv-url}'
          forwardAuthToken: true

resources:

  - name: my-xsuaa
    type: org.cloudfoundry.managed-service
    parameters:
      service: xsuaa
      service-plan: application
      path: ./xs-security.json
      config:
        xsappname: my-cap-app-${org}-${space}
        tenant-mode: dedicated

  - name: my-hana
    type: com.sap.xs.hdi-container
    parameters:
      service: hana
      service-plan: hdi-shared

  - name: my-destination
    type: org.cloudfoundry.managed-service
    parameters:
      service: destination
      service-plan: lite

  - name: my-html5-repo-host
    type: org.cloudfoundry.managed-service
    parameters:
      service: html5-apps-repo
      service-plan: app-host

  - name: my-html5-runtime
    type: org.cloudfoundry.managed-service
    parameters:
      service: html5-apps-repo
      service-plan: app-runtime
```

## Key patterns explained

**`provides` / `requires` with `group: destinations`**: The AppRouter needs to know the CAP service URL at deploy time. The CAP module publishes its URL under `srv-api`. The AppRouter consumes it in a `destinations` group, which AppRouter reads as an environment variable `destinations` — a JSON array of route configs.

**`${default-url}`**: A parameter placeholder that expands to the CF app route assigned at deploy time. Never hardcode URLs in `mta.yaml`.

**`${org}` and `${space}`**: Namespacing XSUAA `xsappname` per org/space prevents collisions when the same app is deployed to multiple spaces (dev, test, prod).

## Building the MTA

```bash
# Install MTA Build Tool
npm install -g mbt

# Build the .mtar archive
mbt build -t ./

# Output: my-cap-app_1.0.0.mtar
```

`mbt` runs each module's build steps (npm build for Node.js, npm run build for Vite), then packages everything into a single archive.

## Common mistakes

| Mistake | Fix |
|---|---|
| Hardcoding space/org-specific URLs | Use `${default-url}`, `${org}`, `${space}` parameters |
| Missing `ignore: [node_modules/]` | Including node_modules bloats the archive |
| Forgetting the HDI deployer module | HANA tables are not created unless you include a `hdi-deployer` module |
| `requires` without `provides` | The consuming module will fail — check that the provider declares the property group |
| `_schema-version` mismatch | Use `3.1` for modern MTAs; older schemas lack some features |

## Checkpoint ✓

You understand the MTA concepts of modules, resources, and dependencies. You can write a valid `mta.yaml` for a CAP + SPA + AppRouter stack, use parameter placeholders for URLs and service names, and build a deployable `.mtar` archive with `mbt build`.
$md$
WHERE slug = 'cap-69-mta-intro';


-- ─────────────────────────────────────────────────────────────────────────────
-- Episode 70 — CF Deploy
-- ─────────────────────────────────────────────────────────────────────────────
UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 70 — CF Deploy: Deploying an MTA to Cloud Foundry

## What you'll learn
- How `cf deploy` works and what it does step by step
- How to install and use the MTA CF Plugin
- How to handle deploy failures, partial deploys, and rollbacks
- How to use `--no-start` for staged deployments
- How to manage multiple MTA versions with `cf deploy --strategy`

## Why this matters
`cf push` deploys a single app. `cf deploy` deploys an entire MTA — creating services, running deployers, pushing modules, and wiring bindings — in the correct dependency order. Understanding what `cf deploy` does under the hood means you can diagnose stuck deploys, pick up from partial failures, and choose the right strategy (standard vs blue-green) for each release.

## Installing the MTA CF Plugin

```bash
# Download the plugin from the CF Community Plugins repo
cf install-plugin multiapps

# Verify
cf mta --help
```

## The deploy lifecycle

When you run `cf deploy my-cap-app.mtar`, the plugin executes these phases:

```
1. Upload archive to CF Deploy Service
2. Resolve descriptor — expand parameters, validate dependencies
3. Create/update resources (managed services)
4. Run content deployers (HDI deployer, HTML5 deployer)
5. Push modules (CF apps)
6. Bind services to modules
7. Start modules
```

Each phase is idempotent: if a deploy fails mid-way, re-running `cf deploy` resumes from where it stopped (or you can restart it with `cf redeploy <operation-id>`).

## Basic deploy command

```bash
# Build first
mbt build -t ./

# Deploy
cf deploy my-cap-app_1.0.0.mtar

# With verbose output
cf deploy my-cap-app_1.0.0.mtar -f    # force — skip confirmation prompts
```

## Monitoring a deploy in progress

```bash
# List active deploy operations
cf mta-ops

# Tail the log of a specific operation
cf dmol -i <operation-id>

# List deployed MTAs
cf mta my-cap-app

# Show modules and resources of a deployed MTA
cf mta-modules my-cap-app
cf mta-services my-cap-app
```

## Resuming or aborting a stuck deploy

```bash
# List operations — find the stuck one
cf mta-ops

# Resume from where it stopped
cf resume-mta-op -i <operation-id>

# Or abort it
cf abort-mta-op -i <operation-id>
```

## Staged deployment: `--no-start`

Build and deploy infrastructure (services + deployers) without starting the CAP app:

```bash
# Deploy services and run content deployers, do not start the CF apps
cf deploy my-cap-app.mtar --no-start

# Verify the database schema was applied correctly, run smoke tests, then:
cf start my-cap-app-srv
cf start my-cap-app-approuter
```

This is useful for production deployments where you want a human gate before traffic is routed.

## Undeploy (teardown)

```bash
# Remove all modules and resources defined in the MTA
cf undeploy my-cap-app --delete-services --delete-service-keys
```

`--delete-services` also deletes the bound managed services — use with caution in production; this drops your HANA HDI container.

## Partial deploy: single module

When only the CAP service code changed (no schema changes, no UI changes):

```bash
# Deploy only the CAP service module
cf deploy my-cap-app.mtar --modules my-cap-app-srv
```

This skips the HDI deployer and UI deployer — much faster.

## Deploy with strategy

```bash
# Blue-green deploy (Episodes 72 covers this in detail)
cf deploy my-cap-app.mtar --strategy blue-green
```

## Common mistakes

| Mistake | Fix |
|---|---|
| `cf push` instead of `cf deploy` | `cf push` bypasses the MTA — services won't be bound correctly |
| Not running `mbt build` before `cf deploy` | Deploy uses the old `.mtar` — always build first in CI/CD |
| `--delete-services` in production | This drops HANA and XSUAA — data loss risk |
| Deploying from a laptop | Use a CI/CD pipeline; local network issues cause incomplete deploys |
| Ignoring `cf mta-ops` output | Check for stuck operations before re-deploying |

## Checkpoint ✓

You can install the MTA CF Plugin, deploy an MTA with `cf deploy`, monitor progress with `cf mta-ops`, resume a failed deploy, use `--no-start` for staged deployments, and undeploy an MTA. You know the order of operations in a deploy and where to look when something goes wrong.
$md$
WHERE slug = 'cap-70-cf-deploy';

-- ─────────────────────────────────────────────────────────────────────────────
-- Episode 71 — BTP Setup & Entitlements
-- ─────────────────────────────────────────────────────────────────────────────
UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 71 — BTP Setup & Entitlements

## What you'll learn
- How BTP is organised: global account, subaccounts, spaces, and org structure
- What entitlements are and how to assign them for your services
- How to set up a Cloud Foundry subaccount for a production CAP deployment
- How to create and configure spaces with proper quotas
- Common entitlement issues and how to diagnose them

## Why this matters
Before you can create an XSUAA instance or an HDI container in a new subaccount you need the right entitlements. Getting entitlement errors at deploy time is a common pain point that blocks teams for hours. Understanding the BTP account hierarchy lets you plan the right structure for dev, test, and production environments and provision services correctly the first time.

## BTP account hierarchy

```
Global Account (your company licence)
  │
  ├─ Subaccount: DEV  (CF org: my-company-dev)
  │     └─ Space: dev
  │
  ├─ Subaccount: TEST (CF org: my-company-test)
  │     └─ Space: test
  │
  └─ Subaccount: PROD (CF org: my-company-prod)
        └─ Space: prod
```

**Global Account**: holds the licence and entitlements for the whole company.
**Subaccount**: has its own CF org, users, and service quota. The unit you bill against.
**CF Org**: one CF org per subaccount. Contains CF spaces.
**CF Space**: the deployment target. Applications and service instances live in a space.

## Assigning entitlements

Entitlements allow a subaccount to use a specific service plan. Without an entitlement, `cf create-service` fails with a "service plan not found" error.

Steps in the BTP Cockpit:
1. Navigate to **Global Account → Entitlements → Entity Assignments**
2. Select your subaccount
3. Click **Configure Entitlements → Add Service Plans**
4. Search for the service (e.g., `hana`), select the plan (`hdi-shared`), set quota
5. Click **Save**

Required entitlements for a typical CAP app:

| Service | Plan | Notes |
|---|---|---|
| `hana` | `hdi-shared` | HANA HDI container |
| `xsuaa` | `application` | Authentication |
| `destination` | `lite` | Destinations |
| `html5-apps-repo` | `app-host`, `app-runtime` | Frontend storage |
| `jobscheduler` | `standard` | Scheduled jobs |
| `application-logs` | `standard` | Logging |
| `feature-flags` | `standard` | Feature flags |
| `objectstore` | `s3-standard` | File storage |

## Creating a Cloud Foundry subaccount

```bash
# Using BTP CLI (btp)
btp login --url https://cli.btp.cloud.sap --subdomain my-company

# Create subaccount
btp create accounts/subaccount \
  --display-name "My CAP Prod" \
  --region eu10 \
  --subdomain my-cap-prod

# Enable CF
btp create accounts/environment-instance \
  --environment cloudfoundry \
  --subaccount <subaccount-id> \
  --service cloudfoundry \
  --plan standard \
  --parameters '{"instance_name":"my-cap-prod"}'
```

## Creating a CF space with quotas

```bash
cf login -a https://api.cf.eu10.hana.ondemand.com -o my-company-prod

# Create space
cf create-space production

# Assign a space quota (if your org has quotas defined)
cf set-space-quota production high-memory

# Add developers to the space
cf set-space-role user@example.com my-company-prod production SpaceDeveloper
```

## Setting up the CF CLI target for deployment

```bash
cf api https://api.cf.eu10.hana.ondemand.com
cf login
cf target -o my-company-prod -s production
```

In CI/CD, use a service account (technical user):
```bash
cf auth <technical-user-email> <password>
cf target -o my-company-prod -s production
```

## Diagnosing entitlement errors

```
Error: The service plan 'hdi-shared' for service 'hana' was not found
```

Checklist:
1. Is the entitlement assigned? (Global Account → Entitlements → check the subaccount)
2. Is there remaining quota? (0 quota = same error as no entitlement)
3. Is the service available in your region? (Check SAP Discovery Center for regional availability)
4. Is the CF space targeted correctly?

## Common mistakes

| Mistake | Fix |
|---|---|
| Deploying to the wrong CF space | Always run `cf target` before `cf deploy` to confirm org/space |
| Forgetting `app-host` vs `app-runtime` entitlements | HTML5 Repo needs both plans entitled |
| Using Trial subaccount for production | Trial accounts expire and lack SLAs |
| Not setting a space quota | Unlimited quota can cause unexpected bill spikes |
| Shared XSUAA across dev and prod | Create separate XSUAA instances per environment |

## Checkpoint ✓

You understand the BTP account hierarchy (global account → subaccount → CF org → space), can assign entitlements in the cockpit, create a subaccount and CF space with the BTP and CF CLIs, and diagnose service plan not found errors.
$md$
WHERE slug = 'cap-71-btp-setup';


-- ─────────────────────────────────────────────────────────────────────────────
-- Episode 72 — Blue-Green Deployment
-- ─────────────────────────────────────────────────────────────────────────────
UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 72 — Blue-Green Deployment

## What you'll learn
- What blue-green deployment is and why it achieves zero-downtime releases
- How CF's built-in blue-green strategy works with MTA CF Plugin
- How to handle database schema migrations during a blue-green deploy
- How to test the green version before traffic is switched
- How to roll back instantly if the green version has issues

## Why this matters
Standard `cf deploy` restarts your application — there is a gap where new instances are starting but old ones are gone. For enterprise apps that users access during business hours, even a 30-second gap causes errors. Blue-green deployment keeps the old version (blue) running while the new version (green) starts, then switches traffic atomically. If green fails, you route back to blue with one command.

## How blue-green works on CF

CF uses **routes** to direct traffic. In a blue-green deploy:

1. Deploy the new version (green) with a temporary route
2. Run smoke tests against the temporary route
3. Map the production route to green
4. Unmap the production route from blue
5. Delete blue

```
Before:
  myapp.cfapps.eu10.hana.ondemand.com  →  [Blue v1.0]

During:
  myapp.cfapps.eu10.hana.ondemand.com  →  [Blue v1.0]  (still serving)
  myapp-green.cfapps.eu10.hana.ondemand.com → [Green v1.1]  (smoke testing)

After switch:
  myapp.cfapps.eu10.hana.ondemand.com  →  [Green v1.1]  (live)
```

## Blue-green with the MTA CF Plugin

```bash
# Build the new version
mbt build -t ./

# Deploy with blue-green strategy
cf deploy my-cap-app_1.1.0.mtar --strategy blue-green
```

The plugin:
1. Deploys new modules as `my-cap-app-srv-idle` with a temporary route
2. Pauses for you to run smoke tests
3. Asks for confirmation before switching routes
4. Deletes the old modules after confirmation

## Testing the green version

After `cf deploy --strategy blue-green` pauses, the green version has a temporary route:
```
my-cap-app-srv-idle.cfapps.eu10.hana.ondemand.com
```

Run your smoke tests:
```bash
# API health check
curl -s https://my-cap-app-srv-idle.cfapps.eu10.hana.ondemand.com/api/health

# Run your smoke test suite
npm run test:smoke -- --url=https://my-cap-app-srv-idle.cfapps.eu10.hana.ondemand.com
```

Then confirm the switch:
```bash
cf resume-mta-op -i <operation-id>
```

## Automated blue-green in CI/CD

```yaml
# .github/workflows/deploy.yml
- name: Deploy (blue-green)
  run: |
    cf deploy my-cap-app_${{ env.VERSION }}.mtar \
      --strategy blue-green \
      --no-confirm              # auto-confirm after smoke tests
    
- name: Smoke tests
  run: npm run test:smoke -- --url=${{ env.GREEN_URL }}
```

With `--no-confirm` the switch happens automatically. Use only if your smoke tests are reliable.

## Database schema migrations during blue-green

Blue and green both use the **same HANA HDI container**. During the traffic switch, both versions run simultaneously. Your schema migrations must be **backward-compatible**:

| Safe | Unsafe |
|---|---|
| Add a nullable column | Drop a column still used by blue |
| Add a new table | Rename a column |
| Add an index | Change a column type narrowly |
| Add a nullable FK | Remove a NOT NULL constraint that blue writes |

Migration strategy:
1. **Expand**: add new columns/tables (both blue and green can coexist)
2. **Switch traffic** to green
3. **Contract**: drop old columns in a separate follow-up deploy (blue is gone now)

## Rolling back

If green has problems after the switch:
```bash
# The old blue version is still stopped (not deleted yet in default strategy)
# Start it and remap the route manually
cf start my-cap-app-srv-old
cf map-route my-cap-app-srv-old cfapps.eu10.hana.ondemand.com --hostname myapp
cf unmap-route my-cap-app-srv cfapps.eu10.hana.ondemand.com --hostname myapp
```

Or re-deploy the previous `.mtar`:
```bash
cf deploy my-cap-app_1.0.0.mtar
```

## Common mistakes

| Mistake | Fix |
|---|---|
| Destructive schema changes during blue-green | Use expand/contract migration pattern |
| Not running smoke tests before confirming switch | Always test the green URL before resuming |
| Using `--no-confirm` in production without reliable smoke tests | Gate on test results; a bad auto-confirm is a real outage |
| Forgetting to map routes after a manual rollback | Verify route mapping with `cf routes` |
| Blue-green with singleton stateful services | Identify stateful parts (queues, sessions) and handle separately |

## Checkpoint ✓

You can deploy an MTA with `--strategy blue-green`, test the green version via its temporary route, confirm the traffic switch, apply backward-compatible schema migrations during a live switch, and roll back to blue when green has issues.
$md$
WHERE slug = 'cap-72-blue-green';

-- ─────────────────────────────────────────────────────────────────────────────
-- Episode 73 — CI/CD with SAP Build Code
-- ─────────────────────────────────────────────────────────────────────────────
UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 73 — CI/CD with SAP Build Code

## What you'll learn
- What SAP Build Code's CI/CD service provides and how it differs from GitHub Actions
- How to connect a Git repository and define a pipeline for a CAP MTA project
- How to configure the standard CAP pipeline stages: build, test, lint, deploy
- How to set up environment-specific deploy targets (dev/test/prod)
- How to handle secrets (CF credentials, service keys) securely in the pipeline

## Why this matters
Deploying from a developer's laptop is fragile — it depends on local tool versions, CF login state, and network reliability. A proper CI/CD pipeline runs builds in a clean environment, runs tests before deploying, and deploys to multiple environments in sequence. SAP Build Code's CI/CD service is a first-class BTP product that integrates natively with Cloud Foundry and Git, so you don't have to manage Jenkins infrastructure yourself.

## What SAP Build Code CI/CD provides

| Feature | Detail |
|---|---|
| Predefined pipeline stages | Init, Build, Test, Compliance, Deploy |
| SAP-curated Docker images | Pre-installed with mbt, CF CLI, node, java |
| Git integration | GitHub, GitLab, Bitbucket, Azure DevOps |
| Credential store | Encrypted secrets (CF login, service keys) |
| Blue-green deploy support | Native integration with MTA CF Plugin |
| Audit log | Full run history with logs per stage |

## Setting up a repository connection

1. BTP Cockpit → **Services → SAP Build Code → CI/CD Service**
2. Go to **Repositories** → **Add**
3. Enter repository URL + personal access token (stored encrypted)
4. Choose branch (e.g. `main`)

## Pipeline configuration: `.pipeline/config.yml`

Add this file to the root of your repository:

```yaml
# .pipeline/config.yml
general:
  buildTool: mta

service:
  name: my-cap-app

stages:
  Build:
    mtaBuildTool: cloudMbt   # use mbt from the SAP Build Code image

  Unit-Tests:
    run: true
    npmRunScript: test

  Lint:
    run: true
    npmRunScript: lint

  Integration-Tests:
    run: false             # enable when you have integration tests

  Deploy-to-Dev:
    cfTargets:
      - apiEndpoint: 'https://api.cf.eu10.hana.ondemand.com'
        org:         my-company-dev
        space:       dev
        credentialsId: cf-dev-credentials
        mtaDeployParameters: '-f'

  Deploy-to-Test:
    cfTargets:
      - apiEndpoint: 'https://api.cf.eu10.hana.ondemand.com'
        org:         my-company-test
        space:       test
        credentialsId: cf-test-credentials
        mtaDeployParameters: '-f'
    runTests: true

  Deploy-to-Prod:
    cfTargets:
      - apiEndpoint: 'https://api.cf.eu10.hana.ondemand.com'
        org:         my-company-prod
        space:       production
        credentialsId: cf-prod-credentials
        mtaDeployParameters: '--strategy blue-green'
    manualConfirmation: true    # human gate before prod deploy
```

## Adding CF credentials to the pipeline

In CI/CD Service → **Credentials** → **Add**:
- Type: `Basic Authentication`
- Name: `cf-prod-credentials`
- Username: technical user email
- Password: technical user password

The pipeline uses these credentials for `cf login` — they are never exposed in pipeline logs.

## Triggering the pipeline

The pipeline triggers automatically on push to the configured branch. You can also trigger manually from the CI/CD UI.

Pipeline stages run in order:
```
Init → Build → Unit-Tests → Lint → Deploy-to-Dev → Deploy-to-Test → [Approval] → Deploy-to-Prod
```

If any stage fails, the pipeline stops and notifies you via email (configurable).

## Using GitHub Actions as an alternative

If your team already uses GitHub Actions, you can replicate the same flow:

```yaml
# .github/workflows/deploy.yml
name: Deploy CAP App

on:
  push:
    branches: [main]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    container:
      image: mcr.microsoft.com/devcontainers/base:ubuntu

    steps:
      - uses: actions/checkout@v4

      - name: Install tools
        run: |
          npm install -g mbt
          wget -q "https://packages.cloudfoundry.org/stable?release=linux64-binary&version=v8&source=github" -O /tmp/cf.tgz
          tar -xzf /tmp/cf.tgz -C /usr/local/bin
          cf install-plugin multiapps -f

      - name: Build MTA
        run: mbt build -t ./

      - name: CF Login
        run: |
          cf api ${{ vars.CF_API }}
          cf auth "${{ secrets.CF_USER }}" "${{ secrets.CF_PASSWORD }}"
          cf target -o "${{ vars.CF_ORG }}" -s "${{ vars.CF_SPACE }}"

      - name: Deploy
        run: cf deploy *.mtar -f
```

Store `CF_USER` and `CF_PASSWORD` in GitHub **Secrets**, org/space/API in **Variables**.

## Common mistakes

| Mistake | Fix |
|---|---|
| Committing CF credentials to the repo | Use CI secrets / credential store |
| No test stage before deploy | Tests must run before any CF deploy |
| Deploying directly to prod on every push | Gate prod deploys with manual approval |
| Using personal user accounts as CI credentials | Create a technical CF user with minimal roles |
| No rollback step | Document the rollback command and who can run it |

## Checkpoint ✓

You can connect a Git repository to SAP Build Code CI/CD, write a `.pipeline/config.yml` with build, test, and multi-environment deploy stages, add CF credentials securely, and gate production deployments with a manual approval step.
$md$
WHERE slug = 'cap-73-cicd';


-- ─────────────────────────────────────────────────────────────────────────────
-- Episode 74 — Monitoring & Alerting
-- ─────────────────────────────────────────────────────────────────────────────
UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 74 — Monitoring & Alerting

## What you'll learn
- What BTP monitoring tools are available and when to use each one
- How to set up SAP Cloud ALM or BTP Cockpit monitoring for your CAP service
- How to expose a `/health` endpoint from CAP for uptime monitoring
- How to configure alerting on error rate, memory, and response time
- How to use `cf app` and `cf events` for first-level incident triage

## Why this matters
You won't be watching the logs 24/7. When something breaks in production you need an alert in Slack or email within minutes, not days. Proper monitoring also tells you when your app is approaching memory limits or when a specific endpoint is suddenly slow — before a user files a ticket.

## Monitoring tools on BTP

| Tool | Best for |
|---|---|
| BTP Cockpit (app overview) | CPU / memory / instance count at a glance |
| `cf app` / `cf logs` | First-level triage from CLI |
| SAP Application Logging (Kibana) | Log-level query and error search |
| SAP Alert Notification Service | Event-driven alerts to email/Slack/PagerDuty |
| SAP Cloud ALM | Cross-landscape health dashboard (enterprise) |
| Custom `/health` endpoint | External uptime monitors (UptimeRobot, Pingdom) |

## Exposing a `/health` endpoint in CAP

```javascript
// srv/server.js
const cds = require('@sap/cds');

cds.on('bootstrap', async app => {
  app.get('/health', async (req, res) => {
    try {
      // Ping the database
      const db = await cds.connect.to('db');
      await db.run('SELECT 1 FROM dummy');

      res.status(200).json({
        status: 'UP',
        timestamp: new Date().toISOString(),
        version: process.env.npm_package_version
      });
    } catch (err) {
      res.status(503).json({
        status: 'DOWN',
        error: err.message
      });
    }
  });
});
```

The `/health` endpoint bypasses XSUAA (no `@requires`) so external uptime monitors can call it without authentication. Ensure it does not expose sensitive information — just `UP`/`DOWN` and a timestamp.

## Configuring SAP Alert Notification Service

See Episode 60 for full setup. For monitoring-specific alerts:

```javascript
// Alert on high error rate in a 5-minute window
// (implemented as a periodic check job — Episode 65)
const ans = await cds.connect.to('AlertNotificationService');

const errorCount = await db.run(
  `SELECT COUNT(*) AS n FROM ErrorLog WHERE ts > NOW() - INTERVAL '5' MINUTE`
);

if (errorCount.n > 50) {
  await ans.post('/producer/v1/resource-events', {
    eventType:    'HighErrorRate',
    eventTimestamp: Date.now(),
    severity:     'CRITICAL',
    resource: {
      resourceName: 'my-cap-app',
      resourceType: 'Application'
    },
    body: {
      state:   'PROBLEM',
      details: `${errorCount.n} errors in the last 5 minutes`
    }
  });
}
```

## Using `cf app` for live metrics

```bash
# Current memory, CPU, instances, status
cf app my-cap-app-srv

# Example output:
# Instances running: 2/2
# Memory usage: 312M / 512M
# CPU:  3.1% / 3.8%
# Disk: 423M / 1G

# Recent CF platform events (restarts, crashes)
cf events my-cap-app-srv

# Stream live logs (combine with grep for errors)
cf logs my-cap-app-srv | grep -i error
```

## Setting memory and scaling thresholds

In `manifest.yml` or MTA:
```yaml
memory: 512M
disk_quota: 1G
instances: 2
```

Autoscale with the CF App Autoscaler (if entitled):
```yaml
# autoscaler-policy.json
{
  "instance_min_count": 2,
  "instance_max_count": 5,
  "scaling_rules": [
    { "metric_type": "memoryused", "threshold": 400, "operator": ">=", "adjustment": "+1" },
    { "metric_type": "memoryused", "threshold": 200, "operator": "<",  "adjustment": "-1" }
  ]
}
```

## Incident triage checklist

When an alert fires:
1. `cf app my-cap-app-srv` — is the app running? How many instances are UP?
2. `cf logs my-cap-app-srv --recent` — look for ERROR lines around the incident time
3. Kibana: filter `level: ERROR AND @timestamp: [now-30m TO now]`
4. `cf events my-cap-app-srv` — any recent crashes or restarts?
5. BTP Cockpit → HANA Cloud → Monitor — is the DB healthy?
6. If memory usage > 90% → `cf scale my-cap-app-srv -m 1G` to buy time
7. If stuck deploy → `cf mta-ops` → abort / resume

## Common mistakes

| Mistake | Fix |
|---|---|
| No `/health` endpoint | Uptime monitors have nothing to poll |
| `/health` endpoint behind auth | External monitors can't reach it — no `@requires` |
| Not setting `instances: 2` minimum | One crash = total downtime |
| Alerting on every error | Alert on error RATE — individual errors are noise |
| Not logging the correlationId | You can't trace a specific user complaint in Kibana |

## Checkpoint ✓

You can expose a `/health` endpoint that pings the database, configure ANS alerts on error rate, use `cf app`, `cf logs`, and `cf events` for triage, and follow a structured incident checklist from alert to resolution.
$md$
WHERE slug = 'cap-74-monitoring';

-- ─────────────────────────────────────────────────────────────────────────────
-- Episode 75 — Distributed Tracing
-- ─────────────────────────────────────────────────────────────────────────────
UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 75 — Distributed Tracing

## What you'll learn
- What distributed tracing is and how it differs from structured logging
- How SAP Cloud ALM and OpenTelemetry support tracing on BTP
- How to enable the `@sap/xb-msg-amqp-v100` tracing plugin in CAP
- How to propagate trace context across HTTP and event-based calls
- How to read traces in the SAP Cloud ALM UI to diagnose latency

## Why this matters
When a user reports "the purchase order page is slow", structured logs tell you that something took 3 seconds but not *which* call in the chain caused it. Distributed tracing generates a **trace** — a tree of spans showing every service call, DB query, and downstream request with its duration. You can see immediately whether the slowdown is in CAP handler code, an HANA query, or an S/4HANA OData call.

## Key concepts

| Term | Meaning |
|---|---|
| Trace | A complete request flow across all services |
| Span | One unit of work (a function call, a DB query, an HTTP request) |
| Trace ID | Unique ID shared by all spans in one trace |
| Span ID | Unique ID for one span |
| Parent Span | The span that initiated the current work unit |
| W3C Trace Context | Standard HTTP headers: `traceparent`, `tracestate` |

## OpenTelemetry in CAP

CAP supports OpenTelemetry (OTel) tracing through `@sap/cds-tracing`:

```bash
npm install @sap/cds-tracing @opentelemetry/sdk-node
```

```javascript
// srv/server.js — enable before anything else
const tracing = require('@sap/cds-tracing');
tracing.enable();   // auto-instruments DB calls, service calls, HTTP handlers
```

CAP will create spans automatically for:
- Every incoming OData request (root span)
- Every `this.on()` / `this.before()` / `this.after()` handler
- Every CQL DB operation
- Every `cds.connect.to()` remote service call

## Propagating trace context

When CAP calls a remote service (S/4HANA, Event Mesh), pass the W3C `traceparent` header automatically:

```javascript
// CAP does this for you when using cds.connect.to()
// For manual fetch calls, propagate explicitly:
const { context } = require('@opentelemetry/api');
const { propagation } = require('@opentelemetry/api');

async function callDownstream(url, req) {
  const headers = {};
  propagation.inject(context.active(), headers);  // injects traceparent

  return fetch(url, { headers });
}
```

## Sending traces to SAP Cloud ALM

Configure the OTel exporter to send to Cloud ALM:

```javascript
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-http');
const { NodeSDK }           = require('@opentelemetry/sdk-node');

const sdk = new NodeSDK({
  traceExporter: new OTLPTraceExporter({
    url: process.env.OTEL_EXPORTER_OTLP_ENDPOINT,
    headers: {
      Authorization: `Bearer ${process.env.OTEL_EXPORTER_TOKEN}`
    }
  })
});

sdk.start();
```

Set `OTEL_EXPORTER_OTLP_ENDPOINT` and `OTEL_EXPORTER_TOKEN` from the Cloud ALM service key in your CF manifest:
```yaml
env:
  OTEL_EXPORTER_OTLP_ENDPOINT: https://cloudalm.cfapps.eu10.hana.ondemand.com/api/v1/traces
  OTEL_EXPORTER_TOKEN: ((cloud-alm-token))
```

## Reading traces in Cloud ALM

1. Navigate to **SAP Cloud ALM → Health Monitoring → Distributed Tracing**
2. Search by trace ID (from a specific user complaint) or filter by:
   - Service name
   - Duration > 2 s (slow requests)
   - Status = ERROR (failed requests)
3. Click a trace to see the span tree
4. Each span shows: start time, duration, attributes (user, tenant, SQL query)

## Correlating traces with logs

Include the trace ID in your structured log entries so you can jump from a log line to its trace:

```javascript
const { trace } = require('@opentelemetry/api');

logger.info('Starting approval workflow', {
  traceId:  trace.getActiveSpan()?.spanContext().traceId,
  userId:   req.user.id,
  poAmount: req.data.totalAmount
});
```

In Kibana, click the `traceId` value → opens the trace in Cloud ALM (if linked).

## Common mistakes

| Mistake | Fix |
|---|---|
| Enabling tracing after other middleware | Enable `@sap/cds-tracing` before all other requires |
| Not propagating `traceparent` in manual fetch calls | Use the OTel propagation API |
| Sampling rate at 100% in production | Set `OTEL_TRACES_SAMPLER_ARG=0.1` (10%) to control volume |
| No trace ID in log entries | Correlate logs and traces via the trace ID field |
| Ignoring span attributes | Span attributes (user, SQL, entity) are what make traces useful |

## Checkpoint ✓

You can enable OpenTelemetry tracing in CAP with `@sap/cds-tracing`, propagate trace context in downstream calls, export traces to SAP Cloud ALM, read the span tree to find the slow step, and correlate traces with structured log entries via trace ID.
$md$
WHERE slug = 'cap-75-tracing';


-- ─────────────────────────────────────────────────────────────────────────────
-- Episode 76 — Multitenancy Basics
-- ─────────────────────────────────────────────────────────────────────────────
UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 76 — Multitenancy Basics

## What you'll learn
- What multitenancy means in a BTP context and when you need it
- How CAP's built-in `@sap/cds-mtxs` plugin implements tenant isolation
- How tenant onboarding and offboarding works (subscribe / unsubscribe)
- How to use `req.tenant` to scope data correctly
- How to test multitenancy locally with mock tenants

## Why this matters
If you build an application for multiple customer organisations that need to share the same deployment but keep their data strictly isolated, you need multitenancy. CAP's `@sap/cds-mtxs` (MTX Sidecar) handles the hard parts: per-tenant HANA HDI containers, automatic tenant routing, and a subscription API that BTP's SaaS Registry calls during onboarding. Without this, you would have to implement tenant routing, schema provisioning, and isolation yourself.

## Tenant isolation model in CAP

| Aspect | How CAP handles it |
|---|---|
| Data | Each tenant gets its own HANA HDI container |
| Authentication | JWT `zid` (zone ID) claim identifies the tenant |
| Routing | `req.tenant` is set automatically from the JWT |
| Schema upgrades | `mtxs` applies schema migrations to all tenant DBs |
| Onboarding | SaaS Registry calls your `/mtx/v1/provisioning/tenant` endpoint |

## Setting up `@sap/cds-mtxs`

```bash
npm install @sap/cds-mtxs
```

```json
// package.json — enable the plugin
{
  "cds": {
    "requires": {
      "multitenancy": true,
      "[production]": {
        "auth": { "kind": "xsuaa" },
        "db": { "kind": "hana" }
      }
    }
  }
}
```

`@sap/cds-mtxs` automatically mounts a `/mtx/v1` API for provisioning, model sync, and extensibility.

## XSUAA configuration for multitenancy

```json
// xs-security.json
{
  "xsappname": "my-cap-saas",
  "tenant-mode": "shared",          // CRITICAL: must be "shared" not "dedicated"
  "scopes": [
    { "name": "$XSAPPNAME.user",        "description": "Application user" },
    { "name": "$XSAPPNAME.admin",       "description": "Admin" },
    { "name": "$XSAPPNAME.mtcallback",  "description": "SaaS Registry callback" }
  ],
  "oauth2-configuration": {
    "token-validity": 43200,
    "refresh-token-validity": 2592000
  }
}
```

`"tenant-mode": "shared"` is essential — it enables the JWT `zid` claim that CAP uses to identify tenants.

## How `req.tenant` works

CAP reads the `zid` (zone ID) from the JWT and sets `req.tenant` automatically:

```javascript
this.before('*', req => {
  console.log('Tenant:', req.tenant);   // e.g. 'abc-customer-guid'

  // CQL queries are automatically scoped to the tenant's HDI container
  // No WHERE clause needed — the DB connection is tenant-specific
});
```

You never have to add `WHERE tenant = ?` to your queries. The HDI container binding is resolved per tenant before the handler runs.

## Tenant onboarding (subscribe)

When a customer subscribes in BTP, the SaaS Registry calls:
```
PUT /mtx/v1/provisioning/tenant/{tenantId}
```

`@sap/cds-mtxs` handles this endpoint. It:
1. Creates a new HANA HDI container for the tenant
2. Deploys the current CDS schema to that container
3. Returns `200 OK` when done

You can hook into the onboarding event:

```javascript
// srv/provisioning.js
const cds = require('@sap/cds');

cds.on('served', async () => {
  const { 'cds.xt.SaasProvisioningService': provisioning } = cds.services;

  provisioning.on('subscribe', async ({ tenant, options }) => {
    console.log(`Tenant ${tenant} subscribed`);

    // Seed initial data for the new tenant
    const db = await cds.connect.to('db', { tenant });
    await db.insert(cds.entities.Settings).entries({
      key: 'welcomeMessage', value: 'Welcome to CodeGoLive!'
    });
  });

  provisioning.on('unsubscribe', async ({ tenant }) => {
    console.log(`Tenant ${tenant} unsubscribed — cleaning up`);
    // Optionally export or archive data before the HDI container is deleted
  });
});
```

## Testing multitenancy locally

```json
// .cdsrc.json — mock tenant setup
{
  "requires": {
    "auth": {
      "kind": "mocked",
      "users": {
        "alice": { "tenant": "t1", "roles": ["admin"] },
        "bob":   { "tenant": "t2", "roles": ["user"] }
      }
    },
    "multitenancy": true
  }
}
```

```bash
cds watch
# alice (tenant t1) and bob (tenant t2) see completely isolated data
```

In-memory SQLite databases are used per tenant in local mock mode — no real HDI containers needed for development.

## Common mistakes

| Mistake | Fix |
|---|---|
| `"tenant-mode": "dedicated"` in xs-security.json | Must be `"shared"` for multitenancy to work |
| Hardcoding tenant ID in queries | Never — use `req.tenant` and let CAP route to the correct DB |
| Not implementing the `subscribe` hook | Default onboarding works, but you miss seeding initial data |
| Sharing a single HANA service instance | Each tenant needs its own HDI container — use `hana/hdi-shared` |
| Forgetting schema migrations apply to all tenants | `cds-mtxs` handles this, but unsafe schema changes affect all tenants simultaneously |

## Checkpoint ✓

You understand the CAP multitenancy model — per-tenant HDI containers, `req.tenant` from the JWT `zid` claim, and the `subscribe`/`unsubscribe` lifecycle. You can configure `@sap/cds-mtxs`, set `"tenant-mode": "shared"` in XSUAA, hook into onboarding to seed initial data, and test tenant isolation locally with mocked users.
$md$
WHERE slug = 'cap-76-multitenancy';

-- ─────────────────────────────────────────────────────────────────────────────
-- Episode 77 — SaaS Registry
-- ─────────────────────────────────────────────────────────────────────────────
UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 77 — SaaS Registry

## What you'll learn
- What the BTP SaaS Registry is and what it manages
- How to register your CAP application as a SaaS app in the registry
- How tenant subscription and unsubscription flows work end-to-end
- How to configure the subscription callback URLs
- How to list and manage subscriptions from the BTP Cockpit

## Why this matters
The SaaS Registry is BTP's central directory of multi-tenant SaaS applications. It connects the "subscribe" button in a customer's BTP Cockpit to your provisioning endpoint. Without registering your app in the SaaS Registry, customers cannot subscribe — you would have to manage tenant onboarding manually. The registry also controls which XSUAA scopes are granted to subscribers and what the consumer app looks like in their cockpit.

## How the SaaS Registry works

```
Customer BTP Cockpit
  │ Click "Subscribe"
  ▼
SaaS Registry
  │ PUT /mtx/v1/provisioning/tenant/{tenantId}
  ▼
Your CAP App (mtxs provisioning endpoint)
  │ Create HDI container, deploy schema
  │ Return 200 OK
  ▼
SaaS Registry
  │ Store subscription record
  │ Redirect customer to app URL
  ▼
Customer opens your app at:
  https://your-app-<customer-subaccount>.cfapps.eu10.hana.ondemand.com
```

## Binding the SaaS Registry

```bash
cf create-service saas-registry application my-saas-registry \
  -c '{
    "appName": "my-cap-saas",
    "appUrls": {
      "getDependencies": "https://my-cap-app.cfapps.eu10.hana.ondemand.com/mtx/v1/provisioning/dependencies",
      "onSubscription": "https://my-cap-app.cfapps.eu10.hana.ondemand.com/mtx/v1/provisioning/tenant/{tenantId}",
      "onSubscriptionAsync": false
    },
    "displayName": "My CAP Learning App",
    "description": "Learn SAP BTP development interactively",
    "category": "Education",
    "xsappname": "my-cap-saas"
  }'
```

The `onSubscription` URL is what the registry calls — `{tenantId}` is a literal placeholder that the registry replaces with the actual tenant GUID at call time.

## MTA descriptor resource

```yaml
resources:
  - name: my-saas-registry
    type: org.cloudfoundry.managed-service
    parameters:
      service: saas-registry
      service-plan: application
      config:
        appName: my-cap-saas
        displayName: My CAP Learning App
        description: Interactive SAP BTP course platform
        category: Education
        appUrls:
          getDependencies: ~{srv-api/srv-url}/mtx/v1/provisioning/dependencies
          onSubscription: ~{srv-api/srv-url}/mtx/v1/provisioning/tenant/{tenantId}
          onSubscriptionAsync: false
    requires:
      - name: srv-api
```

Using `~{srv-api/srv-url}` means the URL is resolved from the CAP module's published URL — no hardcoding.

## The `getDependencies` endpoint

The SaaS Registry calls this endpoint to discover which XSUAA and Destination services the app depends on. `@sap/cds-mtxs` implements it automatically:

```
GET /mtx/v1/provisioning/dependencies
Response:
[
  { "xsappname": "my-cap-saas!t1234" },
  { "xsappname": "destination!b12" }
]
```

## Securing the provisioning endpoint

Only the SaaS Registry should call your provisioning endpoint. `@sap/cds-mtxs` enforces this by requiring the `mtcallback` scope, which is only granted to the SaaS Registry service principal:

```json
// xs-security.json
{
  "scopes": [
    {
      "name": "$XSAPPNAME.mtcallback",
      "description": "SaaS Registry callback scope",
      "grant-as-authority-to-apps": ["$XSAPPNAME!b*"]
    }
  ]
}
```

## Managing subscriptions in the BTP Cockpit

As the provider, you can see all subscriptions:
1. Navigate to **SaaS Registry → your application → Subscriptions**
2. Each subscription shows: tenant ID, subaccount name, status, subscribed date
3. You can manually trigger `getDependencies` to test the endpoint
4. For offboarding: the customer unsubscribes in their cockpit → registry calls `DELETE /mtx/v1/provisioning/tenant/{tenantId}`

## Multi-tenant URL pattern

When a tenant subscribes, their dedicated URL is:
```
https://<tenant-subdomain>-<your-app-name>.cfapps.eu10.hana.ondemand.com
```

AppRouter resolves the subdomain → XSUAA extracts the zone ID → CAP sets `req.tenant`. The routing is automatic.

## Common mistakes

| Mistake | Fix |
|---|---|
| Hardcoding the callback URL | Use `~{srv-api/srv-url}` to resolve at deploy time |
| Not granting `mtcallback` scope to the registry | Provisioning calls will be rejected as unauthorized |
| `onSubscriptionAsync: true` without polling | Async mode requires a Job ID response; start with sync |
| Not implementing `getDependencies` | Subscriber subaccounts won't have the correct XSUAA scopes |
| Missing `saas-registry` entitlement | Provision will fail — check Global Account entitlements first |

## Checkpoint ✓

You can create a SaaS Registry service instance with the correct `onSubscription` and `getDependencies` URLs, bind it in the MTA descriptor using dynamic URL references, secure the provisioning endpoint with the `mtcallback` scope, and manage subscriptions from the BTP Cockpit.
$md$
WHERE slug = 'cap-77-saas-registry';


-- ─────────────────────────────────────────────────────────────────────────────
-- Episode 78 — Performance Tuning
-- ─────────────────────────────────────────────────────────────────────────────
UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 78 — Performance Tuning

## What you'll learn
- How to profile a slow CAP request end-to-end (from HTTP to DB)
- How to eliminate N+1 queries with CQL `expand` and `columns`
- How to tune HANA indexes and use EXPLAIN PLAN
- How to use Node.js profiling tools to find CPU-bound bottlenecks
- How to right-size memory and instances for production

## Why this matters
A CAP application that works correctly but responds in 5 seconds is not production-ready. Performance issues in enterprise apps are almost always one of three things: too many round trips to the database (N+1), missing indexes on frequently-filtered columns, or oversized payloads. This episode gives you a systematic method to find and fix each.

## Step 1: Measure before you optimise

Add response time logging to all handlers:

```javascript
// srv/middleware/timing.js
module.exports = function timingMiddleware(req, res, next) {
  const start = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - start;
    if (duration > 500) {
      cds.log('perf').warn(`Slow request: ${req.method} ${req.path} — ${duration}ms`);
    }
  });
  next();
};
```

Enable in `server.js`:
```javascript
cds.on('bootstrap', app => {
  app.use(require('./middleware/timing'));
});
```

## Step 2: Find N+1 queries

N+1 is the most common CAP performance issue. It occurs when you `READ` a parent list and then separately `READ` each child:

```javascript
// BAD — fires 1 + N queries
const orders = await db.read(Orders);
for (const order of orders) {
  order.items = await db.read(OrderItems).where({ orderId: order.ID });
}
```

Fix with a single query using `expand`:

```javascript
// GOOD — one query with JOIN
const orders = await db.read(Orders).columns(o => {
  o.ID, o.status, o.totalAmount,
  o.items(i => { i.ID, i.product, i.quantity, i.price })
});
```

Or via OData `$expand`:
```
GET /odata/v4/OrderService/Orders?$expand=items($select=ID,product,quantity)
```

## Step 3: Add CDS indexes

```cds
// db/schema.cds
entity Orders {
  key ID        : UUID;
      status    : String(20);  @Common.Label: 'Status'
      createdAt : Timestamp;
      createdBy : String(100);
      customer  : Association to Customers;
}

// Add indexes for commonly filtered fields
annotate Orders with @index: [
  { elements: ['status'] },
  { elements: ['createdAt'] },
  { elements: ['customer_ID'] }   // FK columns need indexes for JOIN performance
];
```

For HANA-specific full-text indexes (Episode 42):
```cds
annotate Products with {
  description @hana.fullTextIndex: { fuzzySearchIndex: true };
}
```

## Step 4: HANA EXPLAIN PLAN

When a HANA query is slow, run EXPLAIN PLAN to see if an index is being used:

```sql
-- In SAP HANA Database Explorer
EXPLAIN PLAN FOR
SELECT * FROM MY_APP_ORDERS WHERE STATUS = 'Pending' AND CREATED_AT > '2026-01-01';
```

Look for:
- `TABLE SCAN` on large tables → missing index
- `HASH JOIN` on unbounded result sets → add `$top` / `LIMIT`
- High `ESTIMATED RECORD COUNT` → stale table statistics → run `UPDATE STATISTICS`

## Step 5: Payload size

Large OData responses slow down both the backend and the browser. Use `$select` and `$top`:

```
# Instead of:
GET /odata/v4/OrderService/Orders

# Use:
GET /odata/v4/OrderService/Orders?$select=ID,status,totalAmount&$top=50&$orderby=createdAt desc
```

Enforce limits server-side:
```javascript
this.before('READ', Orders, req => {
  if (!req.query.SELECT.limit) {
    req.query.SELECT.limit = { rows: { val: 100 } };
  }
});
```

## Step 6: Node.js CPU profiling

```bash
# Run with CPU profiler
node --prof node_modules/@sap/cds/bin/cds-serve

# After a test run, process the profile
node --prof-process isolate-*.log > profile.txt

# Look for functions consuming > 5% CPU
grep "LazyCompile\|Script" profile.txt | head -30
```

Or use `clinic.js`:
```bash
npm install -g clinic
clinic doctor -- node node_modules/@sap/cds/bin/cds-serve
```

## Right-sizing memory and instances

| Metric | Action |
|---|---|
| Memory > 80% at load | Increase `memory` in manifest; investigate leaks with `--inspect` |
| CPU > 60% constantly | Scale instances (`cf scale -i 3`); use autoscaler |
| Response > 2 s on first request | Warm up effect — pre-load caches in `cds.on('served')` |
| Connection pool exhausted | Increase `hana.pool.max` in cds config |

```json
// package.json
{
  "cds": {
    "requires": {
      "db": {
        "kind": "hana",
        "pool": {
          "min": 2,
          "max": 10,
          "acquireTimeoutMillis": 5000
        }
      }
    }
  }
}
```

## Common mistakes

| Mistake | Fix |
|---|---|
| Optimising before measuring | Always profile first — guess wrong and you waste hours |
| `SELECT *` on large entities | Always `$select` only the fields you need |
| No `$top` limit on list endpoints | One slow unbounded query can bring down the whole instance |
| Indexes on every column | Too many indexes hurt write performance — index what you filter on |
| Ignoring Node.js event loop blocking | Long synchronous operations (JSON parsing, heavy crypto) block all requests |

## Checkpoint ✓

You can profile a slow request end-to-end, identify and fix N+1 queries with CQL `expand`, add CDS index annotations, read an HANA EXPLAIN PLAN, enforce pagination limits server-side, and right-size memory and connection pool settings for production load.
$md$
WHERE slug = 'cap-78-performance';

-- ─────────────────────────────────────────────────────────────────────────────
-- Episode 79 — Production Security Hardening
-- ─────────────────────────────────────────────────────────────────────────────
UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 79 — Production Security Hardening

## What you'll learn
- The security controls that must be in place before going to production
- How to configure Content Security Policy (CSP) headers in AppRouter
- How to enable CSRF protection and rate limiting
- How to audit your app against the SAP BTP Security Checklist
- How to scan for secrets committed to git and rotate exposed credentials

## Why this matters
A functionally complete app is not automatically a secure one. Production systems on BTP are internet-accessible — malicious actors scan for misconfigured endpoints, weak tokens, and missing headers within hours of a deployment. Running through the security checklist before go-live is cheaper than responding to an incident.

## Security control inventory

### Authentication & Authorization
- [ ] All non-public routes are protected by `@requires` or `@restrict`
- [ ] Admin routes (`/admin/*`) require the `admin` role
- [ ] The `/health` endpoint returns only status — no internal data
- [ ] XSUAA `tenant-mode: dedicated` (single-tenant) or `shared` (multi-tenant) — never default
- [ ] Mock users (`"kind":"mocked"`) are disabled in production (not in `[production]` profile)

### Transport
- [ ] AppRouter enforces HTTPS — CF does this at the platform level
- [ ] HSTS header is set: `Strict-Transport-Security: max-age=31536000; includeSubDomains`
- [ ] CSP header is configured to prevent XSS

### API hardening
- [ ] CSRF protection enabled on all non-GET routes in AppRouter
- [ ] Rate limiting configured on sensitive endpoints (login, upload)
- [ ] `$top` limit enforced on all list endpoints to prevent large payload attacks
- [ ] Input validation: reject unexpected fields with `strict: true` in CDS model

### Secret management
- [ ] No credentials in source code or `package.json`
- [ ] All secrets in CF environment variables / service bindings
- [ ] Old service keys rotated after any suspected exposure
- [ ] `.env` file is in `.gitignore`

## Configuring CSP headers in AppRouter

```json
// approuter/xs-app.json
{
  "compression": { "enabled": true },
  "responseHeaders": [
    {
      "name": "Content-Security-Policy",
      "value": "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; connect-src 'self' https://*.hana.ondemand.com; frame-ancestors 'none'"
    },
    {
      "name": "X-Frame-Options",
      "value": "DENY"
    },
    {
      "name": "X-Content-Type-Options",
      "value": "nosniff"
    },
    {
      "name": "Strict-Transport-Security",
      "value": "max-age=31536000; includeSubDomains"
    }
  ]
}
```

## Enabling CSRF protection

```json
// approuter/xs-app.json route
{
  "source": "^/api/(.*)$",
  "target": "/api/$1",
  "destination": "cap-backend",
  "csrfProtection": true,    // AppRouter will require X-CSRF-Token header on mutations
  "authenticationType": "xsuaa"
}
```

The React frontend fetches the CSRF token:
```javascript
// Fetch the CSRF token before any POST/PUT/DELETE
const tokenRes = await fetch('/api/xsrf-token', {
  headers: { 'X-CSRF-Token': 'Fetch' }
});
const csrfToken = tokenRes.headers.get('X-CSRF-Token');

// Use it in subsequent mutations
await fetch('/api/odata/v4/OrderService/Orders', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-CSRF-Token': csrfToken
  },
  body: JSON.stringify({ ... })
});
```

## Rate limiting with `express-rate-limit`

```bash
npm install express-rate-limit
```

```javascript
// srv/server.js
const rateLimit = require('express-rate-limit');
const cds       = require('@sap/cds');

cds.on('bootstrap', app => {
  // Strict limit on auth-adjacent endpoints
  const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,  // 15 minutes
    max: 20,
    message: 'Too many requests from this IP, please try again later'
  });

  app.use('/api/auth', authLimiter);
  app.use('/api/upload', authLimiter);

  // General API limit
  const generalLimiter = rateLimit({
    windowMs: 1 * 60 * 1000,   // 1 minute
    max: 200
  });

  app.use('/api', generalLimiter);
});
```

## Scanning for committed secrets

```bash
# Install truffleHog
pip install truffleHog3

# Scan the git history for secrets
trufflehog3 --regex --entropy=False .

# Or use gitleaks
brew install gitleaks
gitleaks detect --source . -v
```

If a secret is found in git history:
1. Rotate the credential immediately — assume it is compromised
2. Remove it from git history (`git filter-repo --path-glob '*.env' --invert-paths`)
3. Force-push the cleaned history (coordinate with the team)
4. Audit CF environment variables and service keys for the same credential

## Disabling mock auth in production

```json
// package.json — production profile overrides
{
  "cds": {
    "requires": {
      "[production]": {
        "auth": { "kind": "xsuaa" }
      },
      "[development]": {
        "auth": {
          "kind": "mocked",
          "users": { ... }
        }
      }
    }
  }
}
```

CAP activates the `[production]` profile when `NODE_ENV=production` (CF sets this automatically).

## Common mistakes

| Mistake | Fix |
|---|---|
| Leaving `"kind":"mocked"` in the top-level `requires` (not profile-scoped) | Scope mock auth to `[development]` only |
| No CSRF on AppRouter routes | Set `"csrfProtection": true` on all mutation routes |
| `frame-ancestors *` in CSP | Use `'none'` to prevent clickjacking |
| Service keys in `package.json` | Use CF environment variables or `cds bind` |
| No rate limiting on upload endpoints | A single client can exhaust Object Store bandwidth |

## Checkpoint ✓

You have worked through the security control inventory, configured CSP/HSTS/X-Frame-Options headers in AppRouter, enabled CSRF protection, added rate limiting on sensitive endpoints, and know how to scan for committed secrets and rotate exposed credentials.
$md$
WHERE slug = 'cap-79-security-hardening';


-- ─────────────────────────────────────────────────────────────────────────────
-- Episode 80 — Go-Live Checklist
-- ─────────────────────────────────────────────────────────────────────────────
UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 80 — Go-Live Checklist

## What you'll learn
- A complete, actionable checklist for taking a CAP application to production
- How to run a pre-go-live smoke test suite
- What to hand over to operations for day-2 support
- What the first 24 hours after go-live should look like
- How to celebrate shipping your first BTP application

## Why this matters
You have learned everything in this course — CAP foundations, data modeling, service development, HANA persistence, authentication, BTP service integrations, and deployment. This final episode brings it all together. A go-live checklist is not bureaucracy — it is the professional habit that prevents you from shipping something that breaks immediately and keeps your production environment stable after launch.

---

## Pre-go-live checklist

### Infrastructure
- [ ] Production subaccount created with correct entitlements (Episode 71)
- [ ] All managed services provisioned in the production space (XSUAA, HANA, Destination, etc.)
- [ ] HANA HDI container deployed with the latest schema (run the HDI deployer module)
- [ ] XSUAA `xs-security.json` has `"tenant-mode": "dedicated"` (or `"shared"` for SaaS)
- [ ] All role collections created and assigned to the appropriate users
- [ ] Destination Service configured with production endpoints (not sandbox/dev)
- [ ] Cloud Connector configured (if using on-premise integration)

### Code & configuration
- [ ] `NODE_ENV=production` is set (CF sets this automatically — verify in `cf env`)
- [ ] Mock auth is disabled — `auth.kind` is `xsuaa` in the `[production]` profile
- [ ] No hardcoded credentials, secrets, or sandbox URLs in source code
- [ ] All `PLACEHOLDER:` comments in legal/contact pages have been filled in
- [ ] `robots.txt` and `sitemap.xml` contain the correct production domain
- [ ] `localStorage` keys use production names (e.g. `cgl-theme`, not legacy `ztd-theme`)

### Security
- [ ] CSP, HSTS, X-Frame-Options headers configured in AppRouter (Episode 79)
- [ ] CSRF protection enabled on mutation routes
- [ ] Rate limiting applied to upload and auth-adjacent endpoints
- [ ] No secrets in git history (`gitleaks detect` returns clean)
- [ ] All admin routes protected by `RequireRole` (frontend) and `@requires` (CAP)
- [ ] `/health` endpoint returns only `UP`/`DOWN` — no internal data

### Observability
- [ ] SAP Application Logging Service bound and `@sap/logging` middleware enabled (Episode 66)
- [ ] `/health` endpoint returning 200 at the production URL
- [ ] External uptime monitor pointing at `/health` (UptimeRobot, Pingdom, or BTP Alert Notification)
- [ ] ANS alert rule created for error rate > threshold (Episode 60)
- [ ] `cf app` shows `running` state with 2+ instances

### CI/CD
- [ ] Pipeline runs successfully on the production branch
- [ ] Deploy stage uses `--strategy blue-green` (Episode 72)
- [ ] Pipeline has a manual approval gate before production deploy (Episode 73)
- [ ] Rollback procedure is documented and tested

### Performance
- [ ] All frequently-filtered columns are indexed (Episode 78)
- [ ] List endpoints enforce `$top` limits
- [ ] Connection pool `max` sized to expected concurrency
- [ ] HANA statistics are up to date (`UPDATE STATISTICS`)

---

## Smoke test suite

Run these immediately after deploying to production:

```bash
# Health check
curl -s https://my-app.cfapps.eu10.hana.ondemand.com/health
# Expected: {"status":"UP","timestamp":"..."}

# XSUAA token acquisition (verify XSUAA is healthy)
curl -X POST "https://my-subaccount.authentication.eu10.hana.ondemand.com/oauth/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials&client_id=...&client_secret=..."
# Expected: {"access_token":"...","token_type":"Bearer"}

# OData metadata (verify CAP service is up and schema is correct)
curl -s -H "Authorization: Bearer <token>" \
  https://my-app.cfapps.eu10.hana.ondemand.com/api/odata/v4/MyService/$metadata
# Expected: XML metadata document

# List endpoint (verify DB connection)
curl -s -H "Authorization: Bearer <token>" \
  "https://my-app.cfapps.eu10.hana.ondemand.com/api/odata/v4/MyService/Entities?\$top=1"
# Expected: {"value":[...]}
```

---

## Day-2 operations handover

Hand over to operations:

**Runbook topics to document:**
1. How to check app health (`cf app`, `/health` URL)
2. How to tail logs (`cf logs`, Kibana URL + common filters)
3. How to scale instances (`cf scale -i N`)
4. How to deploy a new version (`mbt build && cf deploy --strategy blue-green`)
5. How to roll back (deploy previous `.mtar`)
6. How to rotate XSUAA service key (`cf create-service-key`, update bindings)
7. How to check HANA health (BTP Cockpit → HANA Cloud → Monitor)
8. How to pause/unpause scheduled jobs (JSS cockpit)
9. Escalation path: who owns the BTP global account, who has SAP support access

---

## First 24 hours after go-live

| Time | Action |
|---|---|
| T+0 | Smoke tests pass ✓ |
| T+30m | Check Kibana — any unexpected ERROR log entries? |
| T+1h | `cf app` — memory stable, no restarts |
| T+2h | Check ANS — no alerts fired |
| T+4h | Review response times — any endpoints > 1 s? |
| T+24h | Check `/health` uptime monitor — 100% uptime? |
| T+24h | Review HANA Cloud memory and CPU in BTP Cockpit |

If something breaks in the first 24 hours, use the rollback procedure before trying to fix-forward — stability first, root-cause analysis second.

---

## You made it

You have completed the SAP CAP: Zero to Deployed course.

Here is what you built knowledge of across all 80 episodes:

- **CAP Foundations** (Module 1): Project structure, CDS, OData V4, associations, annotations, served handlers
- **CDS Data Modeling** (Module 2): Aspects, types, projections, views, input validation, draft enablement, temporal data, i18n
- **Service Development** (Module 3): Handler lifecycle, custom actions/functions, error handling, messaging, Fiori annotations, remote services
- **Persistence & HANA** (Module 4): SQLite dev, HDI containers, HANA types, migrations, full-text search, RLS, audit logging, personal data
- **Auth & Authorization** (Module 5): XSUAA, JWT, `@requires`/`@restrict`, mock auth, IAS, principal propagation, security patterns
- **BTP Services** (Module 6): Destination, Connectivity, Event Mesh, Alert Notification, S/4HANA integration, BAPI, Workflow, Object Store, Job Scheduling, Logging, Feature Flags, HTML5 Repo
- **Deployment & Production** (Module 7): MTA, CF Deploy, BTP Setup, Blue-Green, CI/CD, Monitoring, Tracing, Multitenancy, SaaS Registry, Performance, Security Hardening

Ship something real. The best way to consolidate this knowledge is to build an application that solves a problem you actually have. Start small — one entity, one service, one deployment. Then grow it.

Good luck.

## Checkpoint ✓

You have completed the entire course. You can navigate a production BTP deployment with confidence, diagnose issues using structured logs and distributed traces, and hand over a stable, monitored, secure application to operations.
$md$
WHERE slug = 'cap-80-checklist';

