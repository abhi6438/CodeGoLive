-- CodeGoLive Arena — SAP CAP Question Bank (60 questions)
-- course_id: sap-cap
-- order_num range: 3000–3059 (avoids collision with sap-btp 1000+ and sap-ai 2000+)
-- Run in Supabase SQL Editor after sap_cap_seed.sql

-- ── Batch 1: CAP Foundations (cap-01 to cap-10) ─────────────────────────────
INSERT INTO public.assessment_questions
  (course_id, question, options, correct_option, explanation, topic_slug, order_num)
VALUES
  ('sap-cap',
   'What command scaffolds a new SAP CAP project?',
   '["cds init", "npm create cap", "cf push --cap", "mbt build"]',
   0, 'cds init creates the standard CAP folder structure (db/, srv/, package.json) and wires up the project.',
   'cap-03-first-project', 3000),

  ('sap-cap',
   'Which file is the entry point for CDS data model definitions in a CAP project?',
   '["srv/service.js", "db/schema.cds", "package.json", "app/index.html"]',
   1, 'CDS schema files live in db/. The canonical name is db/schema.cds, though you can use any .cds filename in that folder.',
   'cap-04-project-structure', 3001),

  ('sap-cap',
   'What does `cds watch` do?',
   '["Deploys the app to Cloud Foundry", "Starts a hot-reload dev server that restarts on .cds or .js file changes", "Runs unit tests in watch mode", "Compiles CDS to SQL and exits"]',
   1, 'cds watch starts the CAP development server with hot-reload. Any change to .cds, .js or .json files triggers an automatic restart.',
   'cap-08-run-local', 3002),

  ('sap-cap',
   'In a CDS entity, which keyword marks the primary key field?',
   '["primary", "key", "id", "unique"]',
   1, 'The `key` keyword in CDS marks a field as the entity primary key. E.g., `key ID : UUID;`',
   'cap-05-cds-basics', 3003),

  ('sap-cap',
   'What OData version does SAP CAP serve by default?',
   '["OData V2", "OData V3", "OData V4", "REST only"]',
   2, 'CAP generates OData V4 endpoints by default. OData V2 requires an additional compatibility layer.',
   'cap-09-odata', 3004),

  ('sap-cap',
   'Which CDS built-in type generates a UUID primary key?',
   '["String", "Integer", "UUID", "GUID"]',
   2, 'The `UUID` type generates a universally unique identifier. Combined with `key`, CAP auto-generates the value on INSERT.',
   'cap-06-entities', 3005),

  ('sap-cap',
   'What does the `managed` aspect automatically add to an entity?',
   '["ID, status, and version fields", "createdAt, createdBy, modifiedAt, modifiedBy fields", "A soft-delete deletedAt field", "A UUID primary key"]',
   1, 'The `managed` aspect adds four audit fields: createdAt, createdBy, modifiedAt, modifiedBy — populated automatically by CAP on every insert/update.',
   'cap-20-managed', 3006),

  ('sap-cap',
   'In a CAP CDS service definition, what does `excluding { field }` do?',
   '["Deletes the field from the database", "Hides the field from the OData projection exposed by the service", "Makes the field read-only", "Marks the field as optional"]',
   1, '`excluding { field }` removes a field from the service projection, so it is never sent to the client even though it exists in the database.',
   'cap-07-services', 3007),

  ('sap-cap',
   'Which OData system query option lets you load related entities in one request?',
   '["$filter", "$select", "$expand", "$search"]',
   2, '$expand instructs the OData service to include associated entity data inline in the response, avoiding a second round trip.',
   'cap-09-odata', 3008),

  ('sap-cap',
   'What does CAP''s generic handler provide automatically for an exposed entity?',
   '["Only CREATE and READ", "Full CRUD (CREATE, READ, UPDATE, DELETE) without any custom code", "READ only — writes require custom handlers", "Only READ and DELETE"]',
   1, 'CAP''s generic service provider automatically handles all four CRUD operations for any entity exposed in a CDS service definition.',
   'cap-10-generic-handlers', 3009),

-- ── Batch 2: CDS Data Modeling (cap-11 to cap-22) ───────────────────────────
  ('sap-cap',
   'What is the difference between an Association and a Composition in CDS?',
   '["Associations are many-to-many; Compositions are one-to-many", "Compositions imply ownership and cascade deletes; Associations are independent references", "There is no difference — they are synonyms", "Associations are for HANA only; Compositions work on SQLite"]',
   1, 'A Composition implies ownership: child records are deleted when the parent is deleted. An Association is a plain foreign-key reference with no ownership semantics.',
   'cap-12-associations', 3010),

  ('sap-cap',
   'Which annotation marks a field as mandatory input in CDS?',
   '["@assert.required", "@mandatory", "@Core.Immutable", "@UI.Required"]',
   1, '`@mandatory` in CDS marks a field as required for input validation. CAP rejects CREATE/UPDATE requests that omit the field.',
   'cap-15-input-validation', 3011),

  ('sap-cap',
   'What does `@odata.draft.enabled: true` enable on a CDS entity?',
   '["Soft deletes on the entity", "Draft (work-in-progress) save without activating the record", "Read-only access for anonymous users", "Automatic UUID generation"]',
   1, 'Draft enablement lets users save incomplete records without activating them. Fiori Elements uses this for the standard edit-save-activate flow.',
   'cap-16-draft', 3012),

  ('sap-cap',
   'In CDS, what is a `view`?',
   '["A cached query result stored in HANA", "A CDS projection defined with SELECT that computes a virtual result set", "A UI component definition", "A synonym for a CDS service"]',
   1, 'A CDS view is defined with `SELECT ... from Entity` and creates a virtual entity whose data is computed at query time, similar to a SQL view.',
   'cap-13-projections', 3013),

  ('sap-cap',
   'Where do you place i18n translation files in a CAP project?',
   '["srv/translations/", "_i18n/ in the project root or db/", "app/i18n/", "package.json under \"translations\""]',
   1, 'CAP looks for i18n files in _i18n/ directories (project root, db/, srv/). Files are named messages.properties or messages_<locale>.properties.',
   'cap-18-i18n', 3014),

  ('sap-cap',
   'Which CDS keyword lets you add fields or annotations to an existing entity without modifying its original file?',
   '["extend", "mixin", "override", "annotate"]',
   0, '`extend entity MyEntity with { ... }` adds new elements. `annotate` adds annotations only. Both work without touching the original .cds file.',
   'cap-21-extend', 3015),

  ('sap-cap',
   'What does the `@assert.range` annotation do?',
   '["Validates that a numeric field falls within a specified minimum and maximum", "Sets the display range in a Fiori chart", "Defines the allowed date range for temporal data", "Restricts which users can access the field"]',
   0, '`@assert.range: [min, max]` causes CAP to reject values outside the specified range on INSERT or UPDATE.',
   'cap-15-input-validation', 3016),

  ('sap-cap',
   'How do you model a many-to-many relationship between Products and Tags in CDS?',
   '["Use Composition of many Tags in Products", "Create a link entity (ProductTags) with Associations to both Products and Tags", "Use @many annotation on the Association", "Many-to-many is not supported in CDS"]',
   1, 'CDS does not have native many-to-many syntax. The standard pattern is an explicit link/junction entity with associations to both sides.',
   'cap-22-schema-design', 3017),

  ('sap-cap',
   'What is the purpose of the `cuid` aspect in CDS?',
   '["Adds a UUID primary key field named ID", "Adds created/modified timestamps", "Adds a soft-delete flag", "Adds a numeric auto-increment key"]',
   0, 'The `cuid` aspect adds `key ID : UUID;` — a UUID primary key that CAP auto-generates on INSERT.',
   'cap-11-aspects', 3018),

  ('sap-cap',
   'Which CDS annotation limits a field to a controlled list of allowed string values?',
   '["@assert.range", "@assert.enum", "@mandatory", "@Core.Immutable"]',
   1, '`@assert.enum` validates that the field value is one of the enum values defined for its type.',
   'cap-19-enums', 3019),

-- ── Batch 3: Service Development (cap-23 to cap-34) ─────────────────────────
  ('sap-cap',
   'In CAP Node.js, which method registers a handler for a custom OData action?',
   '["this.action()", "this.on(\"actionName\", handler)", "this.register()", "this.handle()"]',
   1, '`this.on(\"actionName\", handler)` registers a handler for an OData action or a standard CRUD event. The handler receives the req object.',
   'cap-23-custom-handlers', 3020),

  ('sap-cap',
   'What is the correct phase to use for input validation before a DB write in CAP?',
   '["AFTER", "ON", "BEFORE", "COMMIT"]',
   2, 'BEFORE handlers run before the generic handler processes the request, making them the correct place for validation that should block the operation.',
   'cap-24-before-after', 3021),

  ('sap-cap',
   'How do you define a bound OData action in CDS?',
   '["action myAction() returns String; inside a service block", "action myAction() bound to EntityName returns String; inside a service block", "Inside the entity block: action myAction() returns String;", "Using @bound annotation on an unbound action"]',
   2, 'A bound action is declared inside the entity block within the service definition. Unbound actions are declared directly in the service block.',
   'cap-25-actions', 3022),

  ('sap-cap',
   'What does `req.reject(409, \"Message\")` do in a CAP handler?',
   '["Logs a 409 error and continues processing", "Throws an OData error response with HTTP 409 and stops the request", "Retries the request up to 3 times", "Sends a 409 to the client but commits the DB transaction"]',
   1, '`req.reject()` throws an OData-formatted error, rolling back any changes and returning the error to the client. Execution stops immediately.',
   'cap-26-error-handling', 3023),

  ('sap-cap',
   'In CAP, what is the `delegate` pattern used for with remote services?',
   '["Forwarding the incoming OData request to an external service unchanged", "Caching remote service responses in HANA", "Converting OData V4 to REST automatically", "Handling authentication for remote services"]',
   0, 'The delegate pattern forwards incoming queries directly to a remote service: `return remoteService.run(req.query)`. It avoids reimplementing query logic locally.',
   'cap-33-remote-services', 3024),

  ('sap-cap',
   'Which CAP method imports an OData EDMX metadata file as CDS definitions?',
   '["cds compile --edmx", "cds import file.edmx --as cds", "cf push --edmx", "mbt import edmx"]',
   1, '`cds import ./file.edmx --as cds` converts an OData EDMX metadata document into a .cds file that CAP can use as a remote service definition.',
   'cap-33-remote-services', 3025),

  ('sap-cap',
   'How does CAP publish an in-process event from one handler to another?',
   '["this.broadcast(\"eventName\", data)", "this.emit(\"eventName\", data)", "EventBus.send(\"eventName\", data)", "req.publish(\"eventName\", data)"]',
   1, '`this.emit(\"eventName\", data)` dispatches an event within the same CAP process. Other handlers subscribed with `this.on(\"eventName\", ...)` receive it.',
   'cap-27-events', 3026),

  ('sap-cap',
   'In OData $batch, what is a Change Set?',
   '["A group of read requests executed together", "A group of write operations that are committed atomically", "A batch of schema migration commands", "Multiple parallel GET requests"]',
   1, 'A Change Set in OData $batch wraps multiple write operations (POST/PATCH/DELETE) into a single atomic unit — all succeed or all fail together.',
   'cap-31-batch', 3027),

  ('sap-cap',
   'Which CDS annotation enables the Fiori List Report page for an entity?',
   '["@UI.LineItem", "@UI.Table", "@Fiori.ListReport", "@Common.List"]',
   0, '`@UI.LineItem` defines the columns shown in the Fiori Elements List Report table. Without it, no columns are rendered.',
   'cap-29-fiori-annotations', 3028),

  ('sap-cap',
   'In the SAP Event Mesh CloudEvents standard, what is the `source` field?',
   '["The destination topic the event should be delivered to", "A URI identifying the system that produced the event", "The event payload serialisation format", "The consumer group that should receive the event"]',
   1, 'The CloudEvents `source` field is a URI identifying the origin system — e.g., `/sap/cap/my-app/orders`. It uniquely identifies the producer.',
   'cap-28-messaging', 3029),

-- ── Batch 4: Persistence & HANA (cap-35 to cap-46) ──────────────────────────
  ('sap-cap',
   'Which command deploys a CAP project''s schema to an SQLite file for local development?',
   '["cds build --sqlite", "cds deploy --to sqlite", "npm run hana", "cf deploy --sqlite"]',
   1, '`cds deploy --to sqlite` creates an SQLite database file and applies the CDS schema. Used for local development without HANA.',
   'cap-35-sqlite', 3030),

  ('sap-cap',
   'What is an HDI Container in SAP HANA Cloud?',
   '["A Docker container running HANA", "An isolated schema deployment unit managed by the HANA Deployment Infrastructure", "A connection pool for HANA", "A HANA table space"]',
   1, 'An HDI (HANA Deployment Infrastructure) Container is an isolated, versioned schema unit. Each CAP app gets its own HDI container where all its artifacts are deployed.',
   'cap-36-hana-basics', 3031),

  ('sap-cap',
   'Which CDS annotation enables fuzzy full-text search on a HANA column?',
   '["@search.fullText", "@hana.fullTextIndex: { fuzzySearchIndex: true }", "@Common.FullText", "@Search.Ranked"]',
   1, '`@hana.fullTextIndex: { fuzzySearchIndex: true }` creates a HANA full-text index on the column, enabling OData $search and CONTAINS()/FUZZY() queries.',
   'cap-42-full-text', 3032),

  ('sap-cap',
   'When migrating a HANA schema, which change is UNSAFE (can cause data loss or deploy failure)?',
   '["Adding a nullable column", "Adding a new table", "Dropping a column that still has data", "Adding an index"]',
   2, 'Dropping a column is unsafe in HDI because existing data is lost and active deployments using that column will fail. Use the expand/contract pattern instead.',
   'cap-39-migrations', 3033),

  ('sap-cap',
   'Which CDS type maps to HANA''s NCLOB for large text content?',
   '["String(5000)", "Text", "LargeString", "Clob"]',
   2, '`LargeString` in CDS maps to NCLOB in HANA Cloud, allowing text fields of arbitrary size beyond the String(5000) limit.',
   'cap-38-hana-types', 3034),

  ('sap-cap',
   'What does `@restrict where: ''field = $user''` do in a CAP service?',
   '["Restricts access to users with the field role", "Filters entity rows so each user only sees rows where field equals their user ID", "Makes the field read-only for non-admin users", "Hides the field from OData metadata"]',
   1, '`@restrict where` adds an automatic WHERE clause to all queries, filtering rows based on the current user. It implements row-level security declaratively.',
   'cap-43-rls', 3035),

  ('sap-cap',
   'What is the N+1 query problem in CAP, and how is it fixed?',
   '["Reading N entities then making N separate requests for their children — fix with CQL expand/columns", "Making N retries on a failed query — fix with retry logic", "Running N parallel inserts — fix with batch insert", "Fetching N columns when only 1 is needed — fix with $select"]',
   0, 'N+1 fires one query for the parent list then N queries for each child. CQL''s `.columns(o => { o.children(c => c.*) })` collapses it into one JOIN query.',
   'cap-44-perf', 3036),

  ('sap-cap',
   'What plugin enables automatic audit logging for personal data access in CAP?',
   '["@sap/cds-security", "@cap-js/audit-logging", "@sap/xsuaa-audit", "@cap-js/hana-audit"]',
   1, '`@cap-js/audit-logging` hooks into CAP''s read/write lifecycle and logs all personal data access automatically when `@PersonalData` annotations are present.',
   'cap-45-audit-log', 3037),

  ('sap-cap',
   'In the expand/contract migration pattern, what happens in the "Expand" phase?',
   '["You drop the old columns immediately after deployment", "You add new columns/tables while keeping the old ones — both app versions coexist", "You rename the columns using a transaction", "You create a new HDI container and migrate data"]',
   1, 'The Expand phase adds new schema elements without removing old ones, so the old app version (blue) and new version (green) can run simultaneously against the same HANA database.',
   'cap-39-migrations', 3038),

  ('sap-cap',
   'Which annotation on a CDS entity field adds a HANA B-Tree index to improve query performance?',
   '["@hana.index", "@index", "@Common.Indexed", "@Search.Indexed"]',
   1, '`@index` on a CDS field (in the `annotate ... with @index: [{ elements: [\"field\"] }]` form) creates a HANA B-Tree index to speed up WHERE clause queries on that column.',
   'cap-44-perf', 3039),

-- ── Batch 5: Authentication & Authorization (cap-47 to cap-56) ──────────────
  ('sap-cap',
   'What does `@requires: ''admin''` on a CDS service do?',
   '["Adds an admin UI to the service", "Blocks all requests unless the JWT contains the admin scope", "Makes the service read-only for non-admins", "Creates an admin role collection in BTP automatically"]',
   1, '`@requires` gates the entire service (or entity/action) — any request without the specified role/scope in the JWT is rejected with HTTP 403.',
   'cap-51-requires', 3040),

  ('sap-cap',
   'In XSUAA''s xs-security.json, what does `"tenant-mode": "shared"` enable?',
   '["Allows multiple XSUAA instances to share the same service key", "Enables multitenancy — the JWT zid claim identifies the tenant", "Shares the XSUAA service between dev and prod subaccounts", "Allows shared role collections across global accounts"]',
   1, '`"tenant-mode": "shared"` is required for multi-tenant SaaS apps. It makes XSUAA include the zone ID (zid) in the JWT, which CAP uses to route to the correct tenant database.',
   'cap-49-xs-security', 3041),

  ('sap-cap',
   'Which CAP API retrieves the current user''s ID from the JWT inside a handler?',
   '["req.data.userId", "req.user.id", "cds.context.user", "req.headers.authorization"]',
   1, '`req.user.id` returns the authenticated user''s subject from the JWT. `req.user` also exposes `.roles`, `.is()`, `.attr`, and `.tenant`.',
   'cap-52-jwt', 3042),

  ('sap-cap',
   'In .cdsrc.json mock auth, how do you assign a role to a test user?',
   '["\"roles\": [\"roleName\"] inside the user definition", "\"scope\": \"roleName\" inside the user definition", "Set MOCK_ROLE=roleName in .env", "Use cf set-role for mock users"]',
   0, 'Mock user definitions support a `"roles"` array: `{ "alice": { "roles": ["admin"] } }`. CAP''s mock auth checks these roles against `@requires` annotations.',
   'cap-53-mock-auth', 3043),

  ('sap-cap',
   'What is the OAuth2SAMLBearerAssertion flow used for in BTP?',
   '["Exchanging a BTP JWT for a SAML assertion to authenticate to on-premise systems", "Generating a service key from a SAML IdP", "Converting OAuth tokens to API keys for HANA", "Authenticating between two BTP subaccounts"]',
   0, 'Principal propagation uses OAuth2SAMLBearerAssertion: the BTP user''s JWT is converted to a SAML assertion that the on-premise system (via Cloud Connector) accepts as the user''s identity.',
   'cap-55-principal-prop', 3044),

  ('sap-cap',
   'What is the difference between `@requires` and `@restrict` in CAP?',
   '["@requires checks authentication; @restrict checks authorisation", "@requires gates access (allow/deny); @restrict filters rows returned", "@requires is for services; @restrict is for individual fields", "@requires is deprecated — use @restrict instead"]',
   1, '`@requires` is a gate: it allows or denies the whole request. `@restrict` is a filter: it limits which rows a permitted user can see.',
   'cap-51-requires', 3045),

  ('sap-cap',
   'Which BTP service handles corporate SSO and risk-based MFA for BTP applications?',
   '["XSUAA", "SAP Identity Authentication Service (IAS)", "SAP Credential Store", "SAP Authorization Trust Management"]',
   1, 'SAP Identity Authentication Service (IAS) is the enterprise IdP for BTP. It handles corporate SSO via SAML/OIDC and supports risk-based MFA policies.',
   'cap-54-ias', 3046),

  ('sap-cap',
   'Why should you never set security-relevant fields (like `owner`) from `req.data` in a CAP handler?',
   '["req.data is not available in BEFORE handlers", "A client can send any value in req.data, allowing privilege escalation", "req.data only contains OData metadata", "Setting req.data fields causes a transaction rollback"]',
   1, 'req.data contains client-supplied payload. A malicious client can set any field value, including ownership or status fields, enabling privilege escalation. Always set security fields from `req.user.id`.',
   'cap-52-jwt', 3047),

  ('sap-cap',
   'In xs-security.json, what is a "role template"?',
   '["A JSON template for generating XSUAA service keys", "A named group of scopes that can be assigned to users via role collections", "A CAP annotation that auto-generates XSUAA roles", "An IAM policy document for Cloud Foundry spaces"]',
   1, 'A role template groups one or more scopes. Admins assign role templates to role collections, and role collections are assigned to users in the BTP cockpit.',
   'cap-50-role-collections', 3048),

  ('sap-cap',
   'Which `req.user` method checks if the current user has a specific role?',
   '["req.user.hasRole(\"roleName\")", "req.user.is(\"roleName\")", "req.user.check(\"roleName\")", "req.roles.includes(\"roleName\")"]',
   1, '`req.user.is(\"roleName\")` returns true if the user''s JWT contains the specified role/scope. It is the idiomatic CAP way to check roles in handler code.',
   'cap-52-jwt', 3049),

-- ── Batch 6: BTP Services Integration (cap-57 to cap-68) ────────────────────
  ('sap-cap',
   'What is the purpose of the SAP Destination Service?',
   '["Storing binary files for BTP applications", "Centrally managing connection configurations (URL, auth) for external systems", "Routing HTTP traffic between CF apps", "Providing a CDN for static assets"]',
   1, 'The Destination Service stores named connection configurations (URL, authentication type, credentials) used by BTP apps to call external systems without hardcoding connection details.',
   'cap-57-destination', 3050),

  ('sap-cap',
   'What does SAP Cloud Connector do?',
   '["Encrypts traffic between BTP microservices", "Creates a secure tunnel from on-premise networks to BTP without opening inbound firewall ports", "Connects two BTP subaccounts in different regions", "Provides VPN access to HANA Cloud"]',
   1, 'Cloud Connector runs on-premise and opens an outbound connection to BTP. This tunnel lets BTP apps call on-premise systems without requiring inbound firewall rules.',
   'cap-58-connectivity', 3051),

  ('sap-cap',
   'In SAP Event Mesh, what is a Dead Letter Queue (DLQ)?',
   '["A queue for test messages that should not be processed", "A queue where undeliverable or repeatedly failed messages are parked for inspection", "A backup queue for high-priority messages", "A queue that fires events on a schedule"]',
   1, 'When a message cannot be delivered after the maximum retry count, it is moved to the Dead Letter Queue. This prevents poison messages from blocking the main queue.',
   'cap-59-event-mesh', 3052),

  ('sap-cap',
   'When calling a BAPI from CAP via RFC, why must you call BAPI_TRANSACTION_COMMIT afterwards?',
   '["To release the RFC connection back to the pool", "BAPIs do not auto-commit — BAPI_TRANSACTION_COMMIT explicitly commits the LUW on the ABAP system", "To trigger the ABAP workflow associated with the BAPI", "Because CAP''s generic handler doesn''t support RFC commits"]',
   1, 'ABAP Logical Units of Work (LUWs) are not committed automatically. Calling BAPI_TRANSACTION_COMMIT (or BAPI_TRANSACTION_ROLLBACK on failure) is mandatory to persist state-changing BAPI calls.',
   'cap-62-bapi-rfc', 3053),

  ('sap-cap',
   'What is the delegate pattern when integrating CAP with S/4HANA OData?',
   '["Delegating authentication to S/4HANA''s XSUAA instance", "Forwarding the incoming OData query directly to S/4HANA: `s4.run(req.query)`", "Delegating UI rendering to a Fiori app on S/4HANA", "Synchronising the CDS model with S/4HANA''s metadata"]',
   1, 'The delegate pattern passes the CAP query object directly to the remote service, letting S/4HANA execute it: `return s4.run(req.query)`. CAP handles the response mapping automatically.',
   'cap-61-s4hana', 3054),

  ('sap-cap',
   'In SAP Job Scheduling Service, what HTTP status should your job endpoint return on success?',
   '["201 Created", "204 No Content", "200 OK", "202 Accepted"]',
   2, 'The Job Scheduling Service expects HTTP 200 OK to mark a run as successful. Any non-2xx response triggers a retry according to the configured retry policy.',
   'cap-65-job-scheduling', 3055),

  ('sap-cap',
   'What does the @sap/logging middleware add to every HTTP request in CAP?',
   '["Automatic retry on timeout", "A correlation ID that propagates through all log entries for that request", "Request size validation", "Automatic CSRF token generation"]',
   1, 'The `@sap/logging` middleware generates or extracts a correlation ID (from X-CorrelationID header) and injects it into every log entry, making it possible to trace a request end-to-end in Kibana.',
   'cap-66-logging', 3056),

  ('sap-cap',
   'In the HTML5 App Repository + AppRouter architecture, which component handles the XSUAA login redirect?',
   '["The React SPA", "The CAP backend service", "The AppRouter (@sap/approuter)", "The HTML5 App Repository runtime"]',
   2, 'AppRouter handles the XSUAA OAuth2 flow. It redirects unauthenticated users to the XSUAA login page and exchanges the code for a JWT before forwarding requests to the backend.',
   'cap-68-html5-repo', 3057),

-- ── Batch 7: Deployment & Production (cap-69 to cap-80) ─────────────────────
  ('sap-cap',
   'In an MTA descriptor, what is the difference between a `module` and a `resource`?',
   '["Modules are databases; resources are applications", "Modules are deployable artifacts (CF apps, deployers); resources are managed services or external dependencies", "Modules are frontend code; resources are backend code", "There is no difference — the terms are interchangeable"]',
   1, 'In mta.yaml, `modules` are active artifacts you deploy (CF apps, content deployers), while `resources` are passive dependencies (managed BTP services) that are created/bound but not themselves deployed as apps.',
   'cap-69-mta-intro', 3058),

  ('sap-cap',
   'What does `cf deploy my-app.mtar --strategy blue-green` do?',
   '["Deploys directly over the running app with no traffic interruption check", "Deploys the new version alongside the old one, lets you test it, then switches traffic atomically", "Deploys to the blue environment only and leaves green unchanged", "Builds the MTA and immediately rolls back if any test fails"]',
   1, 'Blue-green deployment keeps the old version (blue) running while the new version (green) starts with a temporary route. After smoke tests pass, traffic is switched atomically and blue is removed.',
   'cap-72-blue-green', 3059);

