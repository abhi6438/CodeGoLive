-- ─────────────────────────────────────────────────────────────────────────────
-- SAP CAP Course — Module 1: CAP Foundations — Full Content
-- Run AFTER sap_cap_seed.sql
-- ─────────────────────────────────────────────────────────────────────────────

-- ── Lesson 1: What is SAP CAP? ───────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Lesson 1 — What is SAP CAP?

## What you'll learn

By the end of this lesson you'll understand what CAP is, why SAP built it, how it fits into the BTP ecosystem, and when to choose the Node.js runtime vs the Java runtime.

---

## What is CAP?

**CAP** stands for **Cloud Application Programming Model**. It is a framework of languages, libraries, and tools that SAP provides to build enterprise-grade cloud services and applications on SAP Business Technology Platform (BTP).

Think of CAP as a **full-stack backend framework** — like Express.js or Spring Boot, but purpose-built for SAP's cloud world. It handles the boring, repetitive parts of building cloud services so you can focus on business logic.

---

## The three pillars of CAP

### 1. CDS — Core Data Services
CDS is CAP's **schema and query language**. You describe your data model and services in `.cds` files using a clean, human-readable syntax. CAP automatically generates OData V4 APIs, database tables, and TypeScript types from those definitions.

```cds
// A complete data model + service in ~10 lines of CDS
entity Books {
  key ID   : UUID;
      title: String(100);
      price: Decimal(10,2);
}

service BookshopService {
  entity Books as projection on Books;
}
```

### 2. Service runtimes (Node.js or Java)
CAP runs on two runtimes:
- **Node.js** (`@sap/cds`) — faster to develop, great for APIs and lightweight services
- **Java** (`com.sap.cds:cds4j`) — better for heavy enterprise workloads, integrates with Spring Boot

> This course uses **Node.js**. Everything you learn is transferable to Java with minor syntax differences.

### 3. BTP integration
CAP is first-class on BTP. It automatically wires up to XSUAA (auth), SAP HANA Cloud (persistence), Destination Service (connectivity), and Event Mesh (messaging) with minimal configuration.

---

## Where CAP fits in BTP

```
Browser / Fiori App
        │
        ▼
   AppRouter            ← handles auth, routes
        │
        ▼
  CAP Service           ← your business logic (this course)
        │
   ┌────┴────┐
   ▼         ▼
HANA Cloud  External APIs (S/4HANA, etc.)
```

Your CAP service is the **backend layer** — it exposes OData V4 or REST APIs, talks to the database, calls external services, and enforces authorization rules.

---

## Why SAP built CAP

Before CAP, SAP developers had to:
- Write ABAP for backend logic
- Hand-code OData services (tedious and error-prone)
- Manually wire up authentication, database, and deployment

CAP removes all of that boilerplate. You define your model in CDS and CAP generates OData endpoints, database tables, and documentation automatically.

---

## Node.js vs Java — which to choose?

| | Node.js | Java |
|---|---|---|
| **Best for** | APIs, microservices, rapid development | Heavy processing, large enterprise orgs |
| **Learning curve** | Low | Medium–High |
| **SAP support** | Full | Full |
| **Spring Boot** | No | Yes |
| **This course** | ✅ Yes | ❌ No |

For new projects on BTP, **Node.js is the recommended starting point** unless your organization has a strong Java preference.

---

## Key terms glossary

| Term | Meaning |
|------|---------|
| **CDS** | Core Data Services — CAP's schema language |
| **Entity** | A database table defined in CDS |
| **Service** | A CDS-defined API that exposes entities |
| **Handler** | Node.js function that runs on CRUD events |
| **HDI** | HANA Deployment Infrastructure — how HANA schemas are deployed |
| **XSUAA** | SAP's OAuth 2.0 authorization server on BTP |
| **MTA** | Multi-Target Application — the BTP deployment package |

---

## Checkpoint ✓

You should now be able to answer:
- What problem does CAP solve?
- What are the three pillars of CAP?
- What is CDS?
- When would you choose Java over Node.js?

In the next lesson, you'll set up your development environment and install all the tools you need.
$md$ WHERE slug = 'cap-01-what-is-cap';


-- ── Lesson 2: Setting Up Your Dev Environment ────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Lesson 2 — Setting Up Your Dev Environment

## What you'll build

A fully working CAP development environment on your local machine with Node.js, the CAP CLI, VS Code extensions, and a verified installation you can rely on for the entire course.

---

## Prerequisites

- A computer running macOS, Windows, or Linux
- Internet access
- Basic terminal / command-line comfort

---

## Step 1 — Install Node.js

CAP requires **Node.js 18 or 20** (LTS versions). Do not use Node 21+ for CAP — some dependencies are not yet verified.

**Option A — Direct download (simplest)**

Go to [https://nodejs.org](https://nodejs.org) and download the **LTS** version.

**Option B — nvm (recommended for developers)**

```bash
# Install nvm (macOS/Linux)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

# Restart terminal, then:
nvm install 20
nvm use 20
nvm alias default 20
```

**Verify:**
```bash
node --version   # Should print v20.x.x
npm --version    # Should print 10.x.x
```

---

## Step 2 — Install the CAP CLI

The `@sap/cds-dk` package gives you the `cds` command-line tool.

```bash
npm install -g @sap/cds-dk
```

> **Why `-g`?** The `-g` flag installs it globally so `cds` is available in any folder, not just one project.

**Verify:**
```bash
cds --version
# Should print: @sap/cds: 8.x.x  @sap/cds-dk: 8.x.x
```

---

## Step 3 — Install VS Code + CAP Extensions

Download VS Code from [https://code.visualstudio.com](https://code.visualstudio.com).

Then install these extensions (Ctrl+Shift+X → search by name):

| Extension | Purpose |
|-----------|---------|
| **SAP CDS Language Support** | Syntax highlighting, autocomplete, error checking for `.cds` files |
| **REST Client** | Send HTTP requests directly from VS Code to test your service |
| **SQLite Viewer** | Inspect your local SQLite database visually |

```
Extensions to install:
- SAPSE.vscode-cds
- humao.rest-client
- qwtel.sqlite-viewer
```

---

## Step 4 — Install SQLite (for local development)

CAP uses SQLite as the local database during development. It's usually pre-installed on macOS and Linux.

```bash
# Check if already installed
sqlite3 --version

# If not installed — macOS
brew install sqlite

# Windows: download from https://www.sqlite.org/download.html
```

---

## Step 5 — Optional: SAP Business Application Studio (BAS)

If you're working in a BTP Trial environment, you can use **SAP Business Application Studio** instead of VS Code. BAS is a browser-based IDE with all CAP tools pre-installed.

To access BAS:
1. Log in to your BTP Trial cockpit
2. Go to **Services → Service Marketplace**
3. Search for **SAP Business Application Studio** → Subscribe
4. Open the application → Create a Dev Space (type: **Full Stack Cloud Application**)

> For this course, **local VS Code is recommended** — it's faster and you can work offline.

---

## Step 6 — Verify everything works

Run this complete verification:

```bash
node --version     # v18.x or v20.x
npm --version      # 9.x or 10.x
cds --version      # 8.x.x
sqlite3 --version  # 3.x.x
git --version      # any recent version
```

All green? You're ready for Lesson 3.

---

## Common setup issues

**`cds: command not found` after install**
Your PATH doesn't include npm global binaries. Run:
```bash
# macOS/Linux
echo 'export PATH="$(npm prefix -g)/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc

# Windows — restart the terminal after npm install
```

**Node version mismatch errors later**
Always use Node 18 or 20. If you installed a different version, use `nvm use 20` before working on CAP projects.

**BAS Dev Space stuck "starting"**
Refresh the browser after 2 minutes. If still stuck, delete the dev space and create a new one.

---

## Checkpoint ✓

Run `cds --version` — if it prints a version number, you're done. In Lesson 3, you'll use this setup to create your first real CAP project.
$md$ WHERE slug = 'cap-02-setup';


-- ── Lesson 3: Your First CAP Project ────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Lesson 3 — Your First CAP Project

## What you'll build

A running CAP project with a bookshop data model and service — with live OData endpoints accessible in your browser, all in under 10 minutes.

---

## Step 1 — Create the project

Open a terminal in an empty folder and run:

```bash
mkdir my-bookshop && cd my-bookshop
cds init
```

You'll see:
```
Creating new CAP project in ./my-bookshop
  Adding .gitignore
  Adding package.json
  Adding .cdsrc.json
  Adding README.md
```

Now install dependencies:
```bash
npm install
```

---

## Step 2 — Understand the generated structure

```
my-bookshop/
├── app/          ← Fiori UI apps go here (empty for now)
├── db/           ← Data model (.cds files)
├── srv/          ← Service definitions and custom handlers
├── .cdsrc.json   ← CAP configuration
├── package.json
└── README.md
```

> **Rule of thumb**: `db/` = what you store, `srv/` = what you expose

---

## Step 3 — Add a data model

Create `db/schema.cds`:

```cds
namespace my.bookshop;

entity Books {
  key ID     : UUID  @Core.Computed;
      title  : String(100) not null;
      author : String(100);
      stock  : Integer default 0;
      price  : Decimal(10, 2);
}

entity Authors {
  key ID    : UUID @Core.Computed;
      name  : String(100) not null;
      books : Association to many Books on books.author = $self.name;
}
```

**What's happening here:**
- `namespace` — groups your entities to avoid name collisions
- `key ID : UUID` — auto-generated UUID primary key
- `@Core.Computed` — tells OData this field is server-managed (client cannot set it)
- `Association to many` — a relationship to Books

---

## Step 4 — Define a service

Create `srv/catalog-service.cds`:

```cds
using my.bookshop as db from '../db/schema';

service CatalogService {
  entity Books   as projection on db.Books;
  entity Authors as projection on db.Authors;
}
```

**What's happening:**
- `using ... from` — imports the data model
- `as projection on` — exposes the entity through the service
- By default, all CRUD operations (CREATE, READ, UPDATE, DELETE) are enabled

---

## Step 5 — Start the server

```bash
cds watch
```

You'll see output like:
```
[cds] - model loaded from 2 file(s):
  db/schema.cds
  srv/catalog-service.cds

[cds] - connect to db > sqlite { database: ':memory:' }
[cds] - serving CatalogService { path: '/odata/v4/catalog' }

[cds] - server listening on { url: 'http://localhost:4004' }
[cds] - launched at ..., version: 8.x.x
```

Open your browser: **[http://localhost:4004](http://localhost:4004)**

You'll see the CAP welcome page with a link to your service.

---

## Step 6 — Explore the auto-generated API

Click on **CatalogService** in the browser. You'll see links to:

```
/odata/v4/catalog/Books        ← GET all books
/odata/v4/catalog/Authors      ← GET all authors
/odata/v4/catalog/$metadata    ← Full OData metadata document
```

Click on `Books` — you'll get:
```json
{ "@odata.context": "...", "value": [] }
```

Empty for now — no data yet. Let's add some.

---

## Step 7 — Seed initial data

Create `db/data/my.bookshop-Books.csv`:

```csv
ID,title,author,stock,price
f1f1f1f1-0000-0000-0000-000000000001,The Hitchhiker's Guide,Douglas Adams,100,12.99
f1f1f1f1-0000-0000-0000-000000000002,Clean Code,Robert C. Martin,50,35.00
f1f1f1f1-0000-0000-0000-000000000003,Domain-Driven Design,Eric Evans,30,45.00
```

> **File naming convention**: `<namespace>-<EntityName>.csv`

The `cds watch` process auto-reloads and picks up the CSV. Refresh `/odata/v4/catalog/Books` in your browser — you'll see the three books.

---

## Step 8 — Try OData queries

In your browser or REST Client, try these:

```
# Filter books under $20
GET http://localhost:4004/odata/v4/catalog/Books?$filter=price lt 20

# Select only title and price
GET http://localhost:4004/odata/v4/catalog/Books?$select=title,price

# Sort by price descending
GET http://localhost:4004/odata/v4/catalog/Books?$orderby=price desc

# Take only top 2
GET http://localhost:4004/odata/v4/catalog/Books?$top=2
```

All of these work **without writing a single line of handler code**. CAP's generic providers handle it automatically.

---

## Common mistakes

**`Error: Cannot find module '@sap/cds'`**
You forgot to run `npm install`. Run it now.

**CSV data not loading**
Check the file name matches exactly: `namespace-EntityName.csv`. Case sensitive.

**Port 4004 already in use**
Another CAP server is running. Press `Ctrl+C` in the other terminal, or run `cds watch --port 4005`.

---

## Checkpoint ✓

You should have:
- [ ] A running CAP server at `http://localhost:4004`
- [ ] Three books visible at `/odata/v4/catalog/Books`
- [ ] Tested at least two OData query options (`$filter`, `$select`, etc.)

In Lesson 4, we go deeper into the project structure so you know exactly where everything belongs as your app grows.
$md$ WHERE slug = 'cap-03-first-project';


-- ── Lesson 4: Understanding CAP Project Structure ────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Lesson 4 — Understanding CAP Project Structure

## What you'll learn

Where every file in a CAP project belongs, what `.cdsrc.json` controls, how profiles work, and how to structure a project that stays clean as it scales to dozens of services and entities.

---

## The full structure at a glance

```
my-project/
│
├── app/                      ← Fiori / UI5 frontends
│   └── my-app/               ← One subfolder per UI app
│       └── webapp/
│
├── db/                       ← Data model layer
│   ├── schema.cds            ← Entity definitions
│   ├── data/                 ← CSV seed data
│   │   └── my.ns-Books.csv
│   └── src/                  ← HANA-specific artifacts (deployed to HANA only)
│       └── my-view.hdbview
│
├── srv/                      ← Service layer
│   ├── catalog-service.cds   ← Service definition
│   ├── catalog-service.js    ← Custom handlers (same base name)
│   └── lib/                  ← Shared utilities
│
├── .cdsrc.json               ← CAP configuration
├── .env                      ← Local secrets (never commit this)
├── package.json
└── mta.yaml                  ← BTP deployment descriptor (added later)
```

---

## The `db/` folder — your data layer

`db/` contains everything related to **what you store**.

```
db/
├── schema.cds          ← All entity definitions
├── data/               ← CSV files for local seed data
│   └── ns-Entity.csv   ← Named: <namespace>-<Entity>.csv
└── src/                ← HANA-only artifacts
    └── *.hdbview       ← HANA Calculation Views, Stored Procs
```

**Rules:**
- Put all entity definitions in `db/schema.cds` (or split into multiple `.cds` files for large projects)
- CSV files in `db/data/` are auto-loaded by `cds watch` into the in-memory SQLite database
- The `db/src/` folder is only deployed to HANA, not SQLite — put native HANA SQL here

---

## The `srv/` folder — your service layer

`srv/` contains everything related to **what you expose and how you handle it**.

```
srv/
├── catalog-service.cds     ← OData service definition
├── catalog-service.js      ← Custom handlers (matched by name)
├── admin-service.cds       ← Another service (admin-only)
├── admin-service.js
└── lib/
    └── helpers.js          ← Shared code (not a CDS file)
```

**Critical rule**: The `.js` handler file must have the **exact same base name** as the `.cds` service file. CAP auto-connects them:

```
catalog-service.cds  ←→  catalog-service.js   ✅ Auto-wired
adminService.cds     ←→  adminService.js       ✅ Auto-wired
catalog-service.cds  ←→  handlers.js           ❌ NOT auto-wired
```

---

## The `.cdsrc.json` file — CAP configuration

This is the brain of your CAP project. It controls how CAP behaves in different environments.

```json
{
  "requires": {
    "db": {
      "kind": "sqlite",
      "credentials": { "database": ":memory:" }
    }
  },
  "features": {
    "fetch_csrf": true
  }
}
```

**Important settings:**

```json
{
  "requires": {
    "db": {
      "[development]": {
        "kind": "sqlite",
        "credentials": { "database": "db.sqlite" }
      },
      "[production]": {
        "kind": "hana"
      }
    },
    "auth": {
      "[development]": { "kind": "mocked" },
      "[production]": { "kind": "xsuaa" }
    }
  }
}
```

---

## Profiles — switching environments

CAP uses **profiles** to switch config between dev and production. The profile is set via the `NODE_ENV` environment variable.

```bash
# Development (default)
cds watch                        # Uses [development] profile

# Production
NODE_ENV=production cds serve    # Uses [production] profile
```

You can define your own profiles:

```json
{
  "requires": {
    "db": {
      "[test]": {
        "kind": "sqlite",
        "credentials": { "database": ":memory:" }
      }
    }
  }
}
```

```bash
NODE_ENV=test npx jest
```

---

## The `package.json` — key CAP fields

```json
{
  "name": "my-bookshop",
  "dependencies": {
    "@sap/cds": "^8.0.0",       ← CAP runtime (required)
    "@sap/cds-dk": "^8.0.0",    ← CAP CLI tools (dev)
    "express": "^4.18.0",       ← Web framework
    "@sap/hana-client": "^2.x"  ← HANA driver (add for HANA)
  },
  "scripts": {
    "start": "cds serve --production",
    "watch": "cds watch",
    "build": "cds build/all"
  },
  "cds": {
    "requires": { ... }          ← Can put cdsrc.json content here
  }
}
```

> **Tip**: For small projects, you can put your CAP config in `package.json` under the `"cds"` key instead of a separate `.cdsrc.json`.

---

## Splitting large schemas

As your project grows, split the data model across multiple files:

```
db/
├── common.cds          ← Shared types and aspects
├── products.cds        ← Product-related entities
└── orders.cds          ← Order-related entities
```

In `srv/catalog-service.cds`, import what you need:
```cds
using { sap.capbookshop.Products } from '../db/products';
using { sap.capbookshop.Orders }   from '../db/orders';
```

---

## Common mistakes

**Putting business logic in `.cds` files**
CDS files are schema/definition only. No JavaScript in `.cds`.

**Naming handler file differently from service file**
`CatalogService.js` won't wire to `catalog-service.cds`. Names must match exactly (with the same casing rules that CDS uses).

**Committing `.env` to git**
Always add `.env` to `.gitignore`. It contains secrets.

---

## Checkpoint ✓

You now understand:
- [ ] What goes in `db/`, `srv/`, and `app/`
- [ ] How `.cdsrc.json` profiles switch between SQLite and HANA
- [ ] How handler files are auto-wired to service definitions
- [ ] How to split a large schema into multiple `.cds` files

In Lesson 5, we go deep into CDS syntax — the language you'll use to define everything.
$md$ WHERE slug = 'cap-04-project-structure';


-- ── Lesson 5: CDS Schema Basics ──────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Lesson 5 — CDS Schema Basics

## What you'll learn

The full CDS grammar — namespaces, entity definitions, service definitions, and the core keywords you'll use in every CAP project.

---

## What is CDS?

CDS (Core Data Services) is CAP's **domain-specific language** for describing data and services. It compiles into SQL (for the database), OData (for the API), and TypeScript types (for your IDE).

One `.cds` file can replace hundreds of lines of boilerplate SQL, OData XML, and TypeScript declarations.

---

## Namespaces

Namespaces prevent name collisions when your project grows or imports from other packages.

```cds
namespace com.mycompany.bookshop;

entity Books { ... }
// Full name: com.mycompany.bookshop.Books
```

**Convention**: Use reverse-domain notation like Java packages — `com.companyname.project`.

You can have multiple namespaces in one project. Each file can declare its own:

```cds
// db/products.cds
namespace com.mycompany.products;
entity Product { ... }

// db/orders.cds
namespace com.mycompany.orders;
entity Order { ... }
```

---

## Basic entity definition

```cds
entity Books {
  key ID    : UUID;
      title : String(100);
      price : Decimal(10,2);
      stock : Integer default 0;
      active: Boolean default true;
}
```

**Syntax rules:**
- `key` marks the primary key field(s)
- Type comes after `:` (colon)
- `default` sets a default value
- Fields without `not null` are **nullable** by default

---

## Built-in scalar types

| CDS Type | SQL equivalent | Use for |
|----------|---------------|---------|
| `UUID` | NVARCHAR(36) | Primary keys |
| `String(n)` | NVARCHAR(n) | Short text |
| `LargeString` | CLOB / NCLOB | Long text, markdown |
| `Integer` | INTEGER | Whole numbers |
| `Int64` | BIGINT | Large numbers |
| `Decimal(p,s)` | DECIMAL(p,s) | Money, measurements |
| `Double` | DOUBLE | Floating point |
| `Boolean` | BOOLEAN | True/false |
| `Date` | DATE | Date only (2024-01-15) |
| `Time` | TIME | Time only (14:30:00) |
| `DateTime` | DATETIME | Date + time (no timezone) |
| `Timestamp` | TIMESTAMP | Date + time + timezone |
| `Binary(n)` | VARBINARY(n) | Raw bytes |

---

## The `using` keyword — imports

Use `using` to import entities from other files:

```cds
// srv/catalog-service.cds
using com.mycompany.bookshop from '../db/schema';
// Now you can reference: com.mycompany.bookshop.Books

// Or import with alias
using com.mycompany.bookshop as bookshop from '../db/schema';
// Now: bookshop.Books
```

Import specific entities:
```cds
using { com.mycompany.bookshop.Books, com.mycompany.bookshop.Authors } from '../db/schema';
```

---

## Service definitions

A service is a CDS concept that maps to an OData service:

```cds
service CatalogService @(path: '/catalog') {
  entity Books   as projection on com.mycompany.bookshop.Books;
  entity Authors as projection on com.mycompany.bookshop.Authors;
}
```

**Key service concepts:**
- `@(path: '/catalog')` — sets the URL path (default is lowercase service name)
- `as projection on` — exposes an entity through the service
- You can expose multiple entities in one service
- You can have multiple services in one CAP project

---

## Restricting operations

By default, a service entity supports full CRUD. You can restrict it:

```cds
service CatalogService {
  // Read-only
  @readonly entity Books as projection on db.Books;

  // Create + read only (no update/delete)
  @insertonly entity Reviews as projection on db.Reviews;

  // Explicit list
  entity Orders as projection on db.Orders
    actions { action cancel(); };
}
```

---

## Comments in CDS

```cds
// Single-line comment

/*
  Multi-line comment
*/

/**
 * Doc comment — appears in OData metadata as @Core.Description
 */
entity Books { ... }
```

---

## Annotations in CDS

Annotations add metadata that drives OData, Fiori UI, validation, and more:

```cds
@title: 'Book Catalog'
entity Books {
  key ID    : UUID;
      @title: 'Book Title'
      @mandatory
      title : String(100);
      
      @title: 'Price in USD'
      @Measures.ISOCurrency: 'USD'
      price : Decimal(10, 2);
}
```

We cover annotations in depth in Lesson 14. For now, remember the syntax: `@AnnotationName: value` placed before the field or entity.

---

## A complete, realistic schema

```cds
namespace com.bookshop;
using { cuid, managed } from '@sap/cds/common';

entity Books : cuid, managed {
  title    : String(100) not null;
  descr    : LargeString;
  price    : Decimal(10,2);
  stock    : Integer default 0;
  author   : Association to Authors;
  genre    : Association to Genres;
}

entity Authors : cuid {
  name  : String(100) not null;
  books : Association to many Books on books.author = $self;
}

entity Genres {
  key ID   : Integer;
      name : String(50) not null;
}
```

> **Note the `cuid` and `managed` aspects** — these are SAP's built-in reusable aspects. `cuid` adds a UUID key called `ID`. `managed` adds `createdAt`, `createdBy`, `modifiedAt`, `modifiedBy`. You'll learn about aspects in Lesson 12.

---

## Checkpoint ✓

- [ ] Can you write an entity with 5 different field types?
- [ ] Can you add a namespace?
- [ ] Can you import and expose an entity in a service?
- [ ] Do you understand the difference between `entity` and `service`?

In Lesson 6 we go deeper into entities — calculated fields, virtual elements, and all the ways to declare data.
$md$ WHERE slug = 'cap-05-cds-basics';


-- ── Lesson 6: Defining Entities & Types ──────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Lesson 6 — Defining Entities & Types

## What you'll learn

Every way to declare fields in CDS — scalars, virtual elements, calculated fields, custom types, and how to define reusable types that keep your schema consistent.

---

## Entities in depth

An entity in CDS maps to a **database table**. Every entity must have at least one `key` field.

### Compound keys (multi-field primary key)

```cds
entity OrderItems {
  key order  : Association to Orders;
  key lineNo : Integer;
      product: String(50);
      qty    : Integer;
}
```

> **Avoid compound keys** where possible. UUID keys are simpler, and CAP handles them automatically.

### Elements with defaults

```cds
entity Products {
  key ID     : UUID;
      status : String(20) default 'active';
      stock  : Integer    default 0;
      taxRate: Decimal    default 0.20;
}
```

### Nullable vs not null

```cds
entity Person {
  key ID       : UUID;
      name     : String not null;  // required
      nickname : String;           // nullable (default)
      age      : Integer;          // nullable
}
```

---

## Virtual elements

Virtual elements exist in the **service layer** but are not persisted to the database. They are computed or populated by handlers at runtime.

```cds
entity Books {
  key ID      : UUID;
      title   : String(100);
      price   : Decimal(10,2);
      stock   : Integer;
      
      // Virtual — computed in a handler, not stored in DB
      virtual discount     : Decimal(10,2);
      virtual isAvailable  : Boolean;
}
```

In your handler, populate them:
```javascript
this.after('READ', 'Books', books => {
  for (const book of books) {
    book.discount    = book.price > 30 ? book.price * 0.1 : 0;
    book.isAvailable = book.stock > 0;
  }
});
```

---

## Calculated elements (stored)

Calculated elements are **persisted** — the value is computed from other fields and stored in the DB:

```cds
entity OrderItems {
  key ID       : UUID;
      quantity : Integer;
      unitPrice: Decimal(10,2);
      
      // Calculated: stored in DB, recomputed on INSERT/UPDATE
      totalPrice = quantity * unitPrice : Decimal(10,2);
}
```

> **Calculated vs Virtual**: Calculated = stored in DB, computed from other fields. Virtual = not in DB, computed in handler at read time.

---

## Custom types

Define reusable types to keep your schema consistent:

```cds
// db/types.cds
namespace com.bookshop.types;

type BookTitle  : String(100);
type Price      : Decimal(10, 2);
type ISBN       : String(13);
type Status     : String(20) enum {
  active    = 'active';
  inactive  = 'inactive';
  archived  = 'archived';
};
```

Use them in entities:
```cds
using { com.bookshop.types } from './types';

entity Books {
  key ID    : UUID;
      title : types.BookTitle;
      price : types.Price;
      isbn  : types.ISBN;
      status: types.Status default 'active';
}
```

---

## Enum types

Enums enforce that a field can only have specific values:

```cds
type Priority : Integer enum {
  low    = 1;
  medium = 2;
  high   = 3;
  urgent = 4;
}

entity Tasks {
  key ID      : UUID;
      title   : String(200);
      priority: Priority default 2;
}
```

CAP validates enum values on INSERT and UPDATE automatically. Trying to set `priority = 99` will get rejected.

---

## Structured types

Structured types let you define a record shape and reuse it:

```cds
type Address {
  street  : String(100);
  city    : String(50);
  country : String(50);
  zip     : String(10);
}

entity Customers {
  key ID              : UUID;
      name            : String(100);
      billingAddress  : Address;
      shippingAddress : Address;
}
```

> **In HANA**: Structured types are stored as a JSON column. In SQLite, CAP flattens them: `billingAddress_street`, `billingAddress_city`, etc.

---

## Array types

```cds
entity Products {
  key ID   : UUID;
      tags : array of String(50);
}
```

> Arrays are stored as JSON in both SQLite and HANA. They are useful for lightweight tagging, but not for data you need to filter or join on. For those cases, use a separate entity with an association.

---

## Annotating for validation

```cds
entity Users {
  key ID    : UUID;
  
      @mandatory
      email : String(254);
      
      @assert.range: [18, 120]
      age   : Integer;
      
      @assert.format: '^[A-Z]{2}[0-9]{6}$'
      passport: String(8);
}
```

| Annotation | What it does |
|-----------|-------------|
| `@mandatory` | Field must be provided on CREATE |
| `@assert.range` | Number must be in `[min, max]` |
| `@assert.format` | String must match regex |
| `@assert.unique` | Value must be unique across all rows |

---

## Best practices

**Use UUID keys everywhere** — they work offline, don't require a sequence, and are safe for distributed systems.

**Define shared types in a `types.cds` file** — then use them across all entities for consistency.

**Avoid over-normalizing** — if a piece of data is always read with its parent and never queried independently, consider structured types instead of a separate entity.

**Use enums instead of magic strings** — `Status.active` is clearer than `'active'` and CAP validates it.

---

## Checkpoint ✓

- [ ] Can you define a virtual element and populate it in a handler?
- [ ] Can you define and use a custom type?
- [ ] Can you create an enum type with 3 values?
- [ ] Can you add `@mandatory` and `@assert.range` to a field?

In Lesson 7 we build on this to define proper service definitions — controlling what operations are allowed and how entities are projected.
$md$ WHERE slug = 'cap-06-entities';


-- ── Lesson 7: Service Definitions ────────────────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Lesson 7 — Service Definitions

## What you'll learn

How to design CDS services — projecting entities, renaming fields, restricting operations, composing multiple services, and setting up endpoints for different consumers.

---

## What is a CDS service?

A CDS service is an **OData V4 service** that exposes your data model to clients. Think of it as the "API contract" — it defines exactly what clients can see and do.

```
db/schema.cds        ← Internal data model (full database schema)
        │
        ▼
srv/my-service.cds   ← Service = filtered, projected view of that model
        │
        ▼
OData V4 API         ← What clients (Fiori, mobile, REST) consume
```

The service layer is intentionally separate from the data model. Your database can have 100 fields on an entity — you only expose the 20 that external consumers need.

---

## Basic projection

```cds
using com.bookshop as db from '../db/schema';

service CatalogService {
  entity Books as projection on db.Books;
}
```

This exposes **all fields** of `Books`. To control what's exposed, use a `SELECT`-style projection:

```cds
service CatalogService {
  entity Books as select from db.Books {
    ID,
    title,
    price,
    author.name as authorName  // flatten association
  };
}
```

---

## Restricting operations

```cds
service CatalogService {
  // Customers can only read books
  @readonly
  entity Books as projection on db.Books;
  
  // Orders can be created and read, not updated or deleted
  @insertonly
  entity Orders as projection on db.Orders;
}

service AdminService @(requires: 'admin') {
  // Admins get full CRUD
  entity Books as projection on db.Books;
}
```

| Annotation | Allowed operations |
|-----------|------------------|
| `@readonly` | GET only |
| `@insertonly` | POST only |
| *(none)* | Full CRUD |

---

## Renaming and excluding fields

```cds
service CatalogService {
  entity Books as select from db.Books {
    ID,
    title,
    price,
    
    // Rename a field
    stock as availableCount,
    
    // Exclude internal fields by not listing them
    // (internalCode is not included → not exposed)
  }
}
```

---

## Adding calculated fields in projection

```cds
service CatalogService {
  entity Books as select from db.Books {
    *,                              // all fields
    stock > 0 as inStock : Boolean  // calculated in DB query
  }
}
```

---

## Multiple services

It's common to have multiple services in one CAP project — one per consumer group:

```cds
// srv/catalog-service.cds — Public API
service CatalogService {
  @readonly entity Books   as projection on db.Books;
  @readonly entity Authors as projection on db.Authors;
  entity Orders as projection on db.Orders
    where $user.id = createdBy;        // row-level filter
}

// srv/admin-service.cds — Back-office
@(requires: 'admin')
service AdminService {
  entity Books   as projection on db.Books;
  entity Authors as projection on db.Authors;
  entity Users   as projection on db.Users;
}
```

---

## Setting the service path

```cds
// Default path: /odata/v4/catalogservice
service CatalogService { ... }

// Custom path: /api/v1/catalog
@(path: '/api/v1/catalog')
service CatalogService { ... }

// Prefix all services via .cdsrc.json:
// { "odata": { "version": 4 }, "server": { "basePath": "/api" } }
```

---

## Bound actions and functions

Actions and functions are service-level operations (like RPC calls):

```cds
service OrderService {
  entity Orders as projection on db.Orders;

  // Bound action — acts on a specific Order
  action  submitOrder()          returns Order;

  // Bound function — reads from a specific Order
  function getTracking()         returns String;

  // Unbound action — not tied to an entity instance
  action  cancelAllPending()     returns Integer;

  // Unbound function
  function getOrderStats()       returns {
    total   : Integer;
    pending : Integer;
    shipped : Integer;
  };
}
```

> Actions = POST (state-changing), Functions = GET (read-only)

We implement handlers for these in Lesson 25.

---

## Exposing associations (navigation)

OData supports navigation — traversing from one entity to another:

```cds
service CatalogService {
  entity Books as projection on db.Books {
    *,
    author: redirected to Authors  // allow navigation to Author
  };
  entity Authors as projection on db.Authors;
}
```

Client can then use:
```
GET /odata/v4/catalog/Books(1234)?$expand=author
GET /odata/v4/catalog/Authors(5678)/books
```

---

## Service security overview

```cds
// Entire service requires a role
@(requires: 'authenticated-user')
service MyService { ... }

// Per-entity requirements
service MyService {
  @(requires: 'admin')
  entity Users as projection on db.Users;

  @readonly
  @(requires: 'viewer')
  entity Products as projection on db.Products;
}
```

Full authorization (XSUAA, `@restrict`) is covered in Module 5.

---

## Checkpoint ✓

- [ ] Can you write a service that exposes only 4 fields of a 10-field entity?
- [ ] Can you create a read-only public service and a full-CRUD admin service?
- [ ] Can you rename a field in a projection?
- [ ] Do you understand the difference between bound and unbound actions?

In Lesson 8 we put this all together and learn how to effectively use `cds watch` for daily development.
$md$ WHERE slug = 'cap-07-services';


-- ── Lesson 8: Running CAP Locally with cds watch ─────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Lesson 8 — Running CAP Locally with cds watch

## What you'll learn

Everything about the `cds watch` development server — hot reload, the Fiori launchpad, the CAP REPL, testing with REST Client, and the mock authentication system for testing secured services locally.

---

## `cds watch` — your daily driver

`cds watch` starts a development server that watches all `.cds` and `.js` files and restarts automatically when you save:

```bash
cds watch
```

```
[cds] - model loaded from 3 file(s)
[cds] - connect to db > sqlite { database: ':memory:' }
[cds] - serving CatalogService { path: '/odata/v4/catalog' }
[cds] - serving AdminService   { path: '/odata/v4/admin' }
[cds] - server listening on { url: 'http://localhost:4004' }
```

### What cds watch does:
1. Compiles all `.cds` files into an in-memory model
2. Creates an in-memory SQLite database
3. Loads CSV files from `db/data/` as seed data
4. Starts an Express HTTP server on port 4004
5. Watches for file changes and restarts

---

## The built-in welcome page

Open [http://localhost:4004](http://localhost:4004) — you'll see:

```
Welcome to cds.services

Web Applications
  /webapp  → (your Fiori app if configured)

Service Endpoints  
  /odata/v4/catalog  → CatalogService

$metadata            → Full OData metadata

⚙ Fiori Preview available
```

Click any service endpoint to open the OData service document.

---

## Using the built-in Fiori launchpad

CAP includes a built-in Fiori preview for annotated services:

```
http://localhost:4004/$fiori-preview?service=CatalogService&entity=Books
```

This gives you a real Fiori List Report UI backed by your service — useful for testing Fiori annotations before connecting a real UI app.

---

## Testing with VS Code REST Client

Create a file `test/catalog.http` (the `.http` extension activates the REST Client plugin):

```http
### Get all books
GET http://localhost:4004/odata/v4/catalog/Books

### Filter books under $20
GET http://localhost:4004/odata/v4/catalog/Books?$filter=price lt 20

### Get a single book by ID
GET http://localhost:4004/odata/v4/catalog/Books(guid'f1f1f1f1-0000-0000-0000-000000000001')

### Create a book
POST http://localhost:4004/odata/v4/catalog/Books
Content-Type: application/json

{
  "title": "Clean Architecture",
  "author": "Robert C. Martin",
  "price": 39.99,
  "stock": 25
}

### Update a book
PATCH http://localhost:4004/odata/v4/catalog/Books(guid'...')
Content-Type: application/json

{ "price": 34.99 }

### Delete a book
DELETE http://localhost:4004/odata/v4/catalog/Books(guid'...')
```

Click **Send Request** above each block to execute it.

---

## Mock authentication for secured services

When your service uses `@requires`, you need to pass a user for local testing:

**In `.cdsrc.json`:**
```json
{
  "requires": {
    "auth": {
      "kind": "mocked",
      "users": {
        "alice": { "roles": ["admin", "viewer"] },
        "bob":   { "roles": ["viewer"] },
        "guest": { "roles": [] }
      }
    }
  }
}
```

**In REST Client — send as Basic Auth:**
```http
### Test as admin
GET http://localhost:4004/odata/v4/admin/Books
Authorization: Basic alice:alice

### Test as regular viewer
GET http://localhost:4004/odata/v4/catalog/Books
Authorization: Basic bob:bob
```

> The password for mocked users is the same as the username. This only works in development mode.

---

## The CAP REPL

The REPL lets you interact with your CAP model programmatically:

```bash
cds repl
```

```javascript
// In the REPL:
> await SELECT.from('com.bookshop.Books')
// Returns all books from the local SQLite

> await INSERT.into('com.bookshop.Books').entries({
    title: 'REPL Test Book',
    price: 9.99,
    stock: 10
  })
// Inserts a record

> cds.model.definitions['com.bookshop.Books']
// Inspect the compiled model definition
```

This is extremely useful for debugging queries without needing a running service.

---

## Persistent SQLite (not in-memory)

By default, `cds watch` uses an **in-memory** SQLite database — data resets every time you restart. For persistent local data:

**.cdsrc.json:**
```json
{
  "requires": {
    "db": {
      "kind": "sqlite",
      "credentials": { "database": "db/bookshop.db" }
    }
  }
}
```

```bash
# Deploy schema to the SQLite file (run once)
cds deploy --to sqlite

# Then watch — data persists across restarts
cds watch
```

> **Tip**: Add `db/*.db` to your `.gitignore` — you don't want to commit the local database.

---

## Useful CLI options

```bash
# Run on a different port
cds watch --port 4005

# Watch only (no browser auto-open)
cds watch --open false

# Run in production mode (no mock auth, no hot reload)
cds serve --production

# Build all (compiles CDS for deployment)
cds build/all

# Show compiled model
cds compile db/schema.cds --to json
cds compile srv/catalog-service.cds --to edmx  # OData EDMX
```

---

## Checkpoint ✓

- [ ] Can you run `cds watch` and browse to the service at `localhost:4004`?
- [ ] Can you test a POST request using REST Client?
- [ ] Have you set up mock users and tested a secured service with Basic Auth?
- [ ] Have you switched to persistent SQLite storage?

In Lesson 9 we explore OData V4 — what's actually happening when CAP handles those `$filter`, `$expand`, and `$select` queries.
$md$ WHERE slug = 'cap-08-run-local';


-- ── Lesson 9: Understanding OData V4 in CAP ──────────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Lesson 9 — Understanding OData V4 in CAP

## What you'll learn

How CAP maps your CDS service to OData V4 — the metadata document, all system query options, batch requests, error response format, and how to call your API from JavaScript without a library.

---

## What is OData V4?

OData (Open Data Protocol) is a REST-based standard for querying and manipulating data. Version 4 is the current standard, supported natively by SAP Fiori, Excel, Power BI, and many other tools.

CAP automatically serves your service as an OData V4 API — you don't write any OData code. The CDS definition is all you need.

---

## The metadata document

Every OData service exposes a metadata document at `$metadata`:

```
GET /odata/v4/catalog/$metadata
```

This is an XML document (EDMX format) that describes every entity, field type, key, navigation, action, and function in your service. Client tools (Fiori, Excel) read this to understand your API shape.

```xml
<EntityType Name="Books">
  <Key><PropertyRef Name="ID"/></Key>
  <Property Name="ID"    Type="Edm.Guid"   Nullable="false"/>
  <Property Name="title" Type="Edm.String"  MaxLength="100"/>
  <Property Name="price" Type="Edm.Decimal" Precision="10" Scale="2"/>
</EntityType>
```

CAP generates this automatically from your CDS model. You never write EDMX manually.

---

## System query options

OData provides powerful built-in query capabilities via URL parameters:

### `$filter` — filter results

```
GET /odata/v4/catalog/Books?$filter=price lt 20
GET /odata/v4/catalog/Books?$filter=price ge 10 and price le 50
GET /odata/v4/catalog/Books?$filter=contains(title, 'Clean')
GET /odata/v4/catalog/Books?$filter=stock gt 0 and author eq 'Adams'
```

**Filter operators:**
| Operator | Meaning | Example |
|---------|---------|---------|
| `eq` | equals | `status eq 'active'` |
| `ne` | not equals | `status ne 'archived'` |
| `lt` `le` | less than / or equal | `price lt 20` |
| `gt` `ge` | greater than / or equal | `stock ge 5` |
| `and` `or` `not` | logical | `a gt 1 and b lt 10` |
| `contains(f, v)` | string contains | `contains(title,'CAP')` |
| `startswith(f,v)` | string starts with | `startswith(name,'S')` |
| `endswith(f,v)` | string ends with | `endswith(email,'.com')` |

### `$select` — choose fields

```
GET /odata/v4/catalog/Books?$select=ID,title,price
```

Response only includes the listed fields. Reduces payload size — critical for mobile apps.

### `$orderby` — sort results

```
GET /odata/v4/catalog/Books?$orderby=price asc
GET /odata/v4/catalog/Books?$orderby=title desc,price asc
```

### `$top` and `$skip` — pagination

```
GET /odata/v4/catalog/Books?$top=10&$skip=0   # page 1
GET /odata/v4/catalog/Books?$top=10&$skip=10  # page 2
GET /odata/v4/catalog/Books?$top=10&$skip=20  # page 3
```

### `$count` — total record count

```
GET /odata/v4/catalog/Books?$count=true&$top=10
```

Response includes `@odata.count: 1234` — the total count before pagination.

### `$expand` — include related entities

```
# Include author details with each book
GET /odata/v4/catalog/Books?$expand=author

# Nested expand
GET /odata/v4/catalog/Orders?$expand=items($expand=product)

# Expand with filter on the nested set
GET /odata/v4/catalog/Authors?$expand=books($filter=price lt 20)
```

### Combine multiple options

```
GET /odata/v4/catalog/Books
  ?$filter=stock gt 0
  &$select=ID,title,price
  &$orderby=price asc
  &$top=5
  &$count=true
  &$expand=author($select=name)
```

---

## OData response format

```json
{
  "@odata.context": "$metadata#Books",
  "@odata.count": 42,
  "value": [
    {
      "ID": "abc-123",
      "title": "Clean Code",
      "price": 35.00,
      "author": {
        "name": "Robert C. Martin"
      }
    }
  ]
}
```

Always wrapped in `{ "value": [...] }`. Single entity reads (by key) return the object directly without `"value"`.

---

## OData error format

```json
{
  "error": {
    "code": "404",
    "message": "Books with ID 'xyz' not found.",
    "target": "ID",
    "details": []
  }
}
```

CAP returns this format automatically for validation errors, not-found, and authorization failures.

---

## Batch requests

OData `$batch` lets you send multiple requests in one HTTP call — critical for performance in Fiori apps:

```http
POST /odata/v4/catalog/$batch
Content-Type: multipart/mixed; boundary=batch_boundary

--batch_boundary
Content-Type: application/http

GET Books?$select=ID,title HTTP/1.1

--batch_boundary
Content-Type: application/http

GET Authors HTTP/1.1

--batch_boundary--
```

CAP handles batch requests automatically. Fiori apps use `$batch` internally for every UI interaction.

---

## Calling OData from JavaScript

No OData library needed for simple cases:

```javascript
// Fetch all books with price filter
const response = await fetch(
  '/odata/v4/catalog/Books?$filter=price lt 20&$select=ID,title,price',
  { headers: { 'Accept': 'application/json' } }
);
const { value: books } = await response.json();

// Create a book
await fetch('/odata/v4/catalog/Books', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ title: 'New Book', price: 19.99 })
});
```

For Fiori/UI5 apps, use `sap.ui.model.odata.v4.ODataModel` — it handles `$batch`, CSRF tokens, and metadata automatically.

---

## Checkpoint ✓

- [ ] Can you write a URL that filters books by price AND contains a search term?
- [ ] Can you paginate through a large result set with `$top` and `$skip`?
- [ ] Can you use `$expand` to include the author with each book?
- [ ] Do you understand the `@odata.context` and `value` wrapper in responses?

In Lesson 10 we learn about CAP's generic handlers — what CAP handles automatically so you don't have to write repetitive CRUD code.
$md$ WHERE slug = 'cap-09-odata';


-- ── Lesson 10: Generic Handlers & Automatic CRUD ─────────────────────────────
UPDATE public.topics SET status = 'published', content_md = $md$
# Lesson 10 — Generic Handlers & Automatic CRUD

## What you'll learn

What CAP's generic service providers handle automatically, how deep insert and deep read work, what you need to implement yourself, and the exact lifecycle of a CAP request from HTTP to database.

---

## The "magic" in CAP

When you define a service and run `cds watch`, CAP automatically handles:

- **READ** — `GET /Books`, `GET /Books(id)`, filtering, sorting, pagination, expand
- **CREATE** — `POST /Books` with validation
- **UPDATE** — `PUT /Books(id)` and `PATCH /Books(id)`
- **DELETE** — `DELETE /Books(id)`
- **Deep operations** — creating an Order with its OrderItems in one POST
- **Cascade delete** — deleting a parent deletes composed children
- **Referential integrity** — foreign key validation
- **Input validation** — `@mandatory`, `@assert.range`, enums

All of this runs without a single line of handler code from you.

---

## The request lifecycle

Every incoming request goes through this pipeline:

```
HTTP Request
     │
     ▼
  BEFORE handlers     ← your pre-processing hooks (validation, enrichment)
     │
     ▼
  ON handlers         ← your business logic (replaces default behavior)
     │                   If no ON handler: CAP's generic handler runs here
     ▼
  AFTER handlers      ← your post-processing hooks (transform, enrich response)
     │
     ▼
HTTP Response
```

If you define an `ON` handler, **CAP's generic handler does NOT run**. Your handler must call `next()` if you want both to execute.

---

## What generic handlers do

### READ

```javascript
// CAP does all of this for you automatically:

// 1. Parse the OData URL ($filter, $select, $expand, etc.)
// 2. Translate to SQL:
//    SELECT ID, title, price FROM Books
//    WHERE price < 20
//    ORDER BY title ASC
//    LIMIT 10 OFFSET 0
// 3. Execute against SQLite/HANA
// 4. Format as OData JSON response
// 5. Handle $expand (additional JOINs or sub-SELECTs)
// 6. Add @odata.count if $count=true
```

### CREATE (deep insert)

Given this POST body:
```json
{
  "customerName": "Alice",
  "items": [
    { "product": "Book A", "qty": 2 },
    { "product": "Book B", "qty": 1 }
  ]
}
```

CAP automatically:
1. Validates required fields
2. Generates UUIDs for all entities
3. INSERTs the Order record
4. INSERTs each OrderItem, linking to the parent Order ID
5. Returns the created tree

This works because the `items` field is defined as a **Composition** in CDS.

---

## Managed fields — automatic population

If your entity uses the `managed` aspect:
```cds
using { managed } from '@sap/cds/common';

entity Books : managed {
  key ID: UUID;
  title : String;
}
```

CAP automatically sets on CREATE:
- `createdAt` = current timestamp
- `createdBy` = current user (from JWT / mock auth)

And on UPDATE:
- `modifiedAt` = current timestamp
- `modifiedBy` = current user

You never set these manually — CAP handles them.

---

## UUID generation — automatic

If you declare `key ID : UUID`, CAP generates a UUID for new records automatically. Clients do not need to supply the ID on POST.

```http
POST /odata/v4/catalog/Books
Content-Type: application/json

{ "title": "New Book", "price": 25.00 }
```

Response:
```json
{
  "ID": "a1b2c3d4-...",   ← auto-generated by CAP
  "title": "New Book",
  "price": 25.00,
  "createdAt": "2024-01-15T10:30:00Z",
  "createdBy": "alice"
}
```

---

## When generic handlers are NOT enough

You need a custom handler when:

| Scenario | Example |
|---------|---------|
| Business logic on write | Recalculate inventory when an order is placed |
| Computed fields at read time | Add a `virtual discount` based on customer tier |
| External system calls | Create a record in S/4HANA when an order is created |
| Complex validation | Check stock before creating an order |
| Side effects | Send an email when a user registers |
| Custom auth logic | Restrict which rows a user can see based on their attributes |

---

## Your first custom handler

Create `srv/catalog-service.js` (same base name as `catalog-service.cds`):

```javascript
const cds = require('@sap/cds');

module.exports = class CatalogService extends cds.ApplicationService {

  async init() {

    // BEFORE READ — add a log
    this.before('READ', 'Books', req => {
      console.log(`User ${req.user.id} is reading Books`);
    });

    // AFTER READ — add a virtual field
    this.after('READ', 'Books', books => {
      for (const book of books) {
        book.inStock = book.stock > 0;
      }
    });

    // ON CREATE — validate before save
    this.before('CREATE', 'Books', req => {
      if (req.data.price < 0) {
        req.error(400, 'Price cannot be negative');
      }
    });

    // Call super.init() to register CAP's generic handlers
    await super.init();
  }
}
```

> **Critical**: always call `await super.init()` at the end of your `init()` method. This registers CAP's generic handlers for operations you didn't override.

---

## Handler execution order

```
BEFORE handlers (yours, in registration order)
        │
        ▼
ON handlers (yours, OR CAP's generic if you didn't register one)
        │
        ▼
AFTER handlers (yours, in registration order)
```

Multiple `before` handlers stack — all run in order. Multiple `on` handlers — only the first one registered runs (unless it calls `next()`).

---

## Common mistake: forgetting `super.init()`

```javascript
// ❌ WRONG — generic CRUD broken, nothing works
module.exports = class MyService extends cds.ApplicationService {
  async init() {
    this.before('READ', 'Books', req => { /* ... */ });
    // forgot super.init() — CAP's generic READ handler never registered!
  }
}

// ✅ CORRECT
module.exports = class MyService extends cds.ApplicationService {
  async init() {
    this.before('READ', 'Books', req => { /* ... */ });
    await super.init();  // always last
  }
}
```

---

## Checkpoint ✓

- [ ] Can you explain the 3-phase request lifecycle (before/on/after)?
- [ ] Do you understand when CAP's generic handler runs vs. your handler?
- [ ] Have you written a handler that adds a virtual field to READ results?
- [ ] Do you know what `managed` adds automatically?

**Module 1 complete!** You now have a solid foundation in CAP. In Module 2, we go deep into CDS data modeling — associations, compositions, aspects, views, annotations, and everything you need to model real-world business data.
$md$ WHERE slug = 'cap-10-generic-handlers';

-- Verify Module 1
SELECT slug, status, LEFT(content_md, 60) AS preview
FROM public.topics
WHERE slug LIKE 'cap-0%' OR slug LIKE 'cap-1%'
ORDER BY order_index;
