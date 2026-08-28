-- Expanded content for all 19 topics
-- Run in Supabase SQL editor

-- ─────────────────────────────────────────────
-- 1-SS-Test  Single Screen
-- ─────────────────────────────────────────────
update public.topics set content_md = $md$
## Single Screen App — Your First SAPUI5 Page

This is where everything starts. Before routing, before backends, before OData — you need to understand how UI5 boots, how it finds your view, and why data binding works the way it does.

---

### Why this matters

Every SAPUI5 application you ever build — no matter how complex — starts with exactly this: a Component, a View, and a Model. Get this mental model right now and every later topic clicks into place.

---

### How UI5 boots (the sequence)

```
index.html loads the UI5 bootstrap script
  → UI5 reads Component.js
    → Component.js sets up models and the root view
      → App.view.xml renders the outer shell
        → Main.view.xml renders your actual content
```

Nothing magical. Just a chain of lookups based on naming conventions.

---

### Project structure

```
webapp/
├── controller/
│   └── Main.controller.js    ← your JS logic
├── view/
│   └── Main.view.xml         ← your UI
├── model/
│   └── data.json             ← local test data
├── Component.js              ← app entry point
├── index.html                ← bootstrap page
└── manifest.json             ← app descriptor
```

---

### Step 1 — index.html

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Hello UI5</title>
  <script id="sap-ui-bootstrap"
    src="https://ui5.sap.com/resources/sap-ui-core.js"
    data-sap-ui-theme="sap_horizon"
    data-sap-ui-libs="sap.m"
    data-sap-ui-resourceroots='{"sap.ui.demo.hello": "./"}'
    data-sap-ui-oninit="module:sap/ui/core/ComponentSupport"
    data-sap-ui-compatVersion="edge"
    data-sap-ui-async="true">
  </script>
</head>
<body class="sapUiBody">
  <div data-sap-ui-component
       data-name="sap.ui.demo.hello"
       data-settings='{"id" : "helloApp"}'
       style="height: 100%">
  </div>
</body>
</html>
```

**Key lines to understand:**
- `data-sap-ui-resourceroots` — tells UI5 that the namespace `sap.ui.demo.hello` maps to `./` (your webapp folder)
- `data-sap-ui-oninit="module:sap/ui/core/ComponentSupport"` — tells UI5 to look for `data-sap-ui-component` divs and boot them automatically
- `data-sap-ui-async="true"` — loads everything asynchronously; always use this

---

### Step 2 — Component.js

```js
sap.ui.define([
    "sap/ui/core/UIComponent",
    "sap/ui/model/json/JSONModel"
], function(UIComponent, JSONModel) {
    "use strict";

    return UIComponent.extend("sap.ui.demo.hello.Component", {
        metadata: {
            manifest: "json"   // reads manifest.json automatically
        },

        init: function() {
            // ALWAYS call the parent init first
            UIComponent.prototype.init.apply(this, arguments);

            // Create a local JSON model from your data file
            var oModel = new JSONModel("model/data.json");
            this.setModel(oModel);
        }
    });
});
```

**Why `manifest: "json"`?**
This one line tells UI5 to read `manifest.json` for the root view, routing config, and data sources. Without it you'd have to declare everything in JS.

---

### Step 3 — manifest.json (the parts that matter now)

```json
{
    "_version": "1.58.0",
    "sap.app": {
        "id": "sap.ui.demo.hello",
        "type": "application"
    },
    "sap.ui5": {
        "rootView": {
            "viewName": "sap.ui.demo.hello.view.App",
            "type": "XML",
            "id": "app"
        }
    }
}
```

`rootView` is the first view UI5 renders. In simple apps this is your main view directly. In multi-screen apps it becomes a shell that holds a page container.

---

### Step 4 — Main.view.xml

```xml
<mvc:View
    controllerName="sap.ui.demo.hello.controller.Main"
    xmlns:mvc="sap.ui.core.mvc"
    xmlns="sap.m">

    <Page title="My Greetings">
        <content>
            <List items="{/Greetings}">
                <items>
                    <StandardListItem title="{message}" />
                </items>
            </List>
        </content>
    </Page>

</mvc:View>
```

**Binding explained:**
- `items="{/Greetings}"` — bind the list to the array at path `/Greetings` in the default model
- `title="{message}"` — for each item, bind the title to the `message` property

The `/` at the start of `/Greetings` means "root of the model". Without it UI5 looks for a relative path.

---

### Step 5 — data.json

```json
{
    "Greetings": [
        { "ID": 1, "message": "Hello from UI5" },
        { "ID": 2, "message": "Data binding works" },
        { "ID": 3, "message": "No backend needed yet" }
    ]
}
```

This is just a plain JS object. UI5's `JSONModel` loads it and makes every path available for binding.

---

### Step 6 — Main.controller.js (minimal for now)

```js
sap.ui.define([
    "sap/ui/core/mvc/Controller"
], function(Controller) {
    "use strict";

    return Controller.extend("sap.ui.demo.hello.controller.Main", {

        onInit: function() {
            // runs once when the view is first created
            console.log("Main controller ready");
        }

    });
});
```

No logic needed yet — the binding does all the work.

---

### What you should see

A page titled "My Greetings" with three list items. Each item's text comes directly from `data.json` — UI5 read the file, parsed it into a model, and the binding rendered it automatically.

---

### Key concept: the binding path

| Expression | Means |
|---|---|
| `{/Greetings}` | Root array named Greetings |
| `{message}` | Property `message` on the current binding context (each list item) |
| `{/Greetings/0/message}` | Absolute path to the first item's message |

This exact syntax works identically for local JSON models and live OData — that's what makes it powerful.

---

### Common mistakes

**Mistake:** Forgetting the `/` in `{/Greetings}`
**Result:** Blank list. UI5 tries a relative path and finds nothing.

**Mistake:** Wrong namespace in `controllerName`
**Result:** UI5 loads the view but can't find the controller. Check the `data-sap-ui-resourceroots` mapping in index.html matches the namespace prefix in your controller's `extend()` call.

**Mistake:** `data.json` path is wrong
**Result:** Model loads but is empty. Open the browser network tab and check if `data.json` returned 404.
$md$
where slug = '1-ss-test';

-- ─────────────────────────────────────────────
-- 2-MS-Test  Multi-Screen Navigation
-- ─────────────────────────────────────────────
update public.topics set content_md = $md$
## Multi-Screen Navigation — Routing in UI5

Now that you can render a single screen, the next challenge is navigating between screens without page reloads. UI5's router handles this via URL hash changes — the URL updates, the router swaps views, the back button works for free.

---

### The mental model

```
manifest.json defines routes + targets
  ↓
Component.js initializes the Router (automatically via manifest)
  ↓
User action calls router.navTo("routeName", { params })
  ↓
Router matches the pattern, loads the target view
  ↓
Target view attaches to the App container's pages aggregation
```

---

### Project structure

```
webapp/
├── controller/
│   ├── Main.controller.js
│   └── Detail.controller.js
├── view/
│   ├── App.view.xml        ← shell with NavContainer
│   ├── Main.view.xml       ← list screen
│   └── Detail.view.xml     ← detail screen
└── manifest.json
```

---

### Step 1 — Add routing to manifest.json

```json
"sap.ui5": {
    "rootView": {
        "viewName": "sap.ui.demo.hello.view.App",
        "type": "XML",
        "id": "app"
    },
    "routing": {
        "config": {
            "routerClass": "sap.m.routing.Router",
            "viewType": "XML",
            "viewPath": "sap.ui.demo.hello.view",
            "controlId": "app",
            "controlAggregation": "pages",
            "bypassed": { "target": "main" }
        },
        "routes": [
            {
                "pattern": "",
                "name": "main",
                "target": "main"
            },
            {
                "pattern": "detail/{itemId}",
                "name": "detail",
                "target": "detail"
            }
        ],
        "targets": {
            "main": { "viewName": "Main" },
            "detail": { "viewName": "Detail" }
        }
    }
}
```

**Key config options:**
- `controlId: "app"` — the ID of your App/NavContainer control that holds pages
- `controlAggregation: "pages"` — the router adds views into this aggregation
- `pattern: ""` — empty string matches the root URL (no hash)
- `pattern: "detail/{itemId}"` — `{itemId}` is a named URL parameter

---

### Step 2 — App.view.xml (the shell)

```xml
<mvc:View
    controllerName="sap.ui.demo.hello.controller.App"
    xmlns:mvc="sap.ui.core.mvc"
    xmlns="sap.m"
    displayBlock="true">

    <App id="app" />

</mvc:View>
```

The `App` control is a `NavContainer` — it holds multiple pages and animates transitions between them. The router uses its `id="app"` to find it (matches `controlId` in manifest).

---

### Step 3 — Main.view.xml (list with tap handler)

```xml
<mvc:View
    controllerName="sap.ui.demo.hello.controller.Main"
    xmlns:mvc="sap.ui.core.mvc"
    xmlns="sap.m">

    <Page title="Greetings">
        <content>
            <List
                id="greetingsList"
                items="{/Greetings}"
                itemPress="onItemPress"
                mode="SingleSelectMaster">
                <items>
                    <StandardListItem
                        title="{message}"
                        type="Navigation" />
                </items>
            </List>
        </content>
    </Page>

</mvc:View>
```

`type="Navigation"` adds the chevron arrow. `itemPress="onItemPress"` fires when any item is tapped.

---

### Step 4 — Main.controller.js (navigate on press)

```js
sap.ui.define([
    "sap/ui/core/mvc/Controller"
], function(Controller) {
    "use strict";

    return Controller.extend("sap.ui.demo.hello.controller.Main", {

        onItemPress: function(oEvent) {
            // Get the binding context of the tapped item
            var oItem = oEvent.getSource();
            var oBindingContext = oItem.getBindingContext();

            // Read the ID from the model
            var iItemId = oBindingContext.getProperty("ID");

            // Navigate to the detail route, passing the ID in the URL
            var oRouter = this.getOwnerComponent().getRouter();
            oRouter.navTo("detail", {
                itemId: iItemId
            });
        }

    });
});
```

**Why `getOwnerComponent().getRouter()`?**
The router belongs to the Component, not the view or controller. Always get it this way.

---

### Step 5 — Detail.view.xml

```xml
<mvc:View
    controllerName="sap.ui.demo.hello.controller.Detail"
    xmlns:mvc="sap.ui.core.mvc"
    xmlns="sap.m">

    <Page
        id="detailPage"
        title="Detail"
        showNavButton="true"
        navButtonPress="onNavBack">

        <content>
            <ObjectHeader
                title="{message}"
                number="{ID}" />
        </content>

    </Page>

</mvc:View>
```

`showNavButton="true"` + `navButtonPress` gives you the back arrow for free.

---

### Step 6 — Detail.controller.js (read URL param, bind view)

```js
sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/ui/core/routing/History"
], function(Controller, History) {
    "use strict";

    return Controller.extend("sap.ui.demo.hello.controller.Detail", {

        onInit: function() {
            // Attach to the "detail" route match event
            var oRouter = this.getOwnerComponent().getRouter();
            oRouter.getRoute("detail").attachPatternMatched(this._onRouteMatched, this);
        },

        _onRouteMatched: function(oEvent) {
            // Read the itemId from the URL
            var iItemId = oEvent.getParameter("arguments").itemId;

            // Find the matching index in the model
            var oModel = this.getOwnerComponent().getModel();
            var aItems = oModel.getProperty("/Greetings");
            var iIndex = aItems.findIndex(function(item) {
                return item.ID == iItemId;
            });

            // Bind the view to that item's path
            this.getView().bindObject("/Greetings/" + iIndex);
        },

        onNavBack: function() {
            var oHistory = History.getInstance();
            var sPreviousHash = oHistory.getPreviousHash();

            if (sPreviousHash !== undefined) {
                window.history.go(-1);
            } else {
                // No previous page in history — go home
                this.getOwnerComponent().getRouter().navTo("main", {}, true);
            }
        }

    });
});
```

---

### How `bindObject` works

`this.getView().bindObject("/Greetings/2")` sets the view's binding context to the third item in the array. Every control inside the view that uses a relative binding like `{message}` now reads from that item automatically — no need to set each field individually.

---

### Common mistakes

**Mistake:** Using `attachRoutePatternMatched` on the router instead of `attachPatternMatched` on the route
**Result:** The handler fires for every route match, not just yours.

**Mistake:** Forgetting to call `attachPatternMatched` in `onInit`
**Result:** The first navigation works, but navigating back and then forward again doesn't refresh the detail view.

**Mistake:** `controlId` in manifest doesn't match the `id` on your `<App>` control
**Result:** Router throws "Could not find target control" and nothing renders.
$md$
where slug = '2-ms-test';

-- ─────────────────────────────────────────────
-- 3-CRUD-Test  Local CRUD
-- ─────────────────────────────────────────────
update public.topics set content_md = $md$
## CRUD on a Local JSON Model

Before connecting to a real backend, you need to master the create/read/update/delete pattern on a local model. The techniques here transfer directly to OData — only the persistence layer changes.

---

### Why local CRUD first?

When you do CRUD against OData, UI5 handles a lot automatically. Learning CRUD on a plain JSONModel first shows you *what* UI5 is doing under the hood — and means you can debug it later.

---

### The view — list + input + buttons

```xml
<mvc:View
    controllerName="sap.ui.demo.hello.controller.Main"
    xmlns:mvc="sap.ui.core.mvc"
    xmlns="sap.m">

    <Page title="CRUD Demo">
        <headerContent>
            <Button text="Add" press="onCreate" type="Emphasized" />
        </headerContent>
        <content>
            <VBox class="sapUiMediumMargin">
                <Input id="newMessage" placeholder="Type a message..." />
            </VBox>
            <List
                id="list"
                items="{/Greetings}"
                delete="onDelete"
                mode="Delete">
                <items>
                    <StandardListItem
                        title="{message}"
                        description="ID: {ID}"
                        type="Active"
                        press="onEdit" />
                </items>
            </List>
        </content>
    </Page>

</mvc:View>
```

`mode="Delete"` adds the delete swipe/button to each list item automatically.

---

### CREATE — adding a new item

```js
onCreate: function() {
    var oView = this.getView();
    var oModel = oView.getModel();
    var oInput = oView.byId("newMessage");
    var sMessage = oInput.getValue().trim();

    // Validate
    if (!sMessage) {
        sap.m.MessageToast.show("Please enter a message");
        return;
    }

    // Read current array
    var aItems = oModel.getProperty("/Greetings");

    // Add new item (generate a simple ID)
    aItems.push({
        ID: Date.now(),
        message: sMessage
    });

    // Write back and refresh
    oModel.setProperty("/Greetings", aItems);

    // Clear the input
    oInput.setValue("");
}
```

**Why `setProperty` + manual push?**
`JSONModel` does not observe array mutations. If you just do `aItems.push(...)` without `setProperty`, the model's internal state updates but UI5's binding doesn't know to re-render. Always read → mutate → write back.

---

### DELETE — removing an item

```js
onDelete: function(oEvent) {
    var oModel = this.getView().getModel();
    var aItems = oModel.getProperty("/Greetings");

    // Get the binding path of the deleted item, e.g. "/Greetings/2"
    var sPath = oEvent.getParameter("listItem").getBindingContextPath();
    var iIndex = parseInt(sPath.split("/").pop(), 10);

    // Remove from array
    aItems.splice(iIndex, 1);
    oModel.setProperty("/Greetings", aItems);
}
```

`getBindingContextPath()` returns the model path of the item, like `/Greetings/2`. Splitting on `/` and taking the last part gives you the array index.

---

### UPDATE — editing in place

Add an edit dialog to your view as a fragment (or inline):

```xml
<!-- In your view or a Fragment -->
<Dialog id="editDialog" title="Edit Message" confirm="onEditConfirm">
    <content>
        <Input id="editInput" value="{/editDraft/message}" />
    </content>
    <endButton>
        <Button text="Cancel" press="onEditCancel" />
    </endButton>
</Dialog>
```

```js
onEdit: function(oEvent) {
    var oModel = this.getView().getModel();
    var oItem = oEvent.getSource();
    var oCtx = oItem.getBindingContext();

    // Store which index we're editing
    this._editPath = oCtx.getPath(); // e.g. "/Greetings/1"

    // Copy the data into a draft path so edits don't affect the list immediately
    oModel.setProperty("/editDraft", Object.assign({}, oCtx.getObject()));

    this.byId("editDialog").open();
},

onEditConfirm: function() {
    var oModel = this.getView().getModel();
    var oDraft = oModel.getProperty("/editDraft");

    // Write draft back to original path
    oModel.setProperty(this._editPath + "/message", oDraft.message);
    this.byId("editDialog").close();
},

onEditCancel: function() {
    this.byId("editDialog").close();
}
```

**The draft pattern** — copy data to a temporary path before editing. This way the list isn't live-updating while the user types in the dialog.

---

### READ — it's just binding

You're already doing READ every time the list renders. `{/Greetings}` reads the entire array; `{message}` reads one property. No explicit "read" call needed.

---

### Full controller skeleton

```js
sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/m/MessageToast"
], function(Controller, MessageToast) {
    "use strict";

    return Controller.extend("sap.ui.demo.hello.controller.Main", {

        onInit: function() {
            // nothing needed — model set in Component.js
        },

        onCreate: function() { /* ... see above ... */ },
        onDelete: function(oEvent) { /* ... see above ... */ },
        onEdit: function(oEvent) { /* ... see above ... */ },
        onEditConfirm: function() { /* ... see above ... */ },
        onEditCancel: function() { /* ... see above ... */ }

    });
});
```

---

### What changes when you move to OData

| Local JSON | OData |
|---|---|
| `aItems.push(...)` then `setProperty` | `oModel.create("/Greetings", data)` |
| `aItems.splice(i,1)` then `setProperty` | `oModel.remove("/Greetings(1)")` |
| `setProperty(path, value)` | `oModel.update("/Greetings(1)", data)` |
| Manual `refresh()` sometimes needed | Auto-refresh after batch submit |

The UI and binding stay identical. Only these three calls change.

---

### Common mistakes

**Mistake:** Mutating the array reference directly without `setProperty`
**Result:** The data changes in memory but the list doesn't re-render.

**Mistake:** Calling `oModel.refresh(true)` when not needed
**Result:** Forces a full re-render and loses scroll position. Only needed if you changed nested data that UI5 can't detect.
$md$
where slug = '3-crud-test';

-- ─────────────────────────────────────────────
-- 4-F4-Test  Value Help Dialog
-- ─────────────────────────────────────────────
update public.topics set content_md = $md$
## Value Help (F4) Dialog

The F4 help dialog is one of the most common patterns in SAP UIs. It lets a user search and pick a value from a list rather than typing it manually — reducing errors and looking professional.

---

### What F4 means

In SAP GUI, pressing F4 on a field opens a "search help" popup. In UI5 the same concept is called a Value Help dialog. You'll see it on every SAP Fiori app that has a "search and select" field.

---

### The pattern in three parts

1. An `Input` field with a value-help icon button
2. A `SelectDialog` fragment that opens on click
3. A confirm handler that writes the selected value back into the input

---

### Step 1 — The Input field in your view

```xml
<mvc:View
    controllerName="sap.ui.demo.hello.controller.Main"
    xmlns:mvc="sap.ui.core.mvc"
    xmlns="sap.m">

    <Page title="Value Help Demo">
        <content>
            <VBox class="sapUiMediumMargin">
                <Label text="Select a Greeting" />
                <Input
                    id="selectedValue"
                    placeholder="Press the icon or F4..."
                    showValueHelp="true"
                    valueHelpRequest="onValueHelpRequest" />
            </VBox>
        </content>
    </Page>

</mvc:View>
```

`showValueHelp="true"` adds the lookup icon inside the input field automatically. `valueHelpRequest` fires when the user clicks it or presses F4.

---

### Step 2 — The SelectDialog as a Fragment

Create `webapp/fragment/ValueHelpDialog.fragment.xml`:

```xml
<core:FragmentDefinition
    xmlns="sap.m"
    xmlns:core="sap.ui.core">

    <SelectDialog
        title="Select a Greeting"
        search="onValueHelpSearch"
        confirm="onValueHelpConfirm"
        cancel="onValueHelpCancel"
        items="{/Greetings}">

        <items>
            <StandardListItem
                title="{message}"
                description="ID: {ID}"
                type="Active" />
        </items>

    </SelectDialog>

</core:FragmentDefinition>
```

**Why a Fragment and not inline in the view?**
Fragments are reusable and lazy-loaded. The dialog only exists in memory when it's open — better performance, and you can reuse the same fragment across views.

---

### Step 3 — The controller

```js
sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/ui/model/Filter",
    "sap/ui/model/FilterOperator"
], function(Controller, Filter, FilterOperator) {
    "use strict";

    return Controller.extend("sap.ui.demo.hello.controller.Main", {

        // Open the dialog (lazy-load it the first time)
        onValueHelpRequest: function() {
            // Cache the dialog promise so we only load the fragment once
            if (!this._pValueHelpDialog) {
                this._pValueHelpDialog = this.loadFragment({
                    name: "sap.ui.demo.hello.fragment.ValueHelpDialog"
                });
            }
            this._pValueHelpDialog.then(function(oDialog) {
                // Reset any previous filter before opening
                oDialog.getBinding("items").filter([]);
                oDialog.open();
            });
        },

        // Filter the list as the user types in the search field
        onValueHelpSearch: function(oEvent) {
            var sValue = oEvent.getParameter("value");
            var oFilter = new Filter("message", FilterOperator.Contains, sValue);
            oEvent.getSource().getBinding("items").filter([oFilter]);
        },

        // Write the selected value back into the Input field
        onValueHelpConfirm: function(oEvent) {
            var oSelectedItem = oEvent.getParameter("selectedItem");
            if (oSelectedItem) {
                this.byId("selectedValue").setValue(
                    oSelectedItem.getTitle()
                );
            }
            // Clear the filter after closing
            oEvent.getSource().getBinding("items").filter([]);
        },

        // User pressed Cancel — do nothing
        onValueHelpCancel: function() {
            // The dialog closes itself
        }

    });
});
```

---

### Understanding `loadFragment` vs the old `Fragment.load` pattern

You may see older code using:
```js
Fragment.load({ id: this.getView().getId(), name: "...", controller: this })
    .then(oDialog => { this.getView().addDependent(oDialog); });
```

From UI5 1.93+ you can use the simpler `this.loadFragment(...)` directly on the controller — it automatically sets the view as the dependent (so the dialog is destroyed with the view) and uses the view's ID scope. Prefer this in new code.

---

### Why `addDependent` (or `loadFragment`) matters

If you open a dialog without making the view its "dependent", the dialog won't be destroyed when the view is destroyed. After a few navigations you end up with zombie dialogs in memory. `loadFragment` handles this automatically.

---

### The caching pattern explained

```js
if (!this._pValueHelpDialog) {
    this._pValueHelpDialog = this.loadFragment({ name: "..." });
}
this._pValueHelpDialog.then(oDialog => oDialog.open());
```

- First call: loads the fragment, stores the Promise, opens when ready
- Every subsequent call: Promise already resolved, opens instantly
- Never creates more than one dialog instance

---

### Extending this to Episode 9

In Episode 9 you'll point the same dialog at a live CAP OData service instead of the local JSON model. The dialog code stays **identical** — only the model source changes. This is the power of UI5's model abstraction.

---

### Common mistakes

**Mistake:** Not resetting the filter before opening the dialog
**Result:** The dialog opens with the previous search already applied, showing a filtered list that confuses the user.

**Mistake:** Creating a new dialog instance every time `onValueHelpRequest` fires
**Result:** Multiple dialogs in memory. Always cache with `this._pValueHelpDialog`.

**Mistake:** Reading `oEvent.getParameter("selectedItem")` without null-checking
**Result:** If the user confirms without selecting anything, this is `null` and your code crashes.
$md$
where slug = '4-f4-test';

-- ─────────────────────────────────────────────
-- 5-CAP-1-TEST  First CAP Service
-- ─────────────────────────────────────────────
update public.topics set content_md = $md$
## Your First CAP Service

CAP (Cloud Application Programming Model) is SAP's opinionated framework for building backend services on BTP. You define your data model and service in a simple `.cds` language, and CAP generates the OData API, handles routing, and manages database access automatically.

---

### Why CAP?

Without CAP you'd write raw OData services by hand — hundreds of lines of boilerplate for every entity. CAP collapses that to a few lines of CDS definition plus optional JS handlers for custom logic.

---

### Install the CAP CLI

```bash
npm install -g @sap/cds-dk
cds --version   # should print 7.x or higher
```

---

### Scaffold a new project

```bash
cds init 5-cap-1-test
cd 5-cap-1-test
npm install
```

This creates the folder structure CAP expects:

```
5-cap-1-test/
├── db/             ← data model goes here
├── srv/            ← service definitions + handlers
├── app/            ← UI (empty for now)
├── package.json
└── .cdsrc.json
```

---

### Step 1 — Define the data model

Create `db/schema.cds`:

```cds
namespace sap.demo;

entity Greetings {
    key ID      : Integer;
        message : String(200);
}
```

**CDS basics:**
- `namespace` — prevents naming collisions when your app grows
- `entity` — like a database table
- `key` — marks the primary key field
- `String(200)` — a varchar(200) column

---

### Step 2 — Define the service

Create `srv/hello-service.cds`:

```cds
using sap.demo from '../db/schema';

service HelloService @(path: '/hello') {
    entity Greetings as projection on sap.demo.Greetings;
}
```

**What this does:**
- `using` — imports your data model
- `service HelloService` — creates an OData service
- `@(path: '/hello')` — mounts it at `/hello`
- `projection on` — exposes the entity through the service (you can expose a subset of columns this way)

CAP auto-generates full OData CRUD from this — no JS needed yet.

---

### Step 3 — Add an in-memory mock handler (optional)

Create `srv/hello-service.js`:

```js
module.exports = (srv) => {

    // Override the READ handler with mock data
    srv.on('READ', 'Greetings', (req) => {
        return [
            { ID: 1, message: 'Hello from CAP' },
            { ID: 2, message: 'No database yet' },
            { ID: 3, message: 'Just a JS handler' }
        ];
    });

};
```

This replaces CAP's auto-generated READ with your own. Useful for testing before a database exists.

---

### Step 4 — Run it

```bash
cds watch
```

`cds watch` starts a local server with live-reload. Open:

```
http://localhost:4004
```

You'll see the CAP service index page listing your services. Click `HelloService` to see the OData service document, then navigate to:

```
http://localhost:4004/hello/Greetings
```

You should get back JSON like:
```json
{
  "value": [
    { "ID": 1, "message": "Hello from CAP" },
    { "ID": 2, "message": "No database yet" }
  ]
}
```

---

### What CAP generated for you automatically

From your two `.cds` files, CAP built:
- An OData V4 service at `/hello`
- `GET /hello/Greetings` — list all
- `GET /hello/Greetings(1)` — get by key
- `POST /hello/Greetings` — create
- `PATCH /hello/Greetings(1)` — update
- `DELETE /hello/Greetings(1)` — delete
- `GET /hello/$metadata` — OData metadata document

You wrote zero routing code. Zero request parsing. Zero response formatting.

---

### The OData metadata document

Visit `http://localhost:4004/hello/$metadata` — this XML document describes every entity, property, and operation in your service. UI5's ODataModel reads this automatically when you connect to the service, which is how it knows what fields exist without you hardcoding them.

---

### package.json dependencies to know

```json
{
    "dependencies": {
        "@sap/cds": "^7",
        "express": "^4"
    },
    "devDependencies": {
        "@sap/cds-dk": "^7",
        "sqlite3": "^5"
    },
    "cds": {
        "requires": {
            "db": { "kind": "sqlite", "credentials": { "database": ":memory:" } }
        }
    }
}
```

The `cds.requires.db` with `":memory:"` means CAP uses an in-memory SQLite database while developing locally. Data resets on every restart — that's fine for now.

---

### Common mistakes

**Mistake:** Forgetting `npm install` after `cds init`
**Result:** `cds watch` fails with missing module errors.

**Mistake:** Naming your JS handler file differently from your CDS file
**Result:** CAP won't pick it up. `hello-service.cds` → `hello-service.js`, same name, same folder.

**Mistake:** Using OData V2 URLs (`/hello/GREETINGSSet`)
**Result:** CAP generates V4 by default. Use the exact entity name from your CDS definition.
$md$
where slug = '5-cap-1-test';

-- ─────────────────────────────────────────────
-- 6-SqlLite-Test  Real Persistence
-- ─────────────────────────────────────────────
update public.topics set content_md = $md$
## SQLite Persistence — Real Data That Survives Restarts

So far your CAP service returns mock data from a JS array. Every restart wipes it. Now you swap that for a real SQLite database file — data persists, and CAP handles all the SQL for you.

---

### Why SQLite for local dev?

SQLite is a single file. No server to run, no credentials to configure. CAP can deploy your entire schema to it with one command. In production you'll use SAP HANA, but SQLite lets you develop and test offline at full speed.

---

### Step 1 — Define the schema in db/schema.cds

```cds
namespace sap.demo;

entity Greetings {
    key ID      : Integer;
        message : String(200);
        created : Timestamp @cds.on.insert: $now;
}
```

The `@cds.on.insert: $now` annotation tells CAP to automatically fill in the current timestamp when a new row is inserted — you don't need to pass it from the frontend.

---

### Step 2 — Deploy the schema to SQLite

```bash
cds deploy --to sqlite:db/greetings.db
```

This command:
1. Reads your `db/schema.cds` definition
2. Generates the SQL `CREATE TABLE` statements
3. Creates the SQLite file at `db/greetings.db`
4. Updates `package.json` to point at that file

After running it, check `package.json` — you'll see:

```json
"cds": {
    "requires": {
        "db": {
            "kind": "sqlite",
            "credentials": { "database": "db/greetings.db" }
        }
    }
}
```

---

### Step 3 — Seed data with CSV files

CAP automatically loads CSV files at startup if they match the pattern:
`db/data/<namespace>-<EntityName>.csv`

Create `db/data/sap.demo-Greetings.csv`:

```csv
ID,message
1,Hello from SQLite
2,Data persists now
3,No more mock arrays
```

**Important:** The filename must match exactly — namespace, dash, entity name. CAP is case-sensitive here.

---

### Step 4 — Remove the JS mock handler

Now that CAP serves real database data, delete (or comment out) the `srv.on('READ', ...)` handler from Episode 5. CAP's built-in database handler takes over automatically.

Your `srv/hello-service.js` can be empty, or you can delete it entirely:

```js
// No handlers needed — CAP serves SQLite data automatically
module.exports = (srv) => {};
```

---

### Step 5 — Run and verify

```bash
cds watch
```

Open `http://localhost:4004/hello/Greetings` — you should see your seeded rows. Stop the server, add a row via a POST, restart — the new row is still there.

---

### How CAP handles SQL without you writing any

When you do `GET /hello/Greetings`, CAP internally runs:
```sql
SELECT ID, message, created FROM SAP_DEMO_GREETINGS
```

When you do `POST /hello/Greetings` with `{"ID": 4, "message": "New item"}`, CAP runs:
```sql
INSERT INTO SAP_DEMO_GREETINGS (ID, message, created) VALUES (4, 'New item', CURRENT_TIMESTAMP)
```

You never write these queries. CAP generates them from your CDS definition.

---

### Inspecting the SQLite file directly

```bash
# Install the sqlite3 CLI if you don't have it
brew install sqlite3   # macOS
apt install sqlite3    # Ubuntu

# Open the database
sqlite3 db/greetings.db

# Inside the sqlite3 shell:
.tables
SELECT * FROM SAP_DEMO_GREETINGS;
.quit
```

This is useful when something isn't saving correctly — you can check the raw database instead of guessing.

---

### The difference between `:memory:` and a file

| `:memory:` | `db/greetings.db` |
|---|---|
| Lives in RAM only | Lives on disk |
| Wiped on every restart | Persists across restarts |
| Good for unit tests | Good for local development |
| CSV seed loads every time | CSV seed loads only on first deploy |

---

### Common mistakes

**Mistake:** CSV filename doesn't match the namespace + entity name exactly
**Result:** CAP silently skips the file. No seed data, no error.

**Mistake:** Running `cds watch` without running `cds deploy` first
**Result:** CAP uses `:memory:` and loses data on restart. Always deploy first when switching to file-based SQLite.

**Mistake:** Editing the SQLite file while `cds watch` is running
**Result:** Sometimes works, sometimes causes lock errors. Stop the server first if you need to manually edit the DB.
$md$
where slug = '6-sqllite-test';

-- ─────────────────────────────────────────────
-- 7-CAP-SS-TEST  OData-backed Single Screen
-- ─────────────────────────────────────────────
update public.topics set content_md = $md$
## Connecting UI5 to CAP — The OData Model

This is the pivotal lesson of the whole course. You're going to take the exact same Single Screen app from Episode 1 and swap the local JSON model for a live OData connection to your CAP service. The view XML changes by zero lines.

---

### The key insight

UI5's binding syntax — `{/Greetings}`, `{message}` — doesn't care what's behind the model. The same XML view works whether the model is a local JSON file or a live network service. This is UI5's model abstraction layer in action.

---

### What changes and what doesn't

| Part | Episode 1 (JSON) | Episode 7 (OData) |
|---|---|---|
| `Main.view.xml` | **unchanged** | **unchanged** |
| `Main.controller.js` | **unchanged** | **unchanged** |
| `Component.js` | `new JSONModel("data.json")` | `new ODataModel(...)` |
| `manifest.json` | no dataSources | add OData dataSource |
| Data lives in | `model/data.json` | CAP SQLite database |

---

### Step 1 — Update manifest.json

```json
"sap.app": {
    "id": "sap.ui.demo.hello",
    "dataSources": {
        "mainService": {
            "uri": "/hello/",
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
```

The `""` key means this is the **default** model — so `{/Greetings}` still works without any prefix.

---

### Step 2 — Update Component.js

Remove the JSONModel setup entirely:

```js
sap.ui.define([
    "sap/ui/core/UIComponent"
], function(UIComponent) {
    "use strict";

    return UIComponent.extend("sap.ui.demo.hello.Component", {
        metadata: {
            manifest: "json"
        },

        init: function() {
            UIComponent.prototype.init.apply(this, arguments);
            // No model setup needed — manifest.json handles it
        }
    });
});
```

When you declare the model in `manifest.json`, UI5 creates it automatically during Component init. You don't need to do it manually.

---

### Step 3 — Configure the proxy (local dev only)

Your UI5 app runs on `http://localhost:5000` (or similar) and your CAP service on `http://localhost:4004`. Browsers block cross-origin requests. You need a proxy.

If using UI5 Tooling, add to `ui5.yaml`:

```yaml
server:
  customMiddleware:
    - name: ui5-middleware-simpleproxy
      afterMiddleware: compression
      configuration:
        baseUri: "http://localhost:4004"
        pathPrefix: "/hello"
```

Or install and configure `@sap-ux/proxy-middleware`. Either way, requests to `/hello/` from your frontend get forwarded to CAP.

---

### Step 4 — The view (no changes needed)

```xml
<!-- EXACTLY the same as Episode 1 -->
<List items="{/Greetings}">
    <items>
        <StandardListItem title="{message}" />
    </items>
</List>
```

Run both servers. The list now shows data from your SQLite database.

---

### What happens under the hood

1. UI5 reads `manifest.json` → creates an `ODataModel` pointed at `/hello/`
2. The `ODataModel` fetches `/hello/$metadata` to learn the entity structure
3. When the list renders, ODataModel sends `GET /hello/Greetings`
4. CAP receives the request, queries SQLite, returns JSON
5. ODataModel parses the response and notifies the binding
6. The list re-renders with real data

You wrote none of steps 2–6.

---

### OData V4 vs V2

CAP generates OData V4 by default. The main differences you'll notice:

| V2 | V4 |
|---|---|
| Response in `{ d: { results: [...] } }` | Response in `{ value: [...] }` |
| `sap.ui.model.odata.v2.ODataModel` | `sap.ui.model.odata.v4.ODataModel` |
| All operations synchronous by default | Async, uses `requestObject()` for reads |

Make sure `manifest.json` says `"odataVersion": "4.0"` and you use the V4 model.

---

### Common mistakes

**Mistake:** CAP and UI5 dev servers both running but no proxy configured
**Result:** CORS errors in the console. Every API call fails.

**Mistake:** `odataVersion` mismatch (V4 service with V2 model)
**Result:** Metadata parses but bindings return nothing — the V2 model doesn't understand V4 response format.

**Mistake:** Hardcoding `http://localhost:4004` in `uri`
**Result:** Works locally, breaks when deployed. Always use a relative path + proxy.
$md$
where slug = '7-cap-ss-test';

-- ─────────────────────────────────────────────
-- 8-CAP-MS-TEST  Full-Stack CRUD
-- ─────────────────────────────────────────────
update public.topics set content_md = $md$
## Full-Stack CRUD — UI5 + CAP + SQLite

This is where everything connects: the routing from Episode 2, the CRUD from Episode 3, and the OData model from Episode 7 — all working together against a real database. Every button click now round-trips to SQLite.

---

### Architecture

```
Browser (UI5)
  ↕  OData V4 HTTP calls
CAP Service (Node.js)
  ↕  CAP CDS ORM
SQLite file
```

---

### Step 1 — Add CRUD handlers to CAP

By default CAP handles CREATE, UPDATE, DELETE automatically when using SQLite. But you often need custom logic — validation, computed fields, audit logging. Here's how to add handlers:

```js
// srv/hello-service.js
module.exports = (srv) => {

    // Before creating: validate and set defaults
    srv.before('CREATE', 'Greetings', (req) => {
        if (!req.data.message || req.data.message.trim() === '') {
            req.error(400, 'Message cannot be empty');
        }
        // CAP assigns the key automatically if it's a UUID
    });

    // After creating: log it
    srv.after('CREATE', 'Greetings', (data) => {
        console.log('Created greeting:', data.ID);
    });

    // Custom action: clear all greetings
    srv.on('clearAll', async (req) => {
        await DELETE.from('Greetings');
        return { success: true };
    });

};
```

**Handler phases:**
- `before` — runs before CAP's default handler. Use for validation, setting defaults.
- `on` — replaces CAP's default handler. Use when you need full control.
- `after` — runs after the default. Use for side effects, transformations.

---

### Step 2 — UI5 CREATE via ODataModel V4

```js
onCreate: function() {
    var sMessage = this.byId("newInput").getValue().trim();
    if (!sMessage) return;

    var oModel = this.getView().getModel();
    var oListBinding = this.byId("list").getBinding("items");

    // Create a new entry in the binding context
    var oContext = oListBinding.create({
        message: sMessage
    });

    // React to success/failure
    oContext.created().then(() => {
        sap.m.MessageToast.show("Saved!");
        this.byId("newInput").setValue("");
    }).catch((oError) => {
        sap.m.MessageBox.error("Failed: " + oError.message);
    });
}
```

In OData V4, `listBinding.create(data)` sends a `POST` to CAP immediately (or batches it, depending on your model's `updateGroupId` setting).

---

### Step 3 — UI5 DELETE via ODataModel V4

```js
onDelete: function(oEvent) {
    var oItem = oEvent.getParameter("listItem");
    var oContext = oItem.getBindingContext();

    oContext.delete().then(() => {
        sap.m.MessageToast.show("Deleted");
    }).catch((oError) => {
        sap.m.MessageBox.error("Delete failed: " + oError.message);
    });
}
```

`context.delete()` sends `DELETE /hello/Greetings(id)` to CAP. No index juggling, no manual array splicing.

---

### Step 4 — UI5 UPDATE via ODataModel V4

```js
onSaveEdit: function() {
    var oContext = this._editContext; // saved when the user clicked Edit
    var sNewMessage = this.byId("editInput").getValue();

    oContext.setProperty("message", sNewMessage);

    // Submit the change
    this.getView().getModel().submitBatch("myGroup").then(() => {
        sap.m.MessageToast.show("Updated");
        this.byId("editDialog").close();
    });
}
```

`context.setProperty(field, value)` marks the property as dirty. `submitBatch()` flushes pending changes as a single OData PATCH request.

---

### Step 5 — Update manifest.json for auto-expand and batch

```json
"": {
    "dataSource": "mainService",
    "settings": {
        "synchronizationMode": "None",
        "operationMode": "Server",
        "autoExpandSelect": true,
        "updateGroupId": "myGroup"
    }
}
```

`updateGroupId: "myGroup"` means changes are batched — they don't send until you call `submitBatch("myGroup")`. This lets you edit multiple fields and save them all in one HTTP request.

---

### Comparing local JSON CRUD vs OData V4 CRUD

| Operation | JSONModel | ODataModel V4 |
|---|---|---|
| Create | `array.push()` + `setProperty` | `listBinding.create(data)` |
| Read | Binding (automatic) | Binding (automatic) |
| Update | `setProperty(path, value)` | `context.setProperty(field, value)` + `submitBatch` |
| Delete | `array.splice()` + `setProperty` | `context.delete()` |

The binding and rendering stay identical. Only the write operations change.

---

### Full round-trip trace for a CREATE

```
User types "Hello" and clicks Add
  → onSave calls listBinding.create({ message: "Hello" })
    → ODataModel V4 sends POST /hello/Greetings  { message: "Hello" }
      → CAP's before-CREATE handler validates the message
        → CAP's default handler INSERTs into SQLite
          → SQLite assigns the ID
            → CAP returns { ID: 7, message: "Hello" }
              → ODataModel updates the list binding
                → UI5 re-renders the list with the new item
```

---

### Common mistakes

**Mistake:** Calling `model.refresh()` after an OData operation
**Result:** Works, but causes an extra GET request you don't need. ODataModel V4 updates the binding automatically after a successful write.

**Mistake:** Forgetting `submitBatch` when `updateGroupId` is set
**Result:** Changes are marked dirty but never sent. The UI looks updated locally, but nothing reaches the database.

**Mistake:** Not handling the `.catch()` on create/delete
**Result:** Errors from CAP (like your validation `req.error(400, ...)`) are swallowed silently.
$md$
where slug = '8-cap-ms-test';

-- ─────────────────────────────────────────────
-- 9-CAP-F4-TEST  Live Value Help
-- ─────────────────────────────────────────────
update public.topics set content_md = $md$
## Value Help Against Live CAP Data

In Episode 4 your F4 dialog searched a static JSON array. Now you connect the same dialog to your real CAP OData service. The user types to search, CAP runs the query, results come back live — and your dialog code barely changes.

---

### What's different from Episode 4

| Part | Episode 4 | Episode 9 |
|---|---|---|
| Dialog fragment XML | Same | Same |
| `onValueHelpConfirm` | Same | Same |
| `onValueHelpSearch` | Filters local array | Sends OData `$filter` to CAP |
| Data source | `JSONModel` | `ODataModel` |

The dialog is identical. The model behind it is different.

---

### Step 1 — The dialog fragment (unchanged from Episode 4)

```xml
<core:FragmentDefinition
    xmlns="sap.m"
    xmlns:core="sap.ui.core">

    <SelectDialog
        title="Select a Greeting"
        search="onValueHelpSearch"
        confirm="onValueHelpConfirm"
        items="{/Greetings}">
        <items>
            <StandardListItem title="{message}" description="ID: {ID}" />
        </items>
    </SelectDialog>

</core:FragmentDefinition>
```

The binding `{/Greetings}` now reads from the ODataModel — same syntax, live data.

---

### Step 2 — The search handler (server-side filtering)

```js
onValueHelpSearch: function(oEvent) {
    var sValue = oEvent.getParameter("value");

    var oFilter = new sap.ui.model.Filter(
        "message",
        sap.ui.model.FilterOperator.Contains,
        sValue
    );

    // Apply the filter to the dialog's items binding
    var oBinding = oEvent.getSource().getBinding("items");
    oBinding.filter([oFilter]);
}
```

With a JSONModel, `.filter()` filters the in-memory array. With an ODataModel, `.filter()` sends:
```
GET /hello/Greetings?$filter=contains(message,'searchTerm')
```

CAP receives the OData filter, translates it to SQL `WHERE message LIKE '%searchTerm%'`, and returns only matching rows. The filtering happens on the server — no matter how many rows exist, only matching ones come back.

---

### Step 3 — Confirm handler (unchanged)

```js
onValueHelpConfirm: function(oEvent) {
    var oSelectedItem = oEvent.getParameter("selectedItem");
    if (oSelectedItem) {
        this.byId("selectedValue").setValue(oSelectedItem.getTitle());
    }
    oEvent.getSource().getBinding("items").filter([]);
}
```

---

### Step 4 — Open handler (one small addition)

When using OData, you need to ensure the binding is refreshed each time the dialog opens, so it shows current data:

```js
onValueHelpRequest: function() {
    if (!this._pValueHelpDialog) {
        this._pValueHelpDialog = this.loadFragment({
            name: "sap.ui.demo.hello.fragment.ValueHelpDialog"
        });
    }
    this._pValueHelpDialog.then(function(oDialog) {
        // Reset filter and refresh data from server
        var oBinding = oDialog.getBinding("items");
        oBinding.filter([]);
        oBinding.refresh();   // ← new: force a fresh GET from CAP
        oDialog.open();
    });
}
```

---

### Understanding OData $filter

When UI5 applies a Filter with `FilterOperator.Contains`, it sends:
```
GET /hello/Greetings?$filter=contains(message,'hello')
```

CAP translates this to SQL:
```sql
SELECT * FROM SAP_DEMO_GREETINGS
WHERE LOWER(message) LIKE '%hello%'
```

Other useful FilterOperators:

| FilterOperator | OData $filter | SQL equivalent |
|---|---|---|
| `EQ` | `message eq 'hello'` | `message = 'hello'` |
| `Contains` | `contains(message,'hi')` | `message LIKE '%hi%'` |
| `StartsWith` | `startswith(message,'hi')` | `message LIKE 'hi%'` |
| `GT` | `ID gt 5` | `ID > 5` |

---

### Common mistakes

**Mistake:** Not calling `oBinding.refresh()` when opening the dialog
**Result:** First open shows current data. After creating/deleting items, dialog still shows stale data.

**Mistake:** Using `FilterOperator.Contains` with an OData V2 service
**Result:** V2 uses `substringof('term', field)` not `contains(field, 'term')`. V4 uses `contains`.
$md$
where slug = '9-cap-f4-test';

-- ─────────────────────────────────────────────
-- 10-Validation-Test
-- ─────────────────────────────────────────────
update public.topics set content_md = $md$
## Input Validation and User Feedback

A form that silently ignores errors destroys user trust. This episode covers every layer of validation in UI5: simple JS checks, binding-level type constraints, and the MessageManager that aggregates errors across your whole app.

---

### Three layers of validation

| Layer | Where | Best for |
|---|---|---|
| JS guard | Controller `onSave` | Quick checks before any network call |
| Binding type constraint | XML view declaration | Field-level format rules (email, min length) |
| Backend validation | CAP `req.error()` | Business rules, cross-field checks |

Use all three. They complement each other — the JS guard catches obvious issues instantly, binding constraints enforce format, and CAP is the final authority.

---

### Layer 1 — JS guard in the controller

```js
onSave: function() {
    var oView = this.getView();
    var sMessage = oView.byId("messageInput").getValue().trim();
    var sCategory = oView.byId("categorySelect").getSelectedKey();

    // Check required fields
    if (!sMessage) {
        sap.m.MessageBox.error("Message is required.");
        oView.byId("messageInput").setValueState("Error");
        oView.byId("messageInput").setValueStateText("Please enter a message");
        return;
    }

    if (!sCategory) {
        sap.m.MessageBox.error("Please select a category.");
        return;
    }

    // Clear error states before saving
    oView.byId("messageInput").setValueState("None");
    // ... proceed with save
}
```

`setValueState("Error")` turns the input border red and shows the icon. `setValueStateText` shows on hover/focus.

---

### Layer 2 — Binding type constraints

Declare constraints directly in the binding expression in XML:

```xml
<Input
    id="messageInput"
    value="{
        path: '/draft/message',
        type: 'sap.ui.model.type.String',
        constraints: {
            minLength: 3,
            maxLength: 200
        }
    }"
    valueLiveUpdate="true" />

<Input
    id="amountInput"
    value="{
        path: '/draft/amount',
        type: 'sap.ui.model.type.Float',
        formatOptions: { decimals: 2 },
        constraints: { minimum: 0 }
    }" />
```

UI5 validates these constraints automatically when the value changes. If the constraint fails, the input turns red and the binding throws a `ValidateException` — your save handler can check this.

---

### Checking binding errors before saving

```js
onSave: function() {
    // Ask UI5 if any bound controls have validation errors
    var oView = this.getView();

    // Trigger validation on all inputs manually
    var aInputs = [
        oView.byId("messageInput"),
        oView.byId("amountInput")
    ];

    var bValid = true;
    aInputs.forEach(function(oInput) {
        try {
            oInput.getBinding("value").getType().validateValue(oInput.getValue());
        } catch (oException) {
            oInput.setValueState("Error");
            oInput.setValueStateText(oException.message);
            bValid = false;
        }
    });

    if (!bValid) {
        sap.m.MessageBox.error("Please correct the errors before saving.");
        return;
    }

    // Safe to save
}
```

---

### Layer 3 — MessageManager (enterprise pattern)

The `MessageManager` collects messages from all binding validations automatically and displays them in a central `MessagePopover`. This is what SAP Fiori apps use:

```js
// In onInit
onInit: function() {
    var oMessageManager = sap.ui.getCore().getMessageManager();

    // Register the view so all its binding errors feed into MessageManager
    oMessageManager.registerObject(this.getView(), true);

    // Bind the message model to a local path for the MessagePopover
    this.getView().setModel(oMessageManager.getMessageModel(), "messages");
}
```

```xml
<!-- Message button in the footer -->
<Button
    icon="sap-icon://message-popup"
    text="{= ${messages>/}.length}"
    press="onMessagePopoverPress"
    type="{= ${messages>/}.length > 0 ? 'Negative' : 'Default'}" />
```

```js
onMessagePopoverPress: function(oEvent) {
    if (!this._pMessagePopover) {
        this._pMessagePopover = this.loadFragment({
            name: "sap.ui.demo.hello.fragment.MessagePopover"
        });
    }
    this._pMessagePopover.then(function(oPopover) {
        oPopover.toggle(oEvent.getSource());
    });
}
```

---

### MessageToast vs MessageBox — when to use which

| Situation | Use |
|---|---|
| Confirming a successful save | `MessageToast.show("Saved!")` |
| Non-blocking info | `MessageToast` |
| Error that needs acknowledgment | `MessageBox.error(...)` |
| Confirm before destructive action | `MessageBox.confirm(...)` |
| Multiple field errors | `MessageManager` + `MessagePopover` |

---

### CAP backend validation

```js
// srv/hello-service.js
srv.before('CREATE', 'Greetings', (req) => {
    if (req.data.message.length < 3) {
        req.error(400, 'Message must be at least 3 characters', 'message');
    }
});
```

The third argument `'message'` is the field name — UI5's ODataModel V4 maps this back to the bound input field and turns it red automatically.

---

### Common mistakes

**Mistake:** Only validating in JS without binding constraints
**Result:** Pasting text into an amount field bypasses your JS check. Binding constraints catch format issues at the binding layer.

**Mistake:** Not clearing error states on a successful save
**Result:** Red borders persist after the data is saved correctly, confusing the user.
$md$
where slug = '10-validation-test';

-- ─────────────────────────────────────────────
-- 11-Filter-Sort-Test
-- ─────────────────────────────────────────────
update public.topics set content_md = $md$
## Search, Filter, and Sort

Every list in a real app needs search and sort. This episode covers UI5's Filter and Sorter APIs — the same code works on local JSON models and live OData, so you write it once.

---

### The complete UI — SearchField + Sort button

```xml
<Page title="Filter and Sort Demo">
    <headerContent>
        <Button icon="sap-icon://sort" press="onSortPress" tooltip="Sort by message" />
    </headerContent>
    <subHeader>
        <Bar>
            <contentMiddle>
                <SearchField
                    id="searchField"
                    placeholder="Search messages..."
                    search="onSearch"
                    liveChange="onSearch"
                    width="100%" />
            </contentMiddle>
        </Bar>
    </subHeader>
    <content>
        <List id="list" items="{/Greetings}">
            <items>
                <StandardListItem title="{message}" description="ID: {ID}" />
            </items>
        </List>
    </content>
</Page>
```

`liveChange="onSearch"` fires on every keystroke — instant search. `search="onSearch"` fires when the user presses Enter or the search icon.

---

### Search handler

```js
onSearch: function(oEvent) {
    var sQuery = oEvent.getParameter("query")    // from "search" event
                 || oEvent.getParameter("newValue"); // from "liveChange" event

    var oList = this.byId("list");
    var oBinding = oList.getBinding("items");

    if (sQuery && sQuery.length > 0) {
        var oFilter = new sap.ui.model.Filter({
            filters: [
                new sap.ui.model.Filter("message", sap.ui.model.FilterOperator.Contains, sQuery),
                new sap.ui.model.Filter("ID",      sap.ui.model.FilterOperator.EQ,       parseInt(sQuery) || -1)
            ],
            and: false  // OR logic: match message OR ID
        });
        oBinding.filter([oFilter]);
    } else {
        // Empty query — remove all filters
        oBinding.filter([]);
    }
}
```

**Combining filters:**
- `and: false` → OR (match any condition)
- `and: true` → AND (must match all conditions)

With an ODataModel this sends:
```
?$filter=contains(message,'hi') or ID eq 3
```

---

### Sort handler — toggle ascending/descending

```js
_bSortAscending: true,

onSortPress: function() {
    this._bSortAscending = !this._bSortAscending;

    var oSorter = new sap.ui.model.Sorter("message", !this._bSortAscending);
    this.byId("list").getBinding("items").sort([oSorter]);

    // Update button icon to show direction
    this.byId("sortBtn").setIcon(
        this._bSortAscending ? "sap-icon://sort-ascending" : "sap-icon://sort-descending"
    );
}
```

---

### Multi-column sort

```js
var aSorters = [
    new sap.ui.model.Sorter("category", false),   // sort by category ASC first
    new sap.ui.model.Sorter("message",  false)    // then by message ASC
];
oBinding.sort(aSorters);
```

With OData this sends: `?$orderby=category asc,message asc`

---

### Combining filter + sort

You can apply both at the same time — they don't interfere:

```js
oBinding.filter([oFilter]);
oBinding.sort([oSorter]);
```

Or pass both to the binding in the XML view declaration:

```xml
<List items="{
    path: '/Greetings',
    sorter: { path: 'message', descending: false }
}">
```

---

### FilterBar for advanced multi-field search

For more complex scenarios, use `sap.ui.comp.filterbar.FilterBar`:

```js
onFilterBarSearch: function(oEvent) {
    var aFilters = [];
    var mParams = oEvent.getParameters();

    if (mParams.selectionSet) {
        mParams.selectionSet.forEach(function(oControl) {
            if (oControl.getValue && oControl.getValue()) {
                aFilters.push(new sap.ui.model.Filter(
                    oControl.getName(),
                    sap.ui.model.FilterOperator.Contains,
                    oControl.getValue()
                ));
            }
        });
    }

    this.byId("list").getBinding("items").filter(aFilters);
}
```

---

### Common mistakes

**Mistake:** Not handling the empty-query case
**Result:** Once the user clears the search field, the list stays filtered. Always call `filter([])` when the query is empty.

**Mistake:** Mixing `liveChange` and `search` events without checking which parameter holds the query
**Result:** `query` is undefined in `liveChange`; `newValue` is undefined in `search`. Check both.

**Mistake:** Sorting a list that has an active filter
**Result:** Sort resets the filter in some UI5 versions. Apply sort and filter together in one call when possible.
$md$
where slug = '11-filter-sort-test';

-- ─────────────────────────────────────────────
-- 12-Auth-Test  XSUAA Security
-- ─────────────────────────────────────────────
update public.topics set content_md = $md$
## Securing Your CAP Service with XSUAA

Right now your CAP service has no authentication — anyone who can reach the URL can read and write your data. XSUAA (Extended Services for User Account and Authentication) is BTP's authorization service. It issues JWT tokens and lets you restrict access by role.

---

### The security model in three pieces

```
xs-security.json    ← defines scopes and roles
  ↓
CAP service.cds     ← @requires annotations reference those roles
  ↓
XSUAA service       ← issues tokens containing the user's scopes
  ↓
CAP runtime         ← checks the token on every request
```

---

### Step 1 — xs-security.json

Create this at the project root:

```json
{
    "xsappname": "hello-app",
    "tenant-mode": "dedicated",
    "scopes": [
        {
            "name": "$XSAPPNAME.read",
            "description": "Read greetings"
        },
        {
            "name": "$XSAPPNAME.write",
            "description": "Create, update, delete greetings"
        },
        {
            "name": "$XSAPPNAME.admin",
            "description": "Full admin access"
        }
    ],
    "role-templates": [
        {
            "name": "Viewer",
            "description": "Can read greetings",
            "scope-references": ["$XSAPPNAME.read"]
        },
        {
            "name": "Editor",
            "description": "Can read and write",
            "scope-references": ["$XSAPPNAME.read", "$XSAPPNAME.write"]
        },
        {
            "name": "Admin",
            "description": "Full access",
            "scope-references": ["$XSAPPNAME.read", "$XSAPPNAME.write", "$XSAPPNAME.admin"]
        }
    ],
    "role-collections": [
        {
            "name": "GreetingViewer",
            "role-template-references": ["$XSAPPNAME.Viewer"]
        },
        {
            "name": "GreetingAdmin",
            "role-template-references": ["$XSAPPNAME.Admin"]
        }
    ]
}
```

**Key concepts:**
- **Scope** — a fine-grained permission string. Always prefixed with `$XSAPPNAME.`
- **Role template** — a named collection of scopes. Users are assigned role templates.
- **Role collection** — a group of role templates assigned in BTP cockpit to users or groups.

---

### Step 2 — Annotate your CDS service

```cds
using sap.demo from '../db/schema';

@requires: 'authenticated-user'
service HelloService @(path: '/hello') {

    @readonly
    entity Greetings as projection on sap.demo.Greetings
        @(restrict: [
            { grant: 'READ',   to: 'read'  },
            { grant: ['CREATE','UPDATE','DELETE'], to: 'write' }
        ]);

    @requires: 'admin'
    action clearAll() returns String;
}
```

**Annotations explained:**
- `@requires: 'authenticated-user'` — rejects all unauthenticated requests at the service level
- `@restrict: [...]` — fine-grained per-operation control
- `grant: 'READ', to: 'read'` — only users with the `read` scope can call GET
- `@requires: 'admin'` — the `clearAll` action needs the `admin` scope

---

### Step 3 — Add XSUAA to package.json

```json
"cds": {
    "requires": {
        "db": {
            "kind": "sqlite",
            "credentials": { "database": "db/greetings.db" }
        },
        "auth": {
            "kind": "xsuaa"
        }
    }
}
```

Locally, CAP will look for a `default-env.json` or `VCAP_SERVICES` to find XSUAA credentials. For local testing, you can use the mock auth:

```json
"auth": {
    "kind": "mocked",
    "users": {
        "alice": { "roles": ["read"] },
        "bob":   { "roles": ["read", "write"] },
        "carol": { "roles": ["read", "write", "admin"] }
    }
}
```

---

### Step 4 — Test mocked auth locally

With mocked auth, pass the username as a Basic Auth header:

```bash
# Read (works for alice)
curl -u alice: http://localhost:4004/hello/Greetings

# Create (fails for alice, works for bob)
curl -u alice: -X POST http://localhost:4004/hello/Greetings \
  -H "Content-Type: application/json" \
  -d '{"message": "test"}'
# → 403 Forbidden

curl -u bob: -X POST http://localhost:4004/hello/Greetings \
  -H "Content-Type: application/json" \
  -d '{"message": "test"}'
# → 201 Created
```

---

### How XSUAA tokens work in production

```
User logs in via BTP IdP
  → XSUAA issues a JWT token
    → Token contains: user ID, email, assigned scopes
      → Every API request includes the token in Authorization header
        → CAP validates the token signature against XSUAA's public key
          → CAP checks if token scopes satisfy the CDS annotations
            → Allow or 403
```

The JWT token is cryptographically signed — it can't be faked. CAP verifies it without calling XSUAA on every request (it caches the public key).

---

### Viewing a JWT token

A XSUAA JWT looks like: `eyJhbGci...eyJ1c2VyX2...signature`

Paste it at [jwt.io](https://jwt.io) to decode it (safe for development tokens). The payload looks like:

```json
{
    "user_name": "bob@example.com",
    "scope": ["hello-app.read", "hello-app.write"],
    "exp": 1735689600
}
```

---

### Common mistakes

**Mistake:** Scope name doesn't match between `xs-security.json` and CDS annotation
**Result:** Users get 403 even with the right role. The scope in `xs-security.json` is `$XSAPPNAME.write` which expands to `hello-app.write`. In CDS `@restrict` you use just `write` (CAP adds the app prefix automatically).

**Mistake:** Forgetting `@requires: 'authenticated-user'` at the service level
**Result:** Anonymous users can still call GET even if individual entities have `@restrict`.

**Mistake:** Using role collections directly in CDS annotations
**Result:** CAP checks scopes, not role collections. Always annotate with scopes or role template names.
$md$
where slug = '12-auth-test';

-- ─────────────────────────────────────────────
-- 13-Destination-Test
-- ─────────────────────────────────────────────
update public.topics set content_md = $md$
## BTP Destinations — Portable Service URLs

Hardcoding `http://localhost:4004` in your UI5 app is fine for local development. The moment you deploy to BTP, that URL is wrong. Destinations solve this by moving the target URL out of your code and into BTP's configuration — your app references the destination name, and BTP resolves it at runtime.

---

### The problem with hardcoded URLs

```json
// manifest.json (fragile)
"dataSources": {
    "mainService": {
        "uri": "http://localhost:4004/hello/",
        "type": "OData"
    }
}
```

This works on your laptop. On BTP it points at nothing. You'd have to maintain different `manifest.json` files per environment — a maintenance nightmare.

---

### The destination solution

```
Your UI5 app → requests "/hello/" (relative)
  ↓
Approuter receives the request
  ↓
Looks up destination "cap-backend" in BTP
  ↓
Forwards to the actual URL: https://your-cap-service.cfapps.eu10.hana.ondemand.com
```

Your app only knows the name `"cap-backend"`. The real URL lives in BTP and can be changed without touching your code.

---

### Step 1 — Create a destination in BTP cockpit

In the BTP cockpit: **Connectivity → Destinations → New Destination**

```
Name:           cap-backend
Type:           HTTP
URL:            https://your-cap-service.cfapps.eu10.hana.ondemand.com
Proxy Type:     Internet
Authentication: NoAuthentication  (XSUAA handles auth separately)
```

For a service that requires XSUAA auth:
```
Authentication: OAuth2JWTBearer
Client ID:      <from your XSUAA service instance>
Client Secret:  <from your XSUAA service instance>
Token Service URL: <XSUAA token URL>
```

---

### Step 2 — Update manifest.json to use relative URL

```json
"sap.app": {
    "dataSources": {
        "mainService": {
            "uri": "/hello/",
            "type": "OData",
            "settings": {
                "odataVersion": "4.0",
                "localUri": "localService/metadata.xml"
            }
        }
    }
}
```

`/hello/` is now relative. The approuter maps it to the right destination.

---

### Step 3 — Configure xs-app.json in the approuter

```json
{
    "welcomeFile": "/index.html",
    "authenticationMethod": "route",
    "routes": [
        {
            "source": "^/hello/(.*)$",
            "target": "$1",
            "destination": "cap-backend",
            "authenticationType": "xsuaa",
            "csrfProtection": false
        },
        {
            "source": "^(.*)$",
            "target": "$1",
            "localDir": "webapp",
            "authenticationType": "xsuaa"
        }
    ]
}
```

The first route: any request to `/hello/...` gets forwarded to the `cap-backend` destination.
The second route: everything else is served from the static `webapp` folder.

---

### Step 4 — Local development with a destination proxy

Locally you don't have BTP, so you need to simulate the destination. Add to `ui5.yaml`:

```yaml
server:
  customMiddleware:
    - name: fiori-tools-proxy
      afterMiddleware: compression
      configuration:
        ignoreCertError: false
        backend:
          - path: /hello
            url: http://localhost:4004
```

This is the local equivalent of the BTP destination — `/hello` requests go to `localhost:4004`.

---

### Why destinations are the right pattern

| Concern | Without destinations | With destinations |
|---|---|---|
| URL changes | Edit code, rebuild, redeploy | Change in BTP cockpit, no code change |
| Credentials | In code or env files | Secured in BTP Destination service |
| Per-environment config | Different builds | Same build, different destination config |
| Certificate trust | Manual | Handled by BTP |

---

### Common mistakes

**Mistake:** Destination name in `xs-app.json` doesn't match the BTP cockpit name
**Result:** 502 Bad Gateway. The approuter can't find the destination.

**Mistake:** Using `http://` for a production destination
**Result:** Security warning or blocked by browser. Production destinations should always use `https://`.

**Mistake:** Not creating a `localService/metadata.xml` for offline development
**Result:** UI5 tries to fetch `$metadata` from the real service, fails when offline. Generate it once with `cds metadata` and commit it.
$md$
where slug = '13-destination-test';

-- ─────────────────────────────────────────────
-- 14-AppRouter-Test
-- ─────────────────────────────────────────────
update public.topics set content_md = $md$
## The Approuter — Authentication Gateway

The approuter is a Node.js application that sits between the browser and all your backend services. It handles login redirects, validates XSUAA tokens, routes requests to destinations, and serves static UI5 files. Without it, you'd have to implement all of that yourself.

---

### What the approuter does

```
Browser
  ↓ request
Approuter
  ├─ Not logged in? → redirect to XSUAA login page
  ├─ Logged in? → validate JWT token
  └─ Route the request:
      ├─ /hello/* → forward to cap-backend destination (with token)
      └─ /* → serve static files from webapp/
```

One entry point. Everything behind it is protected.

---

### Project structure with approuter

```
my-app/
├── app/                    ← approuter
│   ├── xs-app.json         ← routing config
│   └── package.json
├── webapp/                 ← UI5 static files
├── srv/                    ← CAP service
├── db/                     ← data model
├── xs-security.json
└── mta.yaml
```

---

### Step 1 — Create the approuter package

In `app/package.json`:

```json
{
    "name": "approuter",
    "version": "1.0.0",
    "description": "Application Router",
    "dependencies": {
        "@sap/approuter": "^14"
    },
    "scripts": {
        "start": "node node_modules/@sap/approuter/approuter.js"
    }
}
```

```bash
cd app
npm install
```

---

### Step 2 — xs-app.json

```json
{
    "welcomeFile": "/index.html",
    "authenticationMethod": "route",
    "sessionTimeout": 30,
    "routes": [
        {
            "source": "^/hello/(.*)$",
            "target": "$1",
            "destination": "cap-backend",
            "authenticationType": "xsuaa",
            "csrfProtection": false
        },
        {
            "source": "^/(.*)$",
            "target": "$1",
            "localDir": ".",
            "authenticationType": "xsuaa"
        }
    ]
}
```

**Route matching:**
- Routes are evaluated top-to-bottom, first match wins
- `source` is a regex against the request path
- `$1` in `target` refers to the first capture group in `source`
- `authenticationType: "xsuaa"` means the user must be logged in for this route
- `authenticationType: "none"` for public routes (health checks, landing pages)

---

### Step 3 — Bind XSUAA in mta.yaml

```yaml
modules:
  - name: hello-app-approuter
    type: approuter.nodejs
    path: app
    requires:
      - name: hello-xsuaa
      - name: hello-destination-service
    parameters:
      disk-quota: 256M
      memory: 256M

  - name: hello-srv
    type: nodejs
    path: gen/srv
    requires:
      - name: hello-xsuaa
      - name: hello-db

resources:
  - name: hello-xsuaa
    type: org.cloudfoundry.managed-service
    parameters:
      service: xsuaa
      service-plan: application
      path: ./xs-security.json

  - name: hello-destination-service
    type: org.cloudfoundry.managed-service
    parameters:
      service: destination
      service-plan: lite
```

The `requires` section binds service instances to modules. The approuter gets `VCAP_SERVICES` at runtime with the XSUAA and Destination credentials injected automatically.

---

### Step 4 — Local testing with the approuter

```bash
# Set environment variables for local XSUAA mock
export destinations='[{"name":"cap-backend","url":"http://localhost:4004","forwardAuthToken":true}]'

# Start the approuter (from app/ folder)
npm start
```

Or use `default-env.json` in the `app/` folder:

```json
{
    "destinations": [
        {
            "name": "cap-backend",
            "url": "http://localhost:4004",
            "forwardAuthToken": true
        }
    ],
    "VCAP_SERVICES": {
        "xsuaa": [...]
    }
}
```

---

### How token forwarding works

When `forwardAuthToken: true` on a destination:

1. Browser sends request to approuter with XSUAA JWT in cookie
2. Approuter extracts the token
3. Approuter adds `Authorization: Bearer <token>` to the forwarded request
4. CAP receives the request with the token and can validate scopes

Without this, CAP would see an unauthenticated request even though the user is logged in.

---

### Session vs token

| | Session (approuter) | Token (XSUAA JWT) |
|---|---|---|
| Lives in | Browser cookie | HTTP header |
| Expires | After `sessionTimeout` minutes | After token expiry (usually 12h) |
| Renewed by | Any browser request | Approuter refreshes using refresh token |
| Content | Session ID only | User info + scopes |

The approuter maintains the session and refreshes tokens — you don't have to manage this.

---

### Common mistakes

**Mistake:** Routes in `xs-app.json` are in the wrong order
**Result:** The catch-all `^/(.*)$` matches before your API route, serving static files instead of proxying. Always put specific routes before the catch-all.

**Mistake:** `csrfProtection: false` missing for API routes
**Result:** POST/PATCH/DELETE requests get rejected with 403 CSRF error. Disable it for API routes (XSUAA tokens provide protection instead).

**Mistake:** Not binding the destination service to the approuter
**Result:** Approuter can't look up destinations. Bind both `xsuaa` and `destination` service instances.
$md$
where slug = '14-approuter-test';

-- ─────────────────────────────────────────────
-- 15-Deploy-Test  Deploy to BTP
-- ─────────────────────────────────────────────
update public.topics set content_md = $md$
## Deploying to SAP BTP

Everything you've built locally now goes live. This episode walks through `mta.yaml`, the build pipeline, and `cf deploy` — step by step, with every error you're likely to hit explained.

---

### Prerequisites

```bash
# Cloud Foundry CLI
cf --version   # should be 8.x

# MTA Build Tool
mbt --version  # install: npm install -g mbt

# CF MTA Plugin
cf plugins | grep MTA   # install: cf install-plugin multiapps
```

Log in to BTP:
```bash
cf login -a https://api.cf.eu10.hana.ondemand.com
# Enter your BTP credentials
cf target -o your-org -s your-space
```

---

### Understanding mta.yaml

`mta.yaml` is the manifest for your entire multi-target application. It tells the MTA build tool what to build and the CF deployer how to deploy it.

```yaml
_schema-version: '3.1'
ID: hello-app
version: 1.0.0
description: "Hello CAP + UI5 App"

modules:

  # ── CAP backend service ──────────────────────
  - name: hello-srv
    type: nodejs
    path: gen/srv          # built by cds build
    requires:
      - name: hello-db
      - name: hello-xsuaa
    parameters:
      buildpack: nodejs_buildpack
      memory: 256M
    build-parameters:
      builder: npm
      build-result: .

  # ── Database deployer (runs once at deploy) ──
  - name: hello-db-deployer
    type: hdb
    path: gen/db
    requires:
      - name: hello-db
    parameters:
      buildpack: nodejs_buildpack

  # ── Approuter ────────────────────────────────
  - name: hello-approuter
    type: approuter.nodejs
    path: app
    requires:
      - name: hello-xsuaa
      - name: hello-destination-service
      - name: srv-api              # route binding
    parameters:
      memory: 256M

resources:

  # ── HANA (production database) ───────────────
  - name: hello-db
    type: com.sap.xs.hdi-container
    parameters:
      service: hana
      service-plan: hdi-shared

  # ── XSUAA ────────────────────────────────────
  - name: hello-xsuaa
    type: org.cloudfoundry.managed-service
    parameters:
      service: xsuaa
      service-plan: application
      path: ./xs-security.json
      config:
        xsappname: hello-app
        tenant-mode: dedicated

  # ── Destination service ───────────────────────
  - name: hello-destination-service
    type: org.cloudfoundry.managed-service
    parameters:
      service: destination
      service-plan: lite
```

---

### Step 1 — Build the CAP service for production

```bash
# Build CAP artifacts (generates gen/srv and gen/db)
cds build --production
```

This compiles your `.cds` files into deployable artifacts. It creates:
- `gen/srv/` — the Node.js service with compiled models
- `gen/db/` — the HANA deployment artifacts (HDI design-time objects)

---

### Step 2 — Build the MTA archive

```bash
mbt build
```

This packages everything into a single `.mtar` file:
```
mta_archives/hello-app_1.0.0.mtar
```

The archive contains all modules (approuter, CAP service, DB artifacts) zipped together.

---

### Step 3 — Deploy

```bash
cf deploy mta_archives/hello-app_1.0.0.mtar
```

Watch the output carefully. The deployer:
1. Creates/updates service instances (XSUAA, HANA, Destination)
2. Deploys the DB deployer (runs HDI deploy to create tables)
3. Starts the CAP service
4. Starts the approuter

The first deployment takes 5-10 minutes — HANA container provisioning is slow.

---

### Step 4 — Verify the deployment

```bash
cf apps
# Shows: hello-approuter   started   1/1   256M
#        hello-srv          started   1/1   256M

cf routes
# Shows the generated URL, e.g.:
# hello-approuter.cfapps.eu10.hana.ondemand.com
```

Open the approuter URL in your browser — you should be redirected to XSUAA login.

---

### Troubleshooting failed deployments

```bash
# See logs for a specific app
cf logs hello-srv --recent

# See logs live during deploy
cf logs hello-approuter

# Check app environment
cf env hello-srv
```

**Common failure: HANA HDI deploy fails**
```bash
cf logs hello-db-deployer --recent
```
Usually a schema error in your `db/` CDS files.

**Common failure: CAP service crashes on start**
```bash
cf logs hello-srv --recent
```
Usually a missing environment variable or wrong VCAP_SERVICES binding.

---

### Incremental re-deploy (after code changes)

```bash
cds build --production
mbt build
cf deploy mta_archives/hello-app_1.0.0.mtar --strategy rolling
```

`--strategy rolling` keeps the old version running until the new one is healthy — zero downtime.

---

### Common mistakes

**Mistake:** Running `cf deploy` without `cds build --production` first
**Result:** Deploying stale or missing `gen/` artifacts. Always build first.

**Mistake:** `xs-security.json` `xsappname` doesn't match the XSUAA resource config in `mta.yaml`
**Result:** Role templates aren't created, users can't get assigned roles.

**Mistake:** CAP service URL not set as a destination after deployment
**Result:** Approuter can't find `cap-backend`. Create the destination manually in BTP cockpit pointing to your deployed CAP service URL.
$md$
where slug = '15-deploy-test';

-- ─────────────────────────────────────────────
-- 16-MP-1-Test  Capstone: Data Model
-- ─────────────────────────────────────────────
update public.topics set content_md = $md$
## Capstone Part 1 — Design Your Own Data Model

No starter code. No step-by-step guide. You apply everything from Modules 2 and 3 to build something of your own. This episode is about the hardest part: designing the data model before writing a single line of UI code.

---

### Why design first?

Every mistake you make in your data model costs you twice — once when you realize the schema is wrong, once when you have to rewrite the UI to match the fixed schema. Spend 20 minutes on paper before touching the keyboard.

---

### How to design a CDS data model

**Step 1 — Name your entities (nouns)**

Write down the "things" in your domain. If you're building a task tracker:
- Task
- User
- Project
- Comment

Each noun is probably an entity.

**Step 2 — Identify relationships (verbs)**

- A Task *belongs to* a Project → `task.project : Association to Projects`
- A Task *is assigned to* a User → `task.assignee : Association to Users`
- A User *has many* Tasks → `user.tasks : Association to many Tasks on tasks.assignee = $self`

**Step 3 — Add properties to each entity**

Think about what the UI needs to display, filter, and sort. You don't need to be exhaustive — start small and add later.

---

### Example: Task Tracker domain

```cds
namespace sap.capstone;

entity Projects {
    key ID          : UUID;
        name        : String(100) not null;
        description : String(500);
        status      : String(20) default 'active';
        createdAt   : Timestamp @cds.on.insert: $now;
}

entity Users {
    key ID          : UUID;
        name        : String(100) not null;
        email       : String(200) not null;
        role        : String(20) default 'member';
}

entity Tasks {
    key ID          : UUID;
        title       : String(200) not null;
        description : String(1000);
        status      : String(20) default 'open'
            @assert.range enum { open; in_progress; done; cancelled; };
        priority    : Integer default 2;
        dueDate     : Date;
        project     : Association to Projects;
        assignee    : Association to Users;
        createdAt   : Timestamp @cds.on.insert: $now;
        updatedAt   : Timestamp @cds.on.update: $now;
}

entity Comments {
    key ID          : UUID;
        text        : String(2000) not null;
        task        : Association to Tasks;
        author      : Association to Users;
        createdAt   : Timestamp @cds.on.insert: $now;
}
```

**Annotations used:**
- `not null` — required field, CAP enforces this
- `@assert.range enum { ... }` — only these values are valid for this field
- `@cds.on.insert: $now` — auto-fill on create
- `@cds.on.update: $now` — auto-fill on every update

---

### Your service definition

```cds
using sap.capstone from '../db/schema';

@requires: 'authenticated-user'
service TaskService @(path: '/tasks') {

    entity Projects as projection on sap.capstone.Projects;

    entity Users    as projection on sap.capstone.Users;

    entity Tasks    as projection on sap.capstone.Tasks
        { *, project.name as projectName, assignee.name as assigneeName };

    entity Comments as projection on sap.capstone.Comments;
}
```

The `{ *, project.name as projectName }` part expands the Association and adds a computed column — your UI can display the project name without a separate API call.

---

### Self-check before continuing

Ask yourself these questions:

```
□ Can I describe every entity in one sentence?
□ Does every association make sense in both directions?
□ Have I identified which fields need to be required (not null)?
□ Have I thought about what the list view shows (3-4 columns max)?
□ Have I thought about what the detail view shows (all fields)?
□ Are there any fields that should be auto-computed (timestamps, defaults)?
```

If any answer is "not sure" — resolve it before writing UI code.

---

### Deploy to SQLite and seed test data

```bash
cds deploy --to sqlite:db/capstone.db
```

Create `db/data/sap.capstone-Projects.csv`:
```csv
ID,name,status
proj-1,Website Redesign,active
proj-2,Mobile App,active
proj-3,Backend Migration,on_hold
```

Create `db/data/sap.capstone-Tasks.csv`:
```csv
ID,title,status,priority,project_ID
task-1,Design mockups,open,1,proj-1
task-2,Write API docs,in_progress,2,proj-2
task-3,Setup CI/CD,done,2,proj-3
```

Note: For associations, the CSV column name is `EntityName_ID` (e.g. `project_ID`).

---

### Choosing your own domain

Don't use the Task Tracker if you want to build something you care about. Pick a domain you'd actually use. Good options:
- Book/movie tracker
- Recipe manager
- Expense tracker
- Bug tracker
- Inventory system

The only constraint: it needs at least 2 entities with a relationship between them so you can practice associations.
$md$
where slug = '16-mp-1-test';

-- ─────────────────────────────────────────────
-- 17-MP-2-Test  Capstone: UI
-- ─────────────────────────────────────────────
update public.topics set content_md = $md$
## Capstone Part 2 — Build the Full UI5 Frontend

Your data model is designed and deployed. Now build the complete UI5 front-end: multi-screen navigation, full OData CRUD, and at least one Value Help dialog — without step-by-step guidance. This is where you prove you've internalized the course.

---

### Your checklist before writing a single line

```
□ Sketch the screens on paper (or whiteboard)
□ Identify which screen shows the list
□ Identify which screen shows the detail / edit form
□ Identify which fields need a Value Help (F4) dialog
□ Identify which fields need validation
□ Plan the routing config (route names, patterns, parameters)
```

Draw arrows between screens. Label each arrow with the UI5 route name and the URL parameter it passes.

---

### Suggested screen structure

```
App.view.xml (NavContainer shell)
  ├── List.view.xml         → shows all tasks, with search + filter
  │     └── [item tap]
  │           ↓ navTo("detail", { id })
  ├── Detail.view.xml       → shows one task in full
  │     └── [Edit button]
  │           ↓ navTo("edit", { id })
  └── Edit.view.xml         → edit form with save / cancel
```

---

### Routing config template

```json
"routing": {
    "config": {
        "routerClass": "sap.m.routing.Router",
        "viewType": "XML",
        "viewPath": "sap.capstone.view",
        "controlId": "app",
        "controlAggregation": "pages"
    },
    "routes": [
        { "pattern": "",                "name": "list",   "target": "list"   },
        { "pattern": "detail/{taskId}", "name": "detail", "target": "detail" },
        { "pattern": "edit/{taskId}",   "name": "edit",   "target": "edit"   },
        { "pattern": "new",             "name": "new",    "target": "edit"   }
    ],
    "targets": {
        "list":   { "viewName": "List"   },
        "detail": { "viewName": "Detail" },
        "edit":   { "viewName": "Edit"   }
    }
}
```

Both "edit existing" and "create new" use the same `Edit` view — check for `taskId` in `_onRouteMatched` to know which mode you're in.

---

### Edit view: create vs edit mode

```js
_onRouteMatched: function(oEvent) {
    var sTaskId = oEvent.getParameter("arguments").taskId;

    if (sTaskId) {
        // EDIT mode — bind view to the existing task
        this.getView().bindElement("/Tasks(" + sTaskId + ")");
        this._bCreateMode = false;
    } else {
        // CREATE mode — use a local draft model
        this.getView().getModel("draft").setData({
            title: "",
            status: "open",
            priority: 2,
            project_ID: null,
            assignee_ID: null
        });
        this._bCreateMode = true;
    }
},

onSave: function() {
    if (this._bCreateMode) {
        // POST new task
        var oDraft = this.getView().getModel("draft").getData();
        this.getView().getModel().bindList("/Tasks").create(oDraft)
            .created().then(() => this.getOwnerComponent().getRouter().navTo("list"));
    } else {
        // PATCH existing — submit pending changes
        this.getView().getModel().submitBatch("myGroup")
            .then(() => this.getOwnerComponent().getRouter().navTo("list"));
    }
}
```

---

### Value Help on the Project field

Your task has a `project_ID` field. Instead of typing a project ID, the user should pick from a list of projects. This is your F4 Value Help from Episode 4 — now against real OData data from Episode 9.

```xml
<Input
    id="projectInput"
    showValueHelp="true"
    valueHelpRequest="onProjectValueHelp"
    value="{draft>/projectName}" />
```

```js
onProjectValueHelp: function() {
    // Open a SelectDialog bound to /Projects
    // Same pattern as Episode 9 — OData-backed F4
    if (!this._pProjectDialog) {
        this._pProjectDialog = this.loadFragment({
            name: "sap.capstone.fragment.ProjectValueHelp"
        });
    }
    this._pProjectDialog.then(oDialog => {
        oDialog.getBinding("items").refresh();
        oDialog.open();
    });
},

onProjectConfirm: function(oEvent) {
    var oItem = oEvent.getParameter("selectedItem");
    if (oItem) {
        var oCtx = oItem.getBindingContext();
        this.getView().getModel("draft").setProperty("/project_ID", oCtx.getProperty("ID"));
        this.getView().getModel("draft").setProperty("/projectName", oCtx.getProperty("name"));
    }
}
```

---

### If you get stuck — which episode to revisit

| Getting stuck on | Go back to |
|---|---|
| Router won't navigate | Episode 2 — routing config, `navTo`, `attachPatternMatched` |
| List binding empty | Episode 7 — ODataModel setup, manifest dataSources |
| Save not persisting | Episode 8 — `listBinding.create()`, `context.delete()`, `submitBatch` |
| Value Help showing wrong data | Episode 9 — filter + `oBinding.refresh()` |
| Validation not working | Episode 10 — `setValueState`, binding type constraints |

---

### Self-verify before moving to Part 3

```
□ List screen shows all items from the database
□ Tapping an item navigates to the detail screen
□ Detail screen shows the item's data via bindElement
□ Edit form saves changes back to the database
□ Create new item form POSTs to CAP and appears in the list
□ Delete works from the list or detail screen
□ Value Help dialog opens, searches, and fills the field
□ Back button works on all screens
```

All 8 checkboxes? You're ready for Part 3.
$md$
where slug = '17-mp-2-test';

-- ─────────────────────────────────────────────
-- 18-MP-3-Test  Capstone: Polish
-- ─────────────────────────────────────────────
update public.topics set content_md = $md$
## Capstone Part 3 — Polish: Validation, Search, and Sort

Your capstone works. Now make it feel finished. A working app and a polished app are separated by these details: every form validates before saving, errors are explained clearly, lists are searchable, columns are sortable. This episode applies Episodes 10 and 11 to your own app.

---

### Polish checklist

```
□ Every required field shows an error state if empty on save
□ Type mismatches (text in a number field) are caught before the API call
□ CAP backend validation errors surface in the UI (not swallowed)
□ Success feedback after every save/delete (MessageToast)
□ Destructive actions have a confirmation dialog (MessageBox.confirm)
□ List is searchable (SearchField filtering at least one column)
□ At least one column is sortable (toggle asc/desc)
□ Empty state: what does the user see if the list has no items?
□ Loading state: what shows while data is being fetched?
```

---

### Validation pass — add to your Edit view controller

```js
_validateForm: function() {
    var oView = this.getView();
    var bValid = true;

    // Required field check
    var aRequiredIds = ["titleInput", "projectInput"];
    aRequiredIds.forEach(function(sId) {
        var oControl = oView.byId(sId);
        var sValue = (oControl.getValue ? oControl.getValue() : oControl.getSelectedKey()).trim();
        if (!sValue) {
            oControl.setValueState("Error");
            oControl.setValueStateText("This field is required");
            bValid = false;
        } else {
            oControl.setValueState("None");
        }
    });

    // Priority must be 1-5
    var oPriority = oView.byId("priorityInput");
    var iPriority = parseInt(oPriority.getValue(), 10);
    if (isNaN(iPriority) || iPriority < 1 || iPriority > 5) {
        oPriority.setValueState("Error");
        oPriority.setValueStateText("Priority must be between 1 and 5");
        bValid = false;
    } else {
        oPriority.setValueState("None");
    }

    return bValid;
},

onSave: function() {
    if (!this._validateForm()) {
        sap.m.MessageBox.error("Please fix the errors before saving.");
        return;
    }
    // proceed with save...
}
```

---

### Surface CAP errors in the UI

When CAP returns a validation error (e.g. `req.error(400, "Title too short")`), ODataModel V4 rejects the Promise from `create()` or `submitBatch()`:

```js
oContext.created().catch(function(oError) {
    // oError.message contains the CAP error text
    sap.m.MessageBox.error(oError.message || "Save failed. Please try again.");
});

// Or for submitBatch:
this.getView().getModel().submitBatch("myGroup").catch(function(oError) {
    sap.m.MessageBox.error(oError.message);
});
```

Never let a `.catch()` go unhandled — silent failures destroy user confidence.

---

### Confirmation before delete

```js
onDeletePress: function(oEvent) {
    var oContext = oEvent.getSource().getBindingContext();
    var sTitle = oContext.getProperty("title");

    sap.m.MessageBox.confirm(
        'Delete "' + sTitle + '"? This cannot be undone.',
        {
            title: "Confirm Delete",
            actions: [sap.m.MessageBox.Action.DELETE, sap.m.MessageBox.Action.CANCEL],
            emphasizedAction: sap.m.MessageBox.Action.DELETE,
            onClose: function(sAction) {
                if (sAction === sap.m.MessageBox.Action.DELETE) {
                    oContext.delete().then(function() {
                        sap.m.MessageToast.show("Deleted successfully");
                    }).catch(function(oError) {
                        sap.m.MessageBox.error("Delete failed: " + oError.message);
                    });
                }
            }
        }
    );
}
```

---

### Search on the list view

```js
onSearch: function(oEvent) {
    var sQuery = oEvent.getParameter("query") || oEvent.getParameter("newValue") || "";
    var oBinding = this.byId("taskList").getBinding("items");

    if (sQuery.trim()) {
        var oFilter = new sap.ui.model.Filter({
            filters: [
                new sap.ui.model.Filter("title", sap.ui.model.FilterOperator.Contains, sQuery),
                new sap.ui.model.Filter("projectName", sap.ui.model.FilterOperator.Contains, sQuery)
            ],
            and: false
        });
        oBinding.filter([oFilter]);
    } else {
        oBinding.filter([]);
    }
}
```

---

### Sort on the list view

```js
_sSortField: "title",
_bSortDesc: false,

onSortChange: function(oEvent) {
    var sField = oEvent.getParameter("selectedItem").getKey();
    if (sField === this._sSortField) {
        this._bSortDesc = !this._bSortDesc;
    } else {
        this._sSortField = sField;
        this._bSortDesc = false;
    }
    var oSorter = new sap.ui.model.Sorter(this._sSortField, this._bSortDesc);
    this.byId("taskList").getBinding("items").sort([oSorter]);
}
```

Add a `Select` control to the toolbar with options for each sortable column (title, dueDate, priority).

---

### Empty state

Don't show a blank white space when the list is empty:

```xml
<List id="taskList" items="{/Tasks}" noDataText="No tasks found. Click Add to create one." >
    ...
</List>
```

Or with a custom `IllustratedMessage` for a more polished look:

```xml
<List id="taskList" items="{/Tasks}">
    <noData>
        <IllustratedMessage
            illustrationType="sapIllus-NoData"
            title="No Tasks"
            description="Create your first task using the Add button above." />
    </noData>
    ...
</List>
```

---

### Loading state — BusyIndicator

```js
onInit: function() {
    // Show busy state while data loads
    this.byId("taskList").setBusy(true);
    this.byId("taskList").getBinding("items").attachEventOnce("dataReceived", function() {
        this.byId("taskList").setBusy(false);
    }.bind(this));
}
```

---

### The finished feel

A polished app:
- Never silently fails
- Never shows a blank/broken state
- Guides the user when something goes wrong
- Confirms before destroying data
- Responds instantly to search input

These aren't visual design choices — they're the difference between a prototype and a product.
$md$
where slug = '18-mp-3-test';

-- ─────────────────────────────────────────────
-- 19-MP-4-Test  Capstone: Deploy
-- ─────────────────────────────────────────────
update public.topics set content_md = $md$
## Capstone Part 4 — Secure and Deploy Your App

This is the finish line. You'll add XSUAA authentication to your capstone, configure the approuter, and deploy everything to BTP. When this is done, you have a real, secured, live application you built from scratch.

---

### Final checklist overview

```
□ xs-security.json defines scopes for your domain
□ CDS service has @requires and @restrict annotations
□ xs-app.json routes API calls to your CAP service
□ mta.yaml binds all modules and services correctly
□ cds build --production succeeds
□ mbt build creates the .mtar archive
□ cf deploy succeeds
□ Deployed app: login works
□ Deployed app: read/write operations work
□ Deployed app: navigation between screens works
```

---

### Step 1 — xs-security.json for your domain

Adapt this template to your domain:

```json
{
    "xsappname": "capstone-app",
    "tenant-mode": "dedicated",
    "scopes": [
        {
            "name": "$XSAPPNAME.read",
            "description": "Read access to all entities"
        },
        {
            "name": "$XSAPPNAME.write",
            "description": "Create and update records"
        },
        {
            "name": "$XSAPPNAME.delete",
            "description": "Delete records"
        }
    ],
    "role-templates": [
        {
            "name": "Viewer",
            "scope-references": ["$XSAPPNAME.read"]
        },
        {
            "name": "Editor",
            "scope-references": ["$XSAPPNAME.read", "$XSAPPNAME.write"]
        },
        {
            "name": "Manager",
            "scope-references": ["$XSAPPNAME.read", "$XSAPPNAME.write", "$XSAPPNAME.delete"]
        }
    ],
    "role-collections": [
        {
            "name": "CapstonViewer",
            "role-template-references": ["$XSAPPNAME.Viewer"]
        },
        {
            "name": "CapstonManager",
            "role-template-references": ["$XSAPPNAME.Manager"]
        }
    ]
}
```

---

### Step 2 — Annotate your CDS service

```cds
@requires: 'authenticated-user'
service TaskService @(path: '/tasks') {

    entity Tasks as projection on sap.capstone.Tasks
        @(restrict: [
            { grant: 'READ',   to: 'read'  },
            { grant: ['CREATE','UPDATE'], to: 'write'  },
            { grant: 'DELETE', to: 'delete' }
        ]);

    entity Projects as projection on sap.capstone.Projects
        @(restrict: [
            { grant: 'READ', to: 'read' },
            { grant: ['CREATE','UPDATE','DELETE'], to: 'write' }
        ]);
}
```

---

### Step 3 — xs-app.json

```json
{
    "welcomeFile": "/index.html",
    "authenticationMethod": "route",
    "routes": [
        {
            "source": "^/tasks/(.*)$",
            "target": "$1",
            "destination": "capstone-backend",
            "authenticationType": "xsuaa",
            "csrfProtection": false
        },
        {
            "source": "^(.*)$",
            "target": "$1",
            "localDir": ".",
            "authenticationType": "xsuaa"
        }
    ]
}
```

---

### Step 4 — mta.yaml

```yaml
_schema-version: '3.1'
ID: capstone-app
version: 1.0.0

modules:
  - name: capstone-srv
    type: nodejs
    path: gen/srv
    requires:
      - name: capstone-db
      - name: capstone-xsuaa
    parameters:
      memory: 256M

  - name: capstone-db-deployer
    type: hdb
    path: gen/db
    requires:
      - name: capstone-db

  - name: capstone-approuter
    type: approuter.nodejs
    path: app
    requires:
      - name: capstone-xsuaa
      - name: capstone-destination
    parameters:
      memory: 256M

resources:
  - name: capstone-db
    type: com.sap.xs.hdi-container
    parameters:
      service: hana
      service-plan: hdi-shared

  - name: capstone-xsuaa
    type: org.cloudfoundry.managed-service
    parameters:
      service: xsuaa
      service-plan: application
      path: ./xs-security.json
      config:
        xsappname: capstone-app
        tenant-mode: dedicated

  - name: capstone-destination
    type: org.cloudfoundry.managed-service
    parameters:
      service: destination
      service-plan: lite
```

---

### Step 5 — Build and deploy

```bash
# 1. Build CAP artifacts
cds build --production

# 2. Package everything into .mtar
mbt build

# 3. Deploy to BTP
cf deploy mta_archives/capstone-app_1.0.0.mtar
```

---

### Step 6 — Post-deployment: create the destination

After the CAP service is deployed, get its URL:
```bash
cf apps
# capstone-srv   started   1/1   256M   capstone-srv.cfapps.eu10.hana.ondemand.com
```

In BTP cockpit → **Connectivity → Destinations → New**:
```
Name:           capstone-backend
Type:           HTTP
URL:            https://capstone-srv.cfapps.eu10.hana.ondemand.com
Authentication: OAuth2JWTBearer
Client ID:      (from capstone-xsuaa service key)
Client Secret:  (from capstone-xsuaa service key)
Token URL:      (from capstone-xsuaa service key)
```

---

### Step 7 — Assign yourself a role collection

In BTP cockpit → **Security → Users** → find your email → **Assign Role Collections** → select `CapstonManager`.

Without this, you'll log in but get 403 on every API call.

---

### Verifying the live app end-to-end

```
□ Open the approuter URL
□ Redirected to XSUAA login — log in with your BTP credentials
□ App loads — the list shows your seeded data from HANA
□ Create a new item — appears in the list
□ Update an item — change persists on refresh
□ Delete an item — gone after confirmation
□ Log out (clear cookies) — redirected to login again
□ Share the approuter URL with a colleague — they can log in with their BTP user
```

All checkboxes done? You've built and deployed a complete, secured, full-stack SAP BTP application. This is portfolio-ready.

---

### What you've learned across this course

| Module | Skills |
|---|---|
| 1 (UI5 Basics) | Binding, routing, CRUD on local models, Value Help |
| 2 (CAP Basics) | CDS schemas, OData generation, SQLite persistence |
| 3 (Full Stack) | ODataModel V4, live CRUD, server-side filter/sort |
| 4 (Production) | XSUAA auth, BTP Destinations, Approuter, MTA deployment |
| Capstone | Applying all of the above independently |

You're ready to build real SAP BTP applications.
$md$
where slug = '19-mp-4-test';

-- ─────────────────────────────────────────────
-- 0-SP-Test  Course Introduction
-- ─────────────────────────────────────────────
update public.topics set content_md = $md$
## Welcome to Zero to Deployed

This is the introduction to the course. Before writing your first line of code, you need to understand what you'll build, what tools you need, and why this stack exists.

---

### What this course builds

By the end of this course, you will have built and deployed a complete full-stack application on SAP Business Technology Platform (BTP) using:

- **SAPUI5** — SAP's enterprise JavaScript UI framework
- **CAP (Cloud Application Programming Model)** — SAP's backend framework for BTP
- **XSUAA** — BTP's authentication and authorization service
- **SAP HANA** — SAP's cloud-native database (used in production)
- **Cloud Foundry** — the container platform BTP runs on

Not a toy app. A real, secured, deployed application.

---

### Why this stack?

If you want to build applications that integrate with SAP ERP systems (S/4HANA, SAP BTP, SAP Fiori), this is the stack those applications are built on. Every SAP Fiori app you've used as an end-user was built with UI5. Every modern SAP BTP service that exposes an OData API was likely built with CAP.

---

### How the course is structured

```
Module 1 — UI5 Basics (Episodes 1–4)
  Build a complete UI5 app with routing, CRUD, and dialogs
  against a local JSON model. No backend yet.

Module 2 — CAP Basics (Episodes 5–6)
  Build a CAP backend service with SQLite persistence.
  No UI yet — just a working API you can test in the browser.

Module 3 — Full Stack (Episodes 7–9)
  Connect your UI5 frontend to your CAP backend.
  Everything from Modules 1 and 2 working together.

Module 4 — Production Patterns (Episodes 10–15)
  Validation, search/sort, XSUAA auth, destinations,
  approuter, and a real BTP deployment.

Capstone (Episodes 16–19)
  Build your own app from scratch, applying every skill.
```

Each episode builds on the previous one. Don't skip ahead.

---

### Tools to install before Episode 1

**Node.js (LTS version)**
```bash
node --version  # should be 18.x or 20.x
npm --version   # should be 9.x or 10.x
```
Download: [nodejs.org](https://nodejs.org)

**CAP CLI**
```bash
npm install -g @sap/cds-dk
cds --version
```

**UI5 Tooling**
```bash
npm install -g @ui5/cli
ui5 --version
```

**Cloud Foundry CLI**
```bash
cf --version
```
Download: [github.com/cloudfoundry/cli](https://github.com/cloudfoundry/cli/releases)

**MTA Build Tool**
```bash
npm install -g mbt
mbt --version
```

**A code editor**
VS Code with the SAP CDS Language Support extension is strongly recommended:
- Extension ID: `SAPSE.vscode-cds`
- Gives you syntax highlighting and autocomplete for `.cds` files

**A BTP trial account**
Free at [account.hanatrial.ondemand.com](https://account.hanatrial.ondemand.com). You'll need this from Episode 12 onwards.

---

### BTP trial account setup

1. Sign up at the link above
2. Create a subaccount (Cloud Foundry environment, region eu10 recommended)
3. Enable the **SAP HANA Cloud** service (needed for Episodes 14–19)
4. Note your API endpoint: `https://api.cf.eu10.hana.ondemand.com`

You won't need the BTP account until Module 4. Get it set up now so you're not blocked later.

---

### How to follow along

Each episode has:
- A **full explanation** of every concept used
- **Annotated code** with comments explaining each line
- A **project structure** showing exactly what files to create
- **Common mistakes** at the end — read these even if your code works

The best way to learn is to type the code yourself, not copy-paste. When something breaks (it will), read the error message carefully before asking for help — most errors in this course are explained in the "Common mistakes" sections.
$md$
where slug = '0-sp-test';
