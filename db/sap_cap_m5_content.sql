-- ============================================================
-- SAP CAP Course — Module 5: Authentication & Authorization
-- Run AFTER sap_cap_seed.sql
-- Lessons: cap-47 through cap-56 (10 lessons)
-- ============================================================

-- ── Lesson 47 — BTP Security Fundamentals ────────────────────────────────────

UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 47 — BTP Security Fundamentals

## What you'll learn
- BTP identity architecture: IAS, XSUAA, and their relationship
- OAuth 2.0 flows relevant to CAP apps
- JWT token structure and what CAP reads from it
- How `req.user` is populated from the token
- The path from browser login to CAP handler

## Why this matters
Security in BTP is a layer cake. Misunderstanding one layer causes either a broken app (users can't log in) or an insecure one (the wrong users can). Starting with the architecture means you can debug auth issues systematically instead of guessing.

## BTP identity layer

```
┌─────────────────────────────────────────────────────────┐
│                 BTP Identity Flow                        │
│                                                          │
│  Browser ──login──► IAS ──SAML──► XSUAA ──JWT──► CAP    │
│                                                          │
│  IAS:   Corporate identity provider (SSO, MFA)           │
│  XSUAA: BTP authorization server (OAuth 2.0, roles)     │
│  CAP:   Reads JWT, populates req.user                   │
└─────────────────────────────────────────────────────────┘
```

## OAuth 2.0 flows in BTP

| Flow | Use case | Who calls it |
|---|---|---|
| Authorization Code + PKCE | Browser SPA (Fiori) | Fiori app / AppRouter |
| Client Credentials | Service-to-service | CAP → external service |
| JWT Bearer | Principal propagation | CAP → S/4HANA |
| Password | Legacy / testing only | CLI tools |

## JWT token structure

```json
{
  "iss":  "https://mysubdomain.authentication.eu10.hana.ondemand.com",
  "sub":  "user-uuid-abc123",
  "exp":   1726524000,
  "iat":   1726520400,
  "jti":  "unique-token-id",

  "user_name":    "alice@company.com",
  "given_name":   "Alice",
  "family_name":  "Smith",
  "email":        "alice@company.com",
  "zid":          "tenant-id",       // tenant identifier

  "scope": ["bookshop.Admin", "bookshop.Buyer", "openid"],

  "xs.user.attributes": {
    "region":     ["EMEA"],
    "costCenter": ["CC-1001"]
  }
}
```

## What req.user provides

```js
this.on('READ', 'Orders', (req) => {
  console.log(req.user.id)           // 'alice@company.com'
  console.log(req.user.name)         // 'Alice Smith'
  console.log(req.user.locale)       // 'en-US'
  console.log(req.user.tenant)       // 'my-subaccount-id'
  console.log(req.user.tokenInfo)    // raw JWT claims (when needed)

  console.log(req.user.is('Admin'))      // true if scope includes bookshop.Admin
  console.log(req.user.is('Buyer'))      // true if scope includes bookshop.Buyer
  console.log(req.user.attr.region)      // ['EMEA']
  console.log(req.user.attr.costCenter)  // ['CC-1001']
})
```

## Token validation by CAP

When a request arrives:
1. CAP extracts `Authorization: Bearer <token>` header
2. Validates signature using XSUAA's public key (fetched from JWKS endpoint)
3. Checks expiry (`exp` claim)
4. Populates `req.user` from validated claims
5. Rejects with 401 if token is missing/invalid

```json
// .cdsrc.json — enables JWT validation
{
  "requires": {
    "auth": {
      "[production]": {
        "kind": "xsuaa"
      },
      "[development]": {
        "kind": "mocked",
        "users": {
          "alice": { "roles": ["Admin"] },
          "bob":   { "roles": ["Buyer"] }
        }
      }
    }
  }
}
```

## AppRouter — the front door

```
Browser ──► AppRouter (Node.js) ──► XSUAA (auth code flow)
                   │
                   └──► CAP backend (attaches JWT, forwards request)
```

The AppRouter handles:
- Redirecting unauthenticated users to XSUAA login page
- Exchanging auth code for JWT
- Attaching JWT to upstream requests to CAP
- Session management (stores JWT in server-side session)

## Common auth debugging steps

```bash
# 1. Decode the JWT (without verifying signature)
echo '<jwt>' | cut -d '.' -f 2 | base64 -d | jq .

# 2. Check XSUAA JWKS endpoint is reachable
curl https://mysubdomain.authentication.eu10.hana.ondemand.com/.well-known/openid-configuration

# 3. Check CAP logs for auth errors
cf logs bookshop-srv --recent | grep -i 'auth\|401\|403'

# 4. Inspect req.user in a handler
this.before('*', '*', (req) => console.log('User:', JSON.stringify(req.user)))
```

## Hands-on exercise
1. Add `"auth": { "[development]": { "kind": "mocked", ... } }` to `.cdsrc.json` with 3 users
2. Start `cds watch` and call an endpoint with `Authorization: Basic alice:alice`
3. Add a `this.before('*', '*', ...)` that logs `req.user.id` and `req.user.roles`
4. Verify different users get different scopes

## Checkpoint ✓
- [ ] IAS handles corporate SSO; XSUAA handles OAuth 2.0 and role mapping
- [ ] JWT contains: user_name, scope (roles), tenant (zid), user attributes
- [ ] `req.user.is('RoleName')` checks if the scope contains the app's role prefix
- [ ] AppRouter handles the auth code flow and attaches the JWT before CAP sees the request
$md$
WHERE slug = 'cap-47-security-basics';

-- ── Lesson 48 — XSUAA Service Setup ──────────────────────────────────────────

UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 48 — XSUAA Service Setup

## What you'll learn
- Creating and binding the XSUAA service instance
- The `xs-security.json` file — basic structure
- OAuth client credentials vs authorization code flow
- Binding XSUAA to your CAP app
- Testing JWT validation locally

## Why this matters
XSUAA is the gate between the internet and your CAP app. Setting it up correctly — with the right scopes, the right oauth2-configuration, and the right service key — is the foundation for all authorization work. One misconfiguration here causes 401/403 errors everywhere.

## Creating XSUAA via BTP Cockpit

1. BTP Cockpit → Subaccount → Service Marketplace → Authorization & Trust Management Service (XSUAA)
2. Select plan: `application` (for browser + CAP apps)
3. Click "Create" → enter service instance name (e.g., `bookshop-xsuaa`)
4. Provide `xs-security.json` as service parameters

## xs-security.json — minimum viable

```json
{
  "xsappname":    "bookshop",
  "tenant-mode":  "dedicated",
  "scopes": [
    { "name": "$XSAPPNAME.Admin",  "description": "Full access"    },
    { "name": "$XSAPPNAME.Buyer",  "description": "Buy books"      },
    { "name": "$XSAPPNAME.Reader", "description": "Browse catalog" }
  ],
  "role-templates": [
    {
      "name":        "Admin",
      "description": "Administrator role",
      "scope-references": ["$XSAPPNAME.Admin"]
    },
    {
      "name":        "Buyer",
      "description": "Buyer role",
      "scope-references": ["$XSAPPNAME.Buyer", "$XSAPPNAME.Reader"]
    }
  ],
  "oauth2-configuration": {
    "token-validity":    43200,
    "redirect-uris":     ["https://your-app.cfapps.eu10.hana.ondemand.com/**"]
  }
}
```

## Create service via CF CLI

```bash
# Create XSUAA service instance
cf create-service xsuaa application bookshop-xsuaa \
  -c xs-security.json

# Update after changing xs-security.json
cf update-service bookshop-xsuaa -c xs-security.json

# Create a service key for local development
cf create-service-key bookshop-xsuaa bookshop-xsuaa-key
cf service-key bookshop-xsuaa bookshop-xsuaa-key
# Copy the credentials JSON
```

## Binding to the CAP app

```yaml
# mta.yaml
modules:
  - name: bookshop-srv
    type: nodejs
    requires:
      - name: bookshop-xsuaa  # binds the XSUAA service

resources:
  - name: bookshop-xsuaa
    type: org.cloudfoundry.managed-service
    parameters:
      service:      xsuaa
      service-plan: application
      path:         ./xs-security.json
```

## Local testing with service key

```bash
# Create .env with VCAP_SERVICES from the service key
export XSUAA_CREDENTIALS=$(cf service-key bookshop-xsuaa bookshop-xsuaa-key | tail -n +2)

# Or write to .env (add to .gitignore!)
echo "VCAP_SERVICES=$(cf service-key bookshop-xsuaa bookshop-xsuaa-key | tail -n +2 | \
  python3 -c 'import sys,json; creds=json.load(sys.stdin); print(json.dumps({"xsuaa":[{"credentials":creds}]}))')" > .env
```

```json
// .cdsrc.json
{
  "requires": {
    "auth": {
      "[production]": {
        "kind": "xsuaa",
        "vcap": { "label": "xsuaa" }
      }
    }
  }
}
```

## Getting a test JWT (client credentials flow)

```bash
# Get a JWT for service-to-service testing
CLIENT_ID=<from service key>
CLIENT_SECRET=<from service key>
TOKEN_URL=<from service key uaadomain>/oauth/token

curl -s -X POST "$TOKEN_URL" \
  -u "$CLIENT_ID:$CLIENT_SECRET" \
  -d "grant_type=client_credentials&response_type=token" \
  | jq .access_token
```

```http
### Use the token in a request
GET http://localhost:4004/catalog/Books
Authorization: Bearer <access_token>
```

## Rotate XSUAA credentials

```bash
# Regenerate the client secret (rotates credentials)
cf delete-service-key bookshop-xsuaa bookshop-xsuaa-key
cf create-service-key bookshop-xsuaa bookshop-xsuaa-key

# Re-create .env with new credentials
```

## Hands-on exercise
1. Create an XSUAA service instance with Admin and Buyer roles in your BTP trial
2. Create a service key and configure `.env`
3. Run `cds watch` with production auth profile and request a JWT via client credentials
4. Use the JWT in a REST client request and verify `req.user` is populated

## Checkpoint ✓
- [ ] `xsappname` in `xs-security.json` is the prefix for all scope names
- [ ] Service binding injects XSUAA credentials via `VCAP_SERVICES`
- [ ] Client credentials flow gives a service token (no user context)
- [ ] `cf update-service -c xs-security.json` applies changes to an existing instance
$md$
WHERE slug = 'cap-48-xsuaa';


-- ── Lesson 49 — xs-security.json Deep Dive ───────────────────────────────────

UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 49 — xs-security.json Deep Dive

## What you'll learn
- Full `xs-security.json` vocabulary: scopes, attributes, role templates, role collections
- `$XSAPPNAME` placeholder — why it's essential
- User attributes for dynamic authorization
- Instance-level vs cross-subaccount scopes
- Token format configuration

## Why this matters
`xs-security.json` is the security contract for your app. Every scope, role, and attribute you'll use in `@requires` and `@restrict` CDS annotations must be declared here first. Knowing the full vocabulary means you can express any authorization requirement without working around the framework.

## Complete xs-security.json structure

```json
{
  "xsappname":   "bookshop",
  "tenant-mode": "dedicated",

  "scopes": [
    {
      "name":         "$XSAPPNAME.Admin",
      "description":  "Full administrative access"
    },
    {
      "name":         "$XSAPPNAME.Buyer",
      "description":  "Purchase books"
    },
    {
      "name":         "$XSAPPNAME.ViewReports",
      "description":  "View sales reports",
      "granted-apps": ["$XSAPPNAME"]   // restricts who can grant this scope
    }
  ],

  "attributes": [
    {
      "name":        "region",
      "description": "Sales region assigned to the user",
      "valueType":   "string"
    },
    {
      "name":        "costCenter",
      "description": "User's cost center",
      "valueType":   "string"
    }
  ],

  "role-templates": [
    {
      "name":             "Admin",
      "description":      "Administrator",
      "scope-references": ["$XSAPPNAME.Admin"],
      "attribute-references": []
    },
    {
      "name":             "RegionalBuyer",
      "description":      "Buyer with region restriction",
      "scope-references": ["$XSAPPNAME.Buyer"],
      "attribute-references": [
        { "name": "region" }   // ← attribute available in this role
      ]
    }
  ],

  "oauth2-configuration": {
    "token-validity":     43200,
    "refresh-token-validity": 2592000,
    "redirect-uris": [
      "https://*.cfapps.eu10.hana.ondemand.com/**",
      "http://localhost:5000/**"
    ],
    "system-attributes": ["groups", "rolecollections"],
    "user-attributes":   ["region", "costCenter"]
  }
}
```

## Scopes vs role templates vs role collections

```
xs-security.json defines:
  scope          → atomic permission (e.g., bookshop.Admin)
  role-template  → named group of scopes (e.g., Admin = [bookshop.Admin])

BTP Cockpit defines:
  role           → instance of a role template (admin can add attributes)
  role-collection → named group of roles (e.g., "Bookshop Admins" = [Admin role])

User assignment:
  BTP user → assigned to role-collection → gets the scopes → CAP reads from JWT
```

## User attributes in JWT

After assigning a role with attributes to a user:

```json
// Decoded JWT — attributes from xs-security.json
{
  "user_name": "alice",
  "scope":     ["bookshop.Buyer"],
  "xs.user.attributes": {
    "region":     ["EMEA", "NA"],    // user has both regions
    "costCenter": ["CC-1001"]
  }
}
```

```js
// In CAP handler
req.user.attr.region      // ['EMEA', 'NA']
req.user.attr.costCenter  // ['CC-1001']
```

## $XSAPPNAME placeholder — why it matters

```json
// WRONG — hardcoded app name
{ "name": "bookshop.Admin" }

// CORRECT — $XSAPPNAME is substituted at runtime
{ "name": "$XSAPPNAME.Admin" }
// Becomes: "bookshop.Admin" in dedicated tenant
// Becomes: "bookshop!t<tenant-id>.Admin" in shared tenant mode
```

Always use `$XSAPPNAME`. Hardcoded names break multitenant deployments.

## Multitenant vs dedicated

```json
// Dedicated — one subaccount, one XSUAA instance (most apps start here)
{ "tenant-mode": "dedicated" }

// Shared — same XSUAA serves multiple subscriber tenants (SaaS)
{ "tenant-mode": "shared" }
```

## Token validity tuning

```json
"oauth2-configuration": {
  "token-validity":         3600,     // 1 hour (access token)
  "refresh-token-validity": 1209600,  // 14 days (refresh token)
  "autoapprove":            true,     // skip consent screen for trusted apps
  "allowedproviders":       ["sap.default"]   // restrict to SAP IdP
}
```

## Hands-on exercise
1. Add a `region` attribute to your XSUAA configuration
2. Create a `RegionalBuyer` role template that includes the `region` attribute
3. In BTP Cockpit, create a role instance and assign `region=EMEA` to your user
4. Log in and decode your JWT — verify `xs.user.attributes.region` is present

## Checkpoint ✓
- [ ] Always use `$XSAPPNAME` prefix for scope names — never hardcode the app name
- [ ] Attributes in `xs-security.json` must be declared before use in `@restrict where`
- [ ] Role templates → Roles (in Cockpit, with attribute values) → Role Collections → User assignment
- [ ] `tenant-mode: dedicated` for single-tenant; `shared` for multitenant SaaS
$md$
WHERE slug = 'cap-49-xs-security';

-- ── Lesson 50 — Roles, Scopes & Role Collections ─────────────────────────────

UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 50 — Roles, Scopes & Role Collections

## What you'll learn
- Mapping xs-security.json roles to BTP Cockpit role collections
- Assigning role collections to users and user groups
- JWT debugger — inspecting what a user actually gets
- Scope prefixes — `$XSAPPNAME` expansion
- Service-to-service scopes (client credentials)

## Why this matters
You can write perfect CDS security annotations and still have 403 errors because the role isn't assigned in BTP Cockpit. Understanding the assignment chain — scope → role template → role → role collection → user — lets you diagnose any "access denied" quickly.

## The assignment chain

```
xs-security.json                    BTP Cockpit
──────────────────                  ───────────────────────
scope: bookshop.Admin          ←──  role-template "Admin" references it
                                         │
                               ──────────┘
                              role "Bookshop Admin" (instance of template)
                                   │ (with optional attribute values)
                              role collection "Bookshop Administrators"
                                   │
                              User: alice@company.com  ← assigned here
```

## Step-by-step in BTP Cockpit

1. **Security → Roles** → Find role templates for your app
2. Click `+` to create a role from a template → set attribute values if any
3. **Security → Role Collections** → Create "Bookshop Admins"
4. Edit → Add Roles → find and add "Bookshop Admin"
5. **Security → Users** → Find `alice@company.com`
6. Assign Role Collections → "Bookshop Admins"

## Automated role assignment via Cockpit API

For CI/CD:
```bash
# Using BTP CLI
btp assign security/role-collection "Bookshop Admins" \
  --to-user alice@company.com \
  --subaccount <id>
```

## JWT scope format

```json
// Alice's JWT after role collection assignment
{
  "scope": [
    "bookshop.Admin",       // from xs-security.json scope name
    "openid",               // standard OIDC scope
    "uaa.user"              // XSUAA internal scope
  ]
}
```

```js
// CAP strips the app prefix automatically
req.user.is('Admin')    // true — checks scope includes 'bookshop.Admin'
req.user.roles          // ['Admin'] — stripped of 'bookshop.' prefix
```

## JWT debugger — verify what Alice actually gets

```bash
# Get Alice's JWT (password flow — dev only)
curl -s -X POST "https://<subdomain>.authentication.eu10.hana.ondemand.com/oauth/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -u "$CLIENT_ID:$CLIENT_SECRET" \
  -d "grant_type=password&username=alice&password=<pass>&scope=openid" \
  | jq .access_token -r \
  | cut -d'.' -f2 | base64 -d 2>/dev/null | jq .scope
```

Or use [jwt.io](https://jwt.io) — paste the token, check `scope` array.

## Service-to-service scopes (client credentials)

When CAP calls an external service:

```json
// xs-security.json — declare what this app can grant to callers
{
  "scopes": [
    {
      "name":        "$XSAPPNAME.Integrate",
      "description": "Allow external services to call this app",
      "granted-apps": ["<other-app-xsappname>"]   // only this app can get the scope
    }
  ]
}
```

```js
// External CAP service calling this app
const externalClient = await cds.connect.to('BookshopAPI')
// Uses client credentials with 'bookshop.Integrate' scope
// No user in req.user.id — it's a service call
req.user.is('system-user')   // true for service-to-service calls
```

## Role collection templates in mta.yaml (auto-assignment on deploy)

```yaml
# mta.yaml
modules:
  - name: bookshop-srv
    parameters:
      role-collections:
        - name: "Bookshop Admins"
          description: "Full admin access to Bookshop"
          role-template-references:
            - "$XSAPPNAME.Admin"
        - name: "Bookshop Buyers"
          description: "Purchase books"
          role-template-references:
            - "$XSAPPNAME.Buyer"
```

These role collections are created automatically on `cf deploy`.

## Hands-on exercise
1. In BTP Cockpit, create roles from your Admin and Buyer templates
2. Create role collections "Bookshop Admins" and "Bookshop Buyers"
3. Assign your test user to "Bookshop Admins"
4. Get a JWT and verify the scope array contains `bookshop.Admin`
5. Test a `@requires: 'Buyer'` protected endpoint — verify you get 403 without the Buyer scope

## Checkpoint ✓
- [ ] Scope → role template (xs-security.json) → role → role collection (Cockpit) → user (Cockpit)
- [ ] CAP's `req.user.is('RoleName')` checks the JWT scope for `xsappname.RoleName`
- [ ] Service-to-service calls use client credentials — `req.user` has no personal info
- [ ] Role collections in `mta.yaml` are created automatically on `cf deploy`
$md$
WHERE slug = 'cap-50-role-collections';


-- ── Lesson 51 — @requires & @restrict Annotations ────────────────────────────

UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 51 — @requires & @restrict Annotations

## What you'll learn
- `@requires` — coarse-grained role-based access control
- `@restrict` — fine-grained instance-based authorization with WHERE
- Applying both at service, entity, and operation level
- Testing with mock users
- Priority and override rules

## Why this matters
`@requires` and `@restrict` are declarative security — they express authorization rules in CDS, not in handler code. This keeps security concerns out of business logic, makes the rules auditable in the model, and lets CAP enforce them automatically before any handler runs.

## @requires — role check

```cds
// Service level — all operations require this role
service AdminService @(requires: 'admin') {
  entity Users as projection on my.Users;
}

// Entity level — override service-level for one entity
service CatalogService @(requires: 'authenticated-user') {
  entity Books   as projection on my.Books;   // inherits authenticated-user
  entity Reports as projection on my.Reports  // stricter: requires Analyst role
    @(requires: 'Analyst');
}

// Operation level — different roles for different operations
service OrdersService @(requires: 'authenticated-user') {
  entity Orders as projection on my.Orders
    @(requires: {
      READ:   'authenticated-user',    // anyone logged in can read
      CREATE: 'Buyer',                  // only Buyers can create
      UPDATE: 'Buyer',
      DELETE: 'Admin'                   // only Admin can delete
    });
}
```

## @restrict — role + WHERE clause

```cds
service OrdersService {
  entity Orders as projection on my.Orders
    @(restrict: [
      // Admins: full access, no WHERE
      { grant: '*',      to: 'Admin' },

      // Buyers: can only read/write their own orders
      { grant: ['READ','WRITE'], to: 'Buyer', where: 'buyer_ID = $user' },

      // Auditors: read-only, closed orders only
      { grant: 'READ',   to: 'Auditor', where: 'status = ''CLOSED''' }
    ]);
}
```

## Combining @requires and @restrict

```cds
// @requires = gate: who can enter the service at all
// @restrict = filter: what they see/can do once inside

service OrdersService @(requires: 'authenticated-user') {
  entity Orders as projection on my.Orders
    @(restrict: [
      { grant: '*',    to: 'Admin'   },
      { grant: 'READ', to: 'Auditor', where: 'status = ''CLOSED''' },
      { grant: ['READ','WRITE'], to: 'Buyer', where: 'buyer_ID = $user' }
    ]);
}
```

`@requires: 'authenticated-user'` rejects anonymous; `@restrict` filters within the authenticated population.

## Actions and functions

```cds
service OrdersService @(requires: 'authenticated-user') {
  entity Orders as projection on my.Orders
    @(restrict: [{ grant: 'READ', to: 'Buyer', where: 'buyer_ID = $user' }]);

  // Action requires specific role
  action  cancelOrder (ID: UUID) @(requires: 'Admin');
  function getStats ()           @(requires: ['Admin','Analyst']);
}
```

## User attributes in WHERE clause

```cds
entity SalesOrders as projection on my.SalesOrders
  @(restrict: [{
    grant: 'READ',
    to:    'SalesPerson',
    where: 'region = $user.attr.region'   // resolved from JWT attribute
  }]);
```

## Built-in pseudo-roles

| Pseudo-role | Meaning |
|---|---|
| `'any'` | No authentication required |
| `'authenticated-user'` | Any logged-in user |
| `'identified-user'` | User with an identity (may include service users) |
| `'system-user'` | Service-to-service calls (client credentials JWT) |

## Mock users for testing

```json
// .cdsrc.json
{
  "requires": {
    "auth": {
      "[development]": {
        "kind": "mocked",
        "users": {
          "alice": {
            "password": "alice",
            "roles":    ["Buyer"],
            "attr":     { "region": "EMEA" }
          },
          "bob-admin": {
            "password": "admin",
            "roles":    ["Admin"]
          },
          "guest": {
            "password":      "guest",
            "roles":         [],
            "authenticated": false
          }
        }
      }
    }
  }
}
```

```http
### Test as Alice (Buyer)
GET http://localhost:4004/orders/Orders
Authorization: Basic alice:alice

### Test as Bob (Admin)
GET http://localhost:4004/orders/Orders
Authorization: Basic bob-admin:admin
```

## Testing with cds.test

```js
const { GET, DELETE } = cds.test('.').in(__dirname + '/..')

it('buyer can only see own orders', async () => {
  const { data } = await GET('/orders/Orders', {
    headers: { Authorization: 'Basic alice:alice' }
  })
  expect(data.value.every(o => o.buyer_ID === 'alice')).toBe(true)
})

it('buyer cannot delete orders', async () => {
  const { status } = await DELETE('/orders/Orders(order-id)', {
    headers: { Authorization: 'Basic alice:alice' }
  })
  expect(status).toBe(403)
})
```

## Priority rules

1. More specific annotations override less specific
2. Operation-level `@restrict` overrides entity-level
3. Entity-level overrides service-level
4. `@restrict` always wins over `@requires` when both present at the same level

## Checkpoint ✓
- [ ] `@requires: 'RoleName'` is a gate — 403 if the user doesn't have the role
- [ ] `@restrict` with `where` auto-applies a filter to every query for that role
- [ ] `$user` = `req.user.id`; `$user.attr.region` = JWT attribute value
- [ ] Mock users in `.cdsrc.json` with `kind: mocked` enable local auth testing
$md$
WHERE slug = 'cap-51-requires';

-- ── Lesson 52 — JWT Token Handling in Handlers ───────────────────────────────

UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 52 — JWT Token Handling in Handlers

## What you'll learn
- Everything in `req.user` and how to access it
- Reading custom XSUAA attributes from the token
- Propagating the user context to downstream services
- Service-to-service token exchange
- When NOT to trust the token (security pitfalls)

## Why this matters
Custom handlers sometimes need to make auth decisions that CDS annotations can't express — combining multiple attributes, checking group membership, or calling a permission service. Knowing the full req.user API and how to access raw token claims gives you that flexibility.

## req.user API reference

```js
this.on('*', '*', (req) => {
  // Identity
  req.user.id           // 'alice@company.com' (user_name from JWT)
  req.user.name         // 'Alice Smith' (given_name + family_name)
  req.user.email        // 'alice@company.com' (email from JWT)
  req.user.locale       // 'en-US' (locale from JWT or Accept-Language)

  // Authorization
  req.user.roles        // ['Admin'] — scopes stripped of app prefix
  req.user.is('Admin')  // true if 'bookshop.Admin' in JWT scope
  req.user.is('Admin', 'Buyer')  // true if EITHER role
  req.user.hasScope('bookshop.Admin')  // exact scope check (with prefix)

  // Attributes
  req.user.attr.region      // ['EMEA'] — from xs.user.attributes
  req.user.attr.costCenter  // ['CC-1001']

  // Tenant
  req.user.tenant      // 'abc-123' — zid from JWT

  // Raw token
  req.user.tokenInfo.getTokenInfo().userInfo  // full JWT payload
})
```

## Reading raw JWT claims

```js
const tokenInfo = req.user.tokenInfo
if (tokenInfo) {
  const claims = tokenInfo.getTokenInfo()
  const groups  = claims.userInfo['xs.system.attributes']?.['xs.saml.groups'] || []
  const grantType = claims.userInfo['grant_type']  // 'client_credentials' for service tokens
}
```

## Implementing role-based logic in handlers

```js
this.on('READ', 'Orders', async (req) => {
  const { user } = req

  // Multi-condition authorization
  if (user.is('Admin')) {
    return SELECT.from('Orders')   // admins see all
  }

  if (user.is('RegionalManager')) {
    const regions = user.attr.region || []
    return SELECT.from('Orders').where({ region: { in: regions } })
  }

  if (user.is('Buyer')) {
    return SELECT.from('Orders').where({ buyer_ID: user.id })
  }

  // No matching role
  return req.reject(403, 'Insufficient permissions')
})
```

## Detecting service-to-service calls

```js
this.before('*', '*', (req) => {
  // Service tokens have grant_type = 'client_credentials'
  // and no personal user info
  const isServiceCall = !req.user.id || req.user.id === '$system'
  if (isServiceCall) {
    // Audit differently for service calls
    console.log('Service call:', req.event, 'on', req.target?.name)
  }
})
```

## Forwarding the JWT to downstream services

```js
// When CAP calls another service, it needs to propagate the user context
const bpService = await cds.connect.to('BusinessPartnerAPI')

this.on('READ', 'Suppliers', async (req) => {
  // CAP automatically forwards the JWT when using req.query delegation
  return bpService.run(req.query)
  // The JWT is attached to the outbound request automatically
})
```

## Manual token exchange (principal propagation)

```js
// When you need to call an HTTP endpoint directly (not via cds.connect.to)
const { tokenInfo } = req.user
const destService = await cds.connect.to('destination-service')

const options = await destService.getOptions({
  destinationName:   'S4HANA_SYSTEM',
  tokenExchangeType: 'UserTokenToIdToken',
  userToken:         tokenInfo.getTokenValue()
})

const response = await axios.get(`${options.url}/api/endpoint`, {
  headers: options.headers   // includes exchanged token
})
```

## Security pitfalls

```js
// WRONG — never trust client-provided user data
this.before('CREATE', 'Orders', (req) => {
  req.data.buyer_ID = req.data.buyer_ID  // client can fake this!
})

// CORRECT — always use token-verified identity
this.before('CREATE', 'Orders', (req) => {
  req.data.buyer_ID = req.user.id   // from validated JWT
})

// WRONG — never log JWT tokens
console.log('Token:', req.user.tokenInfo)  // logs secret

// WRONG — never expose tokenInfo to clients
return req.user.tokenInfo  // leaks internal token
```

## Hands-on exercise
1. Add a handler that reads `req.user.attr.region` and filters Orders by region
2. Detect service-to-service calls (no `req.user.id`) and log them separately
3. Override the buyer_ID in a BEFORE CREATE handler with `req.user.id`
4. Write a test that verifies the buyer_ID cannot be spoofed by the client

## Checkpoint ✓
- [ ] `req.user.is('Role')` checks scopes (stripped of app prefix)
- [ ] `req.user.attr.attrName` reads user attributes from the JWT
- [ ] Always set security-relevant fields (buyer_ID, tenant_ID) from `req.user` — never from request body
- [ ] CAP auto-propagates the JWT when delegating via `cds.connect.to()` + `bpService.run(req.query)`
$md$
WHERE slug = 'cap-52-jwt';


-- ── Lesson 53 — Mock Authentication in Development ───────────────────────────

UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 53 — Mock Authentication in Development

## What you'll learn
- Full mocked auth configuration in `.cdsrc.json`
- Simulating multiple roles, attributes, and tenants
- Writing authenticated integration tests with `cds.test`
- Debugging auth issues in development
- Switching between mock and real XSUAA

## Why this matters
Every developer needs to test auth scenarios locally — without an XSUAA service instance, without network latency, without shared credentials. The mocked auth system gives you a production-faithful simulation that runs entirely offline.

## Full mock configuration

```json
// .cdsrc.json
{
  "requires": {
    "auth": {
      "[development]": {
        "kind": "mocked",
        "users": {
          "alice": {
            "ID":       "alice",
            "password": "alice",
            "roles":    ["Buyer"],
            "attr": {
              "region":     "EMEA",
              "costCenter": "CC-1001"
            },
            "tenant": "tenant-A"
          },
          "bob": {
            "ID":       "bob",
            "password": "bob",
            "roles":    ["Admin","Buyer"],
            "attr": {
              "region":     "NA"
            },
            "tenant": "tenant-A"
          },
          "carol-analyst": {
            "ID":       "carol",
            "password": "carol",
            "roles":    ["Analyst"],
            "tenant":   "tenant-B"
          },
          "*": {
            "roles": [],
            "tenant": "tenant-default"
          }
        }
      },
      "[production]": {
        "kind": "xsuaa"
      }
    }
  }
}
```

`"*"` defines the default user — anyone with an unknown username gets these settings.

## HTTP Basic auth in development

```http
### As Alice (Buyer, EMEA)
GET http://localhost:4004/orders/Orders
Authorization: Basic alice:alice

### As Bob (Admin + Buyer, NA)
POST http://localhost:4004/orders/Orders
Authorization: Basic bob:bob
Content-Type: application/json

{ "title": "Test Order" }

### Unauthenticated
GET http://localhost:4004/orders/Orders
# No Authorization header — gets 401 if service requires authentication
```

## cds.test with mock users

```js
// test/orders.test.js
const cds = require('@sap/cds')

describe('Order Service', () => {
  // Set up test suite
  const alice = { user: 'alice', password: 'alice' }
  const bob   = { user: 'bob',   password: 'bob'   }

  const { GET, POST, DELETE } = cds.test('.').in(__dirname + '/..')

  it('Alice can read own orders', async () => {
    const { status, data } = await GET('/orders/Orders', { auth: alice })
    expect(status).toBe(200)
    expect(data.value.every(o => o.buyer_ID === 'alice')).toBe(true)
  })

  it('Alice cannot delete orders', async () => {
    const { status } = await DELETE('/orders/Orders(some-uuid)', { auth: alice })
    expect(status).toBe(403)
  })

  it('Bob can delete orders', async () => {
    const { status } = await DELETE('/orders/Orders(some-uuid)', { auth: bob })
    expect(status).toBe(204)
  })

  it('Unauthenticated users get 401', async () => {
    const { status } = await GET('/orders/Orders')
    expect(status).toBe(401)
  })
})
```

## Testing multi-tenant scenarios

```json
// .cdsrc.json — tenants in mock config
"carol-analyst": {
  "tenant": "tenant-B"    // different tenant from alice/bob
}
```

```js
it('tenant B cannot see tenant A data', async () => {
  const carol = { user: 'carol-analyst', password: 'carol' }
  const { data } = await GET('/orders/Orders', { auth: carol })
  // Orders created by tenant-A users should not appear for tenant-B
  expect(data.value).toHaveLength(0)
})
```

## Switching to real XSUAA (per-profile)

```bash
# Dev: use mocked auth
cds watch

# Staging: use real XSUAA
CDS_ENV=staging cds watch
# → picks up [staging] profile → "kind": "xsuaa"
```

## Debugging auth in development

```js
// Log every request's auth context
this.before('*', '*', (req) => {
  console.log({
    event:  req.event,
    target: req.target?.name,
    user:   req.user?.id,
    roles:  req.user?.roles,
    tenant: req.user?.tenant,
    attr:   req.user?.attr
  })
})
```

```bash
# Check auth headers in cds watch output
cds watch --verbose
# Enables request/response logging including auth
```

## Edge cases to test

```
□ Unauthenticated request → 401
□ Authenticated, wrong role → 403
□ Authenticated, correct role, own data → 200
□ Authenticated, correct role, other user's data → filtered (not 403)
□ Admin role → sees all data
□ Service-to-service (no user) → check handling
□ Expired token simulation → not easy in dev, test on staging
```

## Hands-on exercise
1. Add 4 mock users: alice (Buyer), bob (Admin), carol (Analyst), david (no roles)
2. Write integration tests covering all 4 users for your Orders service
3. Add a test for multi-tenant isolation between alice and carol
4. Add a BEFORE handler that logs the auth context — run tests and verify the log

## Checkpoint ✓
- [ ] Mock users in `.cdsrc.json` support roles, attributes, and tenant simulation
- [ ] `cds.test()` with `{ auth: { user, password } }` simulates authenticated requests
- [ ] `"*"` user in mock config is the fallback for undefined users
- [ ] Switch profiles (`CDS_ENV=staging`) to test against real XSUAA
$md$
WHERE slug = 'cap-53-mock-auth';

-- ── Lesson 54 — SAP Identity Authentication Service (IAS) ────────────────────

UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 54 — SAP Identity Authentication Service (IAS)

## What you'll learn
- IAS role and capabilities in BTP
- Setting up IAS as the identity provider for your BTP subaccount
- Configuring SAML trust between IAS and XSUAA
- Custom attributes from IAS user profile
- SSO across BTP apps

## Why this matters
XSUAA is the authorization server. IAS is the authentication server — it handles passwords, MFA, and corporate SSO (connecting to Active Directory or other IdPs). Most enterprise BTP apps eventually integrate IAS for central user management.

## IAS vs XSUAA — quick distinction

```
IAS  = WHO is the user? (authentication, MFA, corporate SSO, user directory)
XSUAA = WHAT can they do? (OAuth 2.0, scopes, role templates, JWT issuance)
```

Typical flow:
```
Browser → AppRouter → XSUAA (authorization code) → XSUAA redirects to IAS → IAS authenticates
→ sends SAML assertion → XSUAA issues JWT with scopes → CAP validates JWT
```

## IAS tenant setup

1. BTP Cockpit → Subaccount → Trust Configuration
2. Click "Establish Trust" → choose IAS tenant
3. BTP automatically creates a SAML trust between IAS and XSUAA
4. Download the metadata, upload to IAS if not auto-registered

## IAS application configuration

In IAS admin console (accounts.ondemand.com/<tenant>):
1. Applications → Add → Web Application
2. Name: "Bookshop"
3. SAML 2.0 → Upload XSUAA metadata
4. Subject Name Identifier: User UUID or email

## Custom user attributes from IAS

IAS can pass custom attributes from the corporate user directory to XSUAA:

```
Corporate AD → IAS (custom schema attributes) → SAML assertion → XSUAA → JWT
```

1. In IAS: User Attributes → Add custom attribute (e.g., `costCenter` from AD attribute)
2. Map to SAML assertion attribute name
3. In xs-security.json: declare the attribute under `attributes`
4. XSUAA includes it in JWT `xs.user.attributes`

## Risk-based authentication (MFA)

```
IAS authentication policy:
- Low risk: standard login
- Medium risk: email OTP
- High risk: TOTP app required

Rules based on:
- User group
- IP range
- Time of day
- Application sensitivity
```

Configure in IAS admin → Risk-based Authentication → Create policy → assign to your application.

## SSO across BTP apps

With IAS as the IdP, a user who has logged into App A is automatically logged into App B (same IAS tenant):
```
Alice logs into Bookshop (App A) → IAS session established
Alice opens Catalog App (App B) → IAS recognises the session → issues SAML assertion directly
→ App B issues JWT → Alice is in, no password prompt
```

## Debugging IAS integration

```bash
# Check SAML assertion content (IAS admin console)
# IAS → Troubleshooting → SAML Tracer
# Shows the SAML assertion sent to XSUAA — verify attributes

# Check XSUAA trust configuration
# BTP Cockpit → Trust Configuration → your IAS tenant
# Should show: "Active", "User Logon Disabled: No"

# Decode JWT after IAS login and check 'iss' claim
# Should be your XSUAA URL, not the IAS URL
# (XSUAA issues the JWT; IAS is not visible in the JWT)
```

## Production checklist for IAS

```
□ IAS tenant linked to BTP subaccount via Trust Configuration
□ XSUAA SAML trust configured (auto via "Establish Trust" button)
□ Corporate IdP (AD/LDAP) connected to IAS for employee users
□ MFA policy applied to sensitive applications
□ Custom attributes mapped: department, costCenter, region
□ Test SSO across at least two apps before go-live
□ Document the IAS tenant URL for support tickets
```

## Hands-on exercise
1. In BTP trial, click "Establish Trust" on your trial IAS tenant
2. Log in to your CAP app via the browser (not Basic auth) — observe the IAS login page
3. Check the JWT's `sub` claim — it's now an IAS user UUID, not an email
4. Map the `email` attribute explicitly in IAS SAML configuration

## Checkpoint ✓
- [ ] IAS handles authentication (who); XSUAA handles authorization (what)
- [ ] "Establish Trust" in BTP Cockpit auto-configures SAML between XSUAA and IAS
- [ ] Custom attributes in IAS flow through SAML assertion → XSUAA → JWT
- [ ] SSO works automatically across all apps that trust the same IAS tenant
$md$
WHERE slug = 'cap-54-ias';


-- ── Lesson 55 — Principal Propagation ────────────────────────────────────────

UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 55 — Principal Propagation

## What you'll learn
- What principal propagation is and when you need it
- OAuth2SAMLBearerAssertion flow step by step
- Configuring a destination for principal propagation
- Implementing propagation in a CAP handler
- Testing and troubleshooting

## Why this matters
When a CAP app calls an on-premise SAP system (ECC, S/4HANA on-prem), the SAP backend needs to know *who* the user is — not just that a service is calling. Principal propagation carries the BTP user's identity into the on-prem system so audit logs and authorizations work correctly.

## What is principal propagation?

```
Without propagation:
  Alice → CAP (alice's JWT) → S/4HANA (service user "CAP_SERVICE")
  S/4HANA sees: all requests come from CAP_SERVICE — no user context

With propagation:
  Alice → CAP (alice's JWT) → exchange for S/4HANA SAML assertion → S/4HANA
  S/4HANA sees: request from ALICE (her on-prem user ID)
```

## The OAuth2SAMLBearerAssertion flow

```
1. CAP receives Alice's BTP JWT (issued by XSUAA)
2. CAP calls XSUAA: "I have Alice's JWT, give me a SAML assertion for alice@company.com"
3. XSUAA issues SAML assertion (short-lived, signed)
4. CAP presents the SAML assertion to S/4HANA's OAuth endpoint
5. S/4HANA exchanges SAML for an access token for alice's on-prem account
6. CAP uses that access token to call S/4HANA APIs as Alice
```

## Destination configuration (BTP Cockpit)

In BTP Cockpit → Connectivity → Destinations → New:

```
Name:              S4HANA_PP
Type:              HTTP
URL:               https://s4hana.company.com
Authentication:    OAuth2SAMLBearerAssertion

Client ID:         <XSUAA client ID>
Client Secret:     <XSUAA client secret>
Token Service URL: https://<subdomain>.authentication.eu10.hana.ondemand.com/oauth/token/alias/<subdomain>

User Header Name:  X-SCI-PRINCIPAL-EMAIL   (varies by S/4HANA version)
AutoTokenRetrieval: On
```

## CAP implementation

```js
// srv/s4-integration.js
const cds = require('@sap/cds')

module.exports = class S4IntegrationService extends cds.ApplicationService {
  async init () {
    const destination = await cds.connect.to('destination-service')
    const s4 = await cds.connect.to('S4HANA_PP')   // configured destination

    this.on('READ', 'MyOrders', async (req) => {
      // CAP uses the destination's OAuth2SAMLBearerAssertion config
      // and automatically exchanges Alice's JWT before calling S/4HANA
      return s4.run(
        `GET /sap/opu/odata/sap/API_SALES_ORDER_SRV/A_SalesOrder`,
        { headers: { 'SAP-Client': '100' } }
      )
    })

    await super.init()
  }
}
```

## Getting user token for propagation

```js
// When you need explicit control
this.on('callS4WithUserContext', async (req) => {
  const { tokenInfo } = req.user
  const userToken = tokenInfo?.getTokenValue()

  if (!userToken) return req.reject(401, 'No user token available for propagation')

  const dest = await cds.connect.to('destination-service')
  const options = await dest.getDestination('S4HANA_PP', {
    userTokenExchangeEnabled: true,
    userToken
  })

  const response = await axios.get(`${options.url}/sap/opu/odata/...`, {
    headers: { ...options.authorizationHeaders }
  })

  return response.data
})
```

## Cloud Connector requirement

For on-premise S/4HANA, the OAuth2SAMLBearerAssertion destination requires:

1. SAP Cloud Connector (SCC) installed on-premise
2. SCC connected to BTP subaccount
3. S/4HANA system exposed via SCC virtual host
4. The destination uses `proxyType: OnPremise` with the virtual host

```
BTP ──SCC tunnel──► On-Premise S/4HANA
```

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| 401 on S/4HANA | SAML trust not configured | Configure S/4HANA OAuth client for XSUAA issuer |
| 403 on S/4HANA | User not in S/4HANA system | Create user mapping or sync from IAS |
| SAML assertion expired | Token exchange took too long | Check network latency, reduce steps |
| "Principal not found" | Username mapping mismatch | Check `User Header Name` in destination config |

## Hands-on exercise
1. Create a destination with `Authentication: OAuth2SAMLBearerAssertion` in BTP Cockpit
2. Connect it to an API sandbox (SAP API Business Hub provides test endpoints)
3. Implement a handler that reads from the destination using CAP's destination service
4. Log `req.user.id` and the outbound call to verify identity propagation

## Checkpoint ✓
- [ ] Principal propagation carries the BTP user's identity into on-prem SAP systems
- [ ] OAuth2SAMLBearerAssertion: BTP JWT → SAML assertion → on-prem OAuth token
- [ ] Destinations with `Authentication: OAuth2SAMLBearerAssertion` handle the exchange automatically
- [ ] On-prem systems require Cloud Connector for BTP connectivity
$md$
WHERE slug = 'cap-55-principal-prop';

-- ── Lesson 56 — Authorization Patterns & Best Practices ──────────────────────

UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 56 — Authorization Patterns & Best Practices

## What you'll learn
- Fine-grained @restrict patterns for real-world scenarios
- Multi-tenant user isolation
- Preventing privilege escalation
- Security testing methodology
- Authorization architecture review checklist

## Why this matters
Authorization bugs are the most common high-severity security finding in SAP BTP app audits. This lesson consolidates all the patterns into a checklist and shows the failure modes that real apps hit in production.

## Pattern 1: Hierarchical roles

```cds
// Lower roles always have a WHERE clause; higher roles don't
entity Tickets as projection on my.Tickets
  @(restrict: [
    { grant: '*',    to: 'SupportAdmin' },   // no filter — sees everything
    { grant: 'READ', to: 'TeamLead', where: 'team_ID in ($user.attr.teams)' },
    { grant: ['READ','WRITE'], to: 'Agent', where: 'assignee_ID = $user' }
  ]);
```

## Pattern 2: Status-based restrictions

```cds
entity Orders as projection on my.Orders
  @(restrict: [
    { grant: 'READ',   to: 'Admin' },
    { grant: 'READ',   to: 'Buyer', where: 'buyer_ID = $user' },
    { grant: 'UPDATE', to: 'Buyer', where: 'buyer_ID = $user and status = ''DRAFT''' },
    { grant: 'DELETE', to: 'Admin', where: 'status = ''CANCELLED''' }
  ]);
```

Buyers can only edit their own DRAFT orders. Admins can delete only CANCELLED orders.

## Pattern 3: Multi-tenant isolation

```js
// For shared-schema multitenancy — always filter by tenant
this.before('*', '*', (req) => {
  if (req.user?.tenant) {
    // Append tenant filter to every query automatically
    if (req.query?.SELECT) req.query.where({ tenant_ID: req.user.tenant })
    if (req.data && !req.data.tenant_ID) req.data.tenant_ID = req.user.tenant
  }
})
```

For HDI-based multitenancy (MTXS), each tenant has a separate schema — no code-level filtering needed.

## Pattern 4: Preventing privilege escalation

```js
// WRONG — user can claim any role by sending it in the body
this.before('UPDATE', 'Users', (req) => {
  // Don't let users elevate their own roles
  if (req.data.roles) {
    if (!req.user.is('Admin')) delete req.data.roles
  }
})

// BETTER — read-only fields managed by the system
entity Users {
  key ID    : UUID;
  name      : String;
  email     : String;
  roles     : String  @readonly;   // @readonly prevents client from setting it
}
```

## Pattern 5: Audit trail for sensitive operations

```js
const sensitiveOps = ['DELETE', 'cancelOrder', 'eraseCustomer']

this.before(sensitiveOps, '*', async (req) => {
  await INSERT.into('AuditTrail').entries({
    ID:        cds.utils.uuid(),
    user_ID:   req.user.id,
    operation: req.event,
    entity:    req.target?.name,
    timestamp: new Date(),
    reason:    req.data?.reason || '(no reason provided)'
  })
})
```

## Security testing methodology

### Layer 1: Unit tests (handlers)
```js
it('handler rejects wrong role', async () => {
  const req = mockRequest({ user: { id: 'alice', roles: ['Buyer'] }, event: 'DELETE' })
  await expect(handler(req)).rejects.toMatchObject({ status: 403 })
})
```

### Layer 2: Integration tests (HTTP)
```js
// Test every role × every operation × own vs other data
const matrix = [
  { user: 'alice', op: 'GET',    own: 200, other: 200 },  // reader
  { user: 'bob',   op: 'DELETE', own: 204, other: 403 },  // buyer can only delete own
  { user: 'admin', op: 'DELETE', own: 204, other: 204 },  // admin deletes anything
]
```

### Layer 3: Negative tests (bypass attempts)
```js
it('cannot bypass filter with $filter override', async () => {
  // Try to bypass buyer_ID filter by explicitly filtering for another user
  const { data } = await GET('/orders/Orders?$filter=buyer_ID eq ''carol''', { auth: alice })
  // CAP ANDs the @restrict where clause — result must be empty
  expect(data.value).toHaveLength(0)
})

it('cannot set buyer_ID in request body', async () => {
  const { data: created } = await POST('/orders/Orders', 
    { buyer_ID: 'carol' },   // try to impersonate carol
    { auth: alice }
  )
  expect(created.buyer_ID).toBe('alice')   // overridden by BEFORE handler
})
```

## Authorization review checklist

```
□ All services have @requires (not all 'any')
□ All entities with user-specific data have @restrict with where clause
□ Buyer/user-role WHERE always uses $user or $user.attr.* (not req.data)
□ No role is granted 'any' on write operations
□ Admin bypass paths are explicit — not implied
□ Sensitive field changes are audit-logged
□ Security-relevant fields (buyer_ID, tenant_ID) set from req.user, not req.data
□ @restrict WHERE clauses tested with bypass attempts
□ Token expiry tested on staging (not dev mock)
□ Service-to-service tokens cannot perform user-only operations
```

## Hands-on exercise
1. Apply all 5 patterns to your Orders service
2. Write the full test matrix (all roles × all operations × own/other data)
3. Write 3 bypass tests: $filter override, body spoofing, and missing WHERE
4. Run the authorization review checklist against your service — fix any gaps

## Checkpoint ✓
- [ ] `@restrict where` auto-applies for filtered access; no `where` = unrestricted
- [ ] Multi-tenant isolation: either separate HDI schemas (MTXS) or explicit `tenant_ID` filter
- [ ] Always set security fields from `req.user` — never from request body
- [ ] Security testing requires negative tests (bypass attempts) not just happy path
$md$
WHERE slug = 'cap-56-auth-patterns';

