-- CodeGoLive — SAP BTP Final Assessment Questions (55 questions)
-- Run AFTER assessment_migration.sql
-- Each question maps to a topic slug for review links.

truncate public.assessment_questions restart identity cascade;

insert into public.assessment_questions
  (course_id, question, options, correct_option, explanation, topic_slug, order_num)
values

-- ===== MODULE 0: Setup & BTP Basics (0-sp-test) =====
('sap-btp',
 'What is SAP Business Application Studio (BAS)?',
 '["A desktop IDE installed on Windows", "A cloud-hosted development environment provided by SAP on BTP", "A local code editor plugin for VS Code", "A SAP HANA database browser"]',
 1,
 'SAP Business Application Studio is a cloud-based IDE running on SAP BTP. It provides pre-configured dev spaces for SAP development without any local installation.',
 '0-sp-test', 1),

('sap-btp',
 'What is the correct first step when starting a new BTP trial?',
 '["Install SAP GUI on your computer", "Create a Cloud Foundry environment and org in the BTP cockpit", "Download the SAP BTP SDK locally", "Configure an on-premise S/4HANA system"]',
 1,
 'In a BTP trial, you first activate a subaccount and create a Cloud Foundry environment (org + space). This gives you the runtime to deploy applications.',
 '0-sp-test', 2),

('sap-btp',
 'Which command creates a new SAPUI5 project in a BAS dev space using the Fiori tools CLI?',
 '["npm create sapui5", "yo @sap/fiori", "cf create-app", "cds init --ui5"]',
 1,
 'The Yeoman generator `yo @sap/fiori` (Fiori tools CLI) creates a scaffolded SAPUI5/Fiori project with the required folder structure and configuration files.',
 '0-sp-test', 3),

('sap-btp',
 'What does a BTP subaccount represent?',
 '["A physical server in SAP data centres", "An isolated environment within a global account for organizing resources and entitlements", "A personal user profile in the BTP cockpit", "A specific SAP application like S/4HANA"]',
 1,
 'A BTP subaccount is an isolated organizational unit inside a global account. It has its own entitlements, users, and environments (CF, Kyma, etc.).',
 '0-sp-test', 4),

-- ===== MODULE 1: SAPUI5 Single Screen (1-ss-test) =====
('sap-btp',
 'In SAPUI5, what is the purpose of the Component.js file?',
 '["It defines the OData service URL", "It is the entry point of the SAPUI5 app, initialising the root view and routing", "It contains CSS styles for the application", "It handles CAP service definitions"]',
 1,
 'Component.js is the application entry point. It extends sap.ui.core.UIComponent, declares the manifest, and bootstraps the root view and router.',
 '1-ss-test', 5),

('sap-btp',
 'Which HTML attribute bootstraps the SAPUI5 framework in index.html?',
 '["data-sap-ui-theme", "id=\"sap-ui-bootstrap\"", "src=\"sap-ui-core.js\"", "Both B and C are required together"]',
 3,
 'The `id="sap-ui-bootstrap"` attribute on the `<script>` tag pointing to `sap-ui-core.js` is how SAPUI5 is bootstrapped. Both the id and the src are required.',
 '1-ss-test', 6),

('sap-btp',
 'What does the `xmlns:m="sap.m"` declaration in an XML view do?',
 '["Imports a CSS stylesheet from sap.m", "Defines the namespace prefix `m` so you can use sap.m controls like <m:Button>", "Registers a new module with the framework", "Connects to a backend OData service"]',
 1,
 'XML namespace declarations map a prefix (like `m`) to a SAPUI5 library (like `sap.m`). This lets you write `<m:Button>` instead of the full qualified name.',
 '1-ss-test', 7),

('sap-btp',
 'In a SAPUI5 MVC pattern, which component handles user interaction logic?',
 '["The XML View", "The JSON Model", "The Controller (.controller.js)", "The manifest.json"]',
 2,
 'The Controller contains the event handler methods (onPress, onInit, etc.). The View defines the UI structure and the Model holds the data.',
 '1-ss-test', 8),

-- ===== MODULE 1: Multi Screen & Routing (2-ms-test) =====
('sap-btp',
 'Where is SAPUI5 routing configuration defined?',
 '["In Component.js directly", "In the `sap.ui5.routing` section of manifest.json", "In the controller\'s onInit method", "In a separate routes.json file"]',
 1,
 'Routing is configured in the `sap.ui5.routing` section of manifest.json. It declares routes (URL patterns), targets (views to display), and the router class.',
 '2-ms-test', 9),

('sap-btp',
 'Which method triggers navigation to a named route in SAPUI5?',
 '["this.getRouter().navTo(\"routeName\", parameters)", "sap.ui.navigate(\"routeName\")", "this.byId(\"router\").go(\"routeName\")", "window.location.href = \"#/routeName\""]',
 0,
 '`this.getRouter().navTo()` is the SAPUI5 API for programmatic navigation. It looks up the route by name and updates the browser URL hash accordingly.',
 '2-ms-test', 10),

('sap-btp',
 'In SAPUI5 routing, what is a "target"?',
 '["The backend URL the app connects to", "The view that is rendered when a route matches", "A placeholder in the URL pattern like {id}", "The default landing page"]',
 1,
 'A target in SAPUI5 routing specifies which view (and optionally which aggregation/container) is displayed when the associated route is matched.',
 '2-ms-test', 11),

('sap-btp',
 'How do you read a URL parameter (e.g. `{itemId}`) from a matched route in the controller?',
 '["this.getOwnerComponent().getModel(\"route\").getProperty(\"/itemId\")", "oEvent.getParameter(\"arguments\").itemId inside attachPatternMatched handler", "this.byId(\"itemId\").getValue()", "window.location.hash.split(\"/\")[1]"]',
 1,
 'You attach a handler to `this.getRouter().getRoute(\"routeName\").attachPatternMatched(handler)`. Inside the handler, `oEvent.getParameter("arguments")` gives you the matched URL parameters.',
 '2-ms-test', 12),

-- ===== MODULE 1: CRUD Local (3-crud-test) =====
('sap-btp',
 'In SAPUI5, which model type is used to store in-memory JSON data (no backend)?',
 '["sap.ui.model.odata.v2.ODataModel", "sap.ui.model.json.JSONModel", "sap.ui.model.resource.ResourceModel", "sap.ui.model.xml.XMLModel"]',
 1,
 'JSONModel stores data as a plain JavaScript object in memory. It is perfect for local data, mock data, and UI state management without any backend.',
 '3-crud-test', 13),

('sap-btp',
 'After adding a new item to a JSONModel array, what must you call to refresh the bound list UI?',
 '["oModel.reset()", "oModel.refresh(true) or oList.getBinding(\"items\").refresh()", "oList.rerender()", "oModel.setData() with the same data again"]',
 1,
 'JSONModel does not automatically detect array mutations. After pushing a new item, you must call `oModel.refresh(true)` or refresh the binding directly to trigger the list to re-render.',
 '3-crud-test', 14),

('sap-btp',
 'What SAPUI5 control is typically used to show a pop-up dialog for Create/Edit operations?',
 '["sap.m.Popover", "sap.m.Dialog", "sap.m.MessageBox", "sap.m.Panel"]',
 1,
 '`sap.m.Dialog` is the standard control for modal dialogs in SAPUI5. It can contain form controls and action buttons for Create/Edit operations.',
 '3-crud-test', 15),

-- ===== MODULE 1: Value Help (4-f4-test) =====
('sap-btp',
 'Which event on a SAPUI5 Input control is fired when the user clicks the value help icon (F4)?',
 '["onChange", "valueHelpRequest", "liveChange", "suggest"]',
 1,
 'The `valueHelpRequest` event is fired when the user presses F4 or clicks the value help icon on an Input with `showValueHelp="true"`. This is where you open your value help dialog.',
 '4-f4-test', 16),

('sap-btp',
 'What is the purpose of using a Fragment (sap.ui.core.Fragment) for a value help dialog?',
 '["To improve rendering performance via server-side compilation", "To define a reusable UI snippet (like a dialog) in a separate XML file, keeping the main view clean", "To create a permanent popup that persists across navigation", "To share a single model instance between multiple views"]',
 1,
 'Fragments let you define UI snippets (like dialogs) in separate XML files and load them on demand. This keeps the main view clean and allows the dialog to be loaded only when needed.',
 '4-f4-test', 17),

-- ===== MODULE 2: CAP Fundamentals (5-cap-1-test) =====
('sap-btp',
 'What command initialises a new CAP (Cloud Application Programming) project?',
 '["npm create cap-project", "cds init <projectName>", "cf create-service cap", "mvn archetype:generate -DarchetypeId=cap"]',
 1,
 '`cds init` scaffolds a new CAP project with the standard folder structure: `db/` for data models, `srv/` for services, and `app/` for UI apps.',
 '5-cap-1-test', 18),

('sap-btp',
 'In CAP, what is CDS (Core Data Services)?',
 '["A database query language, alternative to SQL", "A domain-specific language for defining data models and service interfaces declaratively", "A JavaScript framework for building REST APIs", "A configuration format for Cloud Foundry deployment"]',
 1,
 'CDS is the modelling language at the heart of CAP. You define entities (data model) and services (API) in `.cds` files, and CAP auto-generates OData/REST endpoints and database DDL.',
 '5-cap-1-test', 19),

('sap-btp',
 'In a CAP `.cds` file, which keyword defines a database entity (table)?',
 '["service", "entity", "define", "table"]',
 1,
 'The `entity` keyword in CDS defines a database entity (table). Example: `entity Books { key ID : Integer; title : String; }`',
 '5-cap-1-test', 20),

('sap-btp',
 'What does `cds watch` do in CAP development?',
 '["Deploys the app to Cloud Foundry", "Starts a local development server with hot-reload, serving OData endpoints", "Watches for CSS changes and reloads the browser", "Runs CDS unit tests continuously"]',
 1,
 '`cds watch` starts a local CAP server that watches for file changes. It serves your OData/REST API locally on port 4004, making it easy to test without any deployment.',
 '5-cap-1-test', 21),

('sap-btp',
 'In a CAP service definition, what does `@readonly` on an entity mean?',
 '["The entity is hidden from the API", "The entity can only be read (GET); create, update, delete are not allowed via the service", "The entity is cached permanently", "The entity maps to a database view"]',
 1,
 '`@readonly` restricts the service to expose only READ operations for that entity. Attempts to POST/PATCH/DELETE will be rejected with an error.',
 '5-cap-1-test', 22),

-- ===== MODULE 2: SQLite Persistence (6-sqllite-test) =====
('sap-btp',
 'Which command deploys a CAP data model to a local SQLite database?',
 '["cds build --to sqlite", "cds deploy --to sqlite", "npm run sqlite", "cf push --sqlite"]',
 1,
 '`cds deploy --to sqlite` generates the SQLite DDL from your CDS model and creates/updates the `.db` file in your project. It also loads seed data from CSV files in `db/data/`.',
 '6-sqllite-test', 23),

('sap-btp',
 'Where do you put CSV seed data in a CAP project for SQLite?',
 '["In the root package.json under `seeds`", "In `db/data/` as `<namespace>-<EntityName>.csv` files", "In the `srv/` folder as service-data files", "In a `data.json` file at the project root"]',
 1,
 'CAP automatically loads CSV files from `db/data/` during `cds deploy`. The file name must match the entity\'s fully qualified name, e.g., `my.namespace-Books.csv`.',
 '6-sqllite-test', 24),

('sap-btp',
 'In a CDS entity, what does the `key` keyword signify?',
 '["The field is optional", "The field is the primary key - it must be unique and is used in OData single-record URLs", "The field is encrypted in the database", "The field is a foreign key reference"]',
 1,
 '`key` marks a field as the primary key of an entity. In OData, key fields form the entity key used in URLs like `/Books(1)`. CAP enforces uniqueness for key fields.',
 '6-sqllite-test', 25),

-- ===== MODULE 3: CAP + Single Screen (7-cap-ss-test) =====
('sap-btp',
 'In SAPUI5, which model type connects to a CAP OData V4 service?',
 '["sap.ui.model.json.JSONModel", "sap.ui.model.odata.v4.ODataModel", "sap.ui.model.odata.v2.ODataModel", "sap.ui.model.xml.XMLModel"]',
 1,
 'For CAP services (which expose OData V4), you use `sap.ui.model.odata.v4.ODataModel`. OData V2 model is for older systems. JSONModel is for local in-memory data.',
 '7-cap-ss-test', 26),

('sap-btp',
 'Where in manifest.json do you configure the OData service URL for a SAPUI5 app?',
 '["In `sap.app.services`", "In `sap.ui5.models` — map a model name to a data source defined in `sap.app.dataSources`", "In `sap.ui5.routing.config`", "In `sap.platform.cf`"]',
 1,
 'OData connections are declared in `sap.app.dataSources` (URL, type) and consumed in `sap.ui5.models` (mapping model name to data source). The model is then available in all views.',
 '7-cap-ss-test', 27),

('sap-btp',
 'What is the OData $metadata document used for?',
 '["It documents the privacy policy of the service", "It describes the service\'s entity types, properties, and relationships in XML so clients can understand the API", "It lists the server performance metrics", "It contains the deployment configuration"]',
 1,
 'OData $metadata is a machine-readable XML document at `<serviceRoot>/$metadata` that describes all entity types, key fields, navigation properties, and service operations.',
 '7-cap-ss-test', 28),

-- ===== MODULE 3: CAP + CRUD (8-cap-ms-test) =====
('sap-btp',
 'In CAP, how do you add custom logic (e.g. validation) before an entity is created?',
 '["Override the SQL trigger in the database", "Use `this.before(\"CREATE\", \"EntityName\", handler)` in a service implementation JS file", "Edit the CDS entity with a @validate annotation", "Add a pre-save hook in manifest.json"]',
 1,
 'CAP uses event hooks in the service JS file. `this.before("CREATE", "Books", handler)` runs your handler before the default create logic. You can validate or transform the request payload.',
 '8-cap-ms-test', 29),

('sap-btp',
 'Which HTTP method maps to an OData/CAP "Update" operation (replacing specific fields)?',
 '["PUT (full replacement)", "PATCH (partial update)", "POST (create)", "DELETE"]',
 1,
 'OData/CAP uses PATCH for partial updates (only provided fields are changed). PUT replaces the whole record. POST creates. DELETE removes.',
 '8-cap-ms-test', 30),

('sap-btp',
 'In SAPUI5 with an OData V4 model, how do you submit a batch of changes (create/update/delete) to the backend?',
 '["oModel.submit()", "oModel.submitBatch(\"groupId\")", "oBinding.save()", "oModel.refresh(true)"]',
 1,
 'OData V4 model uses batch groups. Changes made via bound contexts are queued, and `oModel.submitBatch(groupId)` sends them all as a single $batch request to the backend.',
 '8-cap-ms-test', 31),

-- ===== MODULE 3: CAP + Value Help (9-cap-f4-test) =====
('sap-btp',
 'In CAP, how can you expose a separate entity for value help (lookup list) alongside a main entity?',
 '["Create a separate service exposing only the lookup entity, or include it in the same service with @readonly", "Add the lookup to a separate CDS project", "Use a dedicated `valueHelp.cds` filename", "Value helps require a SAP Fiori Elements annotation only"]',
 0,
 'You can include a `@readonly` entity in the same service for lookups, or expose it via a separate service. CAP does not require separate projects — same `srv/` file is fine.',
 '9-cap-f4-test', 32),

-- ===== MODULE 4: Validation & Messages (10-validation-test) =====
('sap-btp',
 'Which SAPUI5 control displays a short transient notification at the bottom of the screen?',
 '["sap.m.Dialog", "sap.m.MessageToast", "sap.m.MessageBox", "sap.m.BusyIndicator"]',
 1,
 'MessageToast shows a brief, non-blocking notification that automatically disappears. MessageBox is modal. Dialog is a full dialog. BusyIndicator shows a loading spinner.',
 '10-validation-test', 33),

('sap-btp',
 'In SAPUI5, what is the `ValueState` property of an Input control used for?',
 '["Setting the default value", "Showing visual validation feedback (None, Success, Warning, Error, Information)", "Binding the control to an OData field", "Defining the input mask format"]',
 1,
 'The `valueState` property (e.g., `sap.ui.core.ValueState.Error`) adds a coloured border and icon to the Input control, giving the user instant visual validation feedback.',
 '10-validation-test', 34),

('sap-btp',
 'What does CAP\'s `@assert.range` annotation do?',
 '["It specifies the date range for data archival", "It automatically validates that a field value falls within allowed bounds at the service layer", "It sets min/max on an HTML input element", "It restricts database column size"]',
 1,
 '`@assert.range` is a CDS annotation that makes CAP automatically reject requests where the annotated field falls outside the specified range, returning an OData error.',
 '10-validation-test', 35),

-- ===== MODULE 4: Filter & Sort (11-filter-sort-test) =====
('sap-btp',
 'In SAPUI5, which class is used to filter a list binding programmatically?',
 '["sap.ui.model.Filter", "sap.m.SearchField with autoSearch=true", "sap.ui.model.Condition", "sap.m.ViewSettingsDialog"]',
 0,
 '`sap.ui.model.Filter` is constructed with a field path, operator (Contains, EQ, GT...), and value. You apply it via `oBinding.filter([oFilter])` on a list binding.',
 '11-filter-sort-test', 36),

('sap-btp',
 'Which SAPUI5 class is used to sort a list binding?',
 '["sap.ui.model.Sorter", "sap.m.SortItem", "sap.ui.core.Order", "sap.m.ListSorter"]',
 0,
 '`sap.ui.model.Sorter` takes a field path and an optional `bDescending` boolean. You apply it via `oBinding.sort(new Sorter("fieldName", true))`.',
 '11-filter-sort-test', 37),

('sap-btp',
 'In an OData request, what does the `$filter` system query option do?',
 '["Specifies which properties to return (projection)", "Filters the result set server-side based on a Boolean expression", "Limits the number of returned records", "Sorts results by a field"]',
 1,
 '`$filter` (e.g., `?$filter=Price gt 20`) is an OData query option that filters records on the server before returning them. SAPUI5\'s OData model translates Filter objects into `$filter` automatically.',
 '11-filter-sort-test', 38),

-- ===== MODULE 4: Auth / XSUAA (12-auth-test) =====
('sap-btp',
 'What is XSUAA in the SAP BTP context?',
 '["Extended SAP UI5 Application Architecture — a new UI framework", "The SAP BTP Authorization and Authentication service, providing OAuth 2.0 tokens and role management", "A cross-subaccount user synchronisation agent", "An XML-based user account format"]',
 1,
 'XSUAA (Extended Services for Cloud Foundry UAA) is the OAuth 2.0 / OIDC-compliant identity and access management service on SAP BTP. It issues JWT tokens containing user roles and scopes.',
 '12-auth-test', 39),

('sap-btp',
 'In a CDS service definition, what does `@requires: "authenticated-user"` do?',
 '["Stores user credentials in the database", "Restricts the service so only authenticated users with a valid JWT can access it", "Sends an email invitation to new users", "Enables multi-factor authentication for the entity"]',
 1,
 '`@requires: "authenticated-user"` is a CAP authorization annotation that rejects any unauthenticated request (no valid JWT) with a 401 Unauthorized response.',
 '12-auth-test', 40),

('sap-btp',
 'What is the xs-security.json file used for in a BTP app?',
 '["It stores SSL certificates for HTTPS", "It defines the OAuth 2.0 scopes and roles for the XSUAA service instance used by the app", "It configures Cross-Site Scripting protection headers", "It lists trusted IP addresses for the subaccount"]',
 1,
 'xs-security.json defines the security descriptor for your app — OAuth scopes, role templates, and role collections. This file is passed to the XSUAA service instance during creation.',
 '12-auth-test', 41),

('sap-btp',
 'In a CAP custom handler, how do you get the current logged-in user?',
 '["req.headers.user", "req.user (or req.user.id) provided by the CAP request context", "process.env.USER", "this.getModel(\"user\").getProperty(\"/name\")"]',
 1,
 'CAP automatically populates `req.user` with the authenticated user\'s details (id, tenant, roles) from the JWT token. You access it in any `before/on/after` handler.',
 '12-auth-test', 42),

-- ===== MODULE 4: Destinations (13-destination-test) =====
('sap-btp',
 'What problem does a BTP Destination solve?',
 '["It speeds up database queries by caching results", "It externalises backend service URLs and credentials so they aren\'t hardcoded in application code", "It routes HTTP traffic between Cloud Foundry spaces", "It translates OData V2 to OData V4 automatically"]',
 1,
 'Destinations store connectivity details (URL, auth type, credentials) in the BTP cockpit. Apps reference the destination by name — the actual URL and credentials are never hardcoded.',
 '13-destination-test', 43),

('sap-btp',
 'Which BTP service is required to use destinations from within a Cloud Foundry application?',
 '["SAP Connectivity Service", "Destination Service (sap-destination)", "SAP HANA Service", "SAP Cloud Identity Service"]',
 1,
 'The Destination service (`sap-destination`) is the Cloud Foundry service that provides API access to destinations defined in the BTP cockpit. Apps bind to it and call its API to get destination details at runtime.',
 '13-destination-test', 44),

-- ===== MODULE 4: App Router (14-approuter-test) =====
('sap-btp',
 'What is the primary role of the SAP Application Router (App Router) in a BTP application?',
 '["It replaces the CAP backend service", "It acts as the single entry point for the application, handling authentication, routing, and serving static files", "It is a middleware for validating SAPUI5 XML views", "It provides a built-in CDS compiler"]',
 1,
 'The App Router is a Node.js app that sits in front of your microservices. It handles XSUAA authentication (OAuth flow), routes requests to CAP backend or UI5 static files based on `xs-app.json`.',
 '14-approuter-test', 45),

('sap-btp',
 'What is the xs-app.json file used for?',
 '["Defining CAP entity models", "Configuring the App Router\'s route rules — which paths map to which backend services or static resources", "Listing Cloud Foundry environment variables", "Configuring BTP subaccount entitlements"]',
 1,
 'xs-app.json is the routing configuration file for the App Router. Each route entry specifies a URL pattern (`source`) and where to forward it (`destination`, `localDir`, or `service`).',
 '14-approuter-test', 46),

('sap-btp',
 'In xs-app.json, what does `"authenticationType": "xsuaa"` on a route mean?',
 '["The route only works on secure HTTPS connections", "The App Router will enforce XSUAA authentication for requests to this route — unauthenticated users are redirected to login", "The route uses basic HTTP authentication", "The route is blocked for external traffic"]',
 1,
 '`"authenticationType": "xsuaa"` tells the App Router to require a valid XSUAA JWT for that route. Unauthenticated requests trigger the OAuth 2.0 authorization code flow.',
 '14-approuter-test', 47),

-- ===== MODULE 4: Deployment (15-deploy-test) =====
('sap-btp',
 'What is mta.yaml used for in BTP deployment?',
 '["It is the CAP data model file", "It is the Multi-Target Application descriptor that defines all modules (UI, backend, approuter) and resources (services) to deploy together as a unit", "It stores environment-specific configuration values like API keys", "It is the SAPUI5 manifest alternative for MTA projects"]',
 1,
 'mta.yaml is the MTA (Multi-Target Application) descriptor. It lists all application modules and BTP service resources, their dependencies, and build parameters. `cf deploy` uses it to deploy everything at once.',
 '15-deploy-test', 48),

('sap-btp',
 'Which command builds a CAP project for production deployment?',
 '["cds watch --production", "cds build --production", "npm run build", "cf package"]',
 1,
 '`cds build --production` compiles CDS models to EDMX and generates optimised artefacts for deployment. It creates a `gen/` folder with the compiled output ready for Cloud Foundry.',
 '15-deploy-test', 49),

('sap-btp',
 'What Cloud Foundry command deploys an MTA archive to BTP?',
 '["cf push", "cf deploy <archive.mtar>", "cf create-app", "cf install-mta"]',
 1,
 '`cf deploy` (from the MTA Deploy Plugin) deploys a `.mtar` archive to Cloud Foundry. Unlike `cf push` which deploys a single app, `cf deploy` handles the entire multi-target application.',
 '15-deploy-test', 50),

('sap-btp',
 'After deploying to BTP Cloud Foundry, which command shows the status of running applications?',
 '["cf status", "cf apps", "cf list", "btp list applications"]',
 1,
 '`cf apps` lists all applications in the current Cloud Foundry space with their state (started/stopped), instances, memory, and URL.',
 '15-deploy-test', 51),

-- ===== MODULE 5: Capstone Concepts =====
('sap-btp',
 'In CAP, how do you define an association (relationship) between two entities?',
 '["Using SQL FOREIGN KEY syntax in the .cds file", "Using the `Association to` or `Composition of` keywords in CDS entity definitions", "By creating a join table manually in the database", "Using the @association annotation"]',
 1,
 'CDS uses `Association to Entity` for unmanaged relationships and `Composition of Entity` for parent-child (owns) relationships. CAP handles the underlying foreign key and navigation property generation.',
 '16-mp-1-test', 52),

('sap-btp',
 'What is the difference between `Association` and `Composition` in CDS?',
 '["Association is for integers, Composition is for strings", "Association links to independently managed entities; Composition creates a parent-child ownership — composed child entities cannot exist without the parent", "Composition is a many-to-many association", "They are identical keywords — interchangeable"]',
 1,
 'In CDS: `Association` is a loose link between independent entities. `Composition` implies ownership — the child\'s lifecycle is bound to the parent. CAP enforces cascaded operations on Compositions.',
 '16-mp-1-test', 53),

('sap-btp',
 'In SAPUI5 data binding, what does the curly brace syntax `{property}` in XML attributes represent?',
 '["A CSS class name", "A property binding expression that binds the attribute value to a model property at the current binding context path", "A JavaScript function call", "An i18n text key"]',
 1,
 '`{propertyName}` is SAPUI5\'s shorthand for property binding. It reads the value from the model at the current context path and keeps it in sync. E.g., `<Text text=\"{firstName}\"/>`.',
 '17-mp-2-test', 54),

-- ===== MODULE 6: Troubleshooting =====
('sap-btp',
 'You get a CORS error when calling your CAP backend from SAPUI5 running on localhost:8080. What is the most common fix?',
 '["Add CORS headers to manifest.json", "Configure `cds.server.cors` in package.json, or use a proxy in the UI5 tooling config to route requests through the same origin", "Install the CORS browser extension", "Change the CAP service to use HTTP instead of HTTPS"]',
 1,
 'CORS errors occur because the browser blocks requests from a different origin. For local development, the easiest fix is to configure a proxy in ui5.yaml / package.json so the SAPUI5 dev server forwards API calls to CAP as if they were same-origin.',
 '20-rtp-test', 55),

('sap-btp',
 'What does HTTP 401 Unauthorized mean in the context of a CAP service with XSUAA?',
 '["The database is down", "The request lacks a valid JWT or the token has expired", "The user exists but does not have the required role (that would be 403)", "The CAP service is not running"]',
 1,
 'HTTP 401 means authentication failed — no token provided, or the JWT is invalid/expired. HTTP 403 means authenticated but not authorised (missing role/scope).',
 '20-rtp-test', 56),

('sap-btp',
 'Your SAPUI5 list is empty but the OData $metadata loads fine. What should you check first?',
 '["Delete and recreate the manifest.json", "Verify the entity set name in the binding path matches the OData service exactly (case-sensitive) and that the service returns data", "Reinstall the SAPUI5 framework", "Check if BAS subscription has expired"]',
 1,
 'A blank list almost always means the binding path is wrong (wrong entity name, missing leading slash, or wrong model name prefix) or the backend returned 0 records. Check browser DevTools network tab for the actual OData request URL and response.',
 '20-rtp-test', 57),

('sap-btp',
 'When running `cf deploy` you get "No space found". What does this mean?',
 '["The mta.yaml file is missing", "Your Cloud Foundry space has run out of memory quota or you are not targeting the correct CF org/space", "The .mtar archive is too large to upload", "XSUAA service creation failed"]',
 1,
 '"No space found" usually means you are not logged in to CF (`cf login`), or you have not targeted the right org and space (`cf target -o ORG -s SPACE`). Check with `cf target`.',
 '15-deploy-test', 58),

('sap-btp',
 'In CAP, you see "entity Books is not exposed by service CatalogService". What is wrong?',
 '["The entity is in the wrong .cds file", "The `Books` entity is defined in the data model but not included (or not re-exposed) in the CatalogService service definition", "SQLite driver is missing", "The port 4004 is already in use"]',
 1,
 'CAP services only expose entities explicitly listed in the `service` block. You need `service CatalogService { entity Books as projection on my.Books; }` in your service .cds file.',
 '5-cap-1-test', 59),

('sap-btp',
 'Which OData system query option limits the number of records returned?',
 '["$skip", "$top", "$count", "$filter"]',
 1,
 '`$top=N` returns only the first N records. `$skip=M` skips M records (used together with $top for pagination). `$count` returns the total record count. `$filter` filters records.',
 '11-filter-sort-test', 60);

select count(*) as total_questions from public.assessment_questions;
