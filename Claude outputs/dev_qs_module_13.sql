-- Module 13 (Authentication & AppRouter) for dev-quickstart

-- Step 1: Insert the module
INSERT INTO modules (course_id, number, title, order_index) VALUES (
  'dev-quickstart',
  '13',
  'Authentication & AppRouter',
  12
) ON CONFLICT (number) DO NOTHING;

INSERT INTO topics (module_id, number, slug, title, focus, description, content_md, order_index, status) VALUES (
  (SELECT id FROM modules WHERE course_id = 'dev-quickstart' AND number = '13'),
  '760',
  'dev-qs-xsuaa-intro',
  'What is XSUAA and xs-security.json',
  'Understand the BTP authorization service and define your app''s security descriptor',
  'Learn what XSUAA does, how it fits in the BTP authentication flow, and use cds add xsuaa to generate and configure xs-security.json.',
  '# What is XSUAA and xs-security.json

Every BTP application that needs to know **who the user is** — or restrict access by role — must use XSUAA.

## What XSUAA does

XSUAA (Extended Services for User Account and Authentication) is BTP''s OAuth2 authorization server. It:

1. Issues **JWT tokens** to authenticated users
2. Embeds **scopes** (permissions) into those tokens based on the user''s role assignments
3. Lets your CAP service verify the token and read `req.user` without writing any auth code yourself

## How it fits in a BTP app

```
Browser / Client
    │
    ▼
AppRouter  ─── redirects unauthenticated users to ───►  XSUAA (login page)
    │                                                         │
    │◄── returns JWT token with user info + scopes ──────────┘
    │
    │  forwards request with Authorization: Bearer <token>
    ▼
CAP Service  ─── validates token via XSUAA public key ───► allows / denies
```

Your CAP service **never sees passwords** — it only sees a signed JWT that XSUAA already verified.

---

## Add XSUAA to a CAP project

```bash
cds add xsuaa
```

This does three things:
1. Creates `xs-security.json` in the project root
2. Adds `@sap/xssec` and `passport` to `package.json`
3. Adds a `requires.auth` section to the `cds` config in `package.json`

---

## The generated xs-security.json — explained

```json
{
  "xsappname": "bookshop",
  "tenant-mode": "dedicated",
  "description": "Security descriptor for bookshop",
  "scopes": [
    {
      "name": "$XSAPPNAME.admin",
      "description": "Full administrative access"
    },
    {
      "name": "$XSAPPNAME.viewer",
      "description": "Read-only access"
    }
  ],
  "attributes": [],
  "role-templates": [
    {
      "name": "admin",
      "description": "Administrators",
      "scope-references": ["$XSAPPNAME.admin"]
    },
    {
      "name": "viewer",
      "description": "Read-only users",
      "scope-references": ["$XSAPPNAME.viewer"]
    }
  ],
  "role-collections": [
    {
      "name": "Bookshop Admin",
      "description": "Full access to Bookshop",
      "role-template-references": ["$XSAPPNAME.admin"]
    }
  ],
  "oauth2-configuration": {
    "redirect-uris": ["https://*.hana.ondemand.com/**"]
  }
}
```

| Field | What it means |
|-------|--------------|
| `xsappname` | Unique app identifier — scopes are prefixed with this |
| `tenant-mode` | `dedicated` = single-tenant, `shared` = multi-tenant (SaaS) |
| `scopes` | Atomic permissions your app checks for |
| `$XSAPPNAME` | Placeholder that becomes your actual xsappname at deployment |
| `role-templates` | Named collections of scopes — assigned to role collections |
| `role-collections` | What admins assign to users in the BTP cockpit |
| `oauth2-configuration` | Allowed redirect URIs after login — use wildcards for CF |

---

## Create the XSUAA service instance on BTP

You need an actual service instance before deploying. Either:

**Option A — via CF CLI:**
```bash
cf create-service xsuaa application bookshop-xsuaa -c xs-security.json
```

**Option B — via mta.yaml (recommended):**
Declare it as a resource (covered in topic 763) — the MTA deployer creates it automatically.

---

## Key rule

> **`$XSAPPNAME` prefix is mandatory on scope names.** If you write the scope as just `admin` (without the prefix), the JWT token your XSUAA issues will never contain that scope and all `@restrict` checks will fail silently.
',
  0,
  'published'
);

INSERT INTO topics (module_id, number, slug, title, focus, description, content_md, order_index, status) VALUES (
  (SELECT id FROM modules WHERE course_id = 'dev-quickstart' AND number = '13'),
  '761',
  'dev-qs-xsuaa-cap',
  'Secure a CAP Service with @requires and @restrict',
  'Add authentication and role-based access to your CDS service definitions',
  'Use CDS security annotations to require authentication and restrict access by scope, inspect req.user in handlers, and test locally with mock users.',
  '# Secure a CAP Service with @requires and @restrict

CAP reads the `Authorization: Bearer <token>` header and exposes a typed `req.user` object in every handler — no middleware code needed.

---

## Require authentication on an entire service

```cds
// srv/cat-service.cds
using bookshop from ''../db/schema'';

@requires: ''authenticated-user''
service CatalogService {
  entity Books    as projection on bookshop.Books;
  entity Orders   as projection on bookshop.Orders;
}
```

Any request without a valid JWT token gets **HTTP 401** automatically.

---

## Restrict individual entities by scope

```cds
@requires: ''authenticated-user''
service CatalogService {

  // Anyone logged in can read
  @readonly
  entity Books as projection on bookshop.Books;

  // Only users with the ''admin'' scope can create/update/delete
  @restrict: [
    { grant: ''READ'',   to: ''viewer'' },
    { grant: [''WRITE'', ''DELETE''], to: ''admin'' }
  ]
  entity Orders as projection on bookshop.Orders;
}
```

The scope names (`viewer`, `admin`) must match the **role-template names** in `xs-security.json` (CAP strips the `$XSAPPNAME.` prefix automatically).

---

## Read the user in a handler

```js
// srv/cat-service.js
module.exports = class CatalogService extends cds.ApplicationService {
  init() {
    this.before(''CREATE'', ''Orders'', req => {
      const { id, name, roles } = req.user;
      console.log(`Order placed by: ${name} (${id})`);
      console.log(`Has admin scope: ${req.user.is(''admin'')}`);

      // Stamp the order with the creator''s ID
      req.data.createdBy = id;
    });
    return super.init();
  }
};
```

| Property | Value |
|----------|-------|
| `req.user.id` | Subject claim from JWT (unique user ID) |
| `req.user.name` | Display name |
| `req.user.attr` | Custom XSUAA attributes |
| `req.user.is(''scope'')` | Returns `true` if the token contains that scope |
| `req.user.roles` | Array of all scopes in the token |

---

## Test locally with mock users

`cds watch` activates mock authentication automatically in development.
You can configure mock users in your `package.json`:

```json
{
  "cds": {
    "requires": {
      "auth": {
        "kind": "mocked",
        "users": {
          "alice": { "roles": ["admin"] },
          "bob":   { "roles": ["viewer"] },
          "carol": {}
        }
      }
    }
  }
}
```

Pass the user as a Basic Auth header (mock only — never in production):

```bash
# Test as alice (admin)
curl -u alice: http://localhost:4004/catalog/Orders

# Test as carol (no roles) — should get 403 on restricted entities
curl -u carol: http://localhost:4004/catalog/Orders
```

Or with the VS Code REST Client:

```http
### Read books (any logged-in user)
GET http://localhost:4004/catalog/Books
Authorization: Basic alice:

### Create order (admin only)
POST http://localhost:4004/catalog/Orders
Authorization: Basic alice:
Content-Type: application/json

{ "bookId": 1, "quantity": 2 }
```

---

## Test with a real XSUAA token (hybrid profile)

Once you have a service key from your BTP XSUAA instance, you can test locally against real auth:

```bash
# Bind the service key for local use
cds bind xsuaa --to bookshop-xsuaa --kind xsuaa

# Run with the real XSUAA
cds watch --profile hybrid
```

With `--profile hybrid`, CAP validates real JWTs from XSUAA instead of mock tokens.
Get a token with the OAuth2 password grant (dev only):

```bash
curl -X POST https://your-tenant.authentication.eu10.hana.ondemand.com/oauth/token \
  -H ''Content-Type: application/x-www-form-urlencoded'' \
  -d ''grant_type=password&username=your@email.com&password=yourpw'' \
  -u ''<clientid>:<clientsecret>''
```

---

## The single most common mistake

Adding `@requires` to the service but forgetting to add `xsuaa` to the `requires` in `package.json`:

```json
{
  "cds": {
    "requires": {
      "auth": { "kind": "xsuaa" }
    }
  }
}
```

Without this, CAP uses the mocked auth even in production and every user appears as `anonymous`.
',
  1,
  'published'
);

INSERT INTO topics (module_id, number, slug, title, focus, description, content_md, order_index, status) VALUES (
  (SELECT id FROM modules WHERE course_id = 'dev-quickstart' AND number = '13'),
  '762',
  'dev-qs-approuter-setup',
  'AppRouter Setup and xs-app.json',
  'Create an AppRouter, configure routes in xs-app.json, and run it locally',
  'Install @sap/approuter, write an xs-app.json that routes requests to your CAP backend, and run the full AppRouter + CAP stack locally before deploying.',
  '# AppRouter Setup and xs-app.json

## What AppRouter actually does

AppRouter is an SAP-provided Node.js reverse proxy. It has three jobs:

1. **Authentication gateway** — redirects unauthenticated browsers to XSUAA login, then stores the token in a session cookie so users only log in once
2. **Token forwarder** — extracts the token from the session and adds `Authorization: Bearer <token>` to every request it proxies to your backend
3. **Static file server** — optionally serves your built SAPUI5 app from the same origin (avoids CORS completely)

Without AppRouter, your SPA would need to implement OAuth2 PKCE itself and handle token refresh — AppRouter does all of that for free.

---

## Create the AppRouter folder

```bash
mkdir -p app/router
cd app/router
npm init -y
npm install @sap/approuter
```

---

## xs-app.json — the routing config

```json
{
  "welcomeFile": "/index.html",
  "authenticationMethod": "route",
  "routes": [
    {
      "source": "^/catalog/(.*)$",
      "target": "/catalog/$1",
      "destination": "srv-api",
      "authenticationType": "xsuaa",
      "csrfProtection": false
    },
    {
      "source": "^/(.*)$",
      "target": "$1",
      "localDir": "webapp",
      "authenticationType": "xsuaa"
    }
  ]
}
```

| Field | What it does |
|-------|-------------|
| `source` | Regex matching incoming request path |
| `target` | Path to rewrite to (capture groups work) |
| `destination` | Named destination (defined in env vars or mta.yaml) |
| `localDir` | Serve static files from this folder (relative to xs-app.json) |
| `authenticationType` | `xsuaa` = require login, `none` = public route |
| `csrfProtection` | Set to `false` for pure API routes (OData handles it internally) |

---

## package.json start script

```json
{
  "name": "approuter",
  "scripts": {
    "start": "node node_modules/@sap/approuter/approuter.js"
  },
  "dependencies": {
    "@sap/approuter": "^16.x.x"
  }
}
```

---

## Run locally with default-env.json

AppRouter needs to know where XSUAA and your backend are.
Create `app/router/default-env.json` (never commit this — add to `.gitignore`):

```json
{
  "destinations": [
    {
      "name": "srv-api",
      "url": "http://localhost:4004",
      "forwardAuthToken": true
    }
  ],
  "VCAP_SERVICES": {
    "xsuaa": [
      {
        "name": "bookshop-xsuaa",
        "label": "xsuaa",
        "plan": "application",
        "credentials": {
          "clientid": "sb-bookshop...",
          "clientsecret": "...",
          "url": "https://yourtenant.authentication.eu10.hana.ondemand.com",
          "xsappname": "bookshop"
        }
      }
    ]
  }
}
```

Copy `credentials` from your XSUAA service key (from BTP Cockpit).

### Start the full local stack

Terminal 1 — CAP backend:
```bash
cd bookshop
cds watch --profile hybrid
```

Terminal 2 — AppRouter:
```bash
cd app/router
npm start
```

AppRouter listens on **port 5000** by default. Open `http://localhost:5000` — you are redirected to XSUAA login, then back to your app.

---

## Change the AppRouter port

```bash
PORT=5001 npm start
```

Or add to `default-env.json`:
```json
{
  "PORT": 5001
}
```

---

## The most common AppRouter mistake

Setting `"authenticationMethod": "none"` globally in xs-app.json for local testing, then forgetting to change it before deploying. You end up with a publicly accessible app with no login. Always use `"authenticationMethod": "route"` and set individual routes to `"authenticationType": "none"` for genuinely public paths.
',
  2,
  'published'
);

INSERT INTO topics (module_id, number, slug, title, focus, description, content_md, order_index, status) VALUES (
  (SELECT id FROM modules WHERE course_id = 'dev-quickstart' AND number = '13'),
  '763',
  'dev-qs-auth-mta-wiring',
  'Wire XSUAA and AppRouter in mta.yaml',
  'Connect authentication and routing in the MTA descriptor for a complete deployable app',
  'Add XSUAA and AppRouter modules and resources to mta.yaml, understand the provides/requires URL passing pattern, and deploy the full authenticated stack to BTP.',
  '# Wire XSUAA and AppRouter in mta.yaml

This is where everything comes together. After this topic you have a complete, deployable, authenticated BTP application.

## The full picture

```
Internet
  │
  ▼
AppRouter (CF app)
  │  ① redirects to XSUAA for login
  │  ② gets JWT token back
  │  ③ forwards request + token to CAP backend
  │
  ▼
CAP Backend (CF app)
  │  ④ validates token against XSUAA
  │  ⑤ applies @restrict rules
  │
  ▼
SAP HANA (HDI container)
```

All three arrows — AppRouter → CAP, AppRouter → XSUAA, CAP → XSUAA — are wired via `mta.yaml`.

---

## Complete annotated mta.yaml

```yaml
_schema-version: "3.1"
ID: bookshop
version: 1.0.0
description: Bookshop — authenticated CAP app on BTP

modules:

  # ── 1. CAP Backend ───────────────────────────────────────────
  - name: bookshop-srv
    type: nodejs
    path: gen/srv
    parameters:
      buildpack: nodejs_buildpack
      memory: 256M
      disk-quota: 512M
    requires:
      - name: bookshop-hana      # HANA HDI container
      - name: bookshop-xsuaa     # XSUAA service instance
    provides:
      - name: srv-api             # exports the backend URL
        properties:
          srv-url: ${default-url} # CF resolves this to the real URL at deploy time

  # ── 2. HANA Deployer ─────────────────────────────────────────
  - name: bookshop-db-deployer
    type: hdb
    path: gen/db
    requires:
      - name: bookshop-hana

  # ── 3. AppRouter ─────────────────────────────────────────────
  - name: bookshop-app
    type: approuter.nodejs
    path: app/router              # the folder with xs-app.json + package.json
    parameters:
      memory: 128M
      disk-quota: 256M
    requires:
      - name: bookshop-xsuaa     # needs XSUAA for login
      - name: srv-api             # consumes the URL exported by bookshop-srv
        group: destinations       # injects it as a named destination
        properties:
          name: srv-api           # destination name used in xs-app.json
          url: ~{srv-url}         # ~{property} resolves from srv-api.provides
          forwardAuthToken: true  # appends the user''s JWT to proxied requests

resources:

  # ── HANA HDI container ───────────────────────────────────────
  - name: bookshop-hana
    type: org.cloudfoundry.managed-service
    parameters:
      service: hana
      service-plan: hdi-shared

  # ── XSUAA service instance ───────────────────────────────────
  - name: bookshop-xsuaa
    type: org.cloudfoundry.managed-service
    parameters:
      service: xsuaa
      service-plan: application
      path: ./xs-security.json    # the security descriptor from cds add xsuaa
```

---

## The provides / requires URL pattern explained

This is the part that trips up most people:

```yaml
# bookshop-srv EXPORTS its URL:
provides:
  - name: srv-api
    properties:
      srv-url: ${default-url}   # CF magic: resolves to https://bookshop-srv.cfapps.eu10...

# bookshop-app CONSUMES it:
requires:
  - name: srv-api
    group: destinations
    properties:
      url: ~{srv-url}           # ~{} reads from the srv-api.provides block
```

- `${default-url}` — a CF MTA placeholder; the deployer substitutes the app''s actual URL
- `~{srv-url}` — a cross-reference; reads the `srv-url` property from the `srv-api` provides block
- `group: destinations` — injects all properties under this requires block into the AppRouter''s `VCAP_APPLICATION.destinations` environment variable

This means AppRouter''s `xs-app.json` destination name `srv-api` resolves automatically — you never hard-code the backend URL.

---

## forwardAuthToken: true

Without this flag, AppRouter proxies the request **without** the user''s token. Your CAP service receives an unauthenticated request and returns 401 even though the user logged in.

Always set `forwardAuthToken: true` on any backend destination that uses `@requires`.

---

## Build and deploy the full stack

```bash
# 1. Compile
cds build --production

# 2. Package
mbt build

# 3. Deploy
cf deploy mta_archives/bookshop_1.0.0.mtar -f
```

The deployer will:
1. Create the `bookshop-hana` HDI container (if new)
2. Create the `bookshop-xsuaa` service instance using `xs-security.json` (if new)
3. Deploy HANA artifacts via `bookshop-db-deployer`
4. Start `bookshop-srv` bound to both HANA and XSUAA
5. Start `bookshop-app` (AppRouter) with the destination pointing at the live backend URL

---

## Assign role collections to your user

After first deployment:

1. Open BTP Cockpit → your subaccount → **Security** → **Users**
2. Find your user → **Assign Role Collection**
3. Assign the role collection you defined in `xs-security.json` (e.g. "Bookshop Admin")
4. Wait ~30 seconds for the token cache to expire, then open the app URL

If the user still gets 403, check:
```bash
cf logs bookshop-srv --recent | grep -i "scope\|403\|unauthorized"
```

---

## Common mta deploy errors with XSUAA

| Error | Cause | Fix |
|-------|-------|-----|
| `Error creating service bookshop-xsuaa: invalid scope name` | Scope doesn''t start with `$XSAPPNAME.` | Fix xs-security.json |
| `403 on all endpoints after login` | `forwardAuthToken: true` missing | Add it to AppRouter destination |
| `redirect_uri_mismatch` | XSUAA `redirect-uris` in xs-security.json doesn''t match app URL | Add `*.hana.ondemand.com/**` wildcard |
| `AppRouter fails to start: Cannot find module...` | `@sap/approuter` not in `app/router/package.json` | `cd app/router && npm install` |
| `JWT token expired` during testing | Default token lifetime is 12 hours | Re-login; for CI use client_credentials grant |
',
  3,
  'published'
);
