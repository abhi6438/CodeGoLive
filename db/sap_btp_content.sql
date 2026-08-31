-- SAP BTP & CAP Content — all 21 topics
-- Run in Supabase SQL editor

UPDATE public.topics SET content_md = $md$
## What Is This?

Your very first SAP BTP session. You will create a BTP Trial account, open Business Application Studio (BAS), scaffold a SAPUI5 app, and see it running in a browser — all in under 30 minutes.

## Why It Matters

Every SAP project starts here. BAS is your cloud IDE; the trial gives you a sandbox that behaves like a real BTP landscape.

## Step-by-Step

### 1 — Get a BTP Trial
Go to [https://www.sap.com/products/technology-platform/trial.html](https://www.sap.com/products/technology-platform/trial.html) and register. You will receive a subaccount in the US10 region.

### 2 — Subscribe to Business Application Studio
In your trial subaccount → **Service Marketplace** → search **SAP Business Application Studio** → subscribe (Free plan).

### 3 — Create a Dev Space
Open BAS → **Create Dev Space** → choose **SAP Fiori** → Start.

### 4 — Scaffold Your First App

Open a terminal in BAS and run:

```bash
yo @sap/fiori-freestyle --skip-install
```

Answer the prompts:
- Template: **SAPUI5 Application**
- Data source: **None**
- Module name: `myapp`
- Namespace: `com.example`

Then:
```bash
cd myapp
npm install
npm start
```

### 5 — Open the Preview

BAS auto-opens a port. Click **Open in New Tab** when prompted. You should see a blank SAPUI5 app with a title bar.

## Key Lines Explained

```
yo @sap/fiori-freestyle   ← SAP's Yeoman generator for Fiori/SAPUI5 apps
npm install               ← installs UI5 tooling + dependencies
npm start                 ← launches a local dev server with live reload
```

## Common Mistakes

- **BAS dev space keeps stopping** → Free tier hibernates after 1h of inactivity; just restart it.
- **Port forwarding not appearing** → Check the **Ports** panel (bottom bar in BAS) and open port 8080 manually.
- **`yo` not found** → Run `npm install -g yo @sap/generator-fiori-freestyle` first.

## ✅ Checkpoint

You should see a running SAPUI5 app in your browser with a page title. The URL will contain `localhost:8080` or a BAS-forwarded URL. You are now inside the SAP BTP development loop.
$md$ WHERE slug = '0-sp-test';

UPDATE public.topics SET content_md = $md$
## What Is This?

A single-screen SAPUI5 app backed by a local JSON model. You will build the XML view, connect it to a JSONModel, and display a list of items — no backend needed yet.

## Why It Matters

Understanding how SAPUI5 separates **view** (XML) from **data** (model) and **logic** (controller) is the foundation of every SAP frontend project.

## Core Concepts

| Concept | What It Does |
|---|---|
| `XMLView` | Declares UI using XML tags like `<List>`, `<Input>` |
| `JSONModel` | Holds your data in plain JavaScript objects |
| `{/items}` binding | Links a model path to a control's property |

## Code — View (webapp/view/Main.view.xml)

```xml
<mvc:View
  controllerName="com.example.myapp.controller.Main"
  xmlns="sap.m"
  xmlns:mvc="sap.ui.core.mvc">

  <Page title="My Products">
    <List id="productList" items="{/products}">
      <StandardListItem
        title="{name}"
        description="{price}"
        type="Active" />
    </List>
  </Page>

</mvc:View>
```

## Code — Controller (webapp/controller/Main.controller.js)

```javascript
sap.ui.define([
  "sap/ui/core/mvc/Controller",
  "sap/ui/model/json/JSONModel"
], function (Controller, JSONModel) {
  "use strict";

  return Controller.extend("com.example.myapp.controller.Main", {
    onInit: function () {
      var oModel = new JSONModel({
        products: [
          { name: "Laptop",  price: "€999" },
          { name: "Monitor", price: "€349" },
          { name: "Keyboard",price: "€79"  }
        ]
      });
      this.getView().setModel(oModel);
    }
  });
});
```

## Key Lines Explained

```
items="{/products}"         ← binds the List to the products array in the model
{ name }                    ← each StandardListItem reads the name property
new JSONModel({...})        ← creates an in-memory data store
this.getView().setModel()   ← attaches the model to the view so binding resolves
```

## Common Mistakes

- **List shows nothing** → Forgot `this.getView().setModel(oModel)` or used a wrong model path like `{products}` instead of `{/products}`.
- **Controller not found** → `controllerName` in the view must match the `extend(...)` string exactly, including namespace.
- **Controls not resolving** → Missing `xmlns="sap.m"` in the View declaration.

## ✅ Checkpoint

Your browser shows a list with "Laptop", "Monitor", "Keyboard" and their prices. No page reloads needed when you change the JSON data — the binding updates automatically.
$md$ WHERE slug = '1-ss-test';

UPDATE public.topics SET content_md = $md$
## What Is This?

Navigation between two screens (Main → Detail) using SAPUI5's router. You will define routes in `manifest.json`, navigate with `navTo()`, and receive parameters on the Detail page.

## Why It Matters

Real Fiori apps always have multiple screens. SAP's router pattern is how every enterprise SAPUI5 app handles navigation — you must know this pattern cold.

## Router Setup (manifest.json)

```json
"routing": {
  "config": {
    "routerClass": "sap.m.routing.Router",
    "viewType": "XML",
    "viewPath": "com.example.myapp.view",
    "controlId": "app",
    "controlAggregation": "pages"
  },
  "routes": [
    { "name": "main",   "pattern": "",          "target": "main"   },
    { "name": "detail", "pattern": "detail/{id}","target": "detail" }
  ],
  "targets": {
    "main":   { "viewName": "Main"   },
    "detail": { "viewName": "Detail" }
  }
}
```

## Navigating Forward (Main controller)

```javascript
onItemPress: function (oEvent) {
  var sId = oEvent.getSource().getBindingContext().getProperty("id");
  this.getOwnerComponent().getRouter().navTo("detail", { id: sId });
}
```

## Receiving Parameters (Detail controller)

```javascript
onInit: function () {
  this.getOwnerComponent().getRouter()
    .getRoute("detail")
    .attachPatternMatched(this._onRouteMatched, this);
},
_onRouteMatched: function (oEvent) {
  var sId = oEvent.getParameter("arguments").id;
  // use sId to filter/bind the model
  this.getView().bindElement("/products/" + sId);
}
```

## Key Lines Explained

```
pattern: "detail/{id}"          ← {id} becomes a URL parameter
navTo("detail", { id: sId })    ← navigates and encodes id into the URL
attachPatternMatched(...)        ← fires every time this route is activated
oEvent.getParameter("arguments").id  ← retrieves the URL parameter
```

## Common Mistakes

- **White screen on navigate** → `controlId: "app"` must match the `id` of your `<App>` control in the shell.
- **_onRouteMatched never fires** → Attached the listener too late (not in `onInit`), or route name is misspelled.
- **Back button doesn't work** → Call `this.getOwnerComponent().getRouter().navTo("main")` or use `window.history.go(-1)`.

## ✅ Checkpoint

Click a list item → Detail view loads and shows that item's data. Browser URL contains `/detail/0` (or whichever id you clicked). Back navigation returns to the list.
$md$ WHERE slug = '2-ms-test';

UPDATE public.topics SET content_md = $md$
## What Is This?

Full Create / Read / Update / Delete against a local JSONModel — no backend. You will add a dialog for Create/Edit, wire up Delete with a confirm dialog, and keep the list in sync.

## Why It Matters

CRUD is the heartbeat of every business app. Mastering CRUD against a local model first lets you focus on UI patterns before adding backend complexity.

## Add Item — Fragment (webapp/fragment/AddProduct.fragment.xml)

```xml
<core:FragmentDefinition
  xmlns="sap.m" xmlns:core="sap.ui.core">
  <Dialog id="addDialog" title="Add Product">
    <content>
      <Input id="nameInput"  placeholder="Product name" />
      <Input id="priceInput" placeholder="Price" />
    </content>
    <beginButton>
      <Button text="Save" press=".onSaveProduct" type="Emphasized" />
    </beginButton>
    <endButton>
      <Button text="Cancel" press=".onCancelDialog" />
    </endButton>
  </Dialog>
</core:FragmentDefinition>
```

## Controller — CRUD operations

```javascript
onAddPress: function () {
  if (!this._oDialog) {
    this._oDialog = this.loadFragment({ name: "com.example.myapp.fragment.AddProduct" });
  }
  this._oDialog.then(d => d.open());
},

onSaveProduct: function () {
  var oModel = this.getView().getModel();
  var aProducts = oModel.getProperty("/products");
  aProducts.push({
    id: aProducts.length,
    name: this.byId("nameInput").getValue(),
    price: this.byId("priceInput").getValue()
  });
  oModel.setProperty("/products", aProducts);
  this.byId("addDialog").close();
},

onDeletePress: function (oEvent) {
  var oCtx = oEvent.getSource().getBindingContext();
  var iIdx = parseInt(oCtx.getPath().split("/").pop());
  var oModel = this.getView().getModel();
  var aProducts = oModel.getProperty("/products");
  aProducts.splice(iIdx, 1);
  oModel.setProperty("/products", aProducts);
}
```

## Key Lines Explained

```
this.loadFragment(...)       ← lazy-loads the XML fragment (dialog) on first use
oModel.getProperty("/products")  ← reads the array from the JSON model
aProducts.push({...})        ← mutates the array (model won't auto-detect this)
oModel.setProperty("/products", aProducts)  ← re-sets the array so binding refreshes
aProducts.splice(iIdx, 1)   ← removes the item at the clicked index
```

## Common Mistakes

- **List doesn't refresh after push** → You must call `setProperty` after mutating the array; `push` alone doesn't trigger binding updates.
- **Dialog opens twice** → Cached `_oDialog` is a Promise; call `.then(d => d.open())` every time.
- **Delete removes wrong item** → `getPath()` returns `/products/2` — split by `/` and pop to get `"2"`, then `parseInt`.

## ✅ Checkpoint

You can add a product (dialog opens, fills, saves to list), edit it inline, and delete it (item removed from list immediately). All changes live only in memory — a page refresh resets everything.
$md$ WHERE slug = '3-crud-test';

UPDATE public.topics SET content_md = $md$
## What Is This?

A Value Help (F4) dialog that lets users search and select a value from a list, then populates an Input field. This is the SAP pattern for dropdown-with-search.

## Why It Matters

Value Help is everywhere in SAP: selecting a customer, a cost center, a material number. Knowing the Fragment + Dialog lifecycle is essential for any Fiori developer.

## Fragment (webapp/fragment/CustomerVH.fragment.xml)

```xml
<core:FragmentDefinition
  xmlns="sap.m" xmlns:core="sap.ui.core">
  <SelectDialog
    id="customerVH"
    title="Select Customer"
    search=".onVHSearch"
    confirm=".onVHConfirm"
    cancel=".onVHCancel"
    items="{/customers}">
    <StandardListItem title="{name}" description="{id}" />
  </SelectDialog>
</core:FragmentDefinition>
```

## Controller

```javascript
onValueHelpRequest: function () {
  if (!this._oVHDialog) {
    this._oVHDialog = this.loadFragment({
      name: "com.example.myapp.fragment.CustomerVH"
    });
  }
  this._oVHDialog.then(function (oDialog) {
    oDialog.getBinding("items").filter([]);   // reset filter
    oDialog.open();
  });
},

onVHSearch: function (oEvent) {
  var sValue = oEvent.getParameter("value");
  var oFilter = new sap.ui.model.Filter("name",
    sap.ui.model.FilterOperator.Contains, sValue);
  oEvent.getSource().getBinding("items").filter([oFilter]);
},

onVHConfirm: function (oEvent) {
  var oCtx = oEvent.getParameter("selectedContexts")[0];
  var sName = oCtx.getProperty("name");
  this.byId("customerInput").setValue(sName);
},

onVHCancel: function () { /* nothing needed */ }
```

## Key Lines Explained

```
SelectDialog               ← SAP control that combines List + Search + Dialog
search=".onVHSearch"       ← fires as the user types in the search box
confirm=".onVHConfirm"     ← fires when the user taps a row
selectedContexts[0]        ← array of selected binding contexts (single-select here)
getBinding("items").filter([ oFilter ])  ← filters the displayed items in real time
filter([])                 ← resets filter when dialog re-opens
```

## Common Mistakes

- **Dialog shows all items even after typing** → You forgot to call `.filter([oFilter])` on the binding — calling it on the control itself doesn't work.
- **Confirm handler gets undefined** → Used `getParameter("selectedItem")` (deprecated) instead of `getParameter("selectedContexts")[0]`.
- **Dialog opens multiple times without reset** → Forgot `filter([])` before `open()` — previous search still applied.

## ✅ Checkpoint

Clicking the Value Help icon opens a searchable list. Typing filters the list in real time. Selecting a row closes the dialog and populates the Input field with the selected name.
$md$ WHERE slug = '4-f4-test';

UPDATE public.topics SET content_md = $md$
## What Is This?

Your first CAP (Cloud Application Programming model) project from scratch. You will init the project, define a CDS data model, expose a service, and test it with a browser.

## Why It Matters

CAP is SAP's opinionated Node.js framework for building OData and REST services. It handles persistence, validation, and SAP protocol boilerplate so you can focus on business logic.

## Scaffold

```bash
npm install -g @sap/cds-dk   # one-time global install
cds init bookshop
cd bookshop
npm install
```

## Data Model (db/schema.cds)

```cds
namespace my.bookshop;
using { cuid, managed } from '@sap/cds/common';

entity Books : cuid, managed {
  title  : String(111);
  author : String(111);
  stock  : Integer;
  price  : Decimal(9,2);
}
```

## Service Definition (srv/cat-service.cds)

```cds
using my.bookshop as my from '../db/schema';

service CatalogService {
  entity Books as projection on my.Books;
}
```

## Custom Handler (srv/cat-service.js)

```javascript
module.exports = cds.service.impl(async function () {
  this.before("CREATE", "Books", (req) => {
    if (!req.data.title) req.error(400, "Title is required");
  });
});
```

## Run & Test

```bash
cds watch          # starts dev server with auto-reload
# Open http://localhost:4004
# Click $metadata to see OData metadata
# Click Books to see the entity set
```

## Key Lines Explained

```
cds init bookshop          ← scaffolds package.json, .cdsrc.json, folders
cuid, managed              ← CDS aspects that add id (UUID) + audit fields
projection on my.Books     ← exposes the entity through the service layer
cds.service.impl(...)      ← registers event handlers (before/after/on)
this.before("CREATE",...)  ← runs before the default CREATE handler
req.error(400, "...")      ← rejects the request with an OData error
cds watch                  ← watches for file changes and auto-restarts
```

## Common Mistakes

- **404 on `/Books`** → The service name in the URL is derived from the CDS service name: `CatalogService` → `/catalog/Books`.
- **Handler not firing** → JS file name must match the CDS service file name (e.g., `cat-service.js` for `cat-service.cds`).
- **`cds` not found** → Install `@sap/cds-dk` globally with `npm i -g @sap/cds-dk`.

## ✅ Checkpoint

`http://localhost:4004/catalog/Books` returns an empty OData JSON response `{"value":[]}`. The service is running and the schema is correct.
$md$ WHERE slug = '5-cap-1-test';

UPDATE public.topics SET content_md = $md$
## What Is This?

Replace CAP's in-memory store with a real SQLite database. You will define seed data in CSV files, deploy the schema, and verify persistence across server restarts.

## Why It Matters

The in-memory store resets on every `cds watch` restart. SQLite gives you real persistence in development without needing a cloud database.

## Add SQLite dependency

```bash
npm add @cap-js/sqlite -D
```

## Seed Data (db/data/my.bookshop-Books.csv)

```csv
ID,title,author,stock,price
1,Wuthering Heights,Emily Brontë,100,12.95
2,Jane Eyre,Charlotte Brontë,200,9.99
3,The Great Gatsby,F. Scott Fitzgerald,50,8.49
```

## Deploy Schema to SQLite

```bash
cds deploy --to sqlite:db/bookshop.db
```

This creates `bookshop.db` in the `db/` folder and imports the CSV data.

## Configure (package.json)

```json
{
  "cds": {
    "requires": {
      "db": {
        "kind": "sqlite",
        "credentials": { "url": "db/bookshop.db" }
      }
    }
  }
}
```

## Verify Persistence

```bash
cds watch
# GET http://localhost:4004/catalog/Books
# Should return the 3 seeded books
# Stop and restart the server
# Data is still there — it's persisted in bookshop.db
```

## Key Lines Explained

```
@cap-js/sqlite               ← CAP's official SQLite adapter
db/data/<namespace>-<Entity>.csv  ← naming convention CAP uses to auto-import CSV
cds deploy --to sqlite:...   ← creates tables + imports CSV data into SQLite
credentials.url              ← tells CAP which SQLite file to use at runtime
```

## Common Mistakes

- **CSV not imported** → File name must exactly match `<namespace>-<EntityName>.csv` with the right capitalization.
- **Data disappears on `cds deploy`** → `cds deploy` drops and recreates tables. Use it only in dev; never against a production DB.
- **`require.db` config ignored** → Must be in `package.json` under the `"cds"` key, not in `.cdsrc.json` for local dev.

## ✅ Checkpoint

`GET /catalog/Books` returns all 3 seeded books. Stop `cds watch`, restart it, and the books are still there. `bookshop.db` file exists in `db/`.
$md$ WHERE slug = '6-sqllite-test';

UPDATE public.topics SET content_md = $md$
## What Is This?

Connect your SAPUI5 single-screen app (from topic 1) to a live CAP OData backend. Swap the local JSONModel for an ODataModel and watch the data flow from the database.

## Why It Matters

This is the full-stack moment. Your UI5 front-end speaks OData; your CAP back-end serves OData. Understanding how `sap.ui.model.odata.v4.ODataModel` replaces `JSONModel` is central to every Fiori project.

## Update manifest.json — add data source

```json
"dataSources": {
  "mainService": {
    "uri": "/catalog/",
    "type": "OData",
    "settings": { "odataVersion": "4.0" }
  }
},
"models": {
  "": {
    "dataSource": "mainService",
    "preload": true,
    "settings": { "synchronizationMode": "None", "operationMode": "Server" }
  }
}
```

## Update the View (no controller code needed)

```xml
<List items="{/Books}">
  <StandardListItem
    title="{title}"
    description="{author}" />
</List>
```

> No `onInit` needed — the ODataModel is set up by the manifest and auto-binds.

## Run Both Together

In one terminal:
```bash
# From CAP project
cds watch
```

In another terminal (or configure ui5.yaml proxy):
```yaml
# ui5.yaml
server:
  customMiddleware:
    - name: ui5-middleware-simpleproxy
      afterMiddleware: compression
      configuration:
        baseUri: "http://localhost:4004"
        pathPrefix: "/catalog"
```

```bash
# From UI5 project
npm start
```

## Key Lines Explained

```
dataSources.mainService.uri: "/catalog/"   ← tells UI5 where the OData service lives
type: "OData"                              ← activates the OData model
{/Books}                                  ← absolute binding to the Books entity set
synchronizationMode: "None"               ← V4 model: no manual sync needed
```

## Common Mistakes

- **CORS error in browser** → You need the proxy middleware (`ui5-middleware-simpleproxy`) or run both on the same origin. CAP's `cds watch` serves on port 4004; UI5 on 8080.
- **Model shows no data** → The URI must end with `/` for OData V4 and the path in the binding must match the entity set name exactly.
- **V2 vs V4 confusion** → CAP exposes OData V4 by default. Use `sap.ui.model.odata.v4.ODataModel`, not V2.

## ✅ Checkpoint

Your SAPUI5 app loads and shows the seeded books from the CAP SQLite database. No hardcoded JSON in the controller. Changing data in the CSV and redeploying updates the UI.
$md$ WHERE slug = '7-cap-ss-test';

UPDATE public.topics SET content_md = $md$
## What Is This?

A full-stack app: SAPUI5 multi-screen navigation + full CRUD operations, all wired to a live CAP OData V4 service backed by SQLite. This is the first time everything works together.

## Core Pattern: OData V4 CRUD

### Read (auto-binding in view)
```xml
<List items="{/Books}" growing="true" growingThreshold="20">
  <StandardListItem title="{title}" description="{author}"
    type="Navigation" press=".onItemPress" />
</List>
```

### Create
```javascript
onCreateBook: function () {
  var oModel = this.getView().getModel();
  var oListBinding = oModel.bindList("/Books");
  var oContext = oListBinding.create({
    title: this.byId("titleInput").getValue(),
    author: this.byId("authorInput").getValue(),
    stock: 0,
    price: 0
  });
  oContext.created().then(() => {
    MessageToast.show("Book created");
    oModel.refresh();
  });
}
```

### Update (inline editing with two-way binding)
```xml
<!-- In Detail view -->
<Input value="{title}" />
<Input value="{author}" />
<Button text="Save" press=".onSave" />
```
```javascript
onSave: function () {
  this.getView().getModel().submitBatch("$auto");
}
```

### Delete
```javascript
onDelete: function () {
  var oCtx = this.getView().getBindingContext();
  oCtx.delete("$auto").then(() => {
    this.getOwnerComponent().getRouter().navTo("main");
  });
}
```

## Key Lines Explained

```
oListBinding.create({...})    ← creates a new entity via OData POST, returns a context
oContext.created()            ← Promise that resolves when the server confirms creation
submitBatch("$auto")          ← flushes pending changes to the server (V4 batch)
oCtx.delete("$auto")          ← sends an OData DELETE request
```

## Common Mistakes

- **Create succeeds but list doesn't update** → Call `oModel.refresh()` after creation, or use the created context's binding to re-fetch.
- **Update not persisting** → OData V4 uses a deferred write model; you must call `submitBatch` or set `autoExpandSelect` + `updateGroupId`.
- **Delete throws 404** → The context must still be bound to the model (not stale from navigation).

## ✅ Checkpoint

You can create a book (it appears in the list), navigate to its detail, edit the title (it saves on "Save"), and delete it (it disappears from the list). All changes survive a server restart.
$md$ WHERE slug = '8-cap-ms-test';

UPDATE public.topics SET content_md = $md$
## What Is This?

Rebuild the Value Help dialog from topic 4, but now the selectable values come from the live CAP OData backend instead of hardcoded JSON. The search filters server-side.

## Key Change: OData-Bound SelectDialog

```xml
<SelectDialog
  id="bookVH"
  title="Select Book"
  search=".onVHSearch"
  confirm=".onVHConfirm"
  items="{
    path: '/Books',
    parameters: { $$queryOptions: { $top: 50 } }
  }">
  <StandardListItem title="{title}" description="{author}" />
</SelectDialog>
```

## Server-Side Search

```javascript
onVHSearch: function (oEvent) {
  var sValue = oEvent.getParameter("value");
  var oBinding = oEvent.getSource().getBinding("items");
  if (sValue) {
    oBinding.filter([
      new Filter("title", FilterOperator.Contains, sValue)
    ]);
  } else {
    oBinding.filter([]);
  }
}
```

> **Important:** With an OData binding, `.filter()` sends a `$filter` query parameter to the server — the filtering is done by CAP/SQLite, not in the browser.

## Confirm Handler

```javascript
onVHConfirm: function (oEvent) {
  var oCtx = oEvent.getParameter("selectedContexts")[0];
  this.byId("bookInput").setValue(oCtx.getProperty("title"));
  this._oVHDialog.then(d => d.getBinding("items").filter([]));
}
```

## Key Lines Explained

```
$$queryOptions: { $top: 50 }   ← limits initial load to 50 items (OData $top)
oBinding.filter([new Filter(...)]) ← sends $filter=contains(title,'...') to CAP
oCtx.getProperty("title")         ← reads the value from the server-side binding context
```

## Common Mistakes

- **Search has no effect** → You're filtering the local model instead of the OData binding. Make sure the dialog's items are bound to an OData path, not a JSON model.
- **All items load on open** → Add `$top` in `$$queryOptions` or set `growing="true"` with `growingThreshold` on the list.
- **Filter not reset on reopen** → Call `filter([])` in the confirm/cancel handler and again before `open()`.

## ✅ Checkpoint

Opening the Value Help loads books from the database. Typing in the search box filters the list in real time (watch the network tab — a new OData request fires). Selecting a book fills the input field.
$md$ WHERE slug = '9-cap-f4-test';

UPDATE public.topics SET content_md = $md$
## What Is This?

Add input validation and user feedback to your SAPUI5 app. You will use `ValueState`, `MessageToast`, `MessageBox`, and CAP's server-side `req.error()`.

## Client-Side Validation (Controller)

```javascript
onSave: function () {
  var oInput = this.byId("titleInput");
  var sValue = oInput.getValue();

  if (!sValue.trim()) {
    oInput.setValueState(sap.ui.core.ValueState.Error);
    oInput.setValueStateText("Title cannot be empty");
    return;
  }

  oInput.setValueState(sap.ui.core.ValueState.None);
  // proceed with save ...
  sap.m.MessageToast.show("Saved successfully");
}
```

## MessageBox for Destructive Actions

```javascript
onDelete: function () {
  sap.m.MessageBox.confirm("Delete this book?", {
    title: "Confirm",
    onClose: function (sAction) {
      if (sAction === sap.m.MessageBox.Action.OK) {
        // perform delete
      }
    }
  });
}
```

## CAP Server-Side Validation

```javascript
// srv/cat-service.js
this.before("CREATE", "Books", (req) => {
  const { title, price } = req.data;
  if (!title)       req.error(400, "Title is required", "in/title");
  if (price < 0)    req.error(400, "Price must be positive", "in/price");
});
```

## OData V4 Error Handling in UI5

```javascript
oContext.created().catch((oError) => {
  var sMsg = oError.message || "Save failed";
  sap.m.MessageBox.error(sMsg);
});
```

## Key Lines Explained

```
setValueState(ValueState.Error)    ← turns the Input border red
setValueStateText("...")           ← shows tooltip/popup with the error text
req.error(400, "...", "in/title")  ← 3rd param maps error to a specific field
MessageBox.confirm(...)            ← modal dialog with OK/Cancel
MessageToast.show(...)             ← non-blocking toast notification (auto-hides)
```

## Common Mistakes

- **ValueState not showing** → Input must have `showValueStateMessage="true"` (default is true, but check you haven't disabled it).
- **Server error not surfaced in UI** → You must handle the `.catch()` on the OData promise; UI5 doesn't show server errors automatically.
- **MessageBox fires twice** → `onClose` is called for every button including the X; always check `sAction === Action.OK`.

## ✅ Checkpoint

Trying to save an empty title shows a red Input with an error message. Clicking Delete shows a confirmation dialog. A server-side validation error (price < 0) is caught and shown in a MessageBox.
$md$ WHERE slug = '10-validation-test';

UPDATE public.topics SET content_md = $md$
## What Is This?

Add a live-search bar, column sorting, and list filtering to your SAPUI5 app. All filtering and sorting happens server-side via OData queries.

## SearchField + Filter

```xml
<!-- View -->
<SearchField search=".onSearch" placeholder="Search books..." />
<List id="bookList" items="{/Books}">
  <StandardListItem title="{title}" description="{author}"
    info="{stock}" infoState="Information" />
</List>
```

```javascript
// Controller
onSearch: function (oEvent) {
  var sQuery = oEvent.getParameter("query");
  var oBinding = this.byId("bookList").getBinding("items");

  var aFilters = [];
  if (sQuery) {
    aFilters = [
      new Filter({
        filters: [
          new Filter("title",  FilterOperator.Contains, sQuery),
          new Filter("author", FilterOperator.Contains, sQuery)
        ],
        and: false   // OR filter — match title OR author
      })
    ];
  }
  oBinding.filter(aFilters);
}
```

## Column Sort

```javascript
onSortByTitle: function () {
  var oBinding = this.byId("bookList").getBinding("items");
  this._bSortAsc = !this._bSortAsc;   // toggle
  oBinding.sort(new Sorter("title", !this._bSortAsc));
},

onSortByPrice: function () {
  var oBinding = this.byId("bookList").getBinding("items");
  oBinding.sort(new Sorter("price", true));  // descending
}
```

## Key Lines Explained

```
oBinding.filter([...])       ← sends $filter to the OData service
new Filter({ filters:[], and:false })  ← OR filter across multiple fields
oBinding.sort(new Sorter("title", false))  ← $orderby=title asc
Sorter("price", true)        ← $orderby=price desc (second arg = descending)
```

## Common Mistakes

- **OR filter not working** → You must use the multi-filter constructor `new Filter({ filters: [...], and: false })`; passing two separate filters to `oBinding.filter([f1, f2])` creates AND logic.
- **Sort resets the filter** → OData V4 binding remembers both; but if you call `.filter()` after `.sort()`, make sure you pass the current sort alongside.
- **Search clears but filter stays** → When query is empty, pass `[]` to `filter()` to clear all filters.

## ✅ Checkpoint

Typing in the search box filters the list to matching titles or authors (watch the network requests — `$filter` appears in the URL). Clicking the sort button reverses the order. Clearing the search restores all items.
$md$ WHERE slug = '11-filter-sort-test';

UPDATE public.topics SET content_md = $md$
## What Is This?

Protect your CAP service with XSUAA (SAP's OAuth2/JWT implementation on BTP). You will define roles, configure `xs-security.json`, and use `@requires` in CDS to lock down endpoints.

## Why It Matters

Every production SAP app on BTP requires authentication. XSUAA is the identity provider for Cloud Foundry; understanding how roles flow from the Identity Provider to your CAP handler is essential.

## xs-security.json

```json
{
  "xsappname": "bookshop",
  "tenant-mode": "dedicated",
  "scopes": [
    { "name": "$XSAPPNAME.admin",  "description": "Admin scope" },
    { "name": "$XSAPPNAME.viewer", "description": "Viewer scope" }
  ],
  "role-templates": [
    { "name": "admin",  "scope-references": ["$XSAPPNAME.admin"]  },
    { "name": "viewer", "scope-references": ["$XSAPPNAME.viewer"] }
  ],
  "role-collections": [
    { "name": "Bookshop Admin", "role-template-references": ["$XSAPPNAME.admin"]  },
    { "name": "Bookshop User",  "role-template-references": ["$XSAPPNAME.viewer"] }
  ]
}
```

## Protect the CDS Service

```cds
// srv/cat-service.cds
using my.bookshop as my from '../db/schema';

@requires: 'viewer'
service CatalogService {
  @readonly entity Books as projection on my.Books;

  @requires: 'admin'
  entity AdminBooks as projection on my.Books;
}
```

## Check Roles in a Handler

```javascript
this.before("*", (req) => {
  if (!req.user.is("admin")) {
    req.error(403, "Admin role required");
  }
});
```

## Local Development with Mock Auth

```json
// package.json
{
  "cds": {
    "requires": {
      "auth": {
        "kind": "mocked",
        "users": {
          "alice": { "roles": ["admin", "viewer"] },
          "bob":   { "roles": ["viewer"] }
        }
      }
    }
  }
}
```

Test with: `GET /catalog/Books` with header `Authorization: Basic alice:`.

## Key Lines Explained

```
$XSAPPNAME.admin       ← scopes are namespaced to the app (prevents collisions)
@requires: 'viewer'    ← CDS annotation: rejects requests without this role
req.user.is("admin")   ← checks if the authenticated user has the admin role
kind: "mocked"         ← local-only mock auth — never deploy this config
```

## Common Mistakes

- **403 in local dev** → You forgot to configure mocked auth or send the Authorization header.
- **Role not found** → The role name in `@requires` must match the role-template name in `xs-security.json`.
- **Works locally, fails on BTP** → On BTP, `kind: "xsuaa"` must be used, pointing to the bound XSUAA service instance.

## ✅ Checkpoint

`GET /catalog/Books` without a header returns 403. `GET /catalog/Books` with `Authorization: Basic alice:` returns the books. `GET /catalog/AdminBooks` with `Authorization: Basic bob:` returns 403 (bob has no admin role).
$md$ WHERE slug = '12-auth-test';

UPDATE public.topics SET content_md = $md$
## What Is This?

BTP Destinations decouple your app from hardcoded backend URLs. Instead of `https://my-backend.example.com`, you reference a named destination; BTP resolves it at runtime.

## Why It Matters

In production, your UI5 app cannot hardcode backend URLs — the URL differs between dev, test, and production. Destinations let you change the target without redeploying the app.

## Create a Destination (BTP Cockpit)

1. Go to **Connectivity → Destinations → New Destination**
2. Fill in:

```
Name:              MyBackend
Type:              HTTP
URL:               https://your-cap-app.cfapps.us10.hana.ondemand.com
Authentication:    NoAuthentication   (or OAuth2 as needed)
ProxyType:         Internet
```

3. Add a property: `HTML5.DynamicDestination = true`

## Reference in xs-app.json (App Router)

```json
{
  "authenticationMethod": "route",
  "routes": [
    {
      "source": "^/catalog/(.*)",
      "target": "/catalog/$1",
      "destination": "MyBackend",
      "authenticationType": "xsuaa"
    }
  ]
}
```

## Reference in manifest.json (UI5 App)

```json
"dataSources": {
  "mainService": {
    "uri": "/catalog/",
    "type": "OData",
    "settings": { "odataVersion": "4.0" }
  }
}
```

> The UI5 app calls `/catalog/` — the App Router intercepts it, looks up `MyBackend` destination, and forwards to the real URL.

## Key Lines Explained

```
destination: "MyBackend"           ← App Router looks this up in BTP at runtime
HTML5.DynamicDestination = true    ← allows the App Router to forward dynamically
source: "^/catalog/(.*)"           ← regex: intercept all /catalog/... requests
target: "/catalog/$1"              ← forward with the captured path segment
```

## Common Mistakes

- **502 Bad Gateway** → Destination URL is wrong or the backend is not running.
- **401 on the backend** → Set `Authentication: NoAuthentication` for dev, or configure proper OAuth2 for production.
- **Works locally, fails on BTP** → Local dev uses a proxy; on BTP you need the App Router properly bound to the XSUAA service.

## ✅ Checkpoint

Your App Router forwards `/catalog/Books` to the real CAP backend via the `MyBackend` destination. Changing the destination URL in BTP Cockpit immediately reroutes traffic without redeployment.
$md$ WHERE slug = '13-destination-test';

UPDATE public.topics SET content_md = $md$
## What Is This?

The App Router (`@sap/approuter`) sits in front of your UI5 app and CAP service. It handles authentication, routing, and destination forwarding — the entry point for every BTP multi-app deployment.

## Why It Matters

On BTP Cloud Foundry, the App Router is the only publicly accessible component. It authenticates users via XSUAA, then forwards requests to the backend using the service binding credentials — your CAP service stays private.

## Folder Structure

```
my-project/
├── approuter/
│   ├── package.json
│   └── xs-app.json
├── bookshop/           ← CAP backend
└── bookshop-ui/        ← SAPUI5 frontend
```

## approuter/package.json

```json
{
  "name": "approuter",
  "dependencies": { "@sap/approuter": "^14" },
  "scripts": { "start": "node node_modules/@sap/approuter/approuter.js" }
}
```

## approuter/xs-app.json

```json
{
  "welcomeFile": "/ui/index.html",
  "authenticationMethod": "route",
  "routes": [
    {
      "source": "^/ui/(.*)",
      "target": "$1",
      "localDir": "../bookshop-ui/webapp",
      "authenticationType": "xsuaa"
    },
    {
      "source": "^/catalog/(.*)",
      "target": "/catalog/$1",
      "destination": "MyBackend",
      "authenticationType": "xsuaa"
    }
  ]
}
```

## Run Locally

```bash
cd approuter && npm install
# Set env vars for local XSUAA mock:
export destinations='[{ "name":"MyBackend", "url":"http://localhost:4004" }]'
node node_modules/@sap/approuter/approuter.js
# Open http://localhost:5000
```

## Key Lines Explained

```
welcomeFile                ← the default page when hitting the root URL
localDir                   ← serves UI5 static files directly from the file system
destination: "MyBackend"   ← looks up the destination by name (env var locally)
authenticationType: "xsuaa"← every request to this route requires a valid JWT
```

## Common Mistakes

- **Redirect loop** → `welcomeFile` must start with a `/` and the route for it must exist.
- **CORS from App Router** → When using the App Router, never set CORS in CAP — the App Router handles it.
- **Destination env var format** → The `destinations` env var must be a JSON array string: `'[{"name":"X","url":"..."}]'`.

## ✅ Checkpoint

Navigating to `http://localhost:5000/ui/index.html` serves the SAPUI5 app. API calls to `/catalog/Books` are proxied by the App Router to CAP. Without a valid session, any request redirects to the login page.
$md$ WHERE slug = '14-approuter-test';

UPDATE public.topics SET content_md = $md$
## What Is This?

Deploy your complete app (UI5 + CAP + App Router) to SAP BTP Cloud Foundry using an MTA (Multi-Target Application) build.

## Why It Matters

An MTA is a single deployable unit that manages multiple apps and service bindings together. Understanding `mta.yaml` is mandatory for any real SAP BTP project.

## mta.yaml

```yaml
_schema-version: '3.1'
ID: bookshop
version: 1.0.0
description: Bookshop CAP + UI5

modules:
  - name: bookshop-srv
    type: nodejs
    path: bookshop
    requires:
      - name: bookshop-db
      - name: bookshop-uaa
    provides:
      - name: srv-api
        properties:
          srv-url: ${default-url}

  - name: bookshop-approuter
    type: approuter.nodejs
    path: approuter
    requires:
      - name: bookshop-uaa
      - name: srv-api
    parameters:
      disk-quota: 256M
      memory: 256M

resources:
  - name: bookshop-db
    type: com.sap.xs.hdi-container
    parameters:
      service: hanatrial
      service-plan: hdi-shared

  - name: bookshop-uaa
    type: org.cloudfoundry.managed-service
    parameters:
      service: xsuaa
      service-plan: application
      path: ./bookshop/xs-security.json
```

## Build & Deploy

```bash
# Install MTA build tool (one-time)
npm install -g mbt

# Build the MTA archive
mbt build

# Deploy to Cloud Foundry
cf login -a https://api.cf.us10.hana.ondemand.com
cf deploy mta_archives/bookshop_1.0.0.mtar
```

## Verify

```bash
cf apps          # list running apps
cf logs bookshop-srv --recent   # check logs
```

## Key Lines Explained

```
modules              ← each app that gets deployed as a CF app
resources            ← service instances that get created/bound
requires/provides    ← dependency graph: approuter gets the CAP URL via srv-api
${default-url}       ← MTA placeholder: resolves to the CF app's URL at deploy time
hdi-container        ← SAP HANA HDI container for persistence (replace sqlite in prod)
mbt build            ← produces a .mtar archive containing all modules
cf deploy *.mtar     ← Cloud Foundry MTA plugin deploys the whole stack
```

## Common Mistakes

- **`mbt` not found** → Install globally: `npm i -g mbt`.
- **Deploy fails with "service not found"** → The `hanatrial` HANA service is only available in Trial. Use `hana` + `hdi-shared` in production.
- **App crashes after deploy** → `cf logs <app-name> --recent` always shows the exact error.

## ✅ Checkpoint

`cf apps` shows `bookshop-srv` and `bookshop-approuter` as `running`. Opening the approuter URL in a browser loads the SAPUI5 app, authenticated via XSUAA, talking to the deployed CAP service on HANA.
$md$ WHERE slug = '15-deploy-test';

UPDATE public.topics SET content_md = $md$
## Capstone Part 1 — Data Model + CAP Service

This is the first of four capstone episodes. You design your own data model, expose it via CAP, and test it end-to-end — without step-by-step guidance.

## The Challenge

Build a **Product Catalog** service with these requirements:

- `Products` entity: `id` (UUID), `name` (String 200), `category` (String 50), `price` (Decimal 9,2), `stock` (Integer), `active` (Boolean)
- `Categories` entity: `id` (String 10), `name` (String 100)
- `Products` has an association to `Categories`
- Service exposes both entities with appropriate read/write restrictions
- At least one custom handler: log every CREATE to console

## Reference: CDS Associations

```cds
entity Products : cuid {
  name     : String(200);
  category : Association to Categories;
  price    : Decimal(9,2);
  stock    : Integer default 0;
  active   : Boolean default true;
}

entity Categories {
  key id   : String(10);
  name     : String(100);
  products : Association to many Products on products.category = $self;
}
```

## Reference: Service with Restrictions

```cds
service ProductCatalog {
  @readonly entity Categories as projection on my.Categories;
  entity Products as projection on my.Products actions {
    action discontinue() returns Products;
  };
}
```

## Reference: Seed CSV (db/data/my-Products.csv)

```csv
ID,name,category_id,price,stock,active
uuid-1,Laptop,TECH,999.00,50,true
uuid-2,Monitor,TECH,349.00,100,true
uuid-3,Desk Chair,FURN,249.00,30,true
```

## ✅ Checkpoint

`GET /product-catalog/Products?$expand=category` returns products with their category names embedded. `POST /product-catalog/Products` creates a new product. The console shows the log message on every create.
$md$ WHERE slug = '16-mp-1-test';

UPDATE public.topics SET content_md = $md$
## Capstone Part 2 — Full UI5 Front-End

Build a complete multi-screen SAPUI5 front-end for the Product Catalog service. No step-by-step — apply everything from topics 1–4.

## Requirements

- **Main screen**: Searchable list of products (title = name, description = category, info = price)
- **Detail screen**: All product fields displayed, with Edit mode
- **Create dialog**: Fragment with inputs for name, category (Value Help), price, stock
- **Delete**: With confirm dialog

## Architecture Reminder

```
webapp/
├── manifest.json          ← routes: main, detail/{id}, create
├── view/
│   ├── Main.view.xml
│   └── Detail.view.xml
├── controller/
│   ├── Main.controller.js
│   └── Detail.controller.js
└── fragment/
    ├── CreateProduct.fragment.xml
    └── CategoryVH.fragment.xml
```

## Key Pattern: $expand in OData V4 binding

```xml
<!-- Main list with category expanded -->
<List items="{
  path: '/Products',
  parameters: {
    $expand: 'category',
    $orderby: 'name'
  }
}">
  <StandardListItem
    title="{name}"
    description="{category/name}"
    info="{price}"
    type="Navigation"
    press=".onItemPress" />
</List>
```

## Key Pattern: Edit Toggle

```javascript
onEdit: function () {
  this._bEditMode = !this._bEditMode;
  this.getView().getModel("ui").setProperty("/editMode", this._bEditMode);
},
onSave: function () {
  this.getView().getModel().submitBatch("$auto")
    .then(() => { this._bEditMode = false; MessageToast.show("Saved"); });
}
```

## ✅ Checkpoint

The app has a working main list with search, a detail view with edit/save, a create dialog with a Value Help for category, and a working delete with confirmation. All data persists in SQLite.
$md$ WHERE slug = '17-mp-2-test';

UPDATE public.topics SET content_md = $md$
## Capstone Part 3 — Polish

Add professional-grade UX polish to the Product Catalog: proper validation, inline error indicators, sort/filter toolbar, and a responsive layout.

## Validation Pattern (reusable)

```javascript
_validateForm: function (aInputIds) {
  var bValid = true;
  aInputIds.forEach(function (sId) {
    var oInput = this.byId(sId);
    if (!oInput.getValue().trim()) {
      oInput.setValueState(sap.ui.core.ValueState.Error);
      oInput.setValueStateText("This field is required");
      bValid = false;
    } else {
      oInput.setValueState(sap.ui.core.ValueState.None);
    }
  }.bind(this));
  return bValid;
},

onSave: function () {
  if (!this._validateForm(["nameInput", "priceInput"])) return;
  // proceed with save
}
```

## Toolbar with Sort + Filter

```xml
<Toolbar>
  <SearchField width="30%" search=".onSearch" />
  <ToolbarSpacer />
  <Select change=".onCategoryFilter">
    <items>
      <core:Item key="" text="All Categories" />
      <core:Item key="TECH" text="Technology" />
      <core:Item key="FURN" text="Furniture" />
    </items>
  </Select>
  <Button icon="sap-icon://sort" press=".onSort" />
</Toolbar>
```

## Responsive Layout with sap.f.DynamicPage

```xml
<f:DynamicPage>
  <f:title>
    <f:DynamicPageTitle>
      <f:heading><Title text="Products" /></f:heading>
      <f:actions>
        <Button text="Add" type="Emphasized" press=".onAdd" />
      </f:actions>
    </f:DynamicPageTitle>
  </f:title>
  <f:content>
    <!-- Your list here -->
  </f:content>
</f:DynamicPage>
```

## ✅ Checkpoint

All required fields show red borders if empty on save attempt. The category dropdown filters the list server-side. Sorting toggles alphabetically. The layout is clean on both desktop and mobile viewport.
$md$ WHERE slug = '18-mp-3-test';

UPDATE public.topics SET content_md = $md$
## Capstone Part 4 — Secure & Deploy

The finish line. Add XSUAA auth, wire up the App Router with a destination, build an MTA, and deploy the complete Product Catalog app to BTP Cloud Foundry.

## Checklist Before Deploying

- [ ] `xs-security.json` defines viewer and admin roles
- [ ] CDS service uses `@requires` annotations
- [ ] `xs-app.json` routes UI and API through the App Router
- [ ] `mta.yaml` defines all modules and resource bindings
- [ ] CSV seed data is in `db/data/`
- [ ] `cds build --production` runs without errors

## Final mta.yaml Summary

```yaml
modules:
  - name: product-catalog-srv      # CAP backend
  - name: product-catalog-approuter # App Router
resources:
  - name: product-catalog-db        # HANA HDI container
  - name: product-catalog-uaa       # XSUAA service
```

## Production Build + Deploy

```bash
cds build --production
mbt build
cf deploy mta_archives/product-catalog_1.0.0.mtar
```

## Assign Roles (BTP Cockpit)

After deploy:
1. Go to **Security → Role Collections**
2. Assign **Product Catalog Admin** role collection to your user
3. Log out and back in to pick up the new role

## Smoke Test Production

```bash
# Get the app URL
cf app product-catalog-approuter

# Open in browser — should prompt for XSUAA login
# After login, the product list should load from HANA
```

## ✅ Checkpoint

The app is live on BTP. Unauthenticated access redirects to the XSUAA login page. After login with the admin role collection assigned, you can create, edit, and delete products. Data is in a HANA HDI container. This is a portfolio-worthy, production-shaped SAP BTP application.
$md$ WHERE slug = '19-mp-4-test';

UPDATE public.topics SET content_md = $md$
## What Is This?

A living reference of 40 real-world errors every SAP BTP developer encounters. Each entry has the exact error message, why it happens, and the fix.

## Binding & Model Errors

**1. List shows nothing after model set**
- Cause: Used `{products}` instead of `{/products}` (missing leading `/` for absolute path)
- Fix: Always use `/` for root-level properties in JSONModel bindings

**2. `Cannot read property 'getModel' of undefined`**
- Cause: Called `this.getView().getModel()` before `onInit` completed
- Fix: Access the model inside `onInit` or after the view is rendered

**3. OData binding shows old data after CRUD**
- Cause: Stale binding context; model not refreshed after create/update
- Fix: Call `oModel.refresh()` or rebind the list element

**4. `Binding path 'X' has no matching property`**
- Cause: Typo in the property name in the XML binding expression
- Fix: Check the exact field names from `$metadata` or your CDS model

## Routing Errors

**5. White screen after `navTo()`**
- Cause: `controlId` in manifest.json routing config doesn't match the App control's `id`
- Fix: Set `"controlId": "app"` and `id="app"` on your `<App>` or `<Shell>` control

**6. Route parameters are `undefined`**
- Cause: `attachPatternMatched` called outside `onInit`, or called on the wrong route
- Fix: Attach the listener in `onInit` using `this.getOwnerComponent().getRouter().getRoute("detail").attachPatternMatched(...)`

**7. Back navigation creates duplicate history entries**
- Cause: Each `navTo("main")` pushes a new browser history entry
- Fix: Use `navTo("main", {}, true)` — third argument `true` replaces history instead of appending

## CAP / OData Errors

**8. `404 Not Found` on CAP endpoint**
- Cause: Wrong URL — CAP derives the path from the service name: `CatalogService` → `/catalog/`
- Fix: Check the CAP welcome page at `http://localhost:4004` for the exact URL

**9. `501 Not Implemented` on CREATE**
- Cause: Entity is `@readonly` in the CDS service definition
- Fix: Remove `@readonly` or create a separate action/function for writes

**10. CSV data not imported**
- Cause: Filename doesn't match `<namespace>-<EntityName>.csv` exactly
- Fix: Check casing — `my.bookshop-Books.csv` not `my.bookshop-books.csv`

**11. `SQLITE_CONSTRAINT: NOT NULL`**
- Cause: Required field in CDS model doesn't have a default value and isn't provided in POST body
- Fix: Add `default` value in CDS or ensure the field is always sent in the request

**12. Handler not called**
- Cause: JS file doesn't match the CDS file name
- Fix: `cat-service.js` must exist alongside `cat-service.cds`

## Authentication / XSUAA Errors

**13. `403 Forbidden` in local development**
- Cause: Mocked auth not configured, or `Authorization` header missing
- Fix: Add `kind: "mocked"` to `cds.requires.auth` in package.json and send `Authorization: Basic alice:`

**14. `AADSTS50011: The reply URL does not match`**
- Cause: XSUAA redirect URI not configured with your App Router URL
- Fix: Add the App Router URL to the XSUAA redirect URIs in the BTP subaccount trust configuration

**15. Token expired errors in production**
- Cause: JWT tokens expire (default 12h); the App Router should refresh automatically
- Fix: Ensure the App Router is bound to the XSUAA service instance and `forwardAuthToken: true` is NOT set on backend routes

## Deployment Errors

**16. `cf deploy` fails: `Service not found`**
- Cause: Using `hanatrial` service plan outside of BTP Trial
- Fix: Change to `hana` with `hdi-shared` plan in production mta.yaml

**17. App crashes: `Error: Cannot find module '@sap/cds'`**
- Cause: `@sap/cds` is in `devDependencies` but not `dependencies`
- Fix: Move `@sap/cds` to `dependencies` in package.json for the CAP module

**18. `mbt build` fails: missing `xs-security.json`**
- Cause: The `path` in the XSUAA resource definition points to a non-existent file
- Fix: Double-check the relative path in mta.yaml: `path: ./bookshop/xs-security.json`

**19. App Router returns 502 on API calls**
- Cause: Destination URL is wrong or the CAP app is not running
- Fix: Check `cf logs <srv-app-name> --recent` and verify the destination URL in BTP Cockpit

**20. HANA deployment fails: `HDI deployer exited with code 1`**
- Cause: CDS model has errors that SQLite tolerates but HANA rejects (e.g., unsupported types)
- Fix: Run `cds compile --to hana` locally to catch HANA-specific issues before deploy

## BAS / Tooling Issues

**21. BAS dev space keeps stopping**
- Cause: Free tier hibernates after 60 minutes of inactivity
- Fix: Click the play button to restart; your files are persisted

**22. `yo` command not found in BAS**
- Cause: Yeoman not installed in the dev space
- Fix: Use the **Fiori: Open Application Generator** from the Command Palette (Ctrl+Shift+P) instead

**23. `npm install` hangs indefinitely**
- Cause: BAS network throttling or SAP registry rate limit
- Fix: Add `.npmrc` file: `@sap:registry=https://registry.npmjs.org/`

**24. Live reload not working in BAS**
- Cause: Port not forwarded in the Ports panel
- Fix: Open **View → Ports** and manually forward port 8080

**25. Changes to CDS not reflected**
- Cause: `cds watch` not running, or watching the wrong directory
- Fix: Ensure you started `cds watch` from the project root (where `package.json` is)

## UI5 / Fiori Specific

**26. `sap.m.MessageToast` not working**
- Cause: Module not required in the `sap.ui.define` array
- Fix: Add `"sap/m/MessageToast"` to the define array and the function parameter

**27. Dialog opens behind other elements (z-index)**
- Cause: Dialog rendered outside the DOM root in some themes
- Fix: Always open dialogs from a controller, never from a custom renderer

**28. `Assertion failed: value must not be null`**
- Cause: `this.byId("someId")` returns `null` — the ID doesn't exist in this view
- Fix: Check that the ID is defined in the XML view and you're in the right controller

**29. OData $expand returns empty array**
- Cause: The association foreign key is null (the related entity doesn't exist)
- Fix: Ensure CSV seed data has valid FK values that match the related entity's key

**30. `TypeError: Cannot read property 'getParameter' of undefined`**
- Cause: Event handler registered with `.bind(this)` but `oEvent` not passed through
- Fix: Check the event attachment syntax; always define handlers as `function(oEvent) {...}`

## CORS & Network

**31. CORS error calling CAP from UI5**
- Cause: UI5 app on port 8080 calling CAP on port 4004 — different origins
- Fix: Use the `ui5-middleware-simpleproxy` in `ui5.yaml` to proxy `/catalog` calls

**32. `net::ERR_NAME_NOT_RESOLVED` in production**
- Cause: Destination URL uses HTTP instead of HTTPS, or the hostname is wrong
- Fix: All URLs on BTP must use HTTPS

**33. Preflight OPTIONS request fails**
- Cause: CAP CORS configuration doesn't include the required headers
- Fix: In CAP dev, CORS is open by default. In production, use the App Router (no direct CAP access)

## Data / Schema

**34. Decimal precision lost (e.g., 9.99 becomes 10)**
- Cause: Binding displays a Number — JavaScript rounds decimals
- Fix: Use `sap.ui.model.type.Decimal` with `formatOptions: { decimals: 2 }` in the binding

**35. Date fields show as numbers**
- Cause: CAP stores dates as ISO strings; UI5 expects a Date type
- Fix: Use `sap.ui.model.type.Date` with `pattern: "yyyy-MM-dd"` in the binding

## Performance

**36. List loads 1000+ items**
- Cause: No `$top` limit on OData binding
- Fix: Add `growing="true" growingThreshold="20"` to the List control (adds `$top=20&$skip=N`)

**37. Slow initial load**
- Cause: Multiple separate OData requests (one per list item) instead of one with `$expand`
- Fix: Use `$expand` in the list binding to fetch related data in a single request

## Miscellaneous

**38. `manifest.json` parsing error**
- Cause: Trailing comma in JSON (JSON doesn't allow trailing commas)
- Fix: Use a JSON linter or VS Code which highlights these errors

**39. UI5 version mismatch**
- Cause: `manifest.json` `minUI5Version` conflicts with the bootstrap version
- Fix: Set `"minUI5Version": "1.120.0"` in manifest.json and use the matching bootstrap CDN URL

**40. App works in Chrome but not Safari**
- Cause: Safari is stricter about ES6+ features and some CSS
- Fix: Check UI5 browser compatibility matrix; avoid `async/await` in older UI5 versions without polyfill

## ✅ Checkpoint

You have a reference you will actually use. Bookmark this topic — every one of these 40 errors is something you will encounter in a real project within your first year.
$md$ WHERE slug = '20-rtp-test';
