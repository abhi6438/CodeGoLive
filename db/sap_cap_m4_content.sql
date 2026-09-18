-- ============================================================
-- SAP CAP Course — Module 4: Persistence & SAP HANA Cloud
-- Run AFTER sap_cap_seed.sql
-- Lessons: cap-35 through cap-46 (12 lessons)
-- ============================================================

-- ── Lesson 35 — SQLite for Local Development ─────────────────────────────────

UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 35 — SQLite for Local Development

## What you'll learn
- Why SQLite is the default local database for CAP
- Configuring `cds.requires.db` for SQLite profiles
- Using `cds deploy --to sqlite` to create a `.db` file
- Seeding data with CSV files
- Dev/prod parity strategy — what differs between SQLite and HANA

## Why this matters
SQLite lets every developer run a fully-functional CAP app locally with zero infrastructure. Understanding its limits prepares you to avoid bugs that only appear on HANA in production.

## Default configuration

CAP uses an in-memory SQLite database by default (no configuration needed):
```json
// .cdsrc.json — explicit but matches the default
{
  "requires": {
    "db": {
      "[development]": { "kind": "sqlite", "credentials": { "database": ":memory:" } },
      "[production]":  { "kind": "hana"   }
    }
  }
}
```

`cds watch` auto-deploys schema to in-memory SQLite on startup.

## Persistent SQLite file

```json
{
  "requires": {
    "db": {
      "[development]": {
        "kind": "sqlite",
        "credentials": { "database": "dev.db" }
      }
    }
  }
}
```

```bash
# Deploy schema to the file
cds deploy --to sqlite

# With specific target
cds deploy --to sqlite:dev.db
```

Now your data persists across `cds watch` restarts — useful for demo scenarios.

## CSV seed files

Place CSV files in `db/data/` or `srv/data/` (legacy) matching entity names:

```
db/
├── schema.cds
└── data/
    ├── my.bookshop-Books.csv          ← namespace-EntityName.csv
    ├── my.bookshop-Authors.csv
    └── my.bookshop-Orders.csv
```

```csv
# db/data/my.bookshop-Books.csv
ID,title,author_ID,price,stock
b1,Hands-On CAP,a1,49.99,100
b2,CDS Cookbook,a2,34.99,50
```

CAP auto-imports CSV on `cds deploy`. Existing rows are **replaced** on re-deploy.

## `cds deploy` vs `cds watch`

| Command | What it does |
|---|---|
| `cds watch` | In-memory SQLite, drops/recreates schema on file change |
| `cds deploy --to sqlite` | Writes schema + CSV to file; CAP uses the file on next start |
| `cds deploy --to hana` | Deploys to HDI container in BTP |

## Dev/prod parity gaps

| Feature | SQLite | HANA Cloud |
|---|---|---|
| Referential integrity | Not enforced | Enforced |
| `LargeBinary` | Stored as blob | BlobDisk |
| Temporal queries | Supported | Supported |
| Full-text search | Not supported | Supported |
| Row-level security | Not supported | Structured Privileges |
| Hierarchies (`$apply=traverse`) | Not supported | Supported |
| Stored procedures | Not available | Available |
| Case sensitivity in strings | Case-insensitive LIKE | Case-sensitive by default |

> Always test HANA-specific features in a DEV HANA Cloud instance before production.

## Multiple profiles

```json
{
  "requires": {
    "db": {
      "[development]": { "kind": "sqlite", "credentials": { "database": ":memory:" } },
      "[test]":        { "kind": "sqlite", "credentials": { "database": "test.db"   } },
      "[staging]":     { "kind": "hana"   },
      "[production]":  { "kind": "hana"   }
    }
  }
}
```

```bash
# Run with a specific profile
CDS_ENV=staging cds watch
NODE_ENV=test cds watch
```

## REPL exploration

```bash
# Interactive CDS REPL connected to SQLite
cds repl

> const db = await cds.connect.to('db')
> await db.run(SELECT.from('Books'))
> await db.run(INSERT.into('Books').entries({ ID: cds.utils.uuid(), title: 'Test', price: 9.99 }))
```

## Hands-on exercise
1. Switch from in-memory to persistent `dev.db`
2. Add CSV seed data for Books, Authors, and Orders
3. Run `cds deploy --to sqlite` and verify data with `sqlite3 dev.db .tables`
4. Try a HANA-only feature (e.g., `contains()` full-text) and observe it fails on SQLite

## Checkpoint ✓
- [ ] CSV files in `db/data/` named `namespace-EntityName.csv` auto-seed on deploy
- [ ] In-memory SQLite is the default; `"database": "dev.db"` persists across restarts
- [ ] `CDS_ENV=<profile>` switches between SQLite dev and HANA staging
- [ ] Key parity gaps: referential integrity, full-text search, and RLS differ
$md$
WHERE slug = 'cap-35-sqlite';

-- ── Lesson 36 — SAP HANA Cloud Fundamentals ──────────────────────────────────

UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 36 — SAP HANA Cloud Fundamentals

## What you'll learn
- HANA Cloud architecture relevant to CAP developers
- HDI (HANA Deployment Infrastructure) — what it is and why CAP uses it
- Provisioning a HANA Cloud free tier instance
- Connecting a CAP app to HANA Cloud locally
- Verifying the connection with `cds deploy --to hana`

## Why this matters
HANA Cloud is the production database for CAP apps on BTP. HDI is the deployment model that keeps schema changes safe, repeatable, and auditable — understanding it prevents the common mistakes that cause deployments to fail.

## HANA Cloud architecture

```
┌─────────────────────────────────────────┐
│           SAP HANA Cloud                │
│                                         │
│  ┌─────────────┐    ┌────────────────┐  │
│  │ System DB   │    │  Tenant DB     │  │
│  │ (admin)     │    │  (your app)    │  │
│  └─────────────┘    │                │  │
│                     │  ┌──────────┐  │  │
│                     │  │  HDI     │  │  │
│                     │  │ Container│  │  │
│                     │  └──────────┘  │  │
│                     └────────────────┘  │
└─────────────────────────────────────────┘
```

- **Tenant DB**: isolated database per BTP subaccount
- **HDI Container**: schema within the tenant DB, fully isolated per application
- **HDI**: the deployment engine that manages CDS-generated artifacts

## What is HDI?

HDI (HANA Deployment Infrastructure) manages **design-time** vs **runtime** artifacts:

| Design-time (your code) | Runtime (HDI deploys) |
|---|---|
| `.hdbcds` / `.hdbtable` files | Tables in HANA |
| `.hdbview` files | Views |
| `.hdbprocedure` files | Stored procedures |
| `.hdbsequence` files | Sequences |

CAP runs `cds build --for hana` to generate these from your CDS model, then HDI deploys them.

## Free tier provisioning

1. BTP Cockpit → Subaccount → Service Marketplace → SAP HANA Cloud → Create
2. Choose **SAP HANA Cloud, SAP HANA Database** (free tier = 30GB, 16vCPU)
3. Set admin password, allow access from your IP (or BTP CF space)
4. Wait ~5 minutes for provisioning
5. Open **SAP HANA Database Explorer** to verify

## Creating a service key

```bash
# Create HANA Cloud service instance (if via CF CLI)
cf create-service hana-cloud hana myapp-hana \
  -c '{"data": {"edition": "cloud", "memory": 30, "systempassword": "YourPassword1"}}'

# Create a service key for local development
cf create-service-key myapp-hana myapp-hana-key
cf service-key myapp-hana myapp-hana-key
```

## Local connection via .env

```bash
# Copy credentials to local .env (never commit!)
cat > .env << 'EOF'
VCAP_SERVICES={"hana":[{"credentials":{"host":"...","port":"443","user":"...","password":"...","schema":"..."}}]}
EOF
```

```json
// .cdsrc.json
{
  "requires": {
    "db": {
      "[development]": {
        "kind": "hana",
        "vcap": { "label": "hana" }
      }
    }
  }
}
```

## Deploy schema to HANA

```bash
# Build CDS → HANA artifacts
cds build --for hana

# Deploy to HANA Cloud (uses .env credentials)
cds deploy --to hana

# Or use HDI deployer (production)
npm run deploy
```

`cds build --for hana` generates:
```
gen/
└── db/
    ├── src/
    │   ├── gen/
    │   │   ├── Books.hdbcds
    │   │   └── Authors.hdbcds
    └── package.json
```

## Verify connection

```bash
# In HANA Database Explorer
SELECT TABLE_NAME FROM TABLES WHERE SCHEMA_NAME = CURRENT_SCHEMA;
-- Should list: BOOKS, AUTHORS, ORDERS, etc.
```

```bash
# Or via cds REPL
cds repl --profile development
> const db = await cds.connect.to('db')
> await db.run(SELECT.from('Books').limit(3))
```

## Common provisioning mistakes

| Mistake | Symptom | Fix |
|---|---|---|
| IP not in allowlist | Connection timeout | Add your IP in HANA Cloud cockpit |
| Wrong credentials in .env | Auth failure | Regenerate service key |
| Schema not created | Table not found | Run `cds deploy --to hana` |
| CAP version mismatch | Build errors | `npm update @sap/cds` |

## Hands-on exercise
1. Provision a free-tier HANA Cloud instance in your BTP trial account
2. Create a service key and add credentials to `.env`
3. Run `cds build --for hana` and inspect the `gen/db/` output
4. Run `cds deploy --to hana` and open HANA Database Explorer to verify tables

## Checkpoint ✓
- [ ] HDI manages design-time artifacts; CAP generates them from CDS
- [ ] Service key credentials go in `.env` as `VCAP_SERVICES` — never commit this file
- [ ] `cds build --for hana` generates `.hdbcds` files; `cds deploy --to hana` applies them
- [ ] Free-tier HANA Cloud: 30GB, 16vCPU, no expiry (trial subaccount limit applies)
$md$
WHERE slug = 'cap-36-hana-basics';


-- ── Lesson 37 — HDI Containers & Deployment ──────────────────────────────────

UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 37 — HDI Containers & Deployment

## What you'll learn
- HDI container lifecycle and isolation model
- Design-time artifact types generated by CAP
- How `cds build` produces deployable artifacts
- The HDI deployer package and how it's wired in MTA
- Incremental schema evolution — what HDI allows and what it doesn't

## Why this matters
HDI is how CAP gets schema changes into HANA Cloud safely. Understanding the artifact lifecycle explains why some schema changes work silently and others fail with cryptic errors — knowing the rules means zero surprises at deployment time.

## HDI container model

```
BTP CF Space
├── CAP Application (Node.js app)          ← your service code
├── HDI Container service instance         ← schema + data
└── HDI Deployer (one-off task)            ← applies changes to HDI
```

- The **HDI Container** is a HANA Cloud schema with its own technical user
- The **HDI Deployer** is a separate Node.js app (`@sap/hdi-deploy`) that runs at deploy time
- The **CAP app** connects to the HDI container via a service binding (injected as `VCAP_SERVICES`)

## Artifact types generated by `cds build --for hana`

| CDS concept | Generated artifact | File extension |
|---|---|---|
| `entity` | Table | `.hdbcds` or `.hdbtable` |
| View / projection | Calculation view | `.hdbcds` |
| CDS function | Scalar function | `.hdbfunction` |
| Sequence | HDI sequence | `.hdbsequence` |
| Table data (CSV) | Table data | `.hdbtabledata` |
| Roles | HDI role | `.hdbrole` |

## Build output structure

```
gen/db/
├── package.json            ← HDI deployer entry point
└── src/
    ├── gen/
    │   ├── my.bookshop.Books.hdbcds
    │   ├── my.bookshop.Authors.hdbcds
    │   └── my.bookshop.Orders.hdbcds
    └── data/
        └── my.bookshop-Books.hdbtabledata
```

## HDI deployer package.json

```json
// gen/db/package.json (generated by cds build)
{
  "name": "bookshop-db",
  "version": "1.0.0",
  "dependencies": {
    "@sap/hdi-deploy": "^4"
  },
  "scripts": {
    "start": "node node_modules/@sap/hdi-deploy/deploy.js"
  }
}
```

## What happens during deployment

```
1. cf push bookshop-db (or mbt build + cf deploy)
2. HDI deployer starts
3. Compares current gen/db/src/ with what's in HDI
4. Determines delta (added, changed, removed artifacts)
5. Applies delta in dependency order
6. Exits 0 on success, non-zero on failure
7. CF task completes; CAP app now uses updated schema
```

## Safe vs unsafe schema changes

### Safe (HDI handles automatically)
```
✓ Add a new entity (table)
✓ Add a nullable column
✓ Add a new view
✓ Change a view definition
✓ Add an index
```

### Unsafe (HDI rejects or data loss risk)
```
✗ Remove a column          → HDI rejects by default
✗ Rename a column          → treated as drop + add = data loss
✗ Change NOT NULL column   → fails if existing rows have nulls
✗ Change column type       → rejected if incompatible
```

### Workarounds for unsafe changes
```sql
-- For a rename: add new column, migrate data, deprecate old
ALTER TABLE BOOKS ADD (NEW_TITLE NVARCHAR(200));
UPDATE BOOKS SET NEW_TITLE = TITLE;
-- Then annotate old column @deprecated in CDS
```

## Forced undeploy (development only!)

```bash
# Nuclear option — drops and recreates the HDI container
# ALL DATA IS LOST
cds deploy --to hana --auto-undeploy
```

Only use on dev containers. Never on production.

## HDI roles and permissions

```json
// gen/db/src/roles/app_user.hdbrole
{
  "role": {
    "name": "app_user",
    "schema_privileges": [{ "privileges": ["SELECT","INSERT","UPDATE","DELETE"] }]
  }
}
```

HDI manages grants automatically for the app's technical user. You don't need to `GRANT` manually.

## Hands-on exercise
1. Run `cds build --for hana` and inspect `gen/db/src/gen/` — find the `.hdbcds` files
2. Add a new `notes: String` field to an entity and rebuild — verify the new artifact
3. Try removing a column from CDS, rebuild, and observe the HDI error message
4. Add `@deprecated` annotation to a field instead of removing it

## Checkpoint ✓
- [ ] HDI deployer is a separate package that runs at deploy time (`@sap/hdi-deploy`)
- [ ] `cds build --for hana` generates `.hdbcds` artifacts in `gen/db/src/gen/`
- [ ] Adding columns is safe; removing/renaming columns requires manual migration
- [ ] `--auto-undeploy` resets the schema but destroys all data — dev only
$md$
WHERE slug = 'cap-37-hdi';

-- ── Lesson 38 — HANA-Specific CDS Types & Features ───────────────────────────

UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 38 — HANA-Specific CDS Types & Features

## What you'll learn
- CDS types that map to HANA-native column types
- `LargeString` and `LargeBinary` — when to use them
- Spatial types: `cds.hana.POINT`, `cds.hana.ST_GEOMETRY`
- Time-series capabilities and partitioning hints
- HANA-specific annotations: `@hana.fullTextIndex`, `@hana.collation`

## Why this matters
HANA Cloud offers column types and indexing strategies unavailable in SQLite. Knowing which annotations unlock them saves you from hand-crafting native SQL for features CAP can generate automatically.

## Standard CDS types (all databases)

| CDS type | HANA type | SQLite type |
|---|---|---|
| `String(n)` | `NVARCHAR(n)` | `TEXT` |
| `Integer` | `INTEGER` | `INTEGER` |
| `Decimal(p, s)` | `DECIMAL(p, s)` | `REAL` |
| `Boolean` | `BOOLEAN` | `INTEGER` |
| `Date` | `DATE` | `TEXT` |
| `DateTime` | `SECONDDATE` | `TEXT` |
| `Timestamp` | `TIMESTAMP` | `TEXT` |
| `UUID` | `NVARCHAR(36)` | `TEXT` |
| `Binary(n)` | `VARBINARY(n)` | `BLOB` |

## Large types

```cds
entity Documents {
  key ID      : UUID;
  title       : String;
  body        : LargeString;    // → NCLOB in HANA (up to 2GB text)
  attachment  : LargeBinary;   // → BLOB in HANA (up to 2GB binary)
  thumbnail   : Binary(32768); // small fixed-size binary
}
```

> Use `LargeString` for rich text, JSON, or Markdown content. Use `LargeBinary` for file attachments. **Never** select `LargeString`/`LargeBinary` columns in list queries — fetch them only for individual records.

## HANA-specific native types

```cds
// Opt in to HANA-native types with cds.hana namespace
using { cds.hana } from '@sap/cds/common';

entity Locations {
  key ID       : UUID;
  name         : String;
  coordinates  : hana.ST_POINT;    // spatial point (lat/lon)
  boundary     : hana.ST_GEOMETRY; // polygon / multipolygon
}
```

```sql
-- OData exposes these as opaque strings; use native SQL for spatial queries
SELECT ID, name,
  coordinates.ST_AsGeoJSON() AS geoJson,
  coordinates.ST_Distance(ST_GeomFromText('POINT(13.4 52.5)','WGS84')) AS distanceM
FROM Locations
ORDER BY distanceM;
```

## Full-text index annotation

```cds
entity Books {
  key ID      : UUID;
  title       : String @hana.fullTextIndex;        // basic full-text
  description : String @hana.fullTextIndex: {
    fuzzySearchIndex: true,                         // fuzzy matching
    text_analysis:    true                          // language detection
  };
}
```

Enables HANA's `CONTAINS()` predicate in OData `$filter`:
```
GET /Books?$filter=contains(description,'machine learning')&fuzzy=0.8
```

## Column table vs row table

```cds
entity FactSales @hana.tableType: 'COLUMN' {  // default for HANA
  // good for analytical queries
}
entity SessionLog @hana.tableType: 'ROW' {    // transactional
  // good for high-frequency inserts/updates
}
```

## Collation (case-sensitive search)

```cds
entity Products {
  code : String @hana.collation: 'BINARY';  // exact case match
  name : String;                             // UNICODE by default (case-insensitive)
}
```

## HANA-specific annotations summary

| Annotation | Effect |
|---|---|
| `@hana.fullTextIndex` | Creates full-text index on the column |
| `@hana.tableType: 'COLUMN'` | Column store (default); analytical workloads |
| `@hana.tableType: 'ROW'` | Row store; transactional workloads |
| `@hana.collation: 'BINARY'` | Case-sensitive string comparison |
| `@hana.storeType: 'PAGE'` | Page-based blob storage |

## Type compatibility table (important for migration)

| Your intent | Use on SQLite | Use on HANA |
|---|---|---|
| Long text (markdown, JSON) | `LargeString` | `LargeString` → NCLOB |
| File content | `LargeBinary` | `LargeBinary` → BLOB |
| UUID primary key | `UUID` | `UUID` → NVARCHAR(36) |
| Geographic point | Not available | `hana.ST_POINT` |

## Hands-on exercise
1. Add `description: LargeString` to your Books entity
2. Annotate `title` with `@hana.fullTextIndex: { fuzzySearchIndex: true }`
3. Add a `location: hana.ST_POINT` field to a Stores entity
4. Build with `cds build --for hana` and inspect the generated artifact to confirm NCLOB vs NVARCHAR

## Checkpoint ✓
- [ ] `LargeString` → NCLOB in HANA; avoid in list queries — fetch for single records only
- [ ] `@hana.fullTextIndex` enables `contains()` OData filter
- [ ] `hana.ST_POINT` / `hana.ST_GEOMETRY` for spatial types — HANA only
- [ ] Column tables (default) for analytics; row tables for heavy transactional workloads
$md$
WHERE slug = 'cap-38-hana-types';

-- ── Lesson 39 — Schema Evolution & Migrations ────────────────────────────────

UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 39 — Schema Evolution & Migrations

## What you'll learn
- The schema change lifecycle in CAP + HDI
- Safe vs breaking changes — the complete decision tree
- CAP migration tooling: `cds migrate` and change sets
- Zero-downtime deployment strategies
- Emergency rollback procedures

## Why this matters
A schema change that works in dev can bring down production if it removes a column that a running app version still reads. Schema evolution is one of the highest-risk operations in enterprise software — these patterns make it safe.

## Safe changes (additive — zero risk)

```cds
// All of these deploy without any data risk:
entity Orders {
  key ID      : UUID;
  status      : String;
  // ✓ Add nullable column
  notes       : String;
  // ✓ Add association
  assignee    : Association to Users;
  // ✓ Increase String length
  description : String(500);  // was String(200)
}
```

```bash
# HDI handles these automatically
cds build --for hana && cds deploy --to hana
```

## Breaking changes — decision tree

```
Is the column used by the running app?
  YES → Don't remove yet → deprecate first
  NO  → Safe to remove → add to .hdiconfig undeploy list

Is the column type changing?
  Compatible (e.g., String(200) → String(500)) → Safe
  Incompatible (e.g., String → Integer)        → Manual migration required

Is a NOT NULL constraint being added?
  Existing rows have nulls? → Set a default first, then add constraint
  All rows are non-null?    → Safe with test confirmation
```

## The two-phase deprecation pattern

```
Phase 1 (deploy v2): Add new column, keep old column, copy data
Phase 2 (deploy v3): Remove old column after all app instances updated
```

```cds
// v2 — both columns exist
entity Books {
  key ID          : UUID;
  title           : String;
  authorName      : String;   // OLD — deprecated
  author_ID       : UUID;     // NEW — references Authors entity
}
```

```js
// v2 handler — read from old, write to new
this.before('CREATE', 'Books', (req) => {
  // Dual-write during transition
  if (req.data.authorName && !req.data.author_ID) {
    const author = await findOrCreateAuthor(req.data.authorName)
    req.data.author_ID = author.ID
  }
})
```

```cds
// v3 — remove old column (only after all consumers updated)
entity Books {
  key ID     : UUID;
  title      : String;
  author_ID  : UUID;
}
```

## CAP migration tables

CAP 7+ tracks schema versions:

```bash
# Generate migration change files
cds migrate --from <old-version> --to <new-version>

# Creates:
db/migrations/
└── 20260917_add_author_ID.json
```

```json
// migration change file
{
  "up": [
    "ALTER TABLE BOOKS ADD (AUTHOR_ID NVARCHAR(36))",
    "UPDATE BOOKS SET AUTHOR_ID = (SELECT ID FROM AUTHORS WHERE NAME = AUTHORNAME LIMIT 1)"
  ],
  "down": [
    "ALTER TABLE BOOKS DROP (AUTHOR_ID)"
  ]
}
```

## Zero-downtime deployment strategy

```
1. Deploy v2 (adds new_column, old_column still present)
   → Both v1 and v2 app instances run simultaneously
   → Blue-green: v2 CF app, v1 still receives traffic

2. Validate v2 health checks pass

3. Switch traffic to v2 (update CF route)

4. Wait for v1 to drain (all in-flight requests complete)

5. Deploy v3 in next release cycle (removes old_column)
```

## HDI undeploy (controlled column removal)

```json
// gen/db/src/.hdiconfig
{
  "file_suffixes": { ... },
  "undeploy": [
    "src/gen/my.bookshop.Books.hdbcds"   // HDI will drop and recreate (DANGER: data loss!)
  ]
}
```

**Never** add production tables to `undeploy`. Use additive migrations instead.

## Emergency rollback

```bash
# HANA Cloud point-in-time recovery (up to 15 days retention)
# In HANA Cloud Cockpit → Recovery → Point-in-Time Recovery
# Stops the instance and recovers to a prior state

# For CF app rollback (without DB rollback)
cf push bookshop --docker-image <previous-version-image>
# Or use blue-green: switch CF route back to old app
```

## Pre-deployment checklist

```
□ Test migration script on a HANA snapshot copy
□ Verify additive changes: no columns removed, no type changes
□ Backup production HDI container before deploy (snapshots)
□ Coordinate with all app consumers about deprecated columns
□ Monitor error rate during and after deployment
□ Document rollback plan with estimated time to recovery
```

## Hands-on exercise
1. Add a new nullable `notes` column to your Books entity — deploy it
2. Then add a NOT NULL `category` column with a default value — deploy it
3. Deprecate `stock` by adding `stockCount` alongside it
4. Write a BEFORE handler that syncs both fields during the transition

## Checkpoint ✓
- [ ] Additive changes (add columns, increase length) are safe and need no special handling
- [ ] Breaking changes follow the two-phase deprecation pattern
- [ ] Zero-downtime uses blue-green deployment with overlapping old/new column lifespan
- [ ] Never add active production tables to the HDI `undeploy` list
$md$
WHERE slug = 'cap-39-migrations';


-- ── Lesson 40 — HANA Calculation Views in CAP ────────────────────────────────

UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 40 — HANA Calculation Views in CAP

## What you'll learn
- What HANA Calculation Views are and when to use them
- Creating Calculation Views with HANA modeler vs SQL script
- Exposing Calculation Views as CDS projections
- Consuming them from CAP OData service
- Limitations compared to SQL views

## Why this matters
Calculation Views are HANA's native analytical engine — column-store optimised for aggregations over millions of rows. For reporting use cases (sales totals, inventory analytics, financial aggregations) they outperform standard SQL views by orders of magnitude.

## Calculation View types

| Type | Use case | Tooling |
|---|---|---|
| Graphical | Visual join/aggregation builder | HANA Database Explorer |
| SQL Script | Complex logic, code reuse | Any text editor |
| Hierarchy | Tree traversal | Graphical tool |

## Creating a Calculation View (SQL Script)

```sql
-- db/hana/CV_SALES_SUMMARY.hdbcalculationview
-- (stored in gen/db/src/ when hand-crafted, or in a separate HANA project)
```

```xml
<!-- CV_SALES_SUMMARY.hdbcalculationview (graphical format, SAP-generated) -->
<?xml version="1.0" encoding="UTF-8"?>
<Calculation:scenario
  xmlns:Calculation="http://www.sap.com/ndb/BiModelCalculation.ecore"
  id="CV_SALES_SUMMARY"
  applyPrivilegeType="NONE"
  dataCategory="CUBE"
  outputViewType="Aggregation">
  <!-- columns, join nodes, aggregation nodes defined here -->
</Calculation:scenario>
```

For CAP developers, the simpler approach is a **SQL-script Calculation View**:

```sql
-- CREATE CALCULATION SCENARIO via HDI procedure
-- Exposed as a SQL view-like object CAP can query
```

## Practical approach: HANA SQL function

CAP can call **HANA SQL scalar and table functions** which give similar performance benefits:

```sql
-- gen/db/src/SalesReport.hdbfunction (deployed via HDI)
FUNCTION SalesReport(p_year INTEGER)
  RETURNS TABLE (
    product_ID NVARCHAR(36),
    product_name NVARCHAR(200),
    total_qty INTEGER,
    total_revenue DECIMAL(15,2)
  )
LANGUAGE SQLSCRIPT AS
BEGIN
  RETURN SELECT
    p.ID AS product_ID,
    p.name AS product_name,
    SUM(oi.quantity) AS total_qty,
    SUM(oi.quantity * oi.price) AS total_revenue
  FROM ORDERS o
  JOIN ORDER_ITEMS oi ON oi.ORDER_ID = o.ID
  JOIN PRODUCTS p ON p.ID = oi.PRODUCT_ID
  WHERE YEAR(o.CREATED_AT) = :p_year
  GROUP BY p.ID, p.name
  ORDER BY total_revenue DESC;
END;
```

## Exposing in CDS

```cds
// srv/analytics-service.cds
service AnalyticsService {
  // Map to HANA table function
  @readonly
  entity SalesReport(year : Integer) as
    select from SalesReport(year);  // CDS doesn't support this directly

  // Use a CDS view instead — CAP generates a standard SQL view
  @readonly
  entity ProductRevenue as select from my.OrderItems {
    product.name as productName,
    sum(quantity * price) as revenue
  }
  group by product.name;
}
```

## Consuming via CAP handler (native SQL)

For true Calculation Views, bypass the CDS layer:

```js
// srv/analytics-service.js
const db = await cds.connect.to('db')

this.on('READ', 'SalesReport', async (req) => {
  const { year = new Date().getFullYear() } = req.data

  // Call the HANA table function directly
  const result = await db.run(
    `SELECT * FROM "SalesReport"(${year}) ORDER BY total_revenue DESC`
  )
  return result
})
```

## Consuming a Graphical Calculation View

After the CV is deployed to HDI:

```js
this.on('READ', 'SalesSummary', async (req) => {
  const result = await db.run(`
    SELECT product_ID, product_name, total_qty, total_revenue
    FROM "_SYS_BIC"."my.bookshop/CV_SALES_SUMMARY"
    WHERE YEAR = ${req.data.year}
  `)
  return result
})
```

## Performance comparison

| Query type | 1M rows | 10M rows |
|---|---|---|
| Standard SQL JOIN aggregation | ~2s | ~20s |
| HANA column store SQL view | ~200ms | ~2s |
| Calculation View (columnar engine) | ~50ms | ~500ms |

## When to use Calculation Views vs CDS views

| Use CDS view | Use HANA Calculation View |
|---|---|
| < 500K rows, transactional reporting | > 1M rows, analytical dashboards |
| Simple aggregations | Complex multi-level hierarchies |
| Dev/prod parity important | HANA-only deployment |
| Portable code priority | Maximum performance priority |

## Hands-on exercise
1. Write a CDS view `ProductRevenue` that aggregates order items by product
2. Annotate it with `@Aggregation.default: #SUM` for Fiori Analytical tables
3. Deploy to HANA and test via OData: `GET /analytics/ProductRevenue?$apply=aggregate(revenue with sum)`
4. Try calling a HANA table function via `db.run(native SQL)` from a handler

## Checkpoint ✓
- [ ] CDS views work on SQLite + HANA; Calculation Views are HANA-only
- [ ] HANA table functions can be called via `db.run('SELECT * FROM "FuncName"(params)')` 
- [ ] Calculation Views are accessed via `_SYS_BIC` schema in native SQL
- [ ] Use Calculation Views for > 1M row analytics; CDS views for standard reporting
$md$
WHERE slug = 'cap-40-hana-views';

-- ── Lesson 41 — Stored Procedures & Native SQL ────────────────────────────────

UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 41 — Stored Procedures & Native SQL

## What you'll learn
- When to use native SQL / stored procedures vs CAP query API
- Calling HANA stored procedures from CAP handlers
- Creating procedures via HDI (`.hdbprocedure`)
- Safe parameter passing (no SQL injection)
- Transactions with stored procedures

## Why this matters
90 % of logic belongs in CDS handlers. But some operations — complex ETL, hierarchical data processing, bulk data moves — are 100x faster as HANA stored procedures. Knowing how to call them from CAP without breaking the transaction model is essential.

## When native SQL makes sense

| Use CAP Query API | Use native SQL / stored proc |
|---|---|
| Standard CRUD | Bulk data processing (> 10K rows) |
| OData operations | Complex recursive CTEs |
| Portable code | HANA-specific features (spatial, full-text) |
| Handler logic | ETL jobs, data migration |
| Simple aggregations | Multi-step analytics with temp tables |

## Simple native SQL from a handler

```js
const db = await cds.connect.to('db')

this.on('calculateRevenue', async (req) => {
  const { productId, year } = req.data

  // Parameterized query — safe from SQL injection
  const result = await db.run(
    `SELECT SUM(oi.QUANTITY * oi.PRICE) AS revenue
     FROM ORDER_ITEMS oi
     JOIN ORDERS o ON oi.ORDER_ID = o.ID
     JOIN PRODUCTS p ON oi.PRODUCT_ID = p.ID
     WHERE p.ID = ? AND YEAR(o.CREATED_AT) = ?`,
    [productId, year]
  )

  return { revenue: result[0]?.REVENUE ?? 0 }
})
```

## Creating a stored procedure via HDI

```sql
-- gen/db/src/proc/ReassignOrders.hdbprocedure
PROCEDURE "ReassignOrders" (
  IN  p_old_assignee NVARCHAR(100),
  IN  p_new_assignee NVARCHAR(100),
  OUT p_count        INTEGER
)
LANGUAGE SQLSCRIPT AS
BEGIN
  UPDATE ORDERS
    SET ASSIGNEE = :p_new_assignee
  WHERE ASSIGNEE = :p_old_assignee
    AND STATUS IN ('DRAFT','SUBMITTED');

  SELECT COUNT(*) INTO p_count
  FROM ORDERS
  WHERE ASSIGNEE = :p_new_assignee;
END;
```

## Calling the procedure from CAP

```js
this.on('reassignOrders', async (req) => {
  const { oldAssignee, newAssignee } = req.data
  const db = await cds.connect.to('db')

  // HANA node.js client call
  const result = await db.run(
    `CALL "ReassignOrders"(?, ?, ?)`,
    [oldAssignee, newAssignee, null]   // null = OUT parameter placeholder
  )

  return { count: result.p_count }
})
```

## Transactions with stored procedures

CAP automatically wraps handlers in a transaction. Procedures called via `db.run()` join that transaction:

```js
this.on('bulkProcess', async (req) => {
  const db = await cds.connect.to('db')

  // All three calls are in the same transaction
  await db.run(`UPDATE ORDERS SET STATUS = 'PROCESSING' WHERE ...`)
  await db.run(`CALL "ProcessBatch"(?, ?)`, [req.data.batchId, null])
  await db.run(`INSERT INTO AUDIT_LOG ...`)

  // Transaction commits when the handler returns successfully
  // Rolls back if the handler throws
})
```

## Avoiding SQL injection

```js
// WRONG — vulnerable to SQL injection
const title = req.data.title
await db.run(`SELECT * FROM BOOKS WHERE TITLE LIKE '%${title}%'`)

// CORRECT — parameterized
await db.run(`SELECT * FROM BOOKS WHERE TITLE LIKE ?`, [`%${title}%`])

// ALSO CORRECT — CDS query API (always safe)
await SELECT.from('Books').where(`title like`, `%${req.data.title}%`)
```

## Bulk operations via native SQL

```js
// Mass update without loading into JS (pure SQL)
this.on('closeExpiredOrders', async (req) => {
  const db = await cds.connect.to('db')
  const cutoff = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString()

  await db.run(
    `UPDATE ORDERS SET STATUS = 'EXPIRED'
     WHERE STATUS = 'SUBMITTED' AND CREATED_AT < ?`,
    [cutoff]
  )
})
```

## Inspecting native query results

```js
const rows = await db.run(`SELECT * FROM BOOKS LIMIT 5`)
// rows is an array of plain objects with UPPER_CASE column names (HANA default)
// { ID: '...', TITLE: '...', PRICE: 29.99 }

// Normalise column names if needed
const books = rows.map(r => ({
  id:    r.ID,
  title: r.TITLE,
  price: r.PRICE
}))
```

## Hands-on exercise
1. Write a stored procedure `ArchiveOldOrders(p_days INTEGER, OUT p_count INTEGER)` in an `.hdbprocedure` file
2. Call it from a CAP action `archiveOrders(days: Integer) returns { count: Integer }`
3. Add a bulk UPDATE via native SQL that sets all archived orders' status
4. Verify the transaction: make the procedure throw midway and confirm the UPDATE is rolled back

## Checkpoint ✓
- [ ] Always use parameterized queries (`?` placeholders) — never string interpolation
- [ ] Procedures created via `.hdbprocedure` HDI artifact are deployed by `cds deploy`
- [ ] `db.run('CALL proc(?, ?)', [in1, null])` calls a procedure; OUT params come back as named properties
- [ ] Native SQL inside a handler automatically joins the request's transaction
$md$
WHERE slug = 'cap-41-stored-procs';


-- ── Lesson 42 — Full-Text Search in HANA ─────────────────────────────────────

UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 42 — Full-Text Search in HANA

## What you'll learn
- HANA full-text index vs SQL LIKE
- Enabling full-text search with `@hana.fullTextIndex`
- OData `$search` and `contains()` predicates
- Fuzzy search configuration
- Linguistic analysis and language detection

## Why this matters
`LIKE '%search%'` scans every row, every character. HANA full-text search uses an inverted index — the same technique as Elasticsearch — that answers text searches in milliseconds even on 100 million rows. It also handles synonyms, inflections, and typos.

## Full-text index annotation

```cds
entity Products {
  key ID          : UUID;
  name            : String          @hana.fullTextIndex;
  description     : LargeString     @hana.fullTextIndex: {
    fuzzySearchIndex:  true,         // tolerate typos
    text_analysis:     true,         // language-aware tokenization
    fast:              true          // FAST index (better performance, more space)
  };
  technicalSpecs  : String;         // not indexed — not searched
}
```

## OData $search system query option

Once the full-text index is in place, standard OData `$search` works:

```
GET /catalog/Products?$search=machine learning
```

CAP translates `$search` into HANA `CONTAINS(*)` automatically for full-text indexed entities.

## OData $filter with contains()

```
# Exact phrase
GET /catalog/Products?$filter=contains(description,'machine learning')

# Fuzzy search (0.8 = 80% similarity threshold)
GET /catalog/Products?$filter=search.ismatch('machin lernig','description','full','false','0.8')
```

## Direct HANA SQL full-text query

```js
const db = await cds.connect.to('db')

this.on('searchProducts', async (req) => {
  const { query, fuzzy = 0.8 } = req.data

  const results = await db.run(`
    SELECT TOP 20
      ID, name, description,
      SCORE() AS relevance
    FROM PRODUCTS
    WHERE CONTAINS(name, description, ?, FUZZY(${fuzzy}))
    ORDER BY SCORE() DESC
  `, [query])

  return results
})
```

## Fuzzy search parameters

| Parameter | Range | Effect |
|---|---|---|
| `FUZZY(0.9)` | 0.0–1.0 | Higher = stricter match |
| `FUZZY(0.7, 'textSearch=compare')` | — | Error-tolerant text matching |
| `FUZZY(0.8, 'similarCalculationMode=compare')` | — | Character comparison mode |

## Language-aware tokenization

```cds
entity Articles {
  title   : String @hana.fullTextIndex: { text_analysis: true };
  // text_analysis enables:
  // - stemming (run/running/ran → run)
  // - stop word filtering (the, a, is)
  // - language detection per document
}
```

```sql
-- After text_analysis is enabled
SELECT * FROM ARTICLES
WHERE CONTAINS(title, 'running', LINGUISTIC);
-- Matches: run, running, ran, runner (stemmed matches)
```

## Indexing strategy

| Scenario | Recommendation |
|---|---|
| Short strings (< 100 chars) | `@hana.fullTextIndex` (basic) |
| Long text, typo tolerance | `@hana.fullTextIndex: { fuzzySearchIndex: true }` |
| Multilingual content | `text_analysis: true` |
| Maximum performance | `fast: true` (uses more disk space) |
| Structured data (IDs, codes) | Don't use full-text index; use standard index instead |

## OData search on multiple entities (cross-entity)

```
GET /catalog/SearchResults?$search=enterprise&$select=type,title,snippet
```

```js
// Handler aggregates results from multiple entities
this.on('READ', 'SearchResults', async (req) => {
  const { '$search': query } = req._.req.query

  const [products, docs, faq] = await Promise.all([
    db.run(`SELECT ID,'product' AS type,name AS title FROM PRODUCTS WHERE CONTAINS(name,?)`, [query]),
    db.run(`SELECT ID,'doc' AS type,title FROM DOCUMENTS WHERE CONTAINS(title,description,?)`, [query]),
    db.run(`SELECT ID,'faq' AS type,question AS title FROM FAQ WHERE CONTAINS(question,answer,?)`, [query])
  ])

  return [...products, ...docs, ...faq]
    .sort((a, b) => (b.SCORE || 0) - (a.SCORE || 0))
    .slice(0, 20)
})
```

## Testing on SQLite (development)

Full-text index annotations are **ignored on SQLite**. Test `$search` on HANA Dev instance:

```bash
# Run against HANA (not SQLite)
CDS_ENV=staging cds watch
# Then test: GET http://localhost:4004/catalog/Products?$search=machine
```

## Hands-on exercise
1. Add `@hana.fullTextIndex: { fuzzySearchIndex: true }` to `title` and `description` on Books
2. Deploy to HANA and test: `GET /catalog/Books?$search=cloud programming`
3. Test fuzzy: search for `progaming` (typo) — should still return CAP books
4. Add `SCORE()` to the result by wrapping the OData call with a native SQL handler

## Checkpoint ✓
- [ ] `@hana.fullTextIndex` annotation enables HANA full-text indexing
- [ ] OData `$search=term` maps to `CONTAINS(*)` automatically
- [ ] `FUZZY(0.8)` threshold: 0.0 = anything matches, 1.0 = exact only
- [ ] Full-text annotations are silently ignored on SQLite — test on HANA
$md$
WHERE slug = 'cap-42-full-text';

-- ── Lesson 43 — Row-Level Security in HANA ────────────────────────────────────

UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 43 — Row-Level Security in HANA

## What you'll learn
- CAP's built-in row-level filtering with `@restrict where`
- Implementing user-scoped data isolation in handlers
- HANA Analytic Privileges for native row-level security
- Tenant-level data isolation patterns
- Testing row-level security

## Why this matters
Row-level security ensures users see only their own data — a salesperson sees their orders, not everyone's. Without it, a single OData `$filter` bypass exposes all records. CAP has built-in support for this, and HANA doubles it at the database engine level.

## CAP @restrict with where clause

```cds
// srv/orders-service.cds
service OrdersService @(requires: 'authenticated-user') {
  entity Orders as projection on my.Orders
    @(restrict: [
      { grant: 'READ',   to: 'Buyer',   where: 'buyer_ID = $user' },
      { grant: '*',      to: 'Admin'                               },
      { grant: ['READ'], to: 'Auditor', where: 'status = ''CLOSED''' }
    ]);
}
```

- `$user` → resolved to `req.user.id` at runtime
- `$user.attr.costCenter` → user attribute from XSUAA JWT
- Admins bypass the WHERE clause (no `where`)
- Auditors can only read CLOSED orders

## Restriction with user attributes

```cds
entity SalesOrders as projection on my.SalesOrders
  @(restrict: [{
    grant: 'READ',
    to:    'SalesPerson',
    where: 'region = $user.attr.region'  // attribute from JWT token
  }]);
```

```json
// XSUAA user token (decoded)
{
  "user_name": "alice",
  "xs.user.attributes": {
    "region": ["EMEA"]   // CAP resolves $user.attr.region = 'EMEA'
  }
}
```

## Handler-based row filtering (fallback)

When `@restrict where` doesn't cover your logic, filter in a BEFORE handler:

```js
this.before('READ', 'Orders', (req) => {
  const { id, is } = req.user

  if (is('Admin')) return   // No restriction for admin

  if (is('Buyer')) {
    // Append WHERE clause to the query
    req.query.where({ buyer_ID: id })
  } else if (is('RegionalManager')) {
    const region = req.user.attr.region
    req.query.where({ region })
  }
})
```

## HANA Analytic Privilege (database-level RLS)

For maximum security — enforced at the HANA engine level, not application level:

```sql
-- gen/db/src/privileges/OrdersReadPrivilege.hdbanalyticprivilege
-- (XML-format, created with HANA modeler or HAA)
CREATE ANALYTIC PRIVILEGE "OrdersReadPrivilege"
  USING VIEW "MY_BOOKSHOP_ORDERS"
  FOR SELECT
  WHERE "BUYER_ID" = SESSION_USER;
```

HANA filters rows using the connected database user identity — even if a rogue query bypasses the app layer.

## Multitenant isolation

```js
// Tenant ID is always available in multitenant apps
this.before('READ', 'Orders', (req) => {
  // In MTXS-based multitenant apps, each tenant has a separate HDI container
  // req.tenant = 'tenant-acme-corp'
  // Data isolation is automatic via separate schema

  // For shared-schema multitenancy, filter explicitly:
  req.query.where({ tenant_ID: req.tenant })
})
```

## Testing row-level security

```js
// Test with different mock users
it('buyer sees only own orders', async () => {
  const { GET } = cds.test('.').in(__dirname + '/..')
    .with({ user: { id: 'alice', roles: ['Buyer'] } })

  const { data } = await GET('/orders/Orders')
  expect(data.value.every(o => o.buyer_ID === 'alice')).toBe(true)
})

it('admin sees all orders', async () => {
  const { GET } = cds.test('.').in(__dirname + '/..')
    .with({ user: { id: 'admin-user', roles: ['Admin'] } })

  const { data } = await GET('/orders/Orders')
  expect(data.value.length).toBeGreaterThan(1)
})
```

## Bypass attempts and how CAP stops them

```
Client: GET /orders/Orders?$filter=buyer_ID ne 'alice'

Without RLS: Returns orders for all buyers
With @restrict where: CAP ANDs the where clause: buyer_ID='alice' AND buyer_ID ne 'alice' → 0 rows
With handler filter: req.query.where({ buyer_ID: id }) is prepended by CAP — same result
```

## Common mistakes

| Mistake | Symptom | Fix |
|---|---|---|
| Missing `@(requires: ...)` on service | Restriction ignored for unauthenticated | Add `@requires` to the service |
| Using `=` instead of `== ` in where clause | CDS parse error | Use `=` (single equals) in CDS annotation strings |
| Forgetting `$user.attr` scope | Attribute undefined at runtime | Declare the attribute in xs-security.json first |
| No test for admin bypass | Admins also filtered | Test admin path explicitly — no where clause for admins |

## Hands-on exercise
1. Add `@restrict` to your Orders entity: Buyers see only their own, Admins see all
2. Write a BEFORE handler that verifies the filter is applied
3. Test with two mock users (alice as Buyer, admin as Admin)
4. Add a `$filter` bypass attempt in your test and verify CAP blocks it

## Checkpoint ✓
- [ ] `@restrict where: 'field = $user'` auto-filters rows per user at query time
- [ ] `$user.attr.attrName` resolves XSUAA JWT attributes in where clauses
- [ ] Handler `req.query.where(...)` can append filters programmatically
- [ ] HANA Analytic Privileges enforce RLS at the engine level for maximum security
$md$
WHERE slug = 'cap-43-rls';


-- ── Lesson 44 — Performance Tuning & Indexing ─────────────────────────────────

UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 44 — Performance Tuning & Indexing

## What you'll learn
- Adding secondary indexes via CDS annotations
- N+1 query problem and how to avoid it with `$expand`
- Profiling slow queries with HANA EXPLAIN PLAN
- CAP-level query optimisations: projection, pagination
- Connection pooling configuration

## Why this matters
A CAP app that works fine with 1000 rows grinds to a halt at 1 million. Most performance problems are predictable: missing indexes, unbounded queries, N+1 reads. Fixing these is cheap before production; expensive after.

## Secondary indexes in CDS

```cds
entity Orders {
  key ID         : UUID;
  status         : String;
  buyer_ID       : UUID;
  createdAt      : Timestamp;
  region         : String;

  // Secondary indexes — generated by cds build for HANA
  @index buyer_ID;              // most common filter field
  @index { region, status };   // composite index for common combined filter
  @index createdAt;            // for date-range queries
}
```

Generated HANA artifact:
```sql
-- gen/db/src/gen/Orders.hdbindex
INDEX "ORDERS_BUYER_IDX" ON "ORDERS" ("BUYER_ID");
INDEX "ORDERS_REGION_STATUS_IDX" ON "ORDERS" ("REGION", "STATUS");
INDEX "ORDERS_CREATEDAT_IDX" ON "ORDERS" ("CREATED_AT");
```

> HANA Cloud tables are column-store by default. Secondary indexes help most for equality and range filters on low-cardinality columns. High-cardinality columns (UUIDs) benefit less from indexes.

## N+1 query problem

```js
// WRONG — fires 1 SELECT for orders + N SELECTs for each buyer
const orders = await SELECT.from('Orders')
for (const o of orders) {
  o.buyerName = (await SELECT.one.from('Users').where({ ID: o.buyer_ID })).name
}

// CORRECT — one query with expand
const orders = await SELECT.from('Orders').columns(o => {
  o.ID, o.status,
  o.buyer(u => { u.ID, u.name })
})
```

## OData $expand depth control

```js
// Cap default allows unlimited expand depth — dangerous in production
// Limit in handler
this.before('READ', 'Orders', (req) => {
  const expandDepth = countExpands(req.query)
  if (expandDepth > 2) return req.reject(400, 'Maximum 2 levels of $expand allowed')
})

function countExpands (query) {
  // Simple depth counter
  let depth = 0
  const str = JSON.stringify(query)
  str.replace(/"expand"/g, () => depth++)
  return depth
}
```

## Mandatory projection for large entities

```js
this.before('READ', 'Products', (req) => {
  // Remove LargeString columns from list queries
  const columns = req.query.SELECT?.columns
  if (columns) {
    req.query.SELECT.columns = columns.filter(c =>
      !['description', 'specifications', 'manual'].includes(c.ref?.[0])
    )
  }
})
```

## Pagination — always enforce

```js
this.before('READ', 'Orders', (req) => {
  const MAX_PAGE_SIZE = 100
  if (!req.query.SELECT?.limit?.rows?.val || req.query.SELECT.limit.rows.val > MAX_PAGE_SIZE) {
    req.query.limit(MAX_PAGE_SIZE)
  }
})
```

## HANA EXPLAIN PLAN

```sql
-- Run in HANA Database Explorer to diagnose slow queries
EXPLAIN PLAN FOR
SELECT * FROM ORDERS WHERE STATUS = 'DRAFT' AND REGION = 'EMEA';

SELECT * FROM "SYS"."EXPLAIN_PLAN_TABLE" WHERE SESSION_USER = CURRENT_USER
ORDER BY STATEMENT_NAME DESC LIMIT 50;
```

Look for:
- **Full table scan** on large tables → add an index
- **Nested loop join** on non-indexed foreign key → add index on FK column
- **Hash join** on sorted data → add ORDER BY to leverage existing sort

## Connection pooling

```json
// .cdsrc.json
{
  "requires": {
    "db": {
      "[production]": {
        "kind": "hana",
        "pool": {
          "max":               10,    // max connections
          "min":               2,     // kept-alive connections
          "acquireTimeoutMs":  5000,  // fail fast if no connection available
          "idleTimeoutMs":     30000  // release idle connections
        }
      }
    }
  }
}
```

## Query profiling in CAP

```js
// Enable query logging
// In .cdsrc.json:
{ "log": { "levels": { "db": "debug" } } }

// Or per-request in handler
this.before('READ', 'Orders', (req) => {
  console.time('READ Orders')
})
this.after('READ', 'Orders', (data, req) => {
  console.timeEnd('READ Orders')
  console.log('Returned', data.length, 'rows')
})
```

## Performance checklist

```
□ All FK columns used in JOIN or WHERE have secondary indexes
□ No unbounded queries — always enforce $top / limit()
□ Large text columns excluded from list projections
□ $expand depth limited to 2–3 levels max
□ Connection pool tuned for your expected concurrency
□ Slow queries identified with EXPLAIN PLAN before go-live
□ Batch operations use native SQL for > 10K rows
```

## Hands-on exercise
1. Add `@index buyer_ID` to your Orders entity and rebuild
2. Write a list query that intentionally triggers N+1 — verify with DB debug logging
3. Refactor to a single `SELECT.from().columns()` with expanded buyer
4. Add a BEFORE handler that enforces max 50 rows on all READ operations

## Checkpoint ✓
- [ ] `@index field` on a CDS entity generates a HANA secondary index
- [ ] N+1 problem: fix by expanding associations in a single CQL query
- [ ] Always limit result size — use `req.query.limit()` in a BEFORE handler
- [ ] EXPLAIN PLAN in HANA Database Explorer identifies missing indexes
$md$
WHERE slug = 'cap-44-perf';

-- ── Lesson 45 — Audit Logging with SAP Audit Log Service ─────────────────────

UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 45 — Audit Logging with SAP Audit Log Service

## What you'll learn
- What the SAP Audit Log Service provides and when it's required
- `@PersonalData` annotations to mark sensitive fields
- Enabling the CAP audit-log plugin
- What gets logged automatically vs what you log manually
- Viewing audit logs in BTP Cockpit

## Why this matters
GDPR and SOX mandate immutable audit records for access to personal data. SAP Audit Log Service provides a tamper-proof, cloud-hosted log. CAP's audit-log plugin can generate these automatically from `@PersonalData` annotations — no custom logging code required for standard CRUD.

## SAP Audit Log Service overview

- Hosted in BTP — separate from your app's database
- Write-once, tamper-proof log entries
- Retention: 90 days (standard), 1–3 years (premium)
- Query via SAP Audit Log Viewer (BTP Cockpit)
- Required for financial-grade and healthcare apps

## Step 1 — Annotate personal data in CDS

```cds
// db/schema.cds
using { managed, cuid } from '@sap/cds/common';

entity Customers : cuid, managed {
  @PersonalData.FieldSemantics: 'DataSubjectID'
  customerNumber : String;          // ← unique identifier for the data subject

  @PersonalData.IsPotentiallyPersonal: true
  firstName : String;

  @PersonalData.IsPotentiallyPersonal: true
  lastName  : String;

  @PersonalData.IsPotentiallySensitive: true
  dateOfBirth : Date;               // sensitive — stricter logging

  email     : String;
  @PersonalData.IsPotentiallyPersonal: true
  phoneNumber : String;
}

annotate Customers with @PersonalData: {
  EntitySemantics: 'DataSubject',
  DataSubjectRole: 'Customer'
};
```

## Step 2 — Enable the audit-log plugin

```bash
npm install @cap-js/audit-logging
```

```json
// .cdsrc.json
{
  "requires": {
    "audit-log": {
      "[production]": {
        "kind": "audit-log-service",
        "vcap": { "label": "auditlog" }
      },
      "[development]": {
        "kind": "@cap-js/audit-logging",
        "impl": "@cap-js/audit-logging/lib/sqlite"  // logs to console in dev
      }
    }
  }
}
```

## Step 3 — Bind Audit Log Service in MTA

```yaml
# mta.yaml
resources:
  - name: auditlog
    type: org.cloudfoundry.managed-service
    parameters:
      service:      auditlog
      service-plan: premium
```

```yaml
modules:
  - name: bookshop-srv
    requires:
      - name: auditlog
```

## What gets logged automatically

| Operation | Auto-logged |
|---|---|
| READ of `@PersonalData` entity | Data access log entry |
| CREATE with personal fields | Data modification log |
| UPDATE of personal fields | Before/after values |
| DELETE of `@PersonalData` entity | Data erasure log |

Each log entry includes: timestamp, user ID, tenant, operation, entity name, data subject ID, and field values (before/after for updates).

## Manual audit log entries

```js
const audit = await cds.connect.to('audit-log')

this.on('exportCustomerData', async (req) => {
  const { customerId } = req.data
  const data = await SELECT.from('Customers').where({ ID: customerId })

  // Manually log a data access event
  await audit.log('SensitiveDataExport', {
    object:  { type: 'Customers', id: { ID: customerId } },
    data_subject: { type: 'Customer', id: customerId },
    attributes: [{ name: 'export', new_value: 'GDPR export triggered' }],
    tenant:  req.tenant
  })

  return data
})
```

## Viewing audit logs in BTP Cockpit

1. BTP Cockpit → Subaccount → Services → Instances → `auditlog` → Open SAP Audit Log Viewer
2. Filter by time range, user, entity type
3. Export for compliance reporting (CSV or JSON)

## Development audit log (console)

```bash
# In dev, audit entries appear in console:
[audit] READ Customers { user: 'alice', subject: { ID: 'cust-001' }, fields: ['firstName','email'] }
[audit] UPDATE Customers { user: 'alice', field: 'email', old: 'a@b.com', new: 'c@d.com' }
```

## Checkpoint ✓
- [ ] `@PersonalData.IsPotentiallyPersonal` marks fields for automatic audit logging
- [ ] `@PersonalData.EntitySemantics: 'DataSubject'` identifies the person entity
- [ ] READ, CREATE, UPDATE, DELETE on annotated entities are logged automatically
- [ ] Manual log entries via `audit.log(event, payload)` for custom operations
$md$
WHERE slug = 'cap-45-audit-log';

-- ── Lesson 46 — Personal Data & GDPR Compliance ────────────────────────────────

UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 46 — Personal Data & GDPR Compliance

## What you'll learn
- GDPR obligations relevant to CAP apps (data inventory, erasure, portability)
- `@PersonalData` annotation vocabulary
- CAP Personal Data plugin — automatic data inventory
- Implementing right-to-erasure (right-to-be-forgotten)
- Data portability (export) implementation

## Why this matters
GDPR penalties reach 4 % of global revenue. For enterprise apps on SAP BTP, implementing GDPR correctly is a compliance requirement, not optional. CAP's built-in annotations and plugin reduce this from a custom dev project to a configuration task.

## GDPR obligations for app developers

| Obligation | What it means | CAP support |
|---|---|---|
| Data inventory | Know what personal data you store | `@PersonalData` annotations → auto-inventory |
| Purpose limitation | Only store data needed for stated purpose | Annotation documentation |
| Data minimisation | Collect minimum necessary fields | Annotation + schema review |
| Right to erasure | Delete on request | `@PersonalData` + erasure handler |
| Right to portability | Export in machine-readable format | Export action |
| Breach notification | 72-hour reporting obligation | Out of scope for CAP |

## Complete @PersonalData annotation vocabulary

```cds
// DATA SUBJECT entity (the person)
annotate Customers with @PersonalData: {
  EntitySemantics : 'DataSubject',
  DataSubjectRole : 'Customer'
};

// RELATED entity (data about the person, but not the person)
annotate Orders with @PersonalData: {
  EntitySemantics  : 'DataSubjectRelated',
  DataSubjectRole  : 'Customer'
};

// Fields on the data subject
annotate Customers with {
  customerNumber @PersonalData.FieldSemantics: 'DataSubjectID';       // unique ID
  firstName      @PersonalData.IsPotentiallyPersonal: true;
  lastName       @PersonalData.IsPotentiallyPersonal: true;
  email          @PersonalData.IsPotentiallyPersonal: true;
  dateOfBirth    @PersonalData.IsPotentiallySensitive: true;           // special category
  healthRecord   @PersonalData.IsPotentiallySensitive: true;           // special category
}

// Field on related entity that links back to the data subject
annotate Orders with {
  customer @PersonalData.FieldSemantics: 'DataSubjectID';   // FK to Customers
}
```

## CAP Personal Data plugin — auto data inventory

```bash
npm install @cap-js/personal-data
```

The plugin:
1. Reads `@PersonalData` annotations at startup
2. Builds an in-memory data inventory (which entities, which fields, which data subjects)
3. Intercepts CUD operations to generate audit log entries automatically
4. Provides a `/admin/personal-data` metadata endpoint for the inventory

## Right-to-erasure implementation

```cds
// srv/admin-service.cds
service AdminService @(requires: 'admin') {
  entity Customers as projection on my.Customers;

  action  eraseCustomer (customerID : UUID) returns String;
}
```

```js
// srv/admin-service.js
this.on('eraseCustomer', async (req) => {
  const { customerID } = req.data

  // 1. Anonymise personal fields (preferred over hard delete for referential integrity)
  await UPDATE('Customers').set({
    firstName:   '[ERASED]',
    lastName:    '[ERASED]',
    email:       `erased-${customerID}@deleted.invalid`,
    dateOfBirth: null,
    phoneNumber: null,
    erasedAt:    new Date()
  }).where({ ID: customerID })

  // 2. Delete orphaned personal data in related entities
  await DELETE.from('CustomerAddresses').where({ customer_ID: customerID })
  await DELETE.from('CustomerPaymentMethods').where({ customer_ID: customerID })

  // 3. Log the erasure (mandatory for GDPR documentation)
  const audit = await cds.connect.to('audit-log')
  await audit.log('PersonalDataErasure', {
    data_subject: { type: 'Customer', id: customerID },
    user:         req.user.id,
    reason:       'GDPR Art. 17 - Right to Erasure'
  })

  return `Customer ${customerID} data erased`
})
```

## Right-to-portability (data export)

```js
this.on('exportCustomerData', async (req) => {
  const { customerID } = req.data

  const [customer, orders, addresses] = await Promise.all([
    SELECT.one.from('Customers').where({ ID: customerID }),
    SELECT.from('Orders').where({ customer_ID: customerID }),
    SELECT.from('CustomerAddresses').where({ customer_ID: customerID })
  ])

  // Return as JSON (GDPR requires machine-readable format)
  return {
    exportDate:  new Date().toISOString(),
    dataSubject: customerID,
    data: {
      profile:   customer,
      orders:    orders,
      addresses: addresses
    }
  }
})
```

## Data retention policy

```cds
entity Orders {
  key ID        : UUID;
  status        : String;
  createdAt     : Timestamp @cds.on.insert: $now;
  retainUntil   : Date;     // set to createdAt + 7 years (legal retention)
  personalDataErasedAt : Timestamp;  // set when customer erased
}
```

```js
// Scheduled cleanup job (runs daily via SAP Job Scheduling)
module.exports = async (req) => {
  const today = new Date().toISOString().split('T')[0]
  const expired = await SELECT.from('Orders').where(`retainUntil < '${today}'`)

  for (const order of expired) {
    await UPDATE('Orders').set({ buyer_name: '[ERASED]', buyer_email: null })
                          .where({ ID: order.ID })
  }
}
```

## GDPR documentation auto-generated by plugin

```
GET /admin/personal-data

{
  "entities": [
    {
      "name":    "Customers",
      "role":    "DataSubject",
      "fields":  ["firstName","lastName","email","dateOfBirth"],
      "sensitive": ["dateOfBirth"]
    },
    {
      "name":    "Orders",
      "role":    "DataSubjectRelated",
      "subject": "customer_ID → Customers"
    }
  ]
}
```

## Hands-on exercise
1. Add `@PersonalData` annotations to your Customers entity (firstName, lastName, email)
2. Install `@cap-js/personal-data` and verify the data inventory endpoint
3. Implement an `eraseCustomer` action that anonymises rather than deletes
4. Implement an `exportCustomerData` function that returns all data as JSON

## Checkpoint ✓
- [ ] `@PersonalData.EntitySemantics: 'DataSubject'` marks the person entity
- [ ] Related entities use `'DataSubjectRelated'` with a FK to the data subject
- [ ] Erasure = anonymise in place (keeps referential integrity) + delete related personal data
- [ ] Export returns a structured JSON document of all personal data for one data subject
$md$
WHERE slug = 'cap-46-personal-data';

