-- Fresh content: all 20 topics fully rewritten with explanation → code → key lines → mistakes → checkpoint

UPDATE public.topics SET content_md = $md$
# Episode 0 — Setup: BTP Trial, BAS, and Your First Project

## What you'll build

A working SAP BTP trial account, an active Business Application Studio (BAS) dev space, and a scaffolded SAPUI5 project you can run in the browser — all before writing a single line of app code.

---

## Why this matters

Every topic in this course runs inside SAP BTP. Getting the environment right once means everything else just works. Skipping steps here causes silent failures later.

---

## Step 1 — Create your BTP Trial account

Go to [https://www.sap.com/products/technology-platform/trial.html](https://www.sap.com/products/technology-platform/trial.html) and click **Start your free trial**.

- Use a personal email (not a corporate one — corporate emails sometimes block verification).
- Choose the region closest to you (US East, Europe, or AP).
- After email verification you land on the **BTP Cockpit**.

> **What is BTP Cockpit?** It is the control panel for all your cloud services — databases, runtimes, destinations, and the dev environment you'll use next.

---

## Step 2 — Open Business Application Studio

In the BTP Cockpit:

1. Click **Services → Service Marketplace**.
2. Search for **SAP Business Application Studio**.
3. Click the tile → **Create** a new subscription (free tier).
4. Once provisioned, click **Go to Application**.

BAS opens in a new browser tab. It looks like VS Code because it is built on the same engine.

---

## Step 3 — Create a Dev Space

A Dev Space is a pre-configured container with the tools you need already installed.

1. Click **Create Dev Space**.
2. Name it (e.g. `UI5CAP`).
3. Choose **SAP Fiori** as the kind.
4. Click **Create Dev Space** and wait ~1 minute for it to start (green dot).

> **Why SAP Fiori kind?** It pre-installs the UI5 CLI, CAP CLI (`cds`), and all Fiori generators. You would have to install these manually with any other kind.

---

## Step 4 — Scaffold your first project

Inside BAS, open a terminal: **Terminal → New Terminal**.

```bash
# Install the Yeoman generator for UI5 (only needed once per dev space)
npm install -g yo generator-easy-ui5

# Scaffold a basic UI5 app
yo easy-ui5 project
```

Answer the prompts:
- Target platform: **Application Router Managed Approuter** (choose Simple for now)
- Namespace: `sap.ui.demo.ep0`
- View name: `Main`

The generator creates this structure:

```
ep0/
 ├── webapp/
 │   ├── controller/
 │   │   └── Main.controller.js
 │   ├── view/
 │   │   └── Main.view.xml
 │   ├── Component.js
 │   ├── index.html
 │   └── manifest.json
 └── package.json
```

---

## Step 5 — Run the preview

```bash
cd ep0
npm install
npm start
```

BAS shows a popup — click **Open in New Tab**. You'll see the default Fiori shell with a blank page. That blank page is your app.

> **Nothing shows yet** — that is expected. The view is empty. You'll add content in Episode 1.

---

## Tools to install before Episode 1

Open the terminal and run these once. They stay installed for the lifetime of your dev space:

```bash
# CAP CLI (needed from Episode 5 onward)
npm install -g @sap/cds-dk

# Verify everything is ready
node --version      # should be 18 or 20
ui5 --version       # should be 3.x
cds --version       # should be 7.x or 8.x
```

---

## How the course is structured

| Episodes | Topic |
|---|---|
| 1–4 | Pure SAPUI5 (no backend) |
| 5–6 | CAP backend with SQLite |
| 7–9 | UI5 talking to CAP over OData |
| 10–11 | Validation, search, sort |
| 12–15 | Auth, destinations, approuter, deploy |
| 16–19 | Capstone mini-project |

---

## Common mistakes

**Mistake:** Dev space shows "STOPPED" when you come back the next day.
**Fix:** Trial dev spaces auto-stop after inactivity. Click the play button (▶) to restart. Your files are preserved.

**Mistake:** `yo easy-ui5` command not found.
**Fix:** Run `npm install -g yo generator-easy-ui5` again — the dev space may have been recreated.

**Mistake:** Preview tab shows a connection error.
**Fix:** Make sure `npm install` completed without errors first. Check the terminal for red text.

---

## ✅ Checkpoint

You should have:
- A BTP trial account you can log into.
- A running BAS dev space (green dot).
- A scaffolded project that opens in the browser with a Fiori shell.
- `node`, `ui5`, and `cds` all returning version numbers in the terminal.
$md$ WHERE slug = '0-sp-test';

UPDATE public.topics SET content_md = $md$
# Episode 1 — Single Screen App: Your First SAPUI5 Page

## What you'll build

A single-screen SAPUI5 app that loads a product list from a local JSON file and displays it in a Fiori List. No backend, no routing yet — just the fundamentals of how UI5 boots, binds data, and renders.

---

## Why this matters

Every SAPUI5 app — no matter how complex — is built on three things: a **Component** (the app entry point), a **View** (the XML layout), and a **Model** (the data). Get this triangle right now and every later episode clicks into place.

---

## How UI5 boots — the sequence

Understanding this sequence prevents 80% of beginner errors:

```
index.html loads the UI5 bootstrap script
  → UI5 sees <div data-sap-ui-component> in the body
    → UI5 reads Component.js (named by data-name attribute)
      → Component.js creates a JSONModel and sets it on the app
        → Component.js reads manifest.json to find the root view
          → manifest.json points to webapp/view/Main.view.xml
            → Main.view.xml renders your list, bound to the model
```

Nothing magical. Just a chain of lookups based on naming conventions.

---

## Project structure

```
1-ss-test/
 ├── webapp/
 │   ├── controller/
 │   │   └── Main.controller.js
 │   ├── view/
 │   │   └── Main.view.xml
 │   ├── model/
 │   │   └── data.json
 │   ├── Component.js
 │   ├── index.html
 │   └── manifest.json
 └── package.json
```

---

## File: index.html

This is the only HTML file. It loads the UI5 framework and tells it where to find your app.

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <title>1-SS-Test</title>
  <script id="sap-ui-bootstrap"
    src="https://sdk.openui5.org/1.120.0/resources/sap-ui-core.js"
    data-sap-ui-theme="sap_horizon"
    data-sap-ui-resourceroots='{"sap.ui.demo.ss": "./"}'
    data-sap-ui-compatVersion="edge"
    data-sap-ui-oninit="module:sap/ui/core/ComponentSupport"
    data-sap-ui-async="true">
  </script>
</head>
<body class="sapUiBody">
  <div data-sap-ui-component
    data-name="sap.ui.demo.ss"
    data-id="container"
    data-settings='{"id": "ss"}'>
  </div>
</body>
</html>
```

**Key lines explained:**
- `data-sap-ui-resourceroots` — maps the namespace `sap.ui.demo.ss` to the current folder `./`. UI5 uses this to find all your files.
- `data-sap-ui-oninit="module:sap/ui/core/ComponentSupport"` — tells UI5 to scan the body for a `<div data-sap-ui-component>` and boot it.
- `data-name="sap.ui.demo.ss"` — UI5 translates this to `sap/ui/demo/ss/Component.js` using the resourceroots map.

---

## File: webapp/Component.js

The app's entry point. Creates the JSON model and mounts it before the view renders.

```js
sap.ui.define([
  "sap/ui/core/UIComponent",
  "sap/ui/model/json/JSONModel"
], function (UIComponent, JSONModel) {
  "use strict";

  return UIComponent.extend("sap.ui.demo.ss.Component", {
    metadata: {
      manifest: "json"   // tells UI5 to read manifest.json for routing and view config
    },

    init: function () {
      // Always call the parent init first
      UIComponent.prototype.init.apply(this, arguments);

      // Load the JSON file and set it as the default (unnamed) model
      var oModel = new JSONModel(
        sap.ui.require.toUrl("sap/ui/demo/ss/model/data.json")
      );
      this.setModel(oModel);
      // Now any view in this app can bind to this model with {/...} paths
    }
  });
});
```

**Key lines explained:**
- `UIComponent.prototype.init.apply(this, arguments)` — never skip this. It sets up internal UI5 plumbing. Skipping it causes silent failures.
- `this.setModel(oModel)` with no name sets the **default model**. Views bind to it with paths starting with `/`.

---

## File: webapp/manifest.json

The app descriptor. Declares the app identity, root view, and registered models.

```json
{
  "_version": "1.58.0",
  "sap.app": {
    "id": "sap.ui.demo.ss",
    "type": "application",
    "title": "Single Screen App",
    "applicationVersion": { "version": "1.0.0" }
  },
  "sap.ui5": {
    "rootView": {
      "viewName": "sap.ui.demo.ss.view.Main",
      "type": "XML",
      "async": true,
      "id": "app"
    },
    "dependencies": {
      "minUI5Version": "1.120.0",
      "libs": { "sap.m": {}, "sap.ui.core": {} }
    }
  }
}
```

**Key lines explained:**
- `rootView.viewName` — UI5 translates `sap.ui.demo.ss.view.Main` to `webapp/view/Main.view.xml` using the resourceroots mapping.
- `"async": true` — loads the view asynchronously. Always use this in modern UI5.

---

## File: webapp/model/data.json

The data your list will display. Plain JSON — no server needed.

```json
{
  "products": [
    { "id": "P001", "name": "Laptop Pro 15",    "category": "Electronics", "price": 1299 },
    { "id": "P002", "name": "Wireless Mouse",    "category": "Accessories", "price":   29 },
    { "id": "P003", "name": "USB-C Hub 7-in-1",  "category": "Accessories", "price":   49 },
    { "id": "P004", "name": "4K Monitor 27\"",   "category": "Electronics", "price":  599 },
    { "id": "P005", "name": "Mechanical Keyboard","category": "Accessories", "price":  129 }
  ]
}
```

---

## File: webapp/view/Main.view.xml

The XML layout. Binds the List to the model array, and each list item to individual product properties.

```xml
<mvc:View
  controllerName="sap.ui.demo.ss.controller.Main"
  xmlns:mvc="sap.ui.core.mvc"
  xmlns="sap.m"
  displayBlock="true">

  <Shell>
    <App id="app">
      <pages>
        <Page title="Products">
          <content>
            <List
              id="productList"
              headerText="Product Catalogue"
              items="{/products}">
              <StandardListItem
                title="{name}"
                description="{category}"
                info="{price} EUR"
                infoState="Success"
                press="onItemPress"
                type="Active" />
            </List>
          </content>
        </Page>
      </pages>
    </App>
  </Shell>

</mvc:View>
```

**Key lines explained:**
- `items="{/products}"` — binds the list to the `products` array in the default model. UI5 creates one `StandardListItem` per array entry.
- `title="{name}"` — relative binding. Because the list is already bound to `/products`, each item's context is one product object. `{name}` means "the `name` property of this product".
- `press="onItemPress"` and `type="Active"` — makes items tappable. The controller handles the press event.

---

## File: webapp/controller/Main.controller.js

Handles user interaction. Shows a toast when an item is tapped.

```js
sap.ui.define([
  "sap/ui/core/mvc/Controller",
  "sap/m/MessageToast"
], function (Controller, MessageToast) {
  "use strict";

  return Controller.extend("sap.ui.demo.ss.controller.Main", {

    onInit: function () {
      // Called once when the view is created.
      // Nothing needed here yet — the model is set in Component.js.
    },

    onItemPress: function (oEvent) {
      // oEvent.getSource() returns the StandardListItem that was pressed
      var oItem = oEvent.getSource();
      var sName = oItem.getTitle();
      MessageToast.show("You selected: " + sName);
    }

  });
});
```

---

## File: package.json

Tells the UI5 CLI how to serve and build the app.

```json
{
  "name": "1-ss-test",
  "version": "1.0.0",
  "scripts": {
    "start": "ui5 serve",
    "build": "ui5 build --all"
  },
  "devDependencies": {
    "@ui5/cli": "^3.0.0"
  }
}
```

Run `npm install` once, then `npm start` to launch the dev server.

---

## Data binding quick reference

| Expression | What it means |
|---|---|
| `{/products}` | The root-level `products` array in the default model |
| `{name}` | The `name` property relative to the current list item context |
| `{/products/0/name}` | Absolute path to the first product's name |
| `{modelName>/path}` | A named model (not the default) |

---

## Common mistakes

**Mistake:** List shows no items.
**Fix:** Check the binding path. `{products}` (without `/`) is a relative path and resolves to nothing at the root. It must be `{/products}`.

**Mistake:** UI5 can't find the controller — console shows "Cannot load module".
**Fix:** The `controllerName` in the view (`sap.ui.demo.ss.controller.Main`) must match the string in the controller's `extend()` call exactly. Also verify `data-sap-ui-resourceroots` in index.html maps `sap.ui.demo.ss` to `./`.

**Mistake:** `data.json` returns 404.
**Fix:** Open the browser network tab. If the URL looks wrong, check that `sap.ui.require.toUrl("sap/ui/demo/ss/model/data.json")` resolves correctly — the slashes come from the namespace dots.

**Mistake:** Pressing an item does nothing.
**Fix:** Make sure the list item has both `type="Active"` and `press="onItemPress"`. Without `type="Active"` the item is not visually interactive.

---

## ✅ Checkpoint

Run `npm start`. In the browser you should see:
- A Fiori shell with a page titled "Products".
- A list of 5 items — each with a name, category, and price.
- Clicking any item shows a MessageToast at the bottom of the screen with the product name.
$md$ WHERE slug = '1-ss-test';

UPDATE public.topics SET content_md = $md$
# Episode 2 — Multi-Screen Navigation: Routing in UI5

## What you'll build

A two-screen SAPUI5 app: a **List page** showing all products, and a **Detail page** showing one product's full information. Tapping an item on the list navigates to its detail. The back button returns to the list.

---

## Why this matters

Almost every real business app has master-detail navigation. UI5's Router handles this cleanly: it maps URL hash fragments (like `#/product/P002`) to views, so navigation is bookmarkable and the browser back button works for free.

---

## The mental model: Router + Routes + Targets

```
User taps item
  → controller calls router.navTo("detail", { productId: "P002" })
    → URL changes to #/detail/P002
      → Router reads manifest.json routes config
        → finds the route matching "detail/:productId"
          → loads and displays the Detail view
            → Detail view's onInit reads productId from the URL and binds the view
```

Three things to configure in manifest.json: **routes** (URL patterns), **targets** (which view to show), and **routing** (which control to put views into).

---

## Project structure

```
2-ms-test/
 ├── webapp/
 │   ├── controller/
 │   │   ├── Main.controller.js     ← list page, handles tap + navigate
 │   │   └── Detail.controller.js   ← detail page, reads route params
 │   ├── view/
 │   │   ├── Main.view.xml          ← list of products
 │   │   └── Detail.view.xml        ← single product detail
 │   ├── model/
 │   │   └── data.json
 │   ├── Component.js
 │   ├── index.html
 │   └── manifest.json
 └── package.json
```

---

## File: webapp/manifest.json (routing section)

The routing config lives inside `sap.ui5`. This is the most important thing to get right.

```json
{
  "sap.ui5": {
    "rootView": {
      "viewName": "sap.ui.demo.ms.view.Main",
      "type": "XML",
      "async": true,
      "id": "app"
    },
    "routing": {
      "config": {
        "routerClass": "sap.m.routing.Router",
        "viewType": "XML",
        "viewPath": "sap.ui.demo.ms.view",
        "controlId": "app",
        "controlAggregation": "pages",
        "async": true
      },
      "routes": [
        {
          "name": "list",
          "pattern": "",
          "target": "list"
        },
        {
          "name": "detail",
          "pattern": "detail/{productId}",
          "target": "detail"
        }
      ],
      "targets": {
        "list": {
          "viewName": "Main",
          "viewLevel": 1
        },
        "detail": {
          "viewName": "Detail",
          "viewLevel": 2
        }
      }
    }
  }
}
```

**Key lines explained:**
- `"controlId": "app"` — the Router puts views into the `<App id="app">` control in the root view.
- `"controlAggregation": "pages"` — specifically into the `pages` aggregation of the App control.
- `"pattern": "detail/{productId}"` — `{productId}` is a URL parameter. It becomes available in the controller as a route argument.
- `"viewLevel"` — controls the slide animation direction. Higher level slides in from the right (forward). Lower level slides from the left (back).

---

## File: webapp/Component.js

Initialize the router in `init()` — this is required.

```js
sap.ui.define([
  "sap/ui/core/UIComponent",
  "sap/ui/model/json/JSONModel"
], function (UIComponent, JSONModel) {
  "use strict";

  return UIComponent.extend("sap.ui.demo.ms.Component", {
    metadata: { manifest: "json" },

    init: function () {
      UIComponent.prototype.init.apply(this, arguments);

      // Load data model
      var oModel = new JSONModel(
        sap.ui.require.toUrl("sap/ui/demo/ms/model/data.json")
      );
      this.setModel(oModel);

      // Initialize the router — reads routes from manifest.json
      // Without this line, navigation never works
      this.getRouter().initialize();
    }
  });
});
```

---

## File: webapp/view/Main.view.xml

The list page. Each item is tappable and passes the product id when pressed.

```xml
<mvc:View
  controllerName="sap.ui.demo.ms.controller.Main"
  xmlns:mvc="sap.ui.core.mvc"
  xmlns="sap.m"
  displayBlock="true">

  <Page title="Products">
    <content>
      <List
        id="productList"
        items="{/products}"
        mode="SingleSelectMaster">
        <StandardListItem
          title="{name}"
          description="{category}"
          info="{price} EUR"
          type="Navigation"
          press="onItemPress" />
      </List>
    </content>
  </Page>

</mvc:View>
```

**Note:** `type="Navigation"` renders the right-arrow chevron on each item, signaling to the user that tapping navigates somewhere.

---

## File: webapp/controller/Main.controller.js

Reads the tapped item's binding context to get its ID, then navigates.

```js
sap.ui.define([
  "sap/ui/core/mvc/Controller"
], function (Controller) {
  "use strict";

  return Controller.extend("sap.ui.demo.ms.controller.Main", {

    onInit: function () {
      // Nothing needed here — model is set in Component.js
    },

    onItemPress: function (oEvent) {
      // Get the binding context of the tapped list item
      // oContext.getPath() returns something like "/products/2"
      var oContext = oEvent.getSource().getBindingContext();
      var sPath = oContext.getPath();               // e.g. "/products/2"
      var oProduct = oContext.getObject();          // the full product object

      // Navigate to the detail route, passing the product id in the URL
      this.getOwnerComponent().getRouter().navTo("detail", {
        productId: oProduct.id   // becomes the {productId} URL parameter
      });
    }

  });
});
```

---

## File: webapp/view/Detail.view.xml

The detail page. Shows all fields of a single product. The `id="detailPage"` is used by the controller to bind data.

```xml
<mvc:View
  controllerName="sap.ui.demo.ms.controller.Detail"
  xmlns:mvc="sap.ui.core.mvc"
  xmlns="sap.m"
  displayBlock="true">

  <Page
    id="detailPage"
    title="{name}"
    showNavButton="true"
    navButtonPress="onNavBack">

    <content>
      <VBox class="sapUiMediumMargin">
        <ObjectHeader
          title="{name}"
          number="{price}"
          numberUnit="EUR" />

        <SimpleForm>
          <Label text="Product ID" />
          <Text text="{id}" />

          <Label text="Category" />
          <Text text="{category}" />

          <Label text="Price" />
          <Text text="{price} EUR" />
        </SimpleForm>
      </VBox>
    </content>

  </Page>

</mvc:View>
```

---

## File: webapp/controller/Detail.controller.js

Listens for the route match event, reads the URL parameter, and binds the view to the correct product.

```js
sap.ui.define([
  "sap/ui/core/mvc/Controller",
  "sap/ui/core/routing/History"
], function (Controller, History) {
  "use strict";

  return Controller.extend("sap.ui.demo.ms.controller.Detail", {

    onInit: function () {
      // Attach a handler that fires every time this route is navigated to
      var oRouter = this.getOwnerComponent().getRouter();
      oRouter.getRoute("detail").attachPatternMatched(this._onRouteMatched, this);
    },

    _onRouteMatched: function (oEvent) {
      // Read the productId from the URL (set by navTo in Main.controller.js)
      var sProductId = oEvent.getParameter("arguments").productId;

      // Find the index of this product in the model array
      var oModel = this.getOwnerComponent().getModel();
      var aProducts = oModel.getProperty("/products");
      var iIndex = aProducts.findIndex(function (p) {
        return p.id === sProductId;
      });

      if (iIndex === -1) {
        // Product not found — go back
        this.onNavBack();
        return;
      }

      // Bind the entire page to the product at this path
      // All {name}, {price}, {category} bindings in the view now resolve
      var oPage = this.byId("detailPage");
      oPage.bindElement("/products/" + iIndex);
    },

    onNavBack: function () {
      // Use History to go back to previous page, or fall back to list route
      var oHistory = History.getInstance();
      var sPreviousHash = oHistory.getPreviousHash();

      if (sPreviousHash !== undefined) {
        window.history.go(-1);
      } else {
        this.getOwnerComponent().getRouter().navTo("list", {}, true);
      }
    }

  });
});
```

**Key lines explained:**
- `attachPatternMatched` — fires every time the user navigates to this route, including back-and-forth. Use this instead of `onInit` for route-dependent setup.
- `bindElement("/products/2")` — sets the binding context for the entire page. Every `{name}`, `{price}` etc. in the view resolves relative to this path.
- `History.getInstance().getPreviousHash()` — checks if there is browser history to go back to. If the user opened the detail URL directly, there is no back history, so navigate to the list route explicitly.

---

## Common mistakes

**Mistake:** Tapping an item does nothing — no navigation.
**Fix:** Check that `this.getOwnerComponent().getRouter().initialize()` is called in `Component.js init()`. Without it the router never starts.

**Mistake:** Detail page is blank — no data shows.
**Fix:** Verify `bindElement` path. Add `console.log("/products/" + iIndex)` to confirm the index is correct before binding.

**Mistake:** The back button navigates to a blank page.
**Fix:** Make sure the root view's `<App id="app">` matches `"controlId": "app"` in manifest.json routing config. The Router puts pages into this control — if the id doesn't match, it creates a new hidden App.

**Mistake:** `attachPatternMatched` fires but `arguments.productId` is undefined.
**Fix:** The route pattern in manifest.json must use `{productId}` (with curly braces) and the `navTo` call must pass `productId` as a key in the parameters object.

---

## ✅ Checkpoint

Run `npm start`. You should be able to:
1. See a list of products on the main page.
2. Tap any product — the app slides to a detail page showing that product's full info.
3. Press the back button (top-left) — it slides back to the list.
4. The browser URL changes to `#/detail/P001` (or whichever id) on navigation.
$md$ WHERE slug = '2-ms-test';

UPDATE public.topics SET content_md = $md$
# Episode 3 — CRUD on a Local JSON Model

## What you'll build

A product management screen where you can **Create** new products, **Read** them in a list, **Update** them by editing in place, and **Delete** them — all against a local JSON model. No backend yet. This teaches you the CRUD patterns you'll reuse when you move to OData in Episode 8.

---

## Why local CRUD first?

When you do CRUD against OData (Episode 8), the operation is asynchronous and goes to a server. When you do it against a local JSON model, it is synchronous and immediate. Learning the pattern locally means you can focus on the UI logic without debugging network calls at the same time.

The view code and controller structure you write here transfers almost directly to Episode 8. What changes: `oModel.setProperty()` becomes an OData update binding, and `oModel.getData()` becomes a context create/delete call.

---

## Project structure

```
3-crud-test/
 ├── webapp/
 │   ├── controller/
 │   │   └── Main.controller.js
 │   ├── view/
 │   │   └── Main.view.xml
 │   ├── fragments/
 │   │   └── ProductDialog.fragment.xml   ← reusable create/edit dialog
 │   ├── model/
 │   │   └── data.json
 │   ├── Component.js
 │   ├── index.html
 │   └── manifest.json
 └── package.json
```

---

## File: webapp/model/data.json

Starting data. The controller will add, edit, and delete items from this array.

```json
{
  "products": [
    { "id": "P001", "name": "Laptop Pro 15",     "category": "Electronics", "price": 1299 },
    { "id": "P002", "name": "Wireless Mouse",     "category": "Accessories", "price":   29 },
    { "id": "P003", "name": "USB-C Hub 7-in-1",   "category": "Accessories", "price":   49 }
  ]
}
```

---

## File: webapp/fragments/ProductDialog.fragment.xml

A reusable dialog used for both creating and editing a product. A **Fragment** is a UI5 concept for a piece of view XML that does not have its own controller — it shares the controller of the view that opens it.

```xml
<core:FragmentDefinition
  xmlns="sap.m"
  xmlns:core="sap.ui.core"
  xmlns:l="sap.ui.layout">

  <Dialog
    id="productDialog"
    title="{dialog>/title}"
    resizable="true">

    <content>
      <l:VerticalLayout width="100%" class="sapUiSmallMargin">

        <Label text="Product ID" required="true" />
        <Input
          id="inputId"
          value="{dialog>/id}"
          placeholder="e.g. P004"
          enabled="{dialog>/idEditable}" />

        <Label text="Name" required="true" />
        <Input
          id="inputName"
          value="{dialog>/name}"
          placeholder="Product name" />

        <Label text="Category" required="true" />
        <Select id="selectCategory" selectedKey="{dialog>/category}">
          <core:Item key="Electronics" text="Electronics" />
          <core:Item key="Accessories" text="Accessories" />
          <core:Item key="Software"    text="Software" />
        </Select>

        <Label text="Price (EUR)" required="true" />
        <Input
          id="inputPrice"
          value="{dialog>/price}"
          type="Number"
          placeholder="0" />

      </l:VerticalLayout>
    </content>

    <buttons>
      <Button text="Save"   type="Emphasized" press="onDialogSave" />
      <Button text="Cancel" press="onDialogCancel" />
    </buttons>

  </Dialog>

</core:FragmentDefinition>
```

**Key concept:** The dialog binds to a model named `"dialog"`. The controller creates this model and populates it differently for create vs edit, but the fragment itself doesn't know or care.

---

## File: webapp/view/Main.view.xml

The list with a toolbar containing Create, Edit, and Delete buttons.

```xml
<mvc:View
  controllerName="sap.ui.demo.crud.controller.Main"
  xmlns:mvc="sap.ui.core.mvc"
  xmlns="sap.m"
  xmlns:core="sap.ui.core"
  displayBlock="true">

  <Page title="Product Management">

    <headerContent>
      <Button text="New Product" icon="sap-icon://add"  press="onCreatePress" type="Emphasized" />
    </headerContent>

    <content>
      <List
        id="productList"
        items="{/products}"
        mode="SingleSelectLeft"
        selectionChange="onSelectionChange">

        <headerToolbar>
          <Toolbar>
            <Title text="Products" />
            <ToolbarSpacer />
            <Button id="editBtn"   text="Edit"   icon="sap-icon://edit"   press="onEditPress"   enabled="false" />
            <Button id="deleteBtn" text="Delete" icon="sap-icon://delete" press="onDeletePress" enabled="false" />
          </Toolbar>
        </headerToolbar>

        <StandardListItem
          title="{name}"
          description="{category}"
          info="{price} EUR"
          infoState="Success" />

      </List>
    </content>

  </Page>

</mvc:View>
```

---

## File: webapp/controller/Main.controller.js

All four CRUD operations in one controller.

```js
sap.ui.define([
  "sap/ui/core/mvc/Controller",
  "sap/ui/model/json/JSONModel",
  "sap/m/MessageToast",
  "sap/m/MessageBox"
], function (Controller, JSONModel, MessageToast, MessageBox) {
  "use strict";

  return Controller.extend("sap.ui.demo.crud.controller.Main", {

    // ─── Lifecycle ────────────────────────────────────────────────────────────

    onInit: function () {
      // Keep track of which product is selected (for edit/delete)
      this._selectedIndex = -1;
    },

    // ─── Selection ────────────────────────────────────────────────────────────

    onSelectionChange: function (oEvent) {
      var bSelected = oEvent.getParameter("selected");
      if (bSelected) {
        // Store the model index of the selected item for later use
        var oContext = oEvent.getParameter("listItem").getBindingContext();
        var sPath = oContext.getPath(); // e.g. "/products/1"
        this._selectedIndex = parseInt(sPath.split("/").pop(), 10);
      } else {
        this._selectedIndex = -1;
      }
      // Enable/disable Edit and Delete buttons based on selection
      this.byId("editBtn").setEnabled(bSelected);
      this.byId("deleteBtn").setEnabled(bSelected);
    },

    // ─── CREATE ───────────────────────────────────────────────────────────────

    onCreatePress: function () {
      // Set up a blank dialog model for a new product
      var oDialogModel = new JSONModel({
        title:      "Create Product",
        id:         "",
        name:       "",
        category:   "Electronics",
        price:      0,
        idEditable: true   // ID is editable only when creating
      });

      this._openDialog(oDialogModel, "create");
    },

    // ─── UPDATE (Edit) ────────────────────────────────────────────────────────

    onEditPress: function () {
      if (this._selectedIndex < 0) { return; }

      // Read the selected product from the main model
      var oModel = this.getView().getModel();
      var oProduct = oModel.getProperty("/products/" + this._selectedIndex);

      // Pre-fill the dialog model with existing values
      var oDialogModel = new JSONModel({
        title:      "Edit Product",
        id:         oProduct.id,
        name:       oProduct.name,
        category:   oProduct.category,
        price:      oProduct.price,
        idEditable: false   // ID cannot be changed when editing
      });

      this._openDialog(oDialogModel, "edit");
    },

    // ─── DELETE ───────────────────────────────────────────────────────────────

    onDeletePress: function () {
      if (this._selectedIndex < 0) { return; }

      var oModel = this.getView().getModel();
      var oProduct = oModel.getProperty("/products/" + this._selectedIndex);

      MessageBox.confirm(
        "Delete \"" + oProduct.name + "\"?",
        {
          onClose: function (sAction) {
            if (sAction === "OK") {
              // Remove the item from the array and update the model
              var aProducts = oModel.getProperty("/products");
              aProducts.splice(this._selectedIndex, 1);
              oModel.setProperty("/products", aProducts);
              // Reset selection state
              this._selectedIndex = -1;
              this.byId("editBtn").setEnabled(false);
              this.byId("deleteBtn").setEnabled(false);
              MessageToast.show("Product deleted");
            }
          }.bind(this)
        }
      );
    },

    // ─── Dialog helpers ───────────────────────────────────────────────────────

    _openDialog: function (oDialogModel, sMode) {
      this._dialogMode = sMode;

      // Load the fragment only once, cache it as this._oDialog
      if (!this._oDialog) {
        this._oDialog = this.loadFragment({
          name: "sap.ui.demo.crud.fragments.ProductDialog"
        });
      }

      // this.loadFragment returns a Promise in modern UI5
      Promise.resolve(this._oDialog).then(function (oDialog) {
        this._oDialog = oDialog;
        oDialog.setModel(oDialogModel, "dialog");
        oDialog.open();
      }.bind(this));
    },

    onDialogSave: function () {
      var oDialog    = this._oDialog;
      var oData      = oDialog.getModel("dialog").getData();
      var oModel     = this.getView().getModel();
      var aProducts  = oModel.getProperty("/products");

      // Basic validation
      if (!oData.id || !oData.name) {
        MessageToast.show("ID and Name are required");
        return;
      }

      if (this._dialogMode === "create") {
        // Check for duplicate ID
        var bExists = aProducts.some(function (p) { return p.id === oData.id; });
        if (bExists) {
          MessageToast.show("A product with this ID already exists");
          return;
        }
        aProducts.push({
          id:       oData.id,
          name:     oData.name,
          category: oData.category,
          price:    parseFloat(oData.price) || 0
        });
        MessageToast.show("Product created");
      } else {
        // Edit: update in place
        aProducts[this._selectedIndex] = {
          id:       oData.id,
          name:     oData.name,
          category: oData.category,
          price:    parseFloat(oData.price) || 0
        };
        MessageToast.show("Product updated");
      }

      oModel.setProperty("/products", aProducts);
      oDialog.close();
    },

    onDialogCancel: function () {
      this._oDialog.close();
    }

  });
});
```

---

## READ — it is just binding

You never write code to "read" data from a JSON model. UI5 binding handles it automatically. When you call `oModel.setProperty("/products", aProducts)` after a create, edit, or delete, every bound control (the list, any labels) updates automatically. This is the power of two-way binding.

---

## What changes when you move to OData (Episode 8)

| Local JSON | OData V4 |
|---|---|
| `aProducts.push({...}); oModel.setProperty(...)` | `oBinding.create({...})` |
| `aProducts.splice(i, 1); oModel.setProperty(...)` | `oContext.delete()` |
| `aProducts[i] = {...}; oModel.setProperty(...)` | `oContext.setProperty("name", value)` then `oModel.submitBatch()` |
| Instant, synchronous | Asynchronous, returns a Promise |

---

## Common mistakes

**Mistake:** Dialog opens but the inputs are blank even when editing.
**Fix:** Make sure `oDialog.setModel(oDialogModel, "dialog")` is called every time the dialog opens, not just the first time. The model must be refreshed per-open.

**Mistake:** `this.loadFragment` throws "loadFragment is not a function".
**Fix:** You are on an older UI5 version. Use `sap.ui.xmlfragment(this.getView().getId(), "...fragments.ProductDialog", this)` as the fallback.

**Mistake:** Delete removes the wrong item after the list reorders.
**Fix:** `this._selectedIndex` stores the array index. After a delete, call `this.byId("productList").removeSelections(true)` to clear the list selection state, then reset `_selectedIndex = -1`.

**Mistake:** Edited price saves as a string, not a number.
**Fix:** Always wrap the price value with `parseFloat()` before saving to the array.

---

## ✅ Checkpoint

Run `npm start`. You should be able to:
1. See the list of 3 products.
2. Click **New Product** → fill the form → **Save** → see the new item appear in the list.
3. Select any item → click **Edit** → change the name → **Save** → see the list update.
4. Select any item → click **Delete** → confirm → see it removed from the list.
$md$ WHERE slug = '3-crud-test';

UPDATE public.topics SET content_md = $md$
# Episode 4 — Value Help (F4) Dialog

## What you'll build

An input field that opens a searchable **Value Help dialog** (also called an F4 dialog, after the keyboard shortcut in SAP GUI) when the user clicks the value help icon. The user picks a value from the dialog and it fills the input field automatically.

---

## Why this matters

In enterprise apps, users should never type freeform text into fields that have a fixed set of valid values. A Value Help dialog shows the allowed values in a searchable list and prevents invalid input. This pattern is in nearly every SAP UI5 app you will build.

---

## The pattern in three parts

```
1. An Input control in your view with valueHelpRequest handler
       ↓
2. A SelectDialog fragment that lists the valid values
       ↓
3. A controller that opens the dialog, filters it on search,
   and writes the selected value back to the input
```

---

## Project structure

```
4-f4-test/
 ├── webapp/
 │   ├── controller/
 │   │   └── Main.controller.js
 │   ├── view/
 │   │   └── Main.view.xml
 │   ├── fragments/
 │   │   └── CategoryDialog.fragment.xml
 │   ├── model/
 │   │   └── data.json
 │   ├── Component.js
 │   ├── index.html
 │   └── manifest.json
 └── package.json
```

---

## File: webapp/model/data.json

Two lists: the products being edited, and the available categories for the value help.

```json
{
  "products": [
    { "id": "P001", "name": "Laptop Pro 15", "category": "Electronics" }
  ],
  "categories": [
    { "key": "Electronics", "text": "Electronics" },
    { "key": "Accessories", "text": "Accessories" },
    { "key": "Software",    "text": "Software" },
    { "key": "Furniture",   "text": "Furniture" },
    { "key": "Stationery",  "text": "Stationery" }
  ]
}
```

---

## File: webapp/view/Main.view.xml

The main form. The Category input has a value help icon (`showValueHelpIcon="true"`) and fires `valueHelpRequest` when clicked.

```xml
<mvc:View
  controllerName="sap.ui.demo.f4.controller.Main"
  xmlns:mvc="sap.ui.core.mvc"
  xmlns="sap.m"
  displayBlock="true">

  <Page title="Product Form">
    <content>
      <SimpleForm
        id="productForm"
        editable="true"
        layout="ResponsiveGridLayout"
        class="sapUiMediumMargin">

        <Label text="Product Name" />
        <Input
          id="inputName"
          value="{/products/0/name}"
          placeholder="Enter product name" />

        <Label text="Category" />
        <Input
          id="inputCategory"
          value="{/products/0/category}"
          showValueHelpIcon="true"
          valueHelpRequest="onCategoryValueHelp"
          placeholder="Click icon to choose category" />

      </SimpleForm>
    </content>
  </Page>

</mvc:View>
```

**Key attribute:** `valueHelpRequest="onCategoryValueHelp"` fires when the user clicks the F4 icon (the small icon at the right of the input). `showValueHelpIcon="true"` makes that icon visible.

---

## File: webapp/fragments/CategoryDialog.fragment.xml

The value help dialog. `SelectDialog` is a UI5 control specifically designed for this use case — it has built-in search and single/multi selection.

```xml
<core:FragmentDefinition
  xmlns="sap.m"
  xmlns:core="sap.ui.core">

  <SelectDialog
    id="categoryDialog"
    title="Select Category"
    search="onDialogSearch"
    confirm="onDialogConfirm"
    cancel="onDialogCancel"
    items="{
      path: '/categories',
      sorter: { path: 'text', descending: false }
    }">

    <StandardListItem
      title="{text}"
      description="{key}"
      type="Active" />

  </SelectDialog>

</core:FragmentDefinition>
```

**Key attributes:**
- `search` — fires as the user types in the search box. Your controller filters the list.
- `confirm` — fires when the user selects an item and presses OK.
- `cancel` — fires when the user closes without selecting.

---

## File: webapp/controller/Main.controller.js

```js
sap.ui.define([
  "sap/ui/core/mvc/Controller",
  "sap/ui/model/Filter",
  "sap/ui/model/FilterOperator"
], function (Controller, Filter, FilterOperator) {
  "use strict";

  return Controller.extend("sap.ui.demo.f4.controller.Main", {

    // ─── Open the dialog ──────────────────────────────────────────────────────

    onCategoryValueHelp: function () {
      // Load the fragment once and cache it
      if (!this._oCategoryDialog) {
        this._oCategoryDialog = this.loadFragment({
          name: "sap.ui.demo.f4.fragments.CategoryDialog"
        });
      }

      Promise.resolve(this._oCategoryDialog).then(function (oDialog) {
        this._oCategoryDialog = oDialog;

        // Reset any previous search filter before opening
        var oBinding = oDialog.getBinding("items");
        if (oBinding) {
          oBinding.filter([]);
        }

        oDialog.open();
      }.bind(this));
    },

    // ─── Search inside the dialog ─────────────────────────────────────────────

    onDialogSearch: function (oEvent) {
      var sValue = oEvent.getParameter("value");
      // Filter the categories list on the 'text' property
      var oFilter = new Filter("text", FilterOperator.Contains, sValue);
      var oBinding = oEvent.getSource().getBinding("items");
      oBinding.filter([oFilter]);
    },

    // ─── Confirm: write selected value back to the input field ───────────────

    onDialogConfirm: function (oEvent) {
      var oSelectedItem = oEvent.getParameter("selectedItem");
      if (oSelectedItem) {
        // Get the selected category key
        var sKey = oSelectedItem.getDescription(); // we put key in description

        // Write it back to the model — the Input binding updates automatically
        this.getView().getModel().setProperty("/products/0/category", sKey);
      }
      // Clear the search filter when dialog closes
      oEvent.getSource().getBinding("items").filter([]);
    },

    // ─── Cancel: just close ───────────────────────────────────────────────────

    onDialogCancel: function (oEvent) {
      oEvent.getSource().getBinding("items").filter([]);
    }

  });
});
```

---

## Understanding `loadFragment` vs the old pattern

| Old (before UI5 1.93) | New (UI5 1.93+) |
|---|---|
| `sap.ui.xmlfragment(viewId, fragmentName, controller)` | `this.loadFragment({ name: fragmentName })` |
| Returns the control synchronously | Returns a Promise |
| You must manually manage the fragment's lifecycle | The framework ties the fragment to the view lifecycle |

Always use `this.loadFragment` in modern UI5. It automatically calls `addDependent(fragment)` on the view, which means the fragment is destroyed when the view is destroyed — no memory leaks.

---

## Why `addDependent` matters

Without `addDependent`, the dialog lives outside the view's lifecycle. If the user navigates away and back, the dialog may keep old binding state or accumulate event handlers. When you use `this.loadFragment`, this is handled for you automatically.

---

## Common mistakes

**Mistake:** The dialog opens but the list is empty.
**Fix:** Check the binding path in the fragment — `path: '/categories'` uses the default model. If your model is named (e.g. `"data"`), use `path: 'data>/categories'`.

**Mistake:** After searching and confirming, the next time you open the dialog the search filter is still applied.
**Fix:** Always call `oBinding.filter([])` both in `onDialogConfirm` and `onDialogCancel`. Also reset it when the dialog opens (as shown in `onCategoryValueHelp`).

**Mistake:** `this.loadFragment` is undefined.
**Fix:** You are using a UI5 version older than 1.93. Use the old `sap.ui.xmlfragment` approach or upgrade your UI5 version in `index.html`.

**Mistake:** The value in the input does not update after confirming.
**Fix:** Check that your `setProperty` path exactly matches the binding in the view. If the input binds to `/products/0/category`, your `setProperty` must target the same path.

**Mistake:** The dialog shows but search does nothing.
**Fix:** The `Filter` property must match a real property in your data. `new Filter("text", ...)` filters on the `text` field. If your data uses `name` or `label`, update the filter accordingly.

---

## ✅ Checkpoint

Run `npm start`. You should see:
1. A form with a Product Name input and a Category input.
2. Clicking the icon on the Category input opens a dialog with 5 categories.
3. Typing in the search box filters the list in real time.
4. Selecting a category and pressing OK fills the Category input.
5. Pressing Cancel closes the dialog without changing the input.
$md$ WHERE slug = '4-f4-test';

UPDATE public.topics SET content_md = $md$
# Episode 5 — Your First CAP Service

## What you'll build

A running OData API built with SAP Cloud Application Programming model (CAP). You define a data model in CDS, expose it as a service, and query it with a browser. No database yet — CAP uses an in-memory store automatically.

---

## Why CAP?

CAP lets you define your entire backend — data model, service, security rules — in a high-level domain language (CDS). It generates the OData API, handles pagination, sorting, filtering, and associations automatically. You write almost no boilerplate.

| Hand-rolled Express API | CAP |
|---|---|
| Write router, controllers, SQL queries | Describe your model in CDS |
| Handle OData protocol manually | CAP generates full OData V4 |
| Write auth middleware | Annotate with `@requires` |

---

## Project structure

```
5-cap-1-test/
 ├── db/
 │   └── schema.cds        ← data model definition
 ├── srv/
 │   ├── product-service.cds   ← service definition (which entities to expose)
 │   └── product-service.js    ← optional: custom logic handlers
 ├── package.json
 └── .cdsrc.json           ← CAP configuration
```

---

## Step 1 — Install the CAP CLI

```bash
npm install -g @sap/cds-dk

# Verify
cds --version   # should print 7.x or 8.x
```

---

## Step 2 — Scaffold the project

```bash
cds init 5-cap-1-test
cd 5-cap-1-test
npm install
```

`cds init` creates the folder structure and a minimal `package.json` pre-configured for CAP.

---

## Step 3 — Define the data model

```cds
// db/schema.cds

namespace com.demo;

entity Products {
  key ID       : Integer;
      name     : String(100);
      category : String(50);
      price    : Decimal(10, 2);
}
```

**What this does:**
- `namespace com.demo` — prefixes all entity names. Your entity is fully named `com.demo.Products`.
- `key ID` — marks `ID` as the primary key. OData uses this for single-record URLs like `/Products(1)`.
- CAP infers the database table structure from this definition. You write no SQL.

---

## Step 4 — Define the service

```cds
// srv/product-service.cds

using com.demo from '../db/schema';

service ProductService @(path: '/api') {
  entity Products as projection on com.demo.Products;
}
```

**What this does:**
- `using` — imports the entity from the schema.
- `service ProductService @(path: '/api')` — exposes the service at `/api`. The full OData URL will be `/api/Products`.
- `projection on` — exposes the entity as-is. You can use projection to rename fields or exclude sensitive ones.

---

## Step 5 — Add an optional custom handler

```js
// srv/product-service.js

const cds = require('@sap/cds');

module.exports = class ProductService extends cds.ApplicationService {

  async init() {
    // Called once when the service starts

    // Example: log every READ request
    this.before('READ', 'Products', (req) => {
      console.log('Reading products, filter:', req.query.SELECT.where);
    });

    // Example: auto-set a default category on CREATE
    this.before('CREATE', 'Products', (req) => {
      if (!req.data.category) {
        req.data.category = 'General';
      }
    });

    await super.init();
  }

};
```

This file is optional — if it does not exist, CAP serves the entity with full auto-CRUD and no custom logic.

---

## File: package.json

```json
{
  "name": "5-cap-1-test",
  "version": "1.0.0",
  "dependencies": {
    "@sap/cds": "^8.0.0",
    "express": "^4.18.0"
  },
  "devDependencies": {
    "@sap/cds-dk": "^8.0.0",
    "sqlite3": "^5.1.0"
  },
  "scripts": {
    "start": "cds run",
    "watch": "cds watch"
  },
  "cds": {
    "requires": {
      "db": {
        "kind": "sqlite",
        "credentials": { "database": ":memory:" }
      }
    }
  }
}
```

**`"database": ":memory:"`** — SQLite in-memory store. Data resets every time you restart the server. You add a real file in Episode 6.

---

## Step 6 — Run it

```bash
cds watch
```

`cds watch` starts the server and auto-restarts on file changes. You should see:

```
[cds] - loaded model from 2 file(s): db/schema.cds, srv/product-service.cds
[cds] - connect to db > sqlite { database: ':memory:' }
[cds] - serving ProductService { path: '/api' }
[cds] - server listening on { url: 'http://localhost:4004' }
```

---

## What CAP generated for you

Open `http://localhost:4004` in a browser. You see the CAP service index page with links to:

| URL | What it does |
|---|---|
| `/api` | OData service document (lists all entity sets) |
| `/api/$metadata` | Full OData metadata XML — describes every entity, field, and type |
| `/api/Products` | Returns all products as JSON |
| `/api/Products(1)` | Returns the product with ID=1 |
| `/api/Products?$filter=category eq 'Electronics'` | Filtered query |
| `/api/Products?$orderby=price desc` | Sorted query |
| `/api/Products?$select=name,price` | Projection query |

All of this works with zero hand-written query code.

---

## Common mistakes

**Mistake:** `cds watch` shows "No model found".
**Fix:** Make sure you are running the command from the project root (where `package.json` is), not from inside `db/` or `srv/`.

**Mistake:** `/api/Products` returns an empty array `{ value: [] }`.
**Fix:** That is correct for an in-memory database with no seed data. Add data in Episode 6 using CSV files.

**Mistake:** CDS file shows a red underline in BAS but `cds watch` still works.
**Fix:** Install the CDS Language Support extension in BAS: **Extensions → search "SAP CDS Language Support"**.

**Mistake:** `cds: command not found`.
**Fix:** Run `npm install -g @sap/cds-dk`. If in BAS, confirm your dev space is the "SAP Fiori" kind which pre-installs this.

---

## ✅ Checkpoint

Run `cds watch`. In a browser, open:
- `http://localhost:4004/api/Products` — should return `{"value": []}` (empty but valid OData response).
- `http://localhost:4004/api/$metadata` — should return an XML document describing the Products entity.
$md$ WHERE slug = '5-cap-1-test';

UPDATE public.topics SET content_md = $md$
# Episode 6 — SQLite Persistence: Real Data That Survives Restarts

## What you'll build

Upgrade your CAP service from an in-memory store to a **SQLite file database**. Add seed data via CSV files. After this episode, data persists between server restarts and you can inspect it with a SQL tool.

---

## Why SQLite for local dev?

| In-memory (Episode 5) | SQLite file (Episode 6) |
|---|---|
| Data lost on restart | Data persists in a `.db` file |
| No seed data needed (it is always empty) | Seed data loaded once from CSV |
| Good for: testing schemas | Good for: realistic local development |

In production (Episode 15) you use SAP HANA. The switch is one line in your deployment config — your CDS model and service code do not change at all.

---

## Project structure changes

```
6-sqllite-test/
 ├── db/
 │   ├── schema.cds
 │   └── data/                          ← NEW: CSV seed files live here
 │       ├── com.demo-Products.csv      ← one CSV per entity
 │       └── com.demo-Categories.csv
 ├── srv/
 │   └── product-service.cds
 ├── package.json                       ← update db kind
 └── .cdsrc.json                        ← optional: move db config here
```

---

## Step 1 — Update package.json to use a file database

Change the `cds.requires.db` section:

```json
{
  "cds": {
    "requires": {
      "db": {
        "kind": "sqlite",
        "credentials": {
          "database": "db/demo.db"
        }
      }
    }
  }
}
```

This tells CAP to store data in `db/demo.db`. The file is created automatically on first deploy.

---

## Step 2 — Deploy the schema to SQLite

```bash
cds deploy --to sqlite:db/demo.db
```

This command:
1. Reads your CDS schema files.
2. Generates the SQL `CREATE TABLE` statements.
3. Runs them against `db/demo.db`.
4. Loads any CSV files from `db/data/`.

You should see output like:

```
 > filling com.demo.Products from db/data/com.demo-Products.csv
 > filling com.demo.Categories from db/data/com.demo-Categories.csv
```

---

## Step 3 — Create CSV seed files

The filename format is critical: `<namespace>-<EntityName>.csv`

```
// db/data/com.demo-Products.csv

ID,name,category_ID,price
1,Laptop Pro 15,1,1299.00
2,Wireless Mouse,2,29.00
3,USB-C Hub 7-in-1,2,49.00
4,4K Monitor 27,1,599.00
5,Mechanical Keyboard,2,129.00
```

```
// db/data/com.demo-Categories.csv

ID,name
1,Electronics
2,Accessories
3,Software
```

**Important:** The column names in the CSV must match the CDS entity field names exactly (case-sensitive).

---

## Step 4 — Update the CDS schema to add Categories

```cds
// db/schema.cds

namespace com.demo;

entity Categories {
  key ID   : Integer;
      name : String(50);
}

entity Products {
  key ID       : Integer;
      name     : String(100);
      category : Association to Categories;
      price    : Decimal(10, 2);
}
```

An `Association to Categories` creates a foreign key `category_ID` automatically. In the CSV, use `category_ID` (the generated FK column name).

---

## Step 5 — Run and verify

```bash
cds watch
```

Now open `http://localhost:4004/api/Products` — you should see your 5 products as JSON.

To expand the association (join the category name):

```
http://localhost:4004/api/Products?$expand=category
```

Response includes the full category object nested inside each product.

---

## How CAP handles SQL without you writing any

When you write `Association to Categories`, CAP:
1. Creates a `category_ID` foreign key column in the Products table.
2. Generates `JOIN` queries automatically when you use `$expand`.
3. Enforces referential integrity at the database level.

You never write `SELECT p.*, c.name FROM Products p JOIN Categories c ON p.category_ID = c.ID`. CAP does it.

---

## Inspecting the SQLite file directly

```bash
# Install the sqlite3 CLI if not present
npm install -g sqlite3   # or: apt-get install sqlite3

# Open the database
sqlite3 db/demo.db

# Inside the sqlite shell:
.tables                    # list all tables
SELECT * FROM com_demo_Products;
SELECT * FROM com_demo_Categories;
.quit
```

Table names use underscores instead of dots: `com.demo.Products` → `com_demo_Products`.

---

## The difference between `:memory:` and a file

| `:memory:` | `db/demo.db` |
|---|---|
| Created fresh on every start | Persists between restarts |
| Seed data loaded from CSV on every start | Seed data loaded once (on `cds deploy`) |
| Re-deploy not needed | Run `cds deploy` after schema changes |

When you change your CDS schema (add a field, rename something), run `cds deploy` again to update the SQLite table structure.

---

## Common mistakes

**Mistake:** CSV data does not load — `cds deploy` output shows no "filling" lines.
**Fix:** Check the filename exactly: `com.demo-Products.csv` (namespace dot entity name, separated by a dash). The namespace comes from your CDS `namespace` declaration.

**Mistake:** `/api/Products` still returns empty after switching to file DB.
**Fix:** You may have forgotten to run `cds deploy`. The file database needs the schema deployed first. Run `cds deploy --to sqlite:db/demo.db`.

**Mistake:** Foreign key errors when loading CSV.
**Fix:** Load the referenced entity first. In the CSV for Products, the `category_ID` values must exist in the Categories CSV. CAP loads CSVs alphabetically — rename them with a number prefix (e.g. `1-com.demo-Categories.csv`, `2-com.demo-Products.csv`) to control order.

**Mistake:** After changing schema, old columns cause errors.
**Fix:** Delete `db/demo.db` and run `cds deploy` again. SQLite does not support all `ALTER TABLE` operations automatically.

---

## ✅ Checkpoint

After `cds deploy` then `cds watch`:
- `http://localhost:4004/api/Products` returns 5 products.
- `http://localhost:4004/api/Products?$expand=category` returns products with nested category objects.
- Restart the server (`Ctrl+C` then `cds watch`) — data is still there.
$md$ WHERE slug = '6-sqllite-test';

UPDATE public.topics SET content_md = $md$
# Episode 7 — Connecting UI5 to CAP: The OData Model

## What you'll build

Wire your Episode 1 single-screen UI5 app to your Episode 6 CAP backend. The product list now loads from the real OData API instead of a local JSON file. This is the moment the two halves of the stack connect.

---

## The key insight

An `ODataModel V4` in UI5 behaves almost identically to a `JSONModel` from the binding side. The list binding `items="{/Products}"` and the item binding `{name}` work the same. What changes is where the data comes from and how it gets there.

| JSONModel | ODataModel V4 |
|---|---|
| Reads from a local `.json` file | Reads from an OData service over HTTP |
| All data loaded at once | Loaded page-by-page on demand |
| Changes are local only | Changes sent to server as PATCH/POST/DELETE |
| No server round-trip | Every read/write is an HTTP request |

---

## Project structure changes

Only 3 files need updating:
1. `manifest.json` — add the OData data source and model
2. `Component.js` — remove the JSONModel, use the OData model from manifest
3. `ui5.yaml` — add a proxy so the UI5 dev server forwards `/api` requests to CAP

---

## Step 1 — Update manifest.json

```json
{
  "sap.app": {
    "id": "sap.ui.demo.ss",
    "dataSources": {
      "mainService": {
        "uri": "/api/",
        "type": "OData",
        "settings": {
          "odataVersion": "4.0"
        }
      }
    }
  },
  "sap.ui5": {
    "models": {
      "": {
        "dataSource": "mainService",
        "preload": true,
        "settings": {
          "synchronizationMode": "None",
          "operationMode": "Server",
          "autoExpandSelect": true
        }
      }
    }
  }
}
```

**Key changes:**
- `dataSources.mainService.uri: "/api/"` — the OData service URL. The `/api/` path is proxied to CAP by the dev server config.
- Declaring the model in manifest.json means UI5 creates it automatically. You no longer need to create it in `Component.js`.
- `"operationMode": "Server"` — sorting and filtering are done by the server (OData `$orderby`, `$filter`), not in the browser.

---

## Step 2 — Update Component.js

Remove the JSONModel code. UI5 now handles model creation from the manifest declaration.

```js
sap.ui.define([
  "sap/ui/core/UIComponent"
], function (UIComponent) {
  "use strict";

  return UIComponent.extend("sap.ui.demo.ss.Component", {
    metadata: { manifest: "json" },

    init: function () {
      UIComponent.prototype.init.apply(this, arguments);
      // No manual model creation needed.
      // UI5 reads the "models" section in manifest.json and creates the ODataModel.
      this.getRouter().initialize();
    }
  });
});
```

---

## Step 3 — Update the view binding path

OData entity names are PascalCase. Change `/products` to `/Products` in the list binding.

```xml
<List
  id="productList"
  items="{
    path: '/Products',
    parameters: {
      $select: 'ID,name,category_ID,price',
      $expand: 'category'
    }
  }">
  <StandardListItem
    title="{name}"
    description="{category/name}"
    info="{price} EUR"
    type="Navigation"
    press="onItemPress" />
</List>
```

**Key changes:**
- `/Products` (capital P) — OData entity set names match the CDS entity name.
- `$expand: 'category'` — fetches the associated Category record in the same request.
- `{category/name}` — navigates the association to get the category name.

---

## Step 4 — Configure the proxy (local dev only)

The UI5 dev server runs on port 5173 (or 8080). The CAP server runs on 4004. The browser cannot call `localhost:4004` directly from a page on `localhost:5173` due to CORS. A dev proxy fixes this.

```yaml
# ui5.yaml
specVersion: "3.0"
metadata:
  name: 7-cap-ss-test
type: application
server:
  customMiddleware:
    - name: ui5-middleware-simpleproxy
      afterMiddleware: compression
      mountPath: /api
      configuration:
        baseUri: http://localhost:4004/api
```

Install the proxy middleware:

```bash
npm install --save-dev ui5-middleware-simpleproxy
```

Now any request from the UI5 app to `/api/...` is forwarded to `http://localhost:4004/api/...`.

---

## OData V4 vs V2

You may see older UI5 code using `sap.ui.model.odata.v2.ODataModel`. This course uses V4:

| OData V2 | OData V4 |
|---|---|
| Older, more widespread in SAP systems | Modern standard, used by CAP |
| Two-phase commit (submitChanges) | Batch and auto-submit via binding |
| `$metadata` format is XML | Same XML, but richer type system |
| `sap.ui.model.odata.v2.ODataModel` | `sap.ui.model.odata.v4.ODataModel` |

CAP always generates OData V4. If you see tutorials using V2 they are based on older SAP Gateway services.

---

## Common mistakes

**Mistake:** List is blank and the console shows "CORS" errors.
**Fix:** The proxy is not set up correctly. Check `ui5.yaml` — the `mountPath` must be `/api` and `baseUri` must point to `http://localhost:4004/api`.

**Mistake:** OData model loads but list shows `undefined` for all fields.
**Fix:** OData entity property names are case-sensitive. Use the exact names from your CDS schema: `name`, `price`, `category`.

**Mistake:** `$expand=category` returns nothing.
**Fix:** You may have forgotten to run `cds deploy` after adding the Association in Episode 6. The SQLite schema needs to include the foreign key.

**Mistake:** App works in dev but the proxy stops working after restart.
**Fix:** Both CAP (`cds watch`) and the UI5 dev server (`npm start`) must be running simultaneously. Open two terminal tabs.

---

## ✅ Checkpoint

Start both servers:
```bash
# Terminal 1: CAP backend
cd 5-cap-1-test && cds watch

# Terminal 2: UI5 frontend
cd 7-cap-ss-test && npm start
```

Open `http://localhost:8080`. You should see the product list populated from CAP. The browser network tab should show a request to `/api/Products` returning your seeded data.
$md$ WHERE slug = '7-cap-ss-test';

UPDATE public.topics SET content_md = $md$
# Episode 8 — Full-Stack CRUD: UI5 + CAP + SQLite

## What you'll build

Add Create, Update, and Delete operations to your connected UI5+CAP app. The Episode 3 CRUD patterns you learned against a local JSON model now talk to the real CAP OData API and persist to SQLite.

---

## Architecture

```
UI5 ODataModel V4
  │
  ├── READ   → GET  /api/Products        (list binding auto-fetches)
  ├── CREATE → POST /api/Products        (oBinding.create({...}))
  ├── UPDATE → PATCH /api/Products(id)   (oContext.setProperty(...) + submitBatch)
  └── DELETE → DELETE /api/Products(id)  (oContext.delete())
          │
     CAP handles routing, validation, and SQL
          │
     SQLite db/demo.db
```

---

## Step 1 — Enable CRUD in the CAP service

By default CAP auto-generates all CRUD operations. But add explicit handlers to customise behaviour:

```js
// srv/product-service.js

const cds = require('@sap/cds');

module.exports = class ProductService extends cds.ApplicationService {

  async init() {

    // Validate before CREATE
    this.before('CREATE', 'Products', (req) => {
      const { name, price } = req.data;
      if (!name || name.trim() === '') {
        req.error(400, 'Product name is required');
      }
      if (price == null || price <= 0) {
        req.error(400, 'Price must be greater than zero');
      }
    });

    // Validate before UPDATE
    this.before('UPDATE', 'Products', (req) => {
      if (req.data.price !== undefined && req.data.price <= 0) {
        req.error(400, 'Price must be greater than zero');
      }
    });

    await super.init();
  }

};
```

`req.error(400, message)` sends a proper OData error response. UI5's ODataModel surfaces this as a rejection in the Promise chain.

---

## Step 2 — UI5 CREATE via ODataModel V4

```js
// In Main.controller.js — onCreatePress handler

onCreatePress: function () {
  // Get the list binding (the "/Products" binding on the List control)
  var oList = this.byId("productList");
  var oBinding = oList.getBinding("items");

  // Create a new entry at the beginning of the list
  // This creates a transient (unsaved) context immediately visible in the UI
  var oContext = oBinding.create({
    name:     "",
    price:    0,
    category_ID: 1
  });

  // Navigate to the detail/edit view for this new (unsaved) context
  this._navToDetail(oContext);
},
```

**Key concept:** `oBinding.create({...})` creates a **transient context**. It appears in the list immediately (optimistic UI) but is not saved until you call `oContext.created()` resolves. If the user cancels, call `oContext.delete()` to discard it.

---

## Step 3 — UI5 UPDATE via ODataModel V4

In the detail/edit view controller:

```js
onSavePress: function () {
  var oContext = this._oContext; // stored when navigating to this view

  // setProperty sends a PATCH for this specific field
  // For multiple fields, batch them:
  var oModel = this.getView().getModel();
  var sPath  = oContext.getPath(); // e.g. /Products(3)

  oModel.setProperty(sPath + "/name",  this.byId("inputName").getValue());
  oModel.setProperty(sPath + "/price", parseFloat(this.byId("inputPrice").getValue()));

  // submitBatch sends all pending PATCH requests in one HTTP call
  oModel.submitBatch("myUpdateGroup")
    .then(function () {
      MessageToast.show("Saved");
      this.onNavBack();
    }.bind(this))
    .catch(function (oError) {
      MessageBox.error("Save failed: " + oError.message);
    });
},
```

**Important:** In OData V4, `setProperty` marks the context as dirty but does NOT send an HTTP request immediately. Only `submitBatch` (or auto-submit depending on your binding group config) sends the PATCH.

---

## Step 4 — UI5 DELETE via ODataModel V4

```js
onDeletePress: function () {
  var oContext = this._oSelectedContext;

  MessageBox.confirm("Delete this product?", {
    onClose: function (sAction) {
      if (sAction !== "OK") { return; }

      oContext.delete()
        .then(function () {
          MessageToast.show("Deleted");
          // List automatically refreshes — the item disappears
        })
        .catch(function (oError) {
          MessageBox.error("Delete failed: " + oError.message);
        });
    }
  });
},
```

`oContext.delete()` sends a `DELETE /api/Products(id)` request. On success the context is removed from the binding and the list updates automatically. No manual refresh needed.

---

## Step 5 — Update manifest.json for auto-expand and batch

```json
"models": {
  "": {
    "dataSource": "mainService",
    "settings": {
      "synchronizationMode": "None",
      "operationMode": "Server",
      "autoExpandSelect": true,
      "groupId": "$auto",
      "updateGroupId": "myUpdateGroup"
    }
  }
}
```

- `"groupId": "$auto"` — READ requests are sent immediately (no manual batch needed for reads).
- `"updateGroupId": "myUpdateGroup"` — all PATCH/POST requests are batched under this group. Only sent when you call `submitBatch("myUpdateGroup")`.

---

## Comparing local JSON CRUD vs OData V4 CRUD

| Operation | JSON Model | OData V4 |
|---|---|---|
| Create | `aProducts.push({...}); oModel.setProperty(...)` | `oBinding.create({...})` → `oModel.submitBatch(...)` |
| Read | Immediate from memory | HTTP GET, async |
| Update | `aProducts[i] = {...}; oModel.setProperty(...)` | `oContext.setProperty(...)` → `oModel.submitBatch(...)` |
| Delete | `aProducts.splice(i,1); oModel.setProperty(...)` | `oContext.delete()` → Promise |
| Error handling | Not needed (local) | `.catch(oError => ...)` always |

---

## Full round-trip trace for a CREATE

```
1. User fills dialog, clicks Save
2. oBinding.create({ name: "New Product", price: 50, category_ID: 1 })
   → item appears in list immediately (transient, unsaved)
3. submitBatch("myUpdateGroup")
   → POST /api/Products  { name: "New Product", price: 50, category_ID: 1 }
4. CAP receives POST
   → runs before('CREATE') handler (validates)
   → CAP inserts row: INSERT INTO com_demo_Products ...
   → CAP returns 201 Created with the full new record (including server-assigned ID)
5. ODataModel receives 201
   → transient context becomes a permanent context with the real ID
   → list binding refreshes the new item's binding
6. MessageToast.show("Created")
```

---

## Common mistakes

**Mistake:** `oBinding.create(...)` throws "Binding must have a create method".
**Fix:** Only list bindings support `create`. Ensure you are calling `getBinding("items")` on the List control, not a property binding on a Text control.

**Mistake:** PATCH is never sent — `submitBatch` resolves immediately with no HTTP request.
**Fix:** `setProperty` must target a property that exists in the OData model's metadata. Check the property name matches exactly (case-sensitive).

**Mistake:** DELETE returns 404.
**Fix:** Make sure the context path includes the key: `/Products(3)`. If `oContext.getPath()` returns `/Products` without a key, you have a binding issue — the context was created without a key predicate.

**Mistake:** CAP returns 400 but the UI shows no error.
**Fix:** Wrap `submitBatch` in `.catch(function(oError) { MessageBox.error(oError.message); })`. By default errors are silent.

---

## ✅ Checkpoint

With both CAP and UI5 servers running:
1. Create a new product via the dialog — it should appear in the list and persist after a browser refresh.
2. Edit a product's name or price — save it and verify the change survives a refresh.
3. Delete a product — it disappears from the list and from `sqlite3 db/demo.db`.
$md$ WHERE slug = '8-cap-ms-test';

UPDATE public.topics SET content_md = $md$
# Episode 9 — Value Help Against Live CAP Data

## What you'll build

Upgrade the Episode 4 static category Value Help dialog to load its values dynamically from the CAP `/api/Categories` OData endpoint. The search now filters server-side using OData `$filter`.

---

## What is different from Episode 4

| Episode 4 | Episode 9 |
|---|---|
| Category list hardcoded in `data.json` | Category list fetched from `/api/Categories` |
| Search filters in-browser (Filter on JSONModel) | Search sends `$filter` to CAP (server-side) |
| Adding a new category means editing JSON | Adding a category goes to the database |

The fragment XML stays nearly the same. What changes is the binding in the fragment (OData path instead of JSON path) and the search handler (server-side filter instead of client-side).

---

## Step 1 — The dialog fragment (updated binding)

```xml
<core:FragmentDefinition
  xmlns="sap.m"
  xmlns:core="sap.ui.core">

  <SelectDialog
    id="categoryDialog"
    title="Select Category"
    search="onDialogSearch"
    confirm="onDialogConfirm"
    cancel="onDialogCancel"
    items="{
      path: '/Categories',
      parameters: {
        $select: 'ID,name',
        $orderby: 'name asc'
      }
    }">

    <StandardListItem
      title="{name}"
      description="{ID}"
      type="Active" />

  </SelectDialog>

</core:FragmentDefinition>
```

The binding path `/Categories` now refers to the OData model (set in manifest.json), not the local JSONModel. The `$select` and `$orderby` parameters are sent as query options in the HTTP request.

---

## Step 2 — The search handler (server-side filtering)

```js
onDialogSearch: function (oEvent) {
  var sValue = oEvent.getParameter("value");
  var oBinding = oEvent.getSource().getBinding("items");

  if (sValue) {
    // Build an OData $filter: name contains the search value
    var oFilter = new Filter({
      path: "name",
      operator: FilterOperator.Contains,
      value1: sValue
    });
    oBinding.filter([oFilter]);
    // This sends: GET /api/Categories?$filter=contains(name,'laptop')
  } else {
    // Empty search — remove the filter, show all
    oBinding.filter([]);
  }
},
```

The `Filter` object with `FilterOperator.Contains` generates the OData `contains()` function in the `$filter` query parameter. CAP handles the SQL `LIKE '%value%'` automatically.

---

## Step 3 — Confirm handler (unchanged from Episode 4)

```js
onDialogConfirm: function (oEvent) {
  var oSelectedItem = oEvent.getParameter("selectedItem");
  if (!oSelectedItem) { return; }

  // Get the category ID from the OData context
  var oContext = oSelectedItem.getBindingContext();
  var sCategoryId   = oContext.getProperty("ID");
  var sCategoryName = oContext.getProperty("name");

  // Write the selected category back to the product form
  var oFormModel = this.getView().getModel("form");
  oFormModel.setProperty("/category_ID",   sCategoryId);
  oFormModel.setProperty("/categoryName",  sCategoryName);  // for display only

  // Clean up filter
  oEvent.getSource().getBinding("items").filter([]);
},
```

---

## Step 4 — Open handler (one small addition)

```js
onCategoryValueHelp: function () {
  if (!this._oCategoryDialog) {
    this._oCategoryDialog = this.loadFragment({
      name: "sap.ui.demo.f4b.fragments.CategoryDialog"
    });
  }

  Promise.resolve(this._oCategoryDialog).then(function (oDialog) {
    this._oCategoryDialog = oDialog;

    // Reset filter before opening so the full list shows
    var oBinding = oDialog.getBinding("items");
    if (oBinding) { oBinding.filter([]); }

    oDialog.open();
  }.bind(this));
},
```

---

## Understanding OData $filter

OData `$filter` is a standardised query language. CAP supports the full OData filter spec:

| Filter | OData syntax | UI5 FilterOperator |
|---|---|---|
| Equals | `name eq 'Laptop'` | `EQ` |
| Contains | `contains(name,'lap')` | `Contains` |
| Starts with | `startswith(name,'L')` | `StartsWith` |
| Greater than | `price gt 100` | `GT` |
| AND | `price gt 100 and category eq 'A'` | Combine with `Filter({and: [...]})` |

UI5 translates `FilterOperator` enum values to the correct OData syntax automatically. You never write the OData filter string by hand.

---

## Common mistakes

**Mistake:** Dialog opens empty — no categories load.
**Fix:** The dialog binding uses the default OData model. Confirm `manifest.json` has the OData model declared as the default (empty name `""`). If you have a named model, prefix the path: `path: 'yourModel>/Categories'`.

**Mistake:** Search does nothing — typing in the search box has no effect.
**Fix:** The `search` event on `SelectDialog` does not fire automatically. Verify the `search` attribute in the fragment XML is set to your handler name: `search="onDialogSearch"`.

**Mistake:** Confirming a category gives `undefined` for the ID.
**Fix:** Use `oContext.getProperty("ID")` (capital ID), not `oContext.getObject().id`. OData property names match the CDS definition exactly.

**Mistake:** CAP returns 400 on the filter request.
**Fix:** `FilterOperator.Contains` generates `contains(name,'value')` which requires OData V4. If your service is V2, use `FilterOperator.Contains` → it generates a different syntax. This course uses V4.

---

## ✅ Checkpoint

1. Open the product form.
2. Click the Category value help icon — the dialog loads category names from CAP.
3. Type "el" in the search box — the list filters to show only "Electronics".
4. Select a category — the Category field in the form updates.
5. Open `http://localhost:4004/api/Categories?$filter=contains(name,'el')` in a browser to verify CAP is filtering correctly server-side.
$md$ WHERE slug = '9-cap-f4-test';

UPDATE public.topics SET content_md = $md$
# Episode 10 — Input Validation and User Feedback

## What you'll build

Three layers of validation on your product form: instant client-side guards in the controller, type-constraint validation via UI5 binding types, and server-side validation in CAP that returns structured error messages back to the UI.

---

## Three layers of validation

```
Layer 1: JS guard in the controller  ─── fast, no server round-trip
        ↓ (passes)
Layer 2: UI5 binding type constraint ─── validates format (email, date, number range)
        ↓ (passes)
Layer 3: CAP backend validation      ─── business rules, database constraints
```

Each layer catches different things. Never rely on only one layer — the browser-side can be bypassed, and the server-side gives a bad user experience if it is the first to catch a typo.

---

## Layer 1 — JS guard in the controller

A simple manual check before you even try to save:

```js
// In Detail.controller.js — onSavePress

onSavePress: function () {
  var sName  = this.byId("inputName").getValue().trim();
  var sPrice = this.byId("inputPrice").getValue();
  var nPrice = parseFloat(sPrice);

  // Check 1: name must not be empty
  if (!sName) {
    MessageBox.error("Product name cannot be empty.");
    this.byId("inputName").setValueState("Error");
    this.byId("inputName").setValueStateText("Name is required");
    return;   // stop here, don't save
  }

  // Check 2: price must be a positive number
  if (isNaN(nPrice) || nPrice <= 0) {
    MessageBox.error("Price must be a positive number.");
    this.byId("inputPrice").setValueState("Error");
    this.byId("inputPrice").setValueStateText("Enter a number greater than 0");
    return;
  }

  // All checks passed — clear error states and save
  this.byId("inputName").setValueState("None");
  this.byId("inputPrice").setValueState("None");
  this._saveProduct(sName, nPrice);
},
```

`setValueState("Error")` turns the input border red. `setValueStateText(...)` shows a tooltip explaining the error. `setValueState("None")` clears it.

---

## Layer 2 — Binding type constraints

Add type constraints directly in the view XML. UI5 validates these automatically when the user leaves the field (on `change` event):

```xml
<Input
  id="inputPrice"
  value="{
    path: 'form>/price',
    type: 'sap.ui.model.type.Float',
    constraints: {
      minimum: 0.01,
      maximum: 999999.99,
      minFractionDigits: 2,
      maxFractionDigits: 2
    },
    formatOptions: {
      minFractionDigits: 2
    }
  }"
  placeholder="0.00" />
```

When the user types `abc` or `-5`, UI5 automatically:
1. Shows the input in red (`ValueState: Error`).
2. Displays the constraint message as a tooltip.
3. Marks the binding as invalid so you can detect it before saving.

---

## Checking binding errors before saving

Before calling save, check if any bound control has a pending type error:

```js
_hasBindingErrors: function () {
  var oView = this.getView();
  // Check all inputs by their IDs
  var aInputIds = ["inputName", "inputPrice", "inputCategory"];
  return aInputIds.some(function (sId) {
    var oControl = oView.byId(sId);
    return oControl && oControl.getValueState() === "Error";
  });
},

onSavePress: function () {
  if (this._hasBindingErrors()) {
    MessageBox.error("Please fix the highlighted errors before saving.");
    return;
  }
  // ... proceed with save
},
```

---

## MessageToast vs MessageBox — when to use which

| Situation | Use |
|---|---|
| Non-blocking confirmation ("Saved successfully") | `MessageToast.show(text)` |
| Error that needs acknowledgement | `MessageBox.error(text)` |
| Confirmation before a destructive action (delete) | `MessageBox.confirm(text, { onClose: fn })` |
| Warning with multiple options | `MessageBox.warning(text, { actions: [...] })` |

```js
// MessageToast — disappears automatically after 3 seconds
MessageToast.show("Product saved");

// MessageBox.error — blocks UI until user clicks OK
MessageBox.error("Name is required", {
  title: "Validation Error",
  onClose: function () {
    // Optional: focus the failing input
    this.byId("inputName").focus();
  }.bind(this)
});

// MessageBox.confirm — ask before deleting
MessageBox.confirm("Delete this product permanently?", {
  title: "Confirm Delete",
  onClose: function (sAction) {
    if (sAction === MessageBox.Action.OK) {
      this._doDelete();
    }
  }.bind(this)
});
```

---

## CAP backend validation

Add input checks in the CAP service handler. `req.error()` sends a structured OData error response:

```js
// srv/product-service.js

this.before('CREATE', 'Products', (req) => {
  const { name, price, category_ID } = req.data;

  if (!name || name.trim().length === 0) {
    req.error(400, 'Product name is required', 'name');
  }
  if (!price || price <= 0) {
    req.error(400, 'Price must be greater than zero', 'price');
  }
  if (!category_ID) {
    req.error(400, 'Category is required', 'category_ID');
  }
});

this.before('UPDATE', 'Products', (req) => {
  if (req.data.price !== undefined && req.data.price <= 0) {
    req.error(400, 'Price must be greater than zero', 'price');
  }
});
```

The third argument to `req.error` is the **target field name**. OData clients can use this to highlight the specific failing input.

---

## Surface CAP errors in the UI

When `submitBatch` fails, the error comes back as a rejected Promise. Parse the message out and show it:

```js
oModel.submitBatch("myUpdateGroup")
  .then(function () {
    MessageToast.show("Saved");
  })
  .catch(function (oError) {
    // oError.message contains the CAP error text
    var sMsg = oError.message || "An unknown error occurred";

    // For OData batch errors, the detail is nested:
    if (oError.cause && oError.cause.responseText) {
      try {
        var oBody = JSON.parse(oError.cause.responseText);
        sMsg = oBody.error.message || sMsg;
      } catch (e) { /* ignore parse error */ }
    }

    MessageBox.error(sMsg);
  }.bind(this));
```

---

## Common mistakes

**Mistake:** `setValueState("Error")` shows red but the user can still save.
**Fix:** You must check `getValueState() === "Error"` (or use `_hasBindingErrors`) before proceeding with save. Setting the visual state does not automatically block the save.

**Mistake:** Type constraint in the binding fires but the error message is generic ("EnterNumber").
**Fix:** Add a `formatOptions.parseAsString: false` to ensure the type parser runs. Also add a custom `type` class extending `sap.ui.model.type.Float` to customise the message.

**Mistake:** CAP validation error arrives but the UI does not show it — console shows the error but the user sees nothing.
**Fix:** Wrap `submitBatch` in `.catch(...)`. The ODataModel does not automatically surface backend errors to the UI.

**Mistake:** `req.error(400, ...)` does not stop execution — code after it still runs.
**Fix:** `req.error` in CAP accumulates errors but does not throw. Add `return;` after each `req.error` call, or check `req.errors.length > 0` before continuing.

---

## ✅ Checkpoint

1. Try saving a product with an empty name — the name input turns red and a MessageBox appears.
2. Try entering a negative price — the price input turns red.
3. Fix both fields and save — the form saves successfully.
4. Use `curl` to send an invalid POST directly to CAP and verify it returns a 400 with a proper error message:
```bash
curl -X POST http://localhost:4004/api/Products \
  -H "Content-Type: application/json" \
  -d '{"name": "", "price": -1, "category_ID": 1}'
```
$md$ WHERE slug = '10-validation-test';

UPDATE public.topics SET content_md = $md$
# Episode 11 — Search, Filter, and Sort

## What you'll build

A product list with a live **search bar** (filters by name), **category filter** (Select control), and a **sort button** that toggles ascending/descending by price. All filtering and sorting is done server-side via OData query options.

---

## The complete UI — SearchField + Sort button

```xml
<mvc:View
  controllerName="sap.ui.demo.filt.controller.Main"
  xmlns:mvc="sap.ui.core.mvc"
  xmlns="sap.m"
  displayBlock="true">

  <Page title="Products">

    <headerContent>
      <Button id="sortBtn" icon="sap-icon://sort" press="onSortPress"
              tooltip="Sort by price" />
    </headerContent>

    <subHeader>
      <Toolbar>
        <SearchField
          id="searchField"
          placeholder="Search by name..."
          search="onSearch"
          liveChange="onSearch"
          width="60%" />
        <ToolbarSpacer />
        <Select id="categoryFilter" change="onCategoryFilter">
          <core:Item key="" text="All Categories"
            xmlns:core="sap.ui.core" />
          <core:Item key="Electronics" text="Electronics"
            xmlns:core="sap.ui.core" />
          <core:Item key="Accessories" text="Accessories"
            xmlns:core="sap.ui.core" />
          <core:Item key="Software"    text="Software"
            xmlns:core="sap.ui.core" />
        </Select>
      </Toolbar>
    </subHeader>

    <content>
      <List id="productList" items="{/Products}">
        <StandardListItem
          title="{name}"
          description="{category/name}"
          info="{price} EUR" />
      </List>
    </content>

  </Page>

</mvc:View>
```

---

## Search handler

```js
sap.ui.define([
  "sap/ui/core/mvc/Controller",
  "sap/ui/model/Filter",
  "sap/ui/model/FilterOperator",
  "sap/ui/model/Sorter"
], function (Controller, Filter, FilterOperator, Sorter) {
  "use strict";

  return Controller.extend("sap.ui.demo.filt.controller.Main", {

    onInit: function () {
      // Track current sort state
      this._bSortDescending = false;
    },

    // Shared helper: read current filter/search values and apply all at once
    _applyFiltersAndSort: function () {
      var oList    = this.byId("productList");
      var oBinding = oList.getBinding("items");
      var aFilters = [];

      // 1. Search filter (by name)
      var sQuery = this.byId("searchField").getValue().trim();
      if (sQuery) {
        aFilters.push(new Filter("name", FilterOperator.Contains, sQuery));
      }

      // 2. Category filter
      var sCategoryKey = this.byId("categoryFilter").getSelectedKey();
      if (sCategoryKey) {
        aFilters.push(new Filter("category/name", FilterOperator.EQ, sCategoryKey));
      }

      // Apply: if multiple filters, AND them together
      var oCombinedFilter = aFilters.length > 1
        ? new Filter({ filters: aFilters, and: true })
        : (aFilters[0] || null);

      oBinding.filter(oCombinedFilter ? [oCombinedFilter] : []);
    },

    onSearch: function () {
      this._applyFiltersAndSort();
    },

    onCategoryFilter: function () {
      this._applyFiltersAndSort();
    },
```

---

## Sort handler — toggle ascending/descending

```js
    onSortPress: function () {
      // Toggle the sort direction each press
      this._bSortDescending = !this._bSortDescending;

      var oList    = this.byId("productList");
      var oBinding = oList.getBinding("items");

      var oSorter = new Sorter("price", this._bSortDescending);
      oBinding.sort(oSorter);

      // Update button icon to show current direction
      var oBtn = this.byId("sortBtn");
      oBtn.setIcon(this._bSortDescending
        ? "sap-icon://sort-descending"
        : "sap-icon://sort-ascending");
    },

  }); // end controller
});
```

`new Sorter("price", true)` tells UI5 to send `$orderby=price desc` in the OData request. CAP translates this to SQL `ORDER BY price DESC`.

---

## Multi-column sort

To sort by multiple fields (e.g. category then price):

```js
var aSorters = [
  new Sorter("category/name", false),   // primary: category ascending
  new Sorter("price", true)             // secondary: price descending
];
oBinding.sort(aSorters);
// Sends: $orderby=category/name asc,price desc
```

---

## Combining filter + sort

Calling `oBinding.filter(...)` and `oBinding.sort(...)` separately works but causes two HTTP requests. To send one request:

```js
// OData V4 ListBinding supports chaining:
oBinding.changeParameters({});  // forces a refresh with current filter AND sort combined
```

Or — the recommended way — always call both together in `_applyFiltersAndSort`:

```js
_applyFiltersAndSort: function () {
  var oBinding = this.byId("productList").getBinding("items");
  // ... build aFilters as above ...
  oBinding.filter(oCombinedFilter ? [oCombinedFilter] : []);

  var oSorter = new Sorter("price", this._bSortDescending);
  oBinding.sort(oSorter);
  // UI5 V4 ODataListBinding batches these into one GET request
},
```

---

## FilterBar for advanced multi-field search

For enterprise forms with many filter fields, use `sap.ui.comp.filterbar.FilterBar`:

```xml
<!-- Requires sap.ui.comp library -->
<filterBar:FilterBar
  id="filterBar"
  search="onFilterBarSearch"
  xmlns:filterBar="sap.ui.comp.filterbar">
  <filterBar:filterGroupItems>
    <filterBar:FilterGroupItem name="name" label="Name" visibleInFilterBar="true">
      <filterBar:control>
        <Input id="filterName" />
      </filterBar:control>
    </filterBar:FilterGroupItem>
  </filterBar:filterGroupItems>
</filterBar:FilterBar>
```

For this course, the `SearchField` + `Select` approach covers the common case.

---

## Common mistakes

**Mistake:** Search works but category filter does nothing.
**Fix:** The category filter path `"category/name"` navigates an association. Make sure `$expand=category` is in the list binding parameters so the association data is available.

**Mistake:** Filter sends the request but results are wrong — "Electronics" filter returns all items.
**Fix:** The `FilterOperator.EQ` comparison is case-sensitive by default in OData. Ensure your seed data uses the exact same casing as your filter value.

**Mistake:** Typing in the search field causes a new HTTP request on every keystroke.
**Fix:** Use `search` event (fires on Enter or clear) instead of `liveChange`, or debounce `liveChange`:
```js
onSearchLive: function (oEvent) {
  clearTimeout(this._searchTimer);
  this._searchTimer = setTimeout(function () {
    this._applyFiltersAndSort();
  }.bind(this), 300); // wait 300ms after last keystroke
},
```

**Mistake:** Sort button press throws "sort is not a function".
**Fix:** OData V4 list bindings use `.sort()`. OData V2 bindings use `.sort()` too but with a different Sorter API. Confirm your model is OData V4 (`sap.ui.model.odata.v4.ODataModel`).

---

## ✅ Checkpoint

1. Open the product list. All products show.
2. Type "lap" in the search bar — only products with "lap" in the name appear.
3. Select "Electronics" from the dropdown — the list further filters.
4. Click the Sort button — list re-orders by price ascending. Click again — descending.
5. Clear the search and reset the filter — all products return.
$md$ WHERE slug = '11-filter-sort-test';

UPDATE public.topics SET content_md = $md$
# Episode 12 — Securing Your CAP Service with XSUAA

## What you'll build

Add authentication and role-based access control to your CAP service using **XSUAA** (the SAP BTP OAuth2 authorization server). Unauthenticated requests return 401. Requests without the right role return 403.

---

## The security model in three pieces

```
1. xs-security.json  ── defines scopes and role templates
        ↓
2. CDS annotations   ── maps scopes to service operations
        ↓
3. XSUAA service     ── issues JWT tokens containing the user's scopes
        ↓
4. CAP               ── validates the token on every request
```

---

## Step 1 — Create xs-security.json

```json
{
  "xsappname": "product-app",
  "tenant-mode": "dedicated",
  "scopes": [
    {
      "name": "$XSAPPNAME.ProductViewer",
      "description": "Can read products"
    },
    {
      "name": "$XSAPPNAME.ProductAdmin",
      "description": "Can create, update, and delete products"
    }
  ],
  "role-templates": [
    {
      "name": "ProductViewer",
      "description": "Read-only access to products",
      "scope-references": ["$XSAPPNAME.ProductViewer"]
    },
    {
      "name": "ProductAdmin",
      "description": "Full access to products",
      "scope-references": [
        "$XSAPPNAME.ProductViewer",
        "$XSAPPNAME.ProductAdmin"
      ]
    }
  ]
}
```

`$XSAPPNAME` is a placeholder — XSUAA replaces it with the actual app name at deploy time.

---

## Step 2 — Annotate your CDS service

```cds
// srv/product-service.cds

using com.demo from '../db/schema';

@requires: 'authenticated-user'
service ProductService @(path: '/api') {

  @readonly
  @requires: 'ProductViewer'
  entity Products as projection on com.demo.Products;

  @requires: 'ProductAdmin'
  action createProduct(name: String, price: Decimal) returns Products;
}
```

- `@requires: 'authenticated-user'` — the whole service requires a valid JWT token.
- `@readonly` + `@requires: 'ProductViewer'` — GET requests need the Viewer scope.
- `@requires: 'ProductAdmin'` on the action — only admins can call it.

You can also annotate at the operation level:

```cds
entity Products as projection on com.demo.Products {
  @requires: 'ProductViewer'
  READ;
  @requires: 'ProductAdmin'
  CREATE; UPDATE; DELETE;
}
```

---

## Step 3 — Add XSUAA to package.json

```json
{
  "cds": {
    "requires": {
      "db": {
        "kind": "sqlite",
        "credentials": { "database": "db/demo.db" }
      },
      "auth": {
        "kind": "xsuaa"
      }
    }
  }
}
```

In production (`cds run --production`), CAP validates real XSUAA JWTs. In development (`cds watch`), CAP uses mock authentication automatically.

---

## Step 4 — Test mocked auth locally

During development, XSUAA is not available. CAP's mock auth lets you simulate any user and roles:

```bash
# Simulate a ProductViewer user
curl http://localhost:4004/api/Products \
  -H "Authorization: Basic viewer:viewer"

# Simulate a ProductAdmin user (Basic auth: user:password, CAP reads roles from a config)
curl -X POST http://localhost:4004/api/Products \
  -H "Authorization: Basic admin:admin" \
  -H "Content-Type: application/json" \
  -d '{"ID": 10, "name": "Test", "price": 9.99, "category_ID": 1}'
```

To configure mock users, add a `.cdsrc.json`:

```json
{
  "requires": {
    "auth": {
      "kind": "mocked",
      "users": {
        "viewer": { "roles": ["ProductViewer"] },
        "admin":  { "roles": ["ProductViewer", "ProductAdmin"] }
      }
    }
  }
}
```

---

## Viewing a JWT token

When deployed and logged in through the approuter (Episode 14), the token is a Base64-encoded JSON. Decode it:

```bash
# Get the token from the Authorization header, then:
echo "eyJ..." | base64 -d | python3 -m json.tool

# Or use jwt.io in a browser (paste the token)
```

The decoded payload contains `scope` (array of granted scopes) and `user_name`.

---

## Common mistakes

**Mistake:** Adding `@requires` breaks local development — all requests return 401.
**Fix:** Make sure `.cdsrc.json` has the mocked auth config with test users. With `"kind": "mocked"`, CAP accepts Basic auth credentials matching your users config.

**Mistake:** `ProductAdmin` can read but not write — getting 403 on POST.
**Fix:** The `ProductAdmin` role template must include both the `ProductAdmin` AND `ProductViewer` scopes (viewers can read, admins can read+write). Check `xs-security.json` — the admin role-template should reference both scopes.

**Mistake:** Deployed app returns 401 even after login.
**Fix:** The JWT token must be forwarded to CAP. This is the approuter's job (Episode 14). Without the approuter, the browser token is not sent to the CAP backend.

---

## ✅ Checkpoint

With `.cdsrc.json` mocked auth:
1. `curl http://localhost:4004/api/Products` (no auth) → 401
2. `curl -u viewer:viewer http://localhost:4004/api/Products` → 200 with product list
3. `curl -u viewer:viewer -X POST http://localhost:4004/api/Products ...` → 403 (viewer can't write)
4. `curl -u admin:admin -X POST http://localhost:4004/api/Products ...` → 201 Created
$md$ WHERE slug = '12-auth-test';

UPDATE public.topics SET content_md = $md$
# Episode 13 — BTP Destinations: Portable Service URLs

## What you'll build

Replace the hardcoded `http://localhost:4004` URL in your app with a **BTP Destination** — a named, managed connection that works in both local development and production without changing any app code.

---

## The problem with hardcoded URLs

In Episode 7 you set up a proxy in `ui5.yaml` pointing to `http://localhost:4004`. This works locally, but when you deploy to BTP:
- The CAP service runs at a different URL (e.g. `https://my-cap-service.cfapps.eu10.hana.ondemand.com`).
- That URL changes between landscapes (dev, test, prod).
- Hardcoding it means updating code for every deployment.

A Destination solves this: the app always calls `/backend/api/Products` and the approuter (Episode 14) resolves `backend` to whatever URL is configured in the BTP Destination service — without any code change.

---

## The destination solution

```
UI5 app calls: /backend/api/Products
        ↓
Approuter reads xs-app.json: route /backend/* → destination "cap-backend"
        ↓
BTP Destination service: "cap-backend" = https://my-cap-service.cfapps.eu10.hana.ondemand.com
        ↓
CAP service receives: GET /api/Products
```

---

## Step 1 — Create a destination in BTP Cockpit

1. In BTP Cockpit, go to **Connectivity → Destinations**.
2. Click **New Destination**.
3. Fill in:

| Field | Value |
|---|---|
| Name | `cap-backend` |
| Type | `HTTP` |
| URL | `https://your-cap-service-url.cfapps.eu10.hana.ondemand.com` |
| Proxy Type | `Internet` |
| Authentication | `NoAuthentication` (or `OAuth2UserTokenExchange` if the service requires auth) |

4. Save.

For local development, you can define the destination in a `default-env.json` file (never commit this to git):

```json
{
  "destinations": [
    {
      "name": "cap-backend",
      "url": "http://localhost:4004",
      "forwardAuthToken": false
    }
  ]
}
```

---

## Step 2 — Update manifest.json to use relative URL

Remove the hardcoded host. The approuter will prepend the correct host.

```json
{
  "sap.app": {
    "dataSources": {
      "mainService": {
        "uri": "/backend/api/",
        "type": "OData",
        "settings": { "odataVersion": "4.0" }
      }
    }
  }
}
```

The path `/backend/api/` works in both local (proxied to `localhost:4004/api/`) and deployed (routed by the approuter through the BTP destination).

---

## Step 3 — Configure xs-app.json in the approuter

The approuter reads `xs-app.json` to know which URL patterns map to which destinations:

```json
{
  "authenticationMethod": "route",
  "routes": [
    {
      "source": "^/backend/(.*)$",
      "target": "/$1",
      "destination": "cap-backend",
      "authenticationType": "xsuaa",
      "csrfProtection": false
    },
    {
      "source": "^/(.*)$",
      "target": "$1",
      "service": "html5-apps-repo-rt",
      "authenticationType": "xsuaa"
    }
  ]
}
```

- `"source": "^/backend/(.*)$"` — any request starting with `/backend/` is matched.
- `"target": "/$1"` — the matched path (after `/backend/`) is forwarded to the destination.
- `"destination": "cap-backend"` — the name of the BTP Destination to use.

---

## Common mistakes

**Mistake:** Local development still fails after setting up `default-env.json`.
**Fix:** `default-env.json` is read by `@sap/approuter` when running locally. Make sure you start the approuter with `node node_modules/@sap/approuter/approuter.js`, not `cds watch`. Or keep the `ui5.yaml` proxy for the UI5 dev server.

**Mistake:** In production, requests return 404 for `/backend/api/Products`.
**Fix:** Check that the destination name in `xs-app.json` (`"cap-backend"`) exactly matches the name in BTP Cockpit. Names are case-sensitive.

**Mistake:** BTP Destination test (the "Check Connection" button in Cockpit) passes but the app still fails.
**Fix:** The "Check Connection" test only checks if the destination URL is reachable. It does not test authentication. If the CAP service requires an XSUAA token, set `"authenticationType": "xsuaa"` on the route.

---

## ✅ Checkpoint

Locally:
1. Start the approuter pointing to `default-env.json`.
2. Open your UI5 app through the approuter port (not the UI5 dev server directly).
3. The product list loads — the network tab shows requests to `/backend/api/Products`, not `localhost:4004`.

In BTP:
- Deploy the destination and approuter, then open the app URL.
- Products load from the deployed CAP service without any URL in the app code.
$md$ WHERE slug = '13-destination-test';

UPDATE public.topics SET content_md = $md$
# Episode 14 — The Approuter: Authentication Gateway

## What you'll build

Add the **SAP Approuter** to your project. The approuter sits in front of your UI5 app and CAP backend, handles the OAuth2 login flow with XSUAA, attaches JWT tokens to backend requests, and manages user sessions.

---

## What the approuter does

```
Browser
  │
  ▼
Approuter  ─── reads xs-app.json
  │
  ├── GET /  → serves the UI5 app HTML from html5-apps-repo
  │
  └── GET /backend/api/* → forwards to CAP with JWT token in Authorization header
              │
              ▼
         CAP validates token, checks scopes, returns data
```

Without the approuter, your UI5 app runs but has no authentication — anyone can call the API. With the approuter, unauthenticated users are redirected to the XSUAA login page.

---

## Step 1 — Create the approuter package

```
approuter/
 ├── xs-app.json      ← routing rules (from Episode 13)
 ├── package.json     ← approuter dependency
 └── default-env.json ← local config (never commit to git)
```

```json
// approuter/package.json
{
  "name": "approuter",
  "version": "1.0.0",
  "dependencies": {
    "@sap/approuter": "^14.0.0"
  },
  "scripts": {
    "start": "node node_modules/@sap/approuter/approuter.js"
  }
}
```

```bash
cd approuter
npm install
```

---

## Step 2 — Update xs-app.json (full version)

```json
{
  "authenticationMethod": "route",
  "sessionTimeout": 30,
  "routes": [
    {
      "source": "^/backend/(.*)$",
      "target": "/$1",
      "destination": "cap-backend",
      "authenticationType": "xsuaa",
      "csrfProtection": false
    },
    {
      "source": "^/(.*)$",
      "target": "$1",
      "service": "html5-apps-repo-rt",
      "authenticationType": "xsuaa"
    }
  ]
}
```

---

## Step 3 — Bind XSUAA in mta.yaml

The `mta.yaml` file describes your multi-target application for deployment. The approuter module must be bound to XSUAA:

```yaml
# mta.yaml (relevant sections)
modules:
  - name: approuter
    type: approuter.nodejs
    path: approuter
    requires:
      - name: xsuaa-service
      - name: cap-backend-destination
      - name: html5-repo-runtime

resources:
  - name: xsuaa-service
    type: org.cloudfoundry.managed-service
    parameters:
      service: xsuaa
      service-plan: application
      config:
        xsappname: product-app
        tenant-mode: dedicated
        path: xs-security.json
```

---

## Step 4 — Local testing with the approuter

For local testing, create `approuter/default-env.json` (never commit):

```json
{
  "PORT": 5000,
  "destinations": [
    {
      "name": "cap-backend",
      "url": "http://localhost:4004",
      "forwardAuthToken": false
    }
  ],
  "VCAP_SERVICES": {
    "xsuaa": [{
      "label": "xsuaa",
      "credentials": {
        "clientid": "sb-product-app",
        "clientsecret": "your-secret",
        "url": "https://your-tenant.authentication.eu10.hana.ondemand.com",
        "xsappname": "product-app"
      }
    }]
  }
}
```

For fully local testing without a real XSUAA, use CAP's mocked auth (Episode 12) and test the UI directly without the approuter.

---

## How token forwarding works

```
1. User opens the app in a browser
2. Approuter checks for a valid session cookie
   → No session: redirect to XSUAA login page
3. User enters credentials on XSUAA login page
4. XSUAA redirects back to the approuter with an authorization code
5. Approuter exchanges the code for a JWT token
6. Approuter stores the token in an encrypted session cookie
7. Approuter serves the UI5 HTML to the browser
8. Browser calls /backend/api/Products
9. Approuter reads the JWT from the session
   → Adds "Authorization: Bearer <token>" header
   → Forwards the request to the CAP service URL (from destination)
10. CAP validates the token and checks scopes
```

---

## Session vs token

| Session cookie | JWT token |
|---|---|
| Lives in the browser, managed by approuter | Sent in the `Authorization` header to the backend |
| Contains an encrypted reference to the JWT | Contains user info and scopes as plain JSON |
| Expires based on `sessionTimeout` in xs-app.json | Expires based on XSUAA settings (typically 12h) |
| Revokable by the approuter | Not revokable (validate expiry only) |

---

## Common mistakes

**Mistake:** After login, the app redirects in a loop and never loads.
**Fix:** The XSUAA redirect URI must be set to the approuter's URL. In the XSUAA service instance, the `oauth2-configuration.redirect-uris` must include `https://your-approuter-url.cfapps.eu10.hana.ondemand.com/**`.

**Mistake:** The approuter starts but all backend requests return 401.
**Fix:** Check that `"forwardAuthToken": true` is set on the destination in `default-env.json` (or in the BTP Destination config in production) when the backend requires the token.

**Mistake:** Session expires too quickly during development.
**Fix:** Increase `sessionTimeout` in `xs-app.json` (value is in minutes). Default is 15 minutes.

**Mistake:** `npm start` in the approuter fails with "Cannot find module '@sap/approuter'".
**Fix:** Run `npm install` inside the `approuter/` folder specifically, not in the project root.

---

## ✅ Checkpoint

1. Run the approuter locally (`npm start` in the `approuter/` folder) pointing to CAP on port 4004.
2. Open `http://localhost:5000` in a browser.
3. With mocked auth: you are logged in as the default mock user automatically.
4. The product list loads, routed through the approuter to CAP.
5. Check the CAP terminal — requests now show an `Authorization` header.
$md$ WHERE slug = '14-approuter-test';

UPDATE public.topics SET content_md = $md$
# Episode 15 — Deploying to SAP BTP

## What you'll build

Deploy your complete application — UI5 frontend, CAP backend, approuter, and all BTP services — to SAP BTP Cloud Foundry using the **Multi-Target Application (MTA)** deployment model.

---

## Understanding mta.yaml

`mta.yaml` describes all the pieces of your application as a single deployable unit:

```yaml
_schema-version: "3.1"
ID: product-app
version: 1.0.0

modules:

  # ── CAP backend ────────────────────────────────────────────
  - name: product-app-srv
    type: nodejs
    path: .
    parameters:
      buildpack: nodejs_buildpack
      memory: 256M
    build-parameters:
      builder: npm
      build-result: gen/srv
      requires:
        - artifacts:
          - product-app-db-deployer.zip
          target-path: gen/db
    requires:
      - name: product-app-db
      - name: product-app-xsuaa

  # ── Database deployer (runs once to create tables + seed) ──
  - name: product-app-db-deployer
    type: hdb
    path: gen/db
    requires:
      - name: product-app-db
        properties:
          hdi-service-name: ${service-name}

  # ── Approuter ──────────────────────────────────────────────
  - name: product-app-approuter
    type: approuter.nodejs
    path: approuter
    parameters:
      memory: 128M
    requires:
      - name: product-app-xsuaa
      - name: product-app-html5-repo-runtime
      - name: srv-api
        group: destinations
        properties:
          name: cap-backend
          url: ~{srv-url}
          forwardAuthToken: true

  # ── UI5 app (deployed to HTML5 Repo) ──────────────────────
  - name: product-app-ui
    type: html5
    path: webapp
    build-parameters:
      build-result: dist
      builder: custom
      commands:
        - npm install
        - npm run build

resources:

  - name: product-app-db
    type: com.sap.xs.hdi-container
    parameters:
      service: hana
      service-plan: hdi-shared

  - name: product-app-xsuaa
    type: org.cloudfoundry.managed-service
    parameters:
      service: xsuaa
      service-plan: application
      config:
        xsappname: product-app
        tenant-mode: dedicated
        path: xs-security.json

  - name: product-app-html5-repo-runtime
    type: org.cloudfoundry.managed-service
    parameters:
      service: html5-apps-repo
      service-plan: app-runtime
```

---

## Step 1 — Build the CAP service for production

```bash
# Install the MTA build tool globally (once)
npm install -g mbt

# Build all modules defined in mta.yaml
mbt build

# Output: creates mta_archives/product-app_1.0.0.mtar
```

The `.mtar` file is a zip archive containing all built modules.

---

## Step 2 — Deploy to BTP

```bash
# Install the CF CLI and MTA plugin (once)
cf install-plugin multiapps

# Log in to BTP Cloud Foundry
cf login -a https://api.cf.eu10.hana.ondemand.com

# Deploy
cf deploy mta_archives/product-app_1.0.0.mtar
```

Watch the output — each module deploys sequentially. The database deployer runs first (creates tables, loads seed data), then the CAP service, then the approuter.

---

## Step 3 — Verify the deployment

```bash
# List running apps
cf apps

# Check logs if something failed
cf logs product-app-srv --recent
cf logs product-app-approuter --recent
```

Open the approuter URL (shown in `cf apps` output under `urls`). Your app should load and show the product list from the HANA database.

---

## Troubleshooting failed deployments

| Symptom | Likely cause | Fix |
|---|---|---|
| `product-app-db-deployer` fails | HANA HDI container not created | Check service plan availability in your BTP account |
| `product-app-srv` crashes on start | Missing environment variable | Check `cf env product-app-srv` for missing bindings |
| Approuter returns 502 | CAP service not started yet | Wait 2 minutes, then retry. Check `cf logs product-app-srv --recent` |
| Login loop after deploy | XSUAA redirect URI mismatch | Add the approuter URL to the XSUAA `redirect-uris` in `xs-security.json` and redeploy |
| Data missing after deploy | DB deployer ran but CSV not found | Check CSV files are in `db/data/` and the filename matches the entity namespace |

---

## Common mistakes

**Mistake:** `mbt build` fails with "module not found".
**Fix:** Run `npm install` in every module folder (root, `approuter/`) before running `mbt build`.

**Mistake:** Deployment succeeds but the app returns 404 for all API calls.
**Fix:** The `forwardAuthToken: true` property on the destination is required when CAP has XSUAA auth. Also check that the destination name in `xs-app.json` matches exactly.

**Mistake:** HANA service creation fails — "quota exceeded".
**Fix:** BTP trial accounts have limited HANA HDI containers. Delete unused ones in the BTP Cockpit under Services → Instances.

**Mistake:** After redeployment, old data persists when it shouldn't.
**Fix:** The database deployer does not drop and recreate tables by default (to preserve production data). To force a full redeploy of the schema, delete the HDI container instance and recreate it, then redeploy.

---

## ✅ Checkpoint

After `cf deploy`:
1. `cf apps` shows all three apps (`product-app-srv`, `product-app-approuter`, `product-app-ui`) with status **started**.
2. Opening the approuter URL in a browser shows the XSUAA login page (or the app directly if already logged in).
3. After logging in, the product list loads from the HANA database.
4. Creating a new product through the UI persists after a page refresh.
$md$ WHERE slug = '15-deploy-test';

UPDATE public.topics SET content_md = $md$
# Capstone Part 1 — Design Your Data Model

## What you'll build

Design and implement the CDS data model for your own mini-project. By the end of this part you will have a running CAP backend with seeded data that you can query from a browser.

---

## Why design first?

A data model that changes halfway through a project causes cascading rewrites — the service, the UI, the CSV files, the OData bindings. Spending 30 minutes on the model design now saves hours later.

The design process is the same whether you are building a task tracker, an inventory system, or a leave management tool.

---

## How to design a CDS data model

Answer four questions before writing any code:

**1. What are my main entities?**
Things you need to store. Nouns: Product, Order, Employee, Project, Task, Customer.

**2. What are the relationships?**
One-to-many (a Project has many Tasks), many-to-many (a Task can have many Tags).

**3. What properties does each entity need?**
Only the fields you will actually display or filter on. Start minimal.

**4. What is the primary key?**
Use `UUID` for new records (CAP generates it automatically). Use a meaningful `String` key when the ID has business meaning (e.g. product codes like `P001`).

---

## Example: Task Tracker domain

```cds
// db/schema.cds

namespace com.tasker;

entity Projects {
  key ID          : UUID @Core.Computed;
      name        : String(100)  @mandatory;
      description : String(500);
      status      : String(20) default 'Active';
      createdAt   : DateTime @cds.on.insert: $now;
}

entity Tasks {
  key ID          : UUID @Core.Computed;
      title       : String(200)  @mandatory;
      description : String(1000);
      priority    : String(10) default 'Medium';  // Low / Medium / High
      dueDate     : Date;
      completed   : Boolean default false;
      project     : Association to Projects;       // FK: project_ID
      assignee    : String(100);
}
```

**Annotations explained:**
- `@Core.Computed` — CAP generates the UUID value; callers do not provide it.
- `@mandatory` — generates a NOT NULL constraint and an OData required annotation.
- `@cds.on.insert: $now` — CAP fills this with the current timestamp on INSERT.
- `Association to Projects` — creates a `project_ID` FK column automatically.

---

## Your service definition

```cds
// srv/task-service.cds

using com.tasker from '../db/schema';

service TaskService @(path: '/api') {

  entity Projects as projection on com.tasker.Projects
    actions {
      action archive() returns Projects;
    };

  entity Tasks as projection on com.tasker.Tasks;
}
```

The `actions` block lets you add custom business operations (like archiving a project) that go beyond basic CRUD.

---

## Deploy to SQLite and seed test data

```bash
# Create CSV seed files first (see the format below), then:
cds deploy --to sqlite:db/tasker.db
cds watch
```

```
// db/data/com.tasker-Projects.csv
ID,name,description,status
550e8400-e29b-41d4-a716-446655440000,Website Redesign,Redesign the company website,Active
550e8400-e29b-41d4-a716-446655440001,Mobile App,Build the iOS and Android app,Active
```

```
// db/data/com.tasker-Tasks.csv
ID,title,priority,completed,project_ID,assignee
660e8400-e29b-41d4-a716-446655440000,Design wireframes,High,false,550e8400-e29b-41d4-a716-446655440000,Alice
660e8400-e29b-41d4-a716-446655440001,Set up CI/CD pipeline,Medium,false,550e8400-e29b-41d4-a716-446655440000,Bob
660e8400-e29b-41d4-a716-446655440002,Implement login screen,High,false,550e8400-e29b-41d4-a716-446655440001,Alice
```

For UUIDs in test data, use any valid UUID v4. You can generate them at [uuidgenerator.net](https://www.uuidgenerator.net/).

---

## Self-check before continuing

Before moving to Part 2, verify each of these in a browser:

| URL | Expected result |
|---|---|
| `http://localhost:4004/api/Projects` | Returns your seeded projects |
| `http://localhost:4004/api/Tasks` | Returns your seeded tasks |
| `http://localhost:4004/api/Tasks?$expand=project` | Tasks with nested project object |
| `http://localhost:4004/api/Tasks?$filter=completed eq false` | Only incomplete tasks |
| `http://localhost:4004/api/$metadata` | XML describing all entities and associations |

If any of these fail, fix them before building the UI.

---

## Choosing your own domain

If you are building something different from the task tracker example, here are starter models for common domains:

**Inventory / stock management:**
```cds
entity Warehouses { key ID: UUID; name: String; location: String; }
entity Items { key ID: UUID; sku: String; name: String; quantity: Integer; warehouse: Association to Warehouses; }
```

**Leave management:**
```cds
entity Employees { key ID: UUID; name: String; department: String; }
entity LeaveRequests { key ID: UUID; type: String; startDate: Date; endDate: Date; status: String default 'Pending'; employee: Association to Employees; }
```

**Sales orders:**
```cds
entity Customers { key ID: UUID; name: String; email: String; country: String; }
entity Orders { key ID: UUID; orderDate: DateTime @cds.on.insert: $now; total: Decimal; status: String; customer: Association to Customers; }
entity OrderItems { key ID: UUID; product: String; quantity: Integer; price: Decimal; order: Association to Orders; }
```

---

## Common mistakes

**Mistake:** UUID primary keys cause CSV loading to fail.
**Fix:** Make sure every UUID in your CSV is a valid UUID v4 format (8-4-4-4-12 hex characters). Invalid UUIDs cause a silent load failure.

**Mistake:** Association shows as `project_ID` in the API but you expected `project`.
**Fix:** This is correct OData V4 behaviour. The navigation property is `project` (for `$expand=project`) but the stored FK column is `project_ID`. Both exist — use `project_ID` when creating/updating, `project` when expanding.

**Mistake:** `cds deploy` runs but `cds watch` shows empty entities.
**Fix:** Run `cds deploy` from the project root, not from inside `db/`. The path `db/tasker.db` is relative to where you run the command.

---

## ✅ Checkpoint

- CAP is running with `cds watch`.
- All your entities return seeded data via the browser.
- `$expand` works for all associations.
- `$filter` works for at least one property.
$md$ WHERE slug = '16-mp-1-test';

UPDATE public.topics SET content_md = $md$
# Capstone Part 2 — Build the Full UI5 Frontend

## What you'll build

A complete multi-screen UI5 application for your capstone domain: a List view, a Detail/Edit view, and a Create dialog. All screens talk to your Part 1 CAP backend over OData V4.

---

## Your checklist before writing a single line

Answer these before opening a code editor:

1. How many screens do I need? (Usually: List, Detail, maybe a Form)
2. Which entity is the "main" one for each screen?
3. What fields must be visible on the List vs. the Detail?
4. Which fields are editable?
5. Which associations need to be expanded on each screen?

Write these down. A 5-minute design session prevents 50 minutes of refactoring.

---

## Suggested screen structure

For a Task Tracker:

```
List screen (Main.view.xml)
 ├── Shows: task title, priority chip, project name, assignee
 ├── Header: "New Task" button
 ├── Sub-header: SearchField + priority filter
 └── On item press → navigate to Detail

Detail/Edit screen (Detail.view.xml)
 ├── Shows: all task fields
 ├── Edit mode: toggle between read-only display and editable inputs
 ├── Save button → PATCH via OData
 ├── Delete button → DELETE via OData
 └── Back button → navigate to List
```

---

## Routing config template

Copy this routing section into your `manifest.json` and replace `yourapp` with your namespace:

```json
"routing": {
  "config": {
    "routerClass": "sap.m.routing.Router",
    "viewType": "XML",
    "viewPath": "com.yourapp.view",
    "controlId": "app",
    "controlAggregation": "pages",
    "async": true
  },
  "routes": [
    { "name": "list",   "pattern": "",               "target": "list"   },
    { "name": "detail", "pattern": "detail/{taskId}", "target": "detail" }
  ],
  "targets": {
    "list":   { "viewName": "Main",   "viewLevel": 1 },
    "detail": { "viewName": "Detail", "viewLevel": 2 }
  }
}
```

---

## Edit view: create vs edit mode

Reuse one view for both creating a new item and editing an existing one. Use a view model to control the mode:

```js
// Detail.controller.js

onInit: function () {
  // Local view model — controls UI state, not business data
  var oViewModel = new JSONModel({
    editMode:   false,
    isNew:      false,
    pageTitle:  "Task Detail",
    saveEnabled: false
  });
  this.getView().setModel(oViewModel, "view");

  // Attach route handler
  var oRouter = this.getOwnerComponent().getRouter();
  oRouter.getRoute("detail").attachPatternMatched(this._onRouteMatched, this);
},

_onRouteMatched: function (oEvent) {
  var sTaskId = oEvent.getParameter("arguments").taskId;

  if (sTaskId === "new") {
    // CREATE mode
    this.getView().getModel("view").setProperty("/isNew", true);
    this.getView().getModel("view").setProperty("/pageTitle", "New Task");
    this.getView().getModel("view").setProperty("/editMode", true);

    // Create a transient context
    var oBinding = this.getOwnerComponent().getModel()
      .bindList("/Tasks");
    this._oContext = oBinding.create({
      title:      "",
      priority:   "Medium",
      completed:  false
    });
    this.getView().setBindingContext(this._oContext);

  } else {
    // EDIT/VIEW mode — bind to existing task
    this.getView().getModel("view").setProperty("/isNew", false);
    this.getView().getModel("view").setProperty("/pageTitle", "Task Detail");
    this.getView().getModel("view").setProperty("/editMode", false);

    this.getView().bindElement({
      path: "/Tasks(" + sTaskId + ")",
      parameters: { $expand: "project" }
    });
  }
},
```

In the XML view, use `{view>/editMode}` to show/hide controls:

```xml
<!-- Read-only display (visible when not editing) -->
<Text text="{title}" visible="{= !${view>/editMode} }" />

<!-- Editable input (visible when editing) -->
<Input value="{title}" visible="{view>/editMode}" />
```

---

## Value Help on the Project field

```js
onProjectValueHelp: function () {
  if (!this._oProjectDialog) {
    this._oProjectDialog = this.loadFragment({
      name: "com.yourapp.fragments.ProjectDialog"
    });
  }
  Promise.resolve(this._oProjectDialog).then(function (oDialog) {
    this._oProjectDialog = oDialog;
    oDialog.getBinding("items").filter([]);
    oDialog.open();
  }.bind(this));
},

onProjectConfirm: function (oEvent) {
  var oCtx = oEvent.getParameter("selectedItem").getBindingContext();
  this._oContext.setProperty("project_ID", oCtx.getProperty("ID"));
  this._oContext.setProperty("_projectName", oCtx.getProperty("name")); // display only
  oEvent.getSource().getBinding("items").filter([]);
},
```

---

## If you get stuck — which episode to revisit

| Problem | Go back to |
|---|---|
| List does not load data | Episode 7 — OData model setup |
| Navigation between screens fails | Episode 2 — Routing |
| Create/Edit/Delete does not work | Episode 8 — Full-stack CRUD |
| Value help does not load or filter | Episode 9 — Value help with CAP |
| Validation errors not showing | Episode 10 — Validation |
| Search/sort not working | Episode 11 — Filter and sort |

---

## Self-verify before moving to Part 3

| Feature | Works? |
|---|---|
| List loads all items from CAP | ☐ |
| Tapping an item opens the Detail view | ☐ |
| Back button returns to List | ☐ |
| "New" button opens an empty Detail in edit mode | ☐ |
| Filling the form and saving creates a record in the DB | ☐ |
| Editing an existing item and saving updates the DB | ☐ |
| Delete removes the item from the list and the DB | ☐ |
| All bound fields display correct data | ☐ |

---

## Common mistakes

**Mistake:** Create navigates to the detail page but the form is blank and save does nothing.
**Fix:** The transient context must be created on a list binding that is attached to the OData model. Use `this.getOwnerComponent().getModel().bindList("/Tasks")` not a list binding from a view control.

**Mistake:** `bindElement` sets the context but fields show undefined.
**Fix:** The OData key in `bindElement` must match the entity key type. For UUID keys: `/Tasks(550e8400-e29b-41d4-a716-446655440000)`. For integer keys: `/Tasks(1)`. No quotes around UUID or integer.

**Mistake:** Save works for new records but not for edits.
**Fix:** For edits, you need to call `submitBatch("myUpdateGroup")` after `setProperty`. For creates, `oContext.created()` resolves when the server confirms the record.

---

## ✅ Checkpoint

Complete the self-verify checklist above. All seven items must work before moving to Part 3.
$md$ WHERE slug = '17-mp-2-test';

UPDATE public.topics SET content_md = $md$
# Capstone Part 3 — Polish: Validation, Search, and Sort

## What you'll build

Add the finishing touches that make your app feel professional: proper validation with visual error states, a working search bar, sortable columns, confirmation dialogs before destructive actions, an empty state when the list has no results, and a loading indicator.

---

## Polish checklist

Work through these in order — each one builds on the previous:

1. ☐ Validation on all required fields (controller guard + binding types)
2. ☐ CAP backend validation with error messages surfaced in the UI
3. ☐ Confirmation dialog before delete
4. ☐ Search on the list view
5. ☐ Sort on the list view
6. ☐ Empty state message when the list has no results
7. ☐ BusyIndicator while data is loading

---

## Validation pass — add to your Edit view controller

For each required field in your form, add both a visual guard and a binding type:

```js
_validateForm: function () {
  var bValid = true;

  // Check each required input
  var aRequired = [
    { id: "inputTitle",    label: "Title is required" },
    { id: "inputAssignee", label: "Assignee is required" }
  ];

  aRequired.forEach(function (oField) {
    var oInput = this.byId(oField.id);
    if (!oInput.getValue().trim()) {
      oInput.setValueState("Error");
      oInput.setValueStateText(oField.label);
      bValid = false;
    } else {
      oInput.setValueState("Success");
    }
  }.bind(this));

  return bValid;
},

onSavePress: function () {
  if (!this._validateForm()) {
    MessageToast.show("Please fix the highlighted fields");
    return;
  }
  // ... proceed with submitBatch
},
```

---

## Surface CAP errors in the UI

Wrap every `submitBatch` call in a `.catch`:

```js
oModel.submitBatch("saveGroup")
  .then(function () {
    MessageToast.show("Saved successfully");
    this.onNavBack();
  }.bind(this))
  .catch(function (oError) {
    var sMsg = "Save failed";
    try {
      // CAP OData errors are in error.cause.responseText
      var oBody = JSON.parse(oError.cause.responseText);
      sMsg = oBody.error.message || sMsg;
    } catch (e) { /* ignore */ }
    MessageBox.error(sMsg, { title: "Error" });
  });
```

---

## Confirmation before delete

Never delete without asking:

```js
onDeletePress: function () {
  var sItemName = this._oContext.getProperty("title") || "this item";

  MessageBox.confirm(
    "Are you sure you want to delete \"" + sItemName + "\"? This cannot be undone.",
    {
      title: "Confirm Delete",
      emphasizedAction: MessageBox.Action.OK,
      onClose: function (sAction) {
        if (sAction !== MessageBox.Action.OK) { return; }

        this._oContext.delete()
          .then(function () {
            MessageToast.show("Deleted");
            this.onNavBack();
          }.bind(this))
          .catch(function (oErr) {
            MessageBox.error("Delete failed: " + oErr.message);
          });
      }.bind(this)
    }
  );
},
```

---

## Search on the list view

```js
onSearch: function (oEvent) {
  var sQuery   = oEvent.getParameter("query") || oEvent.getParameter("newValue") || "";
  var oBinding = this.byId("mainList").getBinding("items");
  var aFilters = [];

  if (sQuery.trim()) {
    // Replace "title" with the main text field of your entity
    aFilters.push(new Filter("title", FilterOperator.Contains, sQuery.trim()));
  }

  oBinding.filter(aFilters);
},
```

In the view, set both `search` and `liveChange` on the SearchField so it responds to both Enter key and typing:

```xml
<SearchField
  id="searchField"
  search="onSearch"
  liveChange="onSearch"
  placeholder="Search tasks..." />
```

---

## Sort on the list view

Add a sort button in the page header or toolbar. Toggle between ascending and descending on each press:

```js
onSortPress: function () {
  this._bDesc = !this._bDesc;
  var oBinding = this.byId("mainList").getBinding("items");
  // Replace "title" with your sort field (e.g. "dueDate", "priority", "name")
  oBinding.sort(new Sorter("title", this._bDesc));

  this.byId("sortBtn").setIcon(this._bDesc
    ? "sap-icon://sort-descending"
    : "sap-icon://sort-ascending");
},
```

---

## Empty state

Show a helpful message when the filtered list has no results:

```xml
<List id="mainList" items="{/Tasks}" noDataText="No tasks found. Try a different search.">
  ...
</List>
```

For a richer empty state with an icon, use `IllustratedMessage` (requires `sap.f` library):

```xml
<f:IllustratedMessage
  illustrationType="sapIllus-NoData"
  title="No Tasks"
  description="Create your first task by pressing the + button."
  visible="{= ${/Tasks}.length === 0 }"
  xmlns:f="sap.f" />
```

---

## Loading state — BusyIndicator

Show a spinner while the OData request is in flight:

```js
// In onRouteMatched, before bindElement
this.getView().setBusy(true);

this.getView().bindElement({
  path: "/Tasks(" + sId + ")",
  parameters: { $expand: "project" },
  events: {
    dataReceived: function () {
      this.getView().setBusy(false);
    }.bind(this)
  }
});
```

`setBusy(true)` overlays the entire view with a semi-transparent spinner. `setBusy(false)` in the `dataReceived` event removes it.

---

## The finished feel

A polished app does these things automatically — the user never has to wonder:

| Situation | Polished behaviour |
|---|---|
| Saving a record | Busy spinner on button → success toast → navigate back |
| Validation error | Red input border + tooltip → MessageBox explanation |
| Deleting an item | Confirmation dialog → success toast → return to list |
| Empty search result | Friendly empty state with guidance |
| Data still loading | Subtle spinner — never a blank white page |

---

## Common mistakes

**Mistake:** `getParameter("query")` returns undefined.
**Fix:** `SearchField` `search` event uses `"query"`. The `liveChange` event uses `"newValue"`. Handle both: `var s = oEvent.getParameter("query") || oEvent.getParameter("newValue") || ""`.

**Mistake:** BusyIndicator never disappears.
**Fix:** Always call `setBusy(false)` in both `dataReceived` (success) and `dataRequested` error path. Use a `try/finally` pattern or attach to both events.

**Mistake:** Delete confirmation fires twice.
**Fix:** `MessageBox.confirm` callback may be bound twice if `onInit` runs more than once (e.g. view is recreated). Use `detachPatternMatched` and re-attach in `onInit`.

---

## ✅ Checkpoint

Go through the polish checklist at the top of this episode. Every item should have a checkmark before you move to Part 4.

Test these edge cases specifically:
- Try to save with an empty required field → should show error, not save.
- Delete an item → confirm the dialog appears.
- Type a search term that matches nothing → should show empty state, not a blank list.
- Navigate to the detail page → should show a loading spinner while data arrives.
$md$ WHERE slug = '18-mp-3-test';

UPDATE public.topics SET content_md = $md$
# Capstone Part 4 — Secure and Deploy Your App

## What you'll build

Add XSUAA authentication, configure your `mta.yaml` for production deployment, deploy to SAP BTP Cloud Foundry, and verify the live app end-to-end.

---

## Final checklist overview

Before deploying, confirm every item below is ready:

| Item | Status |
|---|---|
| `xs-security.json` defines scopes and role-templates for your domain | ☐ |
| CDS service annotated with `@requires` | ☐ |
| `mta.yaml` covers all four modules (db-deployer, srv, approuter, ui) | ☐ |
| `xs-app.json` routes `/backend/*` to the CAP destination | ☐ |
| UI5 `manifest.json` uses `/backend/api/` (not localhost) | ☐ |
| All CSV seed files have valid UUIDs or integers | ☐ |
| `npm install` runs without errors in every module folder | ☐ |

---

## Step 1 — xs-security.json for your domain

Adapt this template to your entities. Replace `myapp`, `Viewer`, and `Admin` with names that match your domain:

```json
{
  "xsappname": "myapp",
  "tenant-mode": "dedicated",
  "scopes": [
    {
      "name": "$XSAPPNAME.Viewer",
      "description": "Read access"
    },
    {
      "name": "$XSAPPNAME.Editor",
      "description": "Create, update, and delete access"
    }
  ],
  "role-templates": [
    {
      "name": "Viewer",
      "description": "Read-only",
      "scope-references": ["$XSAPPNAME.Viewer"]
    },
    {
      "name": "Editor",
      "description": "Full access",
      "scope-references": [
        "$XSAPPNAME.Viewer",
        "$XSAPPNAME.Editor"
      ]
    }
  ]
}
```

---

## Step 2 — Annotate your CDS service

```cds
// srv/your-service.cds

@requires: 'authenticated-user'
service YourService @(path: '/api') {

  @readonly
  @requires: 'Viewer'
  entity Tasks as projection on com.yourapp.Tasks;

  @requires: 'Editor'
  action createTask(title: String) returns Tasks;
}
```

---

## Step 3 — mta.yaml for your capstone

```yaml
_schema-version: "3.1"
ID: myapp
version: 1.0.0

modules:

  - name: myapp-srv
    type: nodejs
    path: .
    parameters:
      memory: 256M
    build-parameters:
      builder: npm
    requires:
      - name: myapp-db
      - name: myapp-xsuaa
    provides:
      - name: srv-api
        properties:
          srv-url: ${default-url}

  - name: myapp-db-deployer
    type: hdb
    path: gen/db
    requires:
      - name: myapp-db

  - name: myapp-approuter
    type: approuter.nodejs
    path: approuter
    parameters:
      memory: 128M
    requires:
      - name: myapp-xsuaa
      - name: myapp-html5-repo-runtime
      - name: srv-api
        group: destinations
        properties:
          name: cap-backend
          url: ~{srv-url}
          forwardAuthToken: true

  - name: myapp-ui
    type: html5
    path: webapp
    build-parameters:
      build-result: dist
      builder: custom
      commands:
        - npm install
        - npm run build

resources:

  - name: myapp-db
    type: com.sap.xs.hdi-container
    parameters:
      service: hana
      service-plan: hdi-shared

  - name: myapp-xsuaa
    type: org.cloudfoundry.managed-service
    parameters:
      service: xsuaa
      service-plan: application
      config:
        xsappname: myapp
        tenant-mode: dedicated
        path: xs-security.json

  - name: myapp-html5-repo-runtime
    type: org.cloudfoundry.managed-service
    parameters:
      service: html5-apps-repo
      service-plan: app-runtime
```

---

## Step 4 — Build

```bash
# Build all modules into the .mtar archive
mbt build

# Expected output:
# INFO Cloud MTA Build Tool version ...
# INFO Generating "META-INF/mtad.yaml"...
# INFO Building module "myapp-srv"...
# INFO Building module "myapp-ui"...
# INFO Generating MTA archive...
# INFO Done packaging MTA project!
```

If `mbt build` fails, the error message names the failing module. Fix that module's `npm install` or build script first.

---

## Step 5 — Build and deploy

```bash
# Log in (if not already logged in)
cf login -a https://api.cf.eu10.hana.ondemand.com

# Deploy
cf deploy mta_archives/myapp_1.0.0.mtar --strategy rolling

# Watch progress
cf apps
```

The `--strategy rolling` flag deploys the new version alongside the old one and switches traffic only after the new one is healthy. Safer than the default stop-start for production.

---

## Step 6 — Post-deployment: create the destination

After `cf deploy`:
1. Go to **BTP Cockpit → Connectivity → Destinations**.
2. Create a destination named `cap-backend` (or verify it was auto-created by the MTA).
3. Set the URL to the CAP service URL shown in `cf apps` under `myapp-srv`.
4. Authentication: `No Authentication` for now (the approuter handles auth via token exchange).

---

## Step 7 — Assign yourself a role collection

After deployment you will get a 403 even as the logged-in user until you assign yourself a role:

1. Go to **BTP Cockpit → Security → Role Collections**.
2. Find the role collection for `Editor` (created automatically from `xs-security.json`).
3. Click it → **Users** tab → **Assign User** → enter your BTP email.

Wait 1-2 minutes for the assignment to propagate, then log out and back in.

---

## Verifying the live app end-to-end

```bash
# Check all apps are running
cf apps
# All should show "started"

# Tail the logs if something is wrong
cf logs myapp-srv --recent

# Confirm the CAP API is reachable (replace with your actual URL)
curl https://myapp-srv.cfapps.eu10.hana.ondemand.com/api/Tasks
```

Open the approuter URL in a browser. You should see the XSUAA login page. Log in with your BTP credentials. The app loads and shows your seeded tasks.

---

## What you've learned across this course

| Episodes | Skills gained |
|---|---|
| 1–4 | SAPUI5 components, views, models, routing, fragments |
| 5–6 | CAP data modelling, OData generation, SQLite persistence |
| 7–9 | Connecting UI5 to CAP, full-stack CRUD, server-side value help |
| 10–11 | Validation, search, filter, sort |
| 12–15 | XSUAA auth, destinations, approuter, Cloud Foundry deployment |
| 16–19 | Design, build, polish, and deploy a complete app from scratch |

You now have a working deployed SAP BTP application with a real HANA database, secured by XSUAA, built on the modern CAP + UI5 stack used in production SAP projects.

---

## Common mistakes

**Mistake:** `cf deploy` succeeds but opening the app URL shows a blank page.
**Fix:** Check `cf logs myapp-approuter --recent`. A common cause is a misconfigured `xs-app.json` route — the `service: html5-apps-repo-rt` route must match the HTML5 app technical name.

**Mistake:** Role collection exists but access is still denied after assigning it.
**Fix:** Log out and log back in to get a new JWT token that includes the new scopes. Tokens are cached for their full lifetime.

**Mistake:** HANA database deployer fails with "quota exceeded".
**Fix:** Delete unused HDI container instances in BTP Cockpit → Services → Instances. Trial accounts are limited to a small number.

**Mistake:** App works in dev but gives 404 for `/backend/api/Tasks` in production.
**Fix:** Verify the destination `cap-backend` in BTP Cockpit points to the correct `myapp-srv` URL. Check for trailing slashes — `https://host.com/api/` with a trailing slash in the manifest but without one in the destination causes 404.

---

## ✅ Final Checkpoint

- [ ] Open the approuter URL in a browser — XSUAA login page appears.
- [ ] Log in — the app loads and shows your data.
- [ ] Create a new record — it persists after a page refresh.
- [ ] Edit a record — changes survive a refresh.
- [ ] Delete a record — it is gone after refresh.
- [ ] Log in with a Viewer-only account — write operations return 403.
- [ ] `cf apps` shows all four modules as **started**.
$md$ WHERE slug = '19-mp-4-test';

UPDATE public.topics SET content_md = $md$
# Real-World Problems: 40 Issues Every SAP BTP Developer Faces

## About this topic

Every problem below was reported by real developers building on the SAP BTP stack. Each entry shows the exact symptom you see, why it happens, and the exact fix. Bookmark this page — you will hit at least 20 of these.

---

## Category 1 — SAPUI5 Binding and Model Problems

---

### Problem 1: List shows no data — binding is correct but list is empty

**Symptom:** You write `items="{/products}"`, the model is loaded, but the list renders zero items.

**Why it happens:** The most common cause is a missing leading slash. `{products}` is a relative path and resolves to nothing at the root level.

**Fix:**
```xml
<!-- Wrong -->
<List items="{products}">

<!-- Correct -->
<List items="{/products}">
```
Second check: open the browser Network tab. If the JSON request returned 200 but the array key is different from what you bound to (e.g. data is in `"items"` but you bound to `"/products"`), the list is also empty.

---

### Problem 2: Two-way binding does not update the model

**Symptom:** User types in an `Input` field but `oModel.getProperty("/name")` still returns the old value.

**Why it happens:** Default binding mode for `JSONModel` is `TwoWay`, but for `ODataModel V4` the default is `OneWay`.

**Fix for JSONModel:**
```js
// Explicitly set mode (usually not needed, JSONModel defaults to TwoWay)
var oModel = new JSONModel(data);
oModel.setDefaultBindingMode("TwoWay");
this.getView().setModel(oModel);
```
**Fix for ODataModel V4:** Use `setProperty` on the context to stage the change, then `submitBatch` to send it. Two-way automatic binding is not how V4 works.

---

### Problem 3: `{i18n>title}` shows the key instead of the translated text

**Symptom:** The page shows literal text `{i18n>title}` instead of "My App Title".

**Why it happens:** The i18n model is not registered or the properties file path is wrong.

**Fix:** In `manifest.json`:
```json
"sap.ui5": {
  "models": {
    "i18n": {
      "type": "sap.ui.model.resource.ResourceModel",
      "settings": {
        "bundleName": "sap.ui.demo.ss.i18n.i18n"
      }
    }
  }
}
```
The bundle name `sap.ui.demo.ss.i18n.i18n` maps to `webapp/i18n/i18n.properties`. The last `i18n` is the filename without the extension.

---

### Problem 4: `bindElement` renders blank — all fields show empty

**Symptom:** You call `oView.bindElement("/Products(1)")` but every `{name}`, `{price}` etc. shows nothing.

**Why it happens:** Either the path does not exist in the model, or for OData the data has not arrived yet when you try to read it.

**Fix:** Add the `dataReceived` event handler to check for errors:
```js
this.getView().bindElement({
  path: "/Products(1)",
  events: {
    dataReceived: function (oEvent) {
      var oData = oEvent.getParameter("data");
      if (!oData) {
        console.error("bindElement failed:", oEvent.getParameter("error"));
      }
    }
  }
});
```
For OData, also confirm the entity key format matches: integer key → `/Products(1)`, UUID key → `/Products(550e8400-e29b-41d4-a716-446655440000)`.

---

### Problem 5: Navigation to detail works but back button shows a blank page

**Symptom:** Tapping an item navigates to the detail view. Pressing the back button returns to the list, but the list is now empty.

**Why it happens:** The router placed the detail view into the App control's `pages` aggregation but did not re-render the list page because it was destroyed (happens when `clearHistory: true` or the page is not cached).

**Fix:** Set `viewCacheKey` in the route target in `manifest.json` to cache the view, or use `History` correctly:
```js
onNavBack: function () {
  var sHash = History.getInstance().getPreviousHash();
  if (sHash !== undefined) {
    window.history.go(-1);
  } else {
    // No history — navigate explicitly to list
    this.getOwnerComponent().getRouter().navTo("list", {}, true);
    // true = replace current URL, prevents adding to history
  }
}
```

---

## Category 2 — SAPUI5 Routing Problems

---

### Problem 6: Route pattern matched but `arguments` is undefined

**Symptom:** `oEvent.getParameter("arguments").productId` throws "Cannot read properties of undefined".

**Why it happens:** The route pattern in `manifest.json` uses `{productId}` but the `navTo` call passes a different key name.

**Fix:**
```json
// manifest.json route
{ "pattern": "detail/{productId}", "name": "detail" }
```
```js
// Controller navTo — key must EXACTLY match the pattern parameter name
this.getOwnerComponent().getRouter().navTo("detail", {
  productId: "P001"   // must be "productId", not "id" or "product_id"
});
```

---

### Problem 7: Router initialized but navigation never happens — URL does not change

**Symptom:** `navTo` is called, no error in console, but the view does not change and the URL hash stays the same.

**Why it happens:** `this.getOwnerComponent().getRouter().initialize()` was never called in `Component.js`.

**Fix:**
```js
// Component.js — init() MUST call initialize()
init: function () {
  UIComponent.prototype.init.apply(this, arguments);
  // ...models...
  this.getRouter().initialize(); // ← without this, router does nothing
}
```

---

### Problem 8: Navigating between the same route twice does not refresh the view

**Symptom:** User is on `/detail/P001`, taps back, then taps a different item. The detail page still shows P001 data.

**Why it happens:** `onInit` runs only once. The view is reused. The route matched handler is the correct place for data loading, but it was not wired up.

**Fix:** Use `attachPatternMatched`, not `onInit`, for all data-loading on routed views:
```js
onInit: function () {
  this.getOwnerComponent().getRouter()
    .getRoute("detail")
    .attachPatternMatched(this._onRouteMatched, this);
},
_onRouteMatched: function (oEvent) {
  var sId = oEvent.getParameter("arguments").productId;
  // load data for sId every time route is activated
}
```

---

## Category 3 — CAP Backend Problems

---

### Problem 9: `cds watch` shows no error but `/api/Products` returns 404

**Symptom:** Terminal shows "serving ProductService { path: '/api' }" but the browser gets 404.

**Why it happens:** The CDS service path ends with `/api` but you are calling `/api/Products` — this is correct. If it returns 404 the entity name is wrong.

**Fix:** OData entity names are PascalCase and match the CDS entity definition exactly. If your entity is `Products`, the URL is `/api/Products` not `/api/products`.

---

### Problem 10: CSV data does not load — `cds deploy` shows no "filling" lines

**Symptom:** Running `cds deploy` shows no output like "filling com.demo.Products from ...".

**Why it happens:** CSV filename does not match the entity's full name including namespace.

**Fix:** The filename must be `<namespace>-<EntityName>.csv`. If your CDS file says `namespace com.demo` and entity `Products`, the file must be `com.demo-Products.csv` — not `Products.csv` or `products.csv`.

---

### Problem 11: CAP returns 400 but `req.error()` is called with status 400

**Symptom:** You call `req.error(400, "Name is required")` but the HTTP response body is empty or shows a different message.

**Why it happens:** `req.error()` accumulates errors — it does not throw immediately. If your handler code continues after `req.error()` and makes an invalid operation, a different error may overwrite yours.

**Fix:**
```js
this.before('CREATE', 'Products', (req) => {
  if (!req.data.name) {
    req.error(400, 'Name is required');
    return; // ← must return explicitly, req.error does NOT stop execution
  }
  // More validation...
});
```

---

### Problem 12: SQLite schema changes break the server — "no such column" error

**Symptom:** You add a new field to a CDS entity and restart `cds watch`. The server crashes with "no such column: newField".

**Why it happens:** SQLite does not automatically migrate the existing `.db` file when the schema changes.

**Fix:**
```bash
# Delete the old database file
rm db/demo.db

# Redeploy the schema and seed data
cds deploy --to sqlite:db/demo.db

# Then restart
cds watch
```
In production (HANA), CAP's HDI deployer handles migrations automatically.

---

### Problem 13: `$expand` returns null instead of the nested object

**Symptom:** `/api/Products?$expand=category` returns `{ "category": null }` for some products.

**Why it happens:** The `category_ID` foreign key value in those rows does not match any ID in the Categories table.

**Fix:** Check your CSV data. Every `category_ID` in `Products.csv` must exist as a `ID` in `Categories.csv`. Fix the CSV and run `cds deploy` again.

---

### Problem 14: CAP auto-generated CRUD gives 405 Method Not Allowed on DELETE

**Symptom:** Your service exposes `entity Products`, but `DELETE /api/Products(1)` returns 405.

**Why it happens:** The service was annotated with `@readonly` somewhere, or the entity is defined as read-only in the projection.

**Fix:** Check your `.cds` service file:
```cds
// Wrong — @readonly blocks all write operations
@readonly
entity Products as projection on com.demo.Products;

// Correct — no @readonly if you want full CRUD
entity Products as projection on com.demo.Products;
```

---

## Category 4 — OData V4 Model Problems

---

### Problem 15: `submitBatch` resolves but the record is NOT saved

**Symptom:** `submitBatch("myGroup")` resolves the Promise with no error, but refreshing the page shows the old data.

**Why it happens:** The `setProperty` call targeted a path that is not part of the `updateGroupId` batch group, or the model was created with `groupId: "$direct"` which sends each change immediately (not via batch).

**Fix:** Ensure your `setProperty` uses the same group the model is configured for:
```js
// In the model declaration in manifest.json
"settings": {
  "updateGroupId": "myUpdateGroup"
}
// In the controller
oModel.setProperty(sPath + "/name", sValue, undefined, true);
// 4th argument true = use the model's updateGroupId
oModel.submitBatch("myUpdateGroup");
```

---

### Problem 16: List binding `create()` throws "Not implemented"

**Symptom:** `oBinding.create({...})` throws a "Not implemented" or "Method not supported" error.

**Why it happens:** The binding is an OData V2 binding (`sap.ui.model.odata.v2.ODataModel`), which does not support `binding.create()`. V2 uses `oModel.createEntry()`.

**Fix:** Verify you are using OData V4 in your manifest:
```json
"settings": {
  "odataVersion": "4.0"
}
```
The model class should be `sap.ui.model.odata.v4.ODataModel`, not V2.

---

### Problem 17: OData request goes to the wrong URL — shows `undefined/api/Products`

**Symptom:** Network tab shows the request URL as `undefined/api/Products` or `null/api/Products`.

**Why it happens:** The `dataSource.uri` in `manifest.json` is missing or the service URL was left empty.

**Fix:**
```json
"dataSources": {
  "mainService": {
    "uri": "/api/",
    "type": "OData",
    "settings": { "odataVersion": "4.0" }
  }
}
```
The `uri` must start with `/` (relative to the host). The dev proxy in `ui5.yaml` then maps `/api/` to `http://localhost:4004/api/`.

---

## Category 5 — CORS and Proxy Problems

---

### Problem 18: CORS error in the browser — "No 'Access-Control-Allow-Origin' header"

**Symptom:** Console shows `Cross-Origin Request Blocked: The Same Origin Policy disallows reading the remote resource at http://localhost:4004/api/Products`.

**Why it happens:** The UI5 dev server (port 8080 or 5173) calls the CAP server (port 4004) directly. Browsers block this cross-origin request.

**Fix:** Add the proxy middleware to `ui5.yaml`:
```yaml
server:
  customMiddleware:
    - name: ui5-middleware-simpleproxy
      afterMiddleware: compression
      mountPath: /api
      configuration:
        baseUri: http://localhost:4004/api
```
Install it: `npm install --save-dev ui5-middleware-simpleproxy`. Now the browser calls `/api/...` on the same port, and the proxy forwards it to CAP.

---

### Problem 19: Proxy is set up but still getting CORS errors after deployment

**Symptom:** Works locally with the proxy. After `cf deploy`, the app gets CORS errors.

**Why it happens:** The `ui5.yaml` proxy only works in local development (`npm start`). In production, the approuter handles routing. If the approuter is not configured, the CORS issue returns.

**Fix:** Make sure `xs-app.json` has a route for `/backend/*` pointing to the `cap-backend` destination, and the destination has the correct URL set in BTP Cockpit.

---

## Category 6 — Authentication and XSUAA Problems

---

### Problem 20: Login succeeds but the app shows 403 Forbidden

**Symptom:** XSUAA login works (redirects back to the app), but every API call returns 403.

**Why it happens:** The logged-in user's BTP account has not been assigned the required role collection.

**Fix:**
1. Go to BTP Cockpit → Security → Role Collections.
2. Find the role collection for your app (e.g. "ProductAdmin").
3. Click it → Users tab → Assign User → enter the BTP email address.
4. Log out and log back in (the JWT token needs to be refreshed to include the new roles).

---

### Problem 21: Dev space works but production returns 401 for all API calls

**Symptom:** Local dev with `cds watch` works fine. After deploying, all API calls return 401.

**Why it happens:** The approuter is not forwarding the JWT token to the CAP service. The `forwardAuthToken: true` property is missing on the destination.

**Fix:** In `mta.yaml`, the approuter's destination binding must have `forwardAuthToken: true`:
```yaml
- name: myapp-approuter
  requires:
    - name: srv-api
      group: destinations
      properties:
        name: cap-backend
        url: ~{srv-url}
        forwardAuthToken: true   # ← this line is critical
```

---

### Problem 22: After adding `@requires` to a CDS service, local development breaks completely

**Symptom:** You add `@requires: 'authenticated-user'` to your service. Now every local `cds watch` request returns 401.

**Why it happens:** The mocked auth is not configured, so CAP requires a real token even locally.

**Fix:** Add a `.cdsrc.json` with mock users:
```json
{
  "requires": {
    "auth": {
      "kind": "mocked",
      "users": {
        "alice": { "roles": ["ProductViewer", "ProductAdmin"] }
      }
    }
  }
}
```
Then use Basic auth in your requests: `curl -u alice:alice http://localhost:4004/api/Products`.

---

## Category 7 — Deployment Problems

---

### Problem 23: `mbt build` fails with "Cannot find module"

**Symptom:** Running `mbt build` exits with a Node "Cannot find module" error.

**Why it happens:** `npm install` was not run in one of the module subfolders (e.g. `approuter/`).

**Fix:**
```bash
npm install              # root
cd approuter && npm install && cd ..
cd webapp && npm install && cd ..
mbt build
```

---

### Problem 24: `cf deploy` succeeds but the app URL returns 502 Bad Gateway

**Symptom:** All modules show as "started" in `cf apps` but opening the approuter URL gives 502.

**Why it happens:** The CAP service started but crashed immediately after. The approuter cannot reach it.

**Fix:**
```bash
cf logs myapp-srv --recent
```
Read the CAP startup logs. Common causes:
- HANA HDI container not fully provisioned yet (wait 2 minutes, retry).
- A missing environment binding (check `cf env myapp-srv`).
- A code error in the service's `server.js` or event handlers.

---

### Problem 25: Data is missing after deployment — HANA tables are empty

**Symptom:** The app deploys and runs, but the product list is empty — seed data is not there.

**Why it happens:** The HDI deployer module ran before the HANA service was fully provisioned, or the CSV files were not included in the `gen/db` artifact.

**Fix:**
```bash
# Rebuild the db artifacts
cds build --production

# Check that gen/db/data/ contains your CSV files
ls gen/db/data/

# Redeploy just the db deployer module
cf deploy mta_archives/myapp_1.0.0.mtar --strategy rolling -m myapp-db-deployer
```

---

### Problem 26: Deployment fails with "quota exceeded" for HANA service

**Symptom:** `cf deploy` fails with "Service broker error: quota exceeded" when creating the HANA HDI container.

**Why it happens:** BTP trial accounts have a strict limit on the number of HANA HDI containers (typically 1).

**Fix:**
1. Go to BTP Cockpit → Services → Instances.
2. Delete any unused HDI container instances from previous projects.
3. Retry the deployment.

---

### Problem 27: App redirects in a login loop and never loads

**Symptom:** The app URL redirects to XSUAA login, login succeeds, then redirects back to the app, which immediately redirects to login again — infinite loop.

**Why it happens:** The XSUAA service's `redirect-uris` does not include the approuter URL.

**Fix:** In `xs-security.json`, add the approuter URL to the redirect URIs:
```json
{
  "oauth2-configuration": {
    "redirect-uris": [
      "https://myapp-approuter.cfapps.eu10.hana.ondemand.com/**"
    ]
  }
}
```
Redeploy after this change. The `**` wildcard allows any path under the domain.

---

## Category 8 — BAS (Business Application Studio) Problems

---

### Problem 28: BAS dev space is "STOPPED" and files appear to be gone

**Symptom:** You open BAS the next morning and the dev space shows "STOPPED". Clicking it starts it, but the file explorer seems empty.

**Why it happens:** BTP trial dev spaces auto-stop after 30-60 minutes of inactivity. Files are preserved — the space just needs to be restarted.

**Fix:** Click the ▶ play button next to the dev space name. Wait about 60 seconds. Your files are exactly where you left them. If the file tree still appears empty, press F5 to reload BAS.

---

### Problem 29: BAS terminal shows "npm: command not found"

**Symptom:** Opening a new terminal in BAS and typing `npm --version` returns "command not found".

**Why it happens:** The dev space is a "Basic" kind, not "SAP Fiori" kind. Basic dev spaces do not pre-install Node.js.

**Fix:** Delete the dev space and create a new one with kind **SAP Fiori**. This pre-installs Node.js, npm, the UI5 CLI, and the CAP CLI.

---

### Problem 30: `npm start` in BAS shows no preview — browser tab does not open

**Symptom:** `npm start` runs `ui5 serve` without errors but the "Open in New Tab" popup never appears.

**Why it happens:** The port mapping for the dev server did not register in BAS.

**Fix:** After `npm start`, look at the bottom status bar in BAS for a port indicator, or go to the **Ports** panel (View → Ports). Find the port (default 8080 for UI5), hover over it, and click the Globe icon to open it in a new tab.

---

### Problem 31: CDS language support shows red underlines but `cds watch` works fine

**Symptom:** BAS shows red squiggles under valid CDS syntax (entity definitions, annotations).

**Why it happens:** The CDS Language Support extension is not installed in this dev space.

**Fix:** In BAS, open the Extensions panel (Ctrl+Shift+X), search for "SAP CDS Language Support", and install it. Reload BAS after installation.

---

## Category 9 — UI5 Fragment and Dialog Problems

---

### Problem 32: Dialog opens with stale data the second time

**Symptom:** Dialog shows correct data the first time. After closing and reopening for a different item, it still shows the first item's data.

**Why it happens:** The dialog model is only set once. When you reopen the dialog, the old model is still there.

**Fix:** Set the model fresh every time the dialog opens:
```js
_openDialog: function (oNewModel) {
  Promise.resolve(this._oDialog).then(function (oDialog) {
    oDialog.setModel(oNewModel, "dialog"); // ← called every open, not just once
    oDialog.open();
  }.bind(this));
}
```

---

### Problem 33: `this.loadFragment` is not a function

**Symptom:** Controller throws "TypeError: this.loadFragment is not a function".

**Why it happens:** You are using UI5 version older than 1.93.

**Fix:** Use the old API as a fallback:
```js
// Old way (works on all versions)
this._oDialog = sap.ui.xmlfragment(
  this.getView().getId(),
  "com.myapp.fragments.MyDialog",
  this
);
this.getView().addDependent(this._oDialog);
this._oDialog.open();
```
Or update your UI5 version in `index.html` to 1.120+.

---

### Problem 34: Fragment loads but none of the button press handlers fire

**Symptom:** Dialog opens, buttons are visible, but clicking them does nothing — no errors, no function called.

**Why it happens:** The fragment was loaded without passing `this` (the controller) as the controller argument.

**Fix:**
```js
// Wrong — no controller context
sap.ui.xmlfragment("com.myapp.fragments.MyDialog");

// Correct — pass the controller as third argument
sap.ui.xmlfragment(
  this.getView().getId(),
  "com.myapp.fragments.MyDialog",
  this   // ← controller context
);
```
With `this.loadFragment`, the controller is always `this` automatically — no extra argument needed.

---

## Category 10 — Performance and Network Problems

---

### Problem 35: OData request returns all fields but the UI only uses two — network is slow

**Symptom:** `/api/Products` returns 50 fields per record but your list only shows `name` and `price`. Page is slow.

**Why it happens:** No `$select` is specified, so OData returns everything.

**Fix:** Add `$select` to the list binding:
```xml
<List items="{
  path: '/Products',
  parameters: {
    $select: 'ID,name,price'
  }
}">
```
This sends `GET /api/Products?$select=ID,name,price` — a fraction of the data.

---

### Problem 36: Scrolling the list makes dozens of HTTP requests

**Symptom:** Opening a product list triggers one request. Scrolling down triggers one request per row.

**Why it happens:** Lazy loading (`GrowingList` or `Table` with `growing="true"`) is enabled and the page size is set to 1 (or the threshold is very small).

**Fix:** Set a reasonable page size:
```xml
<List growing="true" growingThreshold="25">
```
This loads 25 items at a time, not 1. The default is 20 if you do not specify.

---

### Problem 37: App takes 10 seconds to load on first open

**Symptom:** The app loads instantly during development but takes 10+ seconds in production.

**Why it happens:** All UI5 resources are loaded individually in development mode. Production requires a build step to bundle them.

**Fix:**
```bash
# Build the UI5 app for production (bundles all JS/CSS into fewer files)
ui5 build --all

# Or via npm
npm run build
```
The `dist/` folder contains the optimized bundle. In `mta.yaml`, deploy from `dist/` not `webapp/`.

---

### Problem 38: Filter request returns all items — `$filter` is ignored by CAP

**Symptom:** Sending `/api/Products?$filter=contains(name,'lap')` returns all products unfiltered.

**Why it happens:** The service or entity is annotated with `@cds.query.limit` or `@cds.search` but the OData filter is being applied to the wrong field path.

**Fix:** Check the field name in the filter matches the CDS entity field name exactly (case-sensitive). `name` is different from `Name`. Also verify your CAP version supports the `contains()` OData function (requires CAP 6+).

---

## Category 11 — Data and Type Problems

---

### Problem 39: Price saves as a string `"29"` instead of number `29`

**Symptom:** After creating a product, the database stores `"29"` (string) for the price field instead of `29` (number). Sorting by price gives wrong results.

**Why it happens:** HTML input values are always strings. If you read the value with `getProperty()` or `getValue()` and pass it directly to the model without parsing, it stays a string.

**Fix:**
```js
// Wrong
req.data.price = this.byId("inputPrice").getValue();

// Correct
req.data.price = parseFloat(this.byId("inputPrice").getValue()) || 0;
```

---

### Problem 40: UUID primary keys cause "Cannot create record — key conflict" on second deploy

**Symptom:** After a schema redeploy, inserting records fails with a unique constraint violation.

**Why it happens:** Your CSV seed data uses hardcoded UUIDs. When you redeploy, CAP tries to insert the same UUIDs again. If the HDI deployer is configured to merge (not replace) data, duplicates fail.

**Fix Option 1:** Use integer keys for seed data (simpler, no UUID format required).

**Fix Option 2:** Add `--dry-run` to your deploy command to check what will happen before it runs.

**Fix Option 3:** For the HDI deployer in production, configure `undeploy.json` to drop and re-create the data on each deploy:
```json
["com.demo::Products"]
```
This tells HDI to delete and reseed the `Products` data on every deployment. Only use this for reference/lookup data, never for user-generated records.

---

## Quick troubleshooting lookup

| Symptom | Most likely cause | Jump to |
|---|---|---|
| List shows no items | Wrong binding path (missing `/`) | Problem 1 |
| Two-way binding not working | ODataModel V4 does not auto-sync | Problem 2 |
| i18n shows key text | i18n model not declared in manifest | Problem 3 |
| bindElement renders blank | Path wrong or data not arrived yet | Problem 4 |
| Back button shows blank page | View destroyed, not cached | Problem 5 |
| Route arguments undefined | navTo key != pattern parameter | Problem 6 |
| navTo does nothing | Router not initialized | Problem 7 |
| Detail shows wrong record | Using onInit instead of attachPatternMatched | Problem 8 |
| 404 on valid OData URL | Wrong entity case (Products vs products) | Problem 9 |
| CSV not loaded | Wrong filename format | Problem 10 |
| req.error continues execution | Forgot `return` after req.error | Problem 11 |
| "no such column" error | Schema changed, forgot cds deploy | Problem 12 |
| $expand returns null | FK value not found in parent table | Problem 13 |
| 405 on DELETE | @readonly annotation on entity | Problem 14 |
| submitBatch resolves but no save | Wrong updateGroupId | Problem 15 |
| oBinding.create throws | Using OData V2 not V4 | Problem 16 |
| URL shows undefined/api/... | dataSource uri missing in manifest | Problem 17 |
| CORS error in browser | Proxy not configured in ui5.yaml | Problem 18 |
| CORS in production | Approuter routes not configured | Problem 19 |
| 403 after login | Role collection not assigned to user | Problem 20 |
| 401 in production | forwardAuthToken missing | Problem 21 |
| Local dev 401 after @requires | Mocked auth not configured | Problem 22 |
| mbt build "Cannot find module" | npm install not run in subfolder | Problem 23 |
| 502 after deploy | CAP service crashed — check cf logs | Problem 24 |
| HANA tables empty | HDI deployer ran before HANA ready | Problem 25 |
| "quota exceeded" on deploy | Delete unused HDI container instances | Problem 26 |
| Infinite login redirect loop | XSUAA redirect-uris not set | Problem 27 |
| BAS dev space looks empty | Auto-stopped — restart it | Problem 28 |
| npm not found in BAS | Wrong dev space kind (needs SAP Fiori) | Problem 29 |
| Preview tab does not open | Open manually via Ports panel | Problem 30 |
| CDS red underlines | CDS Language Support not installed | Problem 31 |
| Dialog shows stale data | Model not reset on open | Problem 32 |
| loadFragment not a function | UI5 version < 1.93 | Problem 33 |
| Fragment buttons do nothing | Controller not passed to xmlfragment | Problem 34 |
| Slow network, too many fields | Missing $select on list binding | Problem 35 |
| Scroll triggers many requests | growingThreshold too small | Problem 36 |
| Slow production load | App not built (npm run build) | Problem 37 |
| $filter ignored | Field name case mismatch | Problem 38 |
| Price saves as string | Missing parseFloat() | Problem 39 |
| UUID key conflict on redeploy | Duplicate UUIDs in CSV | Problem 40 |
$md$ WHERE slug = '20-rtp-test';
