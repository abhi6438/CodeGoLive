-- Module 9 topics for dev-quickstart


INSERT INTO topics (module_id, number, slug, title, focus, description, content_md, order_index, status) VALUES (
  (SELECT id FROM modules WHERE course_id = 'dev-quickstart' AND number = '9'),
  '720',
  'dev-qs-cap-node-init',
  'cds init — Your First CAP Project',
  'Scaffold a CAP Node.js project and understand what gets created',
  'Use cds init to create a new CAP project, add a sample service, and explore the generated folder structure.',
  '# cds init — Your First CAP Project

CAP (Cloud Application Programming Model) lets you build OData services with very little boilerplate.

## Make sure the CDS CLI is installed

```bash
cds --version
# @sap/cds-dk: 8.x.x
```

If not installed:

```bash
npm install -g @sap/cds-dk
```

## Create a new project

```bash
cds init bookshop
cd bookshop
```

## What gets generated

```
bookshop/
├── app/          ← SAPUI5 / Fiori frontends go here
├── db/           ← CDS data model files (.cds)
├── srv/          ← Service definitions (.cds) and handlers (.js)
├── .cdsrc.json   ← CDS configuration
└── package.json
```

## Add a sample data model

Create `db/schema.cds`:

```cds
namespace bookshop;

entity Books {
  key ID     : Integer;
  title      : String(100);
  author     : String(50);
  stock      : Integer;
  price      : Decimal(10, 2);
}
```

## Add a service

Create `srv/cat-service.cds`:

```cds
using bookshop from ''../db/schema'';

service CatalogService {
  entity Books as projection on bookshop.Books;
}
```

## Add sample data

Create `db/data/bookshop-Books.csv`:

```csv
ID,title,author,stock,price
1,The Hobbit,J.R.R. Tolkien,100,14.99
2,Dune,Frank Herbert,75,12.50
3,Foundation,Isaac Asimov,50,11.99
```

## Run the server

```bash
cds watch
```

Visit `http://localhost:4004` — you''ll see your OData service metadata and the Books entity.

## Key facts about cds init

- It creates an empty project — no models or services by default
- `cds add samples` adds the full Bookshop sample
- `cds add hana` wires up SAP HANA as the database (instead of SQLite in dev)
- `cds add approuter` adds an AppRouter for BTP deployment
',
  0,
  'published'
);


INSERT INTO topics (module_id, number, slug, title, focus, description, content_md, order_index, status) VALUES (
  (SELECT id FROM modules WHERE course_id = 'dev-quickstart' AND number = '9'),
  '721',
  'dev-qs-cap-node-folder',
  'CAP Node.js Folder Structure',
  'Understand every file and folder in a CAP Node.js project',
  'Detailed walkthrough of db/, srv/, app/, package.json, .cdsrc.json, and how they connect at runtime.',
  '# CAP Node.js Folder Structure

```
my-cap-app/
├── app/                         ← Fiori/SAPUI5 UI apps (optional)
│   └── my-ui/
│       ├── webapp/
│       └── ui5.yaml
│
├── db/                          ← Data layer
│   ├── schema.cds               ← Entity definitions
│   ├── data/                    ← CSV seed data for local dev
│   │   └── my.namespace-Books.csv
│   └── src/                     ← HANA-specific artifacts (hdbview, etc.)
│
├── srv/                         ← Service layer
│   ├── cat-service.cds          ← Service definition
│   └── cat-service.js           ← Custom handler (optional)
│
├── .cdsrc.json                  ← CDS runtime config
├── package.json                 ← npm config + cds section
└── mta.yaml                     ← MTA deployment descriptor (added later)
```

## The db/ folder

This is where your **data model** lives. CDS compiles `.cds` files into SQL or HANA artifacts.

```cds
// db/schema.cds
namespace my.namespace;

entity Products {
  key ID       : UUID;
  name         : String(100);
  description  : localized String;  // ← auto i18n table
  price        : Decimal(10, 2);
  category     : Association to Categories;
}

entity Categories {
  key ID   : Integer;
  name     : String(50);
  products : Composition of many Products on products.category = $self;
}
```

## The srv/ folder

Service definitions expose entities as OData endpoints.

```cds
// srv/cat-service.cds
using my.namespace from ''../db/schema'';

service CatalogService @(path: ''/catalog'') {
  entity Products as projection on my.namespace.Products;
  entity Categories as projection on my.namespace.Categories;

  // Read-only projection with extra annotations
  @readonly entity ProductView as projection on my.namespace.Products
    excluding { description };
}
```

## Custom handlers (srv/cat-service.js)

```js
const cds = require(''@sap/cds'');
module.exports = class CatalogService extends cds.ApplicationService {
  init() {
    this.before(''CREATE'', ''Products'', req => {
      if (!req.data.price || req.data.price <= 0) {
        req.error(400, ''Price must be positive'');
      }
    });
    return super.init();
  }
};
```

## .cdsrc.json

```json
{
  "requires": {
    "db": {
      "kind": "sqlite",
      "[production]": { "kind": "hana" }
    }
  },
  "features": { "fetch_csrf": true }
}
```

## package.json — the cds section

```json
{
  "cds": {
    "requires": { "db": { "kind": "sqlite" } },
    "hana": { "deploy-format": "hdbtable" }
  }
}
```

The `cds` key in package.json overrides `.cdsrc.json` and is the recommended place for config.
',
  1,
  'published'
);


INSERT INTO topics (module_id, number, slug, title, focus, description, content_md, order_index, status) VALUES (
  (SELECT id FROM modules WHERE course_id = 'dev-quickstart' AND number = '9'),
  '722',
  'dev-qs-cap-node-watch',
  'cds watch — Running the Server',
  'Use cds watch for live-reload development and understand the output',
  'Start and stop the CAP dev server, read the startup output, access the service explorer, and handle common startup errors.',
  '# cds watch — Running the CAP Dev Server

`cds watch` is the primary development command for CAP. It watches your files and restarts the server on every change.

## Start the server

```bash
cd my-cap-app
cds watch
```

## Understanding the startup output

```
cds serve all --with-mocks --in-memory?
...
[cds] - model loaded from 2 file(s):
  db/schema.cds
  srv/cat-service.cds

[cds] - connect to db > sqlite { database: '':memory:'' }
[cds] - serving CatalogService { path: ''/catalog'', impl: ''srv/cat-service.js'' }

[cds] - server listening on { url: ''http://localhost:4004'' }
[cds] - launched at ... in: 842ms
[cds] - [ terminate with ^C ]
```

Line by line:
- **model loaded** — which `.cds` files were compiled
- **connect to db** — SQLite in-memory (default for local dev)
- **serving CatalogService** — the OData path and optional JS handler
- **localhost:4004** — the URL to open

## The service explorer

Open `http://localhost:4004` in a browser. You''ll see:

- Links to each service''s metadata (`$metadata`)
- Entity set links you can click to browse data
- A Fiori Preview button (if installed)

## Access the OData endpoint directly

```
http://localhost:4004/catalog/Products
http://localhost:4004/catalog/Products?$top=5&$orderby=name
http://localhost:4004/catalog/Products?$filter=price gt 10
```

## Stop the server

Press `Ctrl+C` in the terminal.

## Common startup errors

### `Cannot find module ''@sap/cds''`

```bash
npm install   # install project dependencies first
```

### `Port 4004 already in use`

```bash
# macOS / Linux
lsof -ti:4004 | xargs kill

# Windows
netstat -ano | findstr :4004
taskkill /PID <pid> /F
```

### `Error: No model found`

Your `.cds` files have a syntax error. Check the line number in the error output.

## Useful cds watch flags

```bash
cds watch --port 4005          # different port
cds watch --log-level debug    # verbose output (shows SQL queries)
cds watch --profile production # use production config profile
```
',
  2,
  'published'
);


INSERT INTO topics (module_id, number, slug, title, focus, description, content_md, order_index, status) VALUES (
  (SELECT id FROM modules WHERE course_id = 'dev-quickstart' AND number = '9'),
  '723',
  'dev-qs-cap-node-debug',
  'Debugging CAP Node.js with VS Code',
  'Set breakpoints in CAP handlers and inspect request objects',
  'Configure the VS Code debugger for a CAP Node.js project, set breakpoints in service handlers, inspect the req object, and use the Debug Console.',
  '# Debugging CAP Node.js with VS Code

VS Code''s Node.js debugger works natively with CAP — no extra plugins needed.

## Method 1 — attach to cds watch (easiest)

### Step 1 — start cds watch with inspect flag

```bash
node --inspect node_modules/.bin/cds watch
# or use the npm script approach:
```

Add to `package.json`:

```json
{
  "scripts": {
    "start:debug": "node --inspect node_modules/.bin/cds watch"
  }
}
```

Then run:

```bash
npm run start:debug
```

You''ll see: `Debugger listening on ws://127.0.0.1:9229/...`

### Step 2 — attach VS Code

Press `F5` → if prompted, select **Node.js: Attach** and accept the default port 9229.

## Method 2 — launch.json (full control)

Create `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "CAP Node.js",
      "type": "node",
      "request": "launch",
      "program": "${workspaceFolder}/node_modules/.bin/cds",
      "args": ["watch"],
      "cwd": "${workspaceFolder}",
      "console": "integratedTerminal",
      "restart": true
    }
  ]
}
```

Press `F5` to start. The integrated terminal shows `cds watch` output.

## Set a breakpoint in a handler

Open `srv/cat-service.js`, click the line gutter to set a breakpoint:

```js
this.before(''READ'', ''Products'', req => {
  // ← breakpoint here
  console.log(''Query:'', req.query);
});
```

Trigger a GET request to `/catalog/Products` — VS Code will pause at the breakpoint.

## Inspect the `req` object

When paused, hover over `req` in the editor or open the **Debug Console** (bottom panel) and type:

```js
req.data           // body for CREATE/UPDATE
req.query          // parsed CQL query object
req.user.id        // logged-in user
req.headers        // HTTP headers
```

## Inspect the database (SQLite in dev)

In the Debug Console:

```js
const db = cds.db
await db.run(SELECT.from(''my.namespace.Products''))
```

## Hot reload with breakpoints

`cds watch` restarts on file change. VS Code reconnects the debugger automatically (the `restart: true` in launch.json handles this).
',
  3,
  'published'
);
