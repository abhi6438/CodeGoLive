-- Module 8 topics for dev-quickstart


INSERT INTO topics (module_id, number, slug, title, focus, description, content_md, order_index, status) VALUES (
  (SELECT id FROM modules WHERE course_id = 'dev-quickstart' AND number = '8'),
  '710',
  'dev-qs-ui5-generate',
  'Generate Your First SAPUI5 App',
  'Use SAP Fiori Application Generator to scaffold a SAPUI5 project',
  'Open the Fiori Application Generator in VS Code, pick a Fiori Elements template, connect to an OData service, and generate the project skeleton.',
  '# Generate Your First SAPUI5 App

The fastest way to start a SAPUI5 project is the **SAP Fiori Application Generator** inside VS Code.

## Step 1 — Open the generator

Press `Ctrl+Shift+P` → type **Fiori: Open Application Generator** → press Enter.

## Step 2 — Choose a template

Select **SAP Fiori Elements** → **List Report Page** (good default for most enterprise apps).

## Step 3 — Choose a data source

For a local mock server (no BTP account needed yet), select:

- Data source: **None**
- Template: **List Report Page**
- Click **Next**

## Step 4 — Fill in project details

| Field | Example value |
|-------|---------------|
| Module name | `my-first-app` |
| Application title | `My First App` |
| Application namespace | `com.mycompany` |
| Description | `Learning SAPUI5` |
| Add deployment configuration | No (for now) |

Click **Finish**. The generator creates the folder and runs `npm install` automatically.

## Step 5 — Open the project

```bash
cd my-first-app
code .
```

## Alternative — using the @ui5/cli directly

```bash
npm create fiori-app my-first-app
# follow the prompts
```

## What gets generated

```
my-first-app/
├── webapp/
│   ├── manifest.json       ← app descriptor (most important file)
│   ├── Component.js        ← app entry point
│   ├── index.html          ← local test page
│   └── view/               ← XML views
├── ui5.yaml                ← build/serve config
└── package.json
```

The `manifest.json` is the heart of every SAPUI5 app — it declares the data model, routing, and UI settings.
',
  0,
  'published'
);


INSERT INTO topics (module_id, number, slug, title, focus, description, content_md, order_index, status) VALUES (
  (SELECT id FROM modules WHERE course_id = 'dev-quickstart' AND number = '8'),
  '711',
  'dev-qs-ui5-folder-structure',
  'SAPUI5 Folder Structure Explained',
  'Understand every folder and file in a generated SAPUI5 project',
  'Walk through each part of a SAPUI5 app folder — webapp, manifest.json, Component.js, views, controllers, and build config.',
  '# SAPUI5 Folder Structure Explained

Every SAPUI5 app follows a predictable structure. Here''s what each part means.

```
my-app/
├── webapp/                  ← all runtime source code lives here
│   ├── manifest.json        ← app descriptor (routing, data, i18n)
│   ├── Component.js         ← app entry point — bootstraps the whole app
│   ├── index.html           ← local dev HTML — not deployed to production
│   │
│   ├── view/                ← XML views — one file per screen
│   │   └── Main.view.xml
│   │
│   ├── controller/          ← JS controllers — logic for each view
│   │   └── Main.controller.js
│   │
│   ├── model/               ← data model setup (OData, JSON)
│   │   └── models.js
│   │
│   ├── i18n/                ← translations
│   │   └── i18n.properties
│   │
│   └── css/                 ← custom styles (use sparingly)
│       └── style.css
│
├── ui5.yaml                 ← @ui5/cli config — serves, builds, deploys
├── package.json             ← npm dependencies and scripts
└── .gitignore
```

## Key files explained

### manifest.json

The single most important file. It declares:

```json
{
  "sap.app": {
    "id": "com.mycompany.myapp",
    "type": "application",
    "dataSources": {
      "mainService": {
        "uri": "/sap/opu/odata/sap/MY_SERVICE/",
        "type": "OData",
        "settings": { "odataVersion": "4.0" }
      }
    }
  },
  "sap.ui5": {
    "routing": {
      "routes": [{ "name": "main", "target": "main" }],
      "targets": {
        "main": { "viewName": "Main" }
      }
    }
  }
}
```

### Component.js

```js
sap.ui.define(["sap/ui/core/UIComponent"], function (UIComponent) {
  return UIComponent.extend("com.mycompany.myapp.Component", {
    metadata: { manifest: "json" },
    init: function () {
      UIComponent.prototype.init.apply(this, arguments);
      this.getRouter().initialize();
    }
  });
});
```

### ui5.yaml

Controls the local server and build process:

```yaml
specVersion: "3.0"
metadata:
  name: my-first-app
type: application
server:
  customMiddleware:
    - name: fiori-tools-proxy
      configuration:
        backend:
          - path: /sap
            url: https://your-btp-service.hana.ondemand.com
```

## Golden rules

1. **Never put business logic in a view** — keep XML clean, put logic in the controller.
2. **All OData paths go in manifest.json** — not hard-coded in controllers.
3. **Use i18n for all user-facing strings** — never hard-code text in XML or JS.
',
  1,
  'published'
);


INSERT INTO topics (module_id, number, slug, title, focus, description, content_md, order_index, status) VALUES (
  (SELECT id FROM modules WHERE course_id = 'dev-quickstart' AND number = '8'),
  '712',
  'dev-qs-ui5-dev-server',
  'Run & Stop the Dev Server',
  'Start, stop, and reload the SAPUI5 local dev server',
  'Use the ui5 serve command to start a local dev server with live reload, understand the URLs it exposes, and learn how to stop it cleanly.',
  '# Run & Stop the SAPUI5 Dev Server

The `@ui5/cli` ships a local development server with live reload.

## Start the server

```bash
cd my-first-app
npm start
# or directly:
ui5 serve --open
```

The `--open` flag opens your default browser automatically.

## Default URLs

| URL | What it shows |
|-----|---------------|
| `http://localhost:8080/index.html` | Your app with mock data |
| `http://localhost:8080/test/flpSandbox.html` | Fiori Launchpad sandbox |

## Live reload

Any time you save a `.js`, `.xml`, or `.json` file inside `webapp/`, the browser refreshes automatically — no manual reload needed.

## Stop the server

Press `Ctrl+C` in the terminal where `ui5 serve` is running.

## Common issues

### Port already in use

```bash
ui5 serve --port 8081
```

Or kill what''s using 8080:

```bash
# macOS / Linux
lsof -ti:8080 | xargs kill

# Windows PowerShell
netstat -ano | findstr :8080
# find the PID, then:
taskkill /PID <pid> /F
```

### App shows blank page

1. Open Chrome DevTools (`F12`) → **Console** tab
2. Look for red errors — usually a missing file path or a mis-spelled view name
3. Check `manifest.json` routing section matches your view file names exactly

## package.json scripts (what `npm start` actually runs)

```json
{
  "scripts": {
    "start": "ui5 serve --open",
    "build": "ui5 build --all --dest dist",
    "lint": "eslint webapp"
  }
}
```

You can add `--config ui5.yaml` if you have multiple config files.
',
  2,
  'published'
);


INSERT INTO topics (module_id, number, slug, title, focus, description, content_md, order_index, status) VALUES (
  (SELECT id FROM modules WHERE course_id = 'dev-quickstart' AND number = '8'),
  '713',
  'dev-qs-ui5-debug',
  'Debugging SAPUI5 in Chrome DevTools',
  'Set breakpoints, inspect the model, and read network calls in DevTools',
  'Use Chrome DevTools to set JS breakpoints in SAPUI5 controllers, inspect the binding context, and read OData network requests.',
  '# Debugging SAPUI5 in Chrome DevTools

Chrome DevTools is the main debugging environment for SAPUI5 apps.

## Enable SAPUI5 Debug Mode

Add `?sap-ui-debug=true` to the URL:

```
http://localhost:8080/index.html?sap-ui-debug=true
```

This loads the non-minified source files, making breakpoints and stack traces readable.

## Set a Breakpoint in a Controller

1. Open DevTools (`F12`) → **Sources** tab
2. Navigate to `webpack://` or find your controller file under `localhost:8080`
3. Click the line number where you want to pause
4. Trigger the action in the UI — execution pauses at your breakpoint

### Quick way — add `debugger` in code

```js
onPress: function (oEvent) {
  debugger; // ← DevTools will pause here
  var oItem = oEvent.getSource();
  // ...
}
```

Remove `debugger` statements before committing.

## Inspect the Binding Context

In DevTools Console, reference any SAPUI5 control by its ID:

```js
// Get the model data bound to a list item
sap.ui.getCore().byId("myList").getBinding("items").getModel().getData()

// Get a specific control and its binding context
var oCtrl = sap.ui.getCore().byId("myInput");
oCtrl.getBindingContext().getObject()
```

## Inspect OData Network Calls

1. Open DevTools → **Network** tab
2. Filter by **XHR** or type `odata` in the filter box
3. Click a request to see:
   - **Headers** — URL, method, auth token
   - **Response** — JSON payload returned by the service
   - **Timing** — how long the request took

### Simulate network errors

In the Network tab, right-click a request → **Block request URL**. This lets you test how your app handles service failures.

## SAPUI5 Support Tool (built-in debugger)

Press `Ctrl+Alt+Shift+S` while the app is running to open the built-in SAPUI5 Support Tool. It shows:

- Model state
- Binding issues
- Performance timeline
- Control tree

## Common errors and what they mean

| Error | Likely cause |
|-------|-------------|
| `Cannot read property ''getModel'' of undefined` | View not rendered yet; code ran too early |
| `TypeError: oEvent.getSource(...).getBindingContext is not a function` | Wrong control type — check the event source |
| `404 on /sap/opu/odata/...` | OData endpoint path in manifest.json is wrong |
',
  3,
  'published'
);
