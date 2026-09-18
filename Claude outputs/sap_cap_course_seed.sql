-- ─────────────────────────────────────────────────────────────────────────────
-- SAP BTP CAP (Cloud Application Programming Model) — Full Course Seed
-- Core → Advanced → Industry Level | 7 Modules | 80 Lessons
-- Run in Supabase SQL Editor
-- ─────────────────────────────────────────────────────────────────────────────

-- ── 1. Course ──────────────────────────────────────────────────────────────────
INSERT INTO public.courses (id, title, subtitle, description, status, icon, accent_color, accent_light, tags, level, estimated_hours, order_index)
VALUES (
  'sap-cap',
  'SAP BTP CAP Development',
  'Master the Cloud Application Programming Model from core to production',
  'A complete, industry-level course on SAP''s Cloud Application Programming Model (CAP). You''ll build real-world applications using CDS data modeling, Node.js service handlers, SAP HANA Cloud persistence, XSUAA authentication, and BTP services integration — then deploy production-grade apps with MTA and CI/CD.',
  'available',
  '☁️',
  '#00A36C',
  '#e6f7f2',
  ARRAY['CAP', 'CDS', 'HANA Cloud', 'XSUAA', 'MTA', 'Node.js'],
  'Core → Advanced → Industry',
  60,
  2
)
ON CONFLICT (id) DO UPDATE SET
  title            = EXCLUDED.title,
  subtitle         = EXCLUDED.subtitle,
  description      = EXCLUDED.description,
  status           = EXCLUDED.status,
  icon             = EXCLUDED.icon,
  accent_color     = EXCLUDED.accent_color,
  accent_light     = EXCLUDED.accent_light,
  tags             = EXCLUDED.tags,
  level            = EXCLUDED.level,
  estimated_hours  = EXCLUDED.estimated_hours,
  order_index      = EXCLUDED.order_index;


-- ── 2. Modules ─────────────────────────────────────────────────────────────────
INSERT INTO public.modules (id, course_id, title, order_index) VALUES
  ('cap-m01', 'sap-cap', 'CAP Foundations',                   1),
  ('cap-m02', 'sap-cap', 'CDS Data Modeling',                 2),
  ('cap-m03', 'sap-cap', 'Service Development',               3),
  ('cap-m04', 'sap-cap', 'Persistence & SAP HANA Cloud',      4),
  ('cap-m05', 'sap-cap', 'Authentication & Authorization',    5),
  ('cap-m06', 'sap-cap', 'BTP Services Integration',          6),
  ('cap-m07', 'sap-cap', 'Deployment & Production',           7)
ON CONFLICT (id) DO UPDATE SET
  title       = EXCLUDED.title,
  order_index = EXCLUDED.order_index;


-- ── 3. Topics / Lessons ───────────────────────────────────────────────────────
-- All 80 lessons seeded as status = 'draft'
-- Publish each one after adding content in the Admin Console

INSERT INTO public.topics (slug, module_id, title, description, order_index, status) VALUES

-- ══════════════════════════════════════════════════════════════════════════════
-- MODULE 1: CAP FOUNDATIONS (10 lessons)
-- ══════════════════════════════════════════════════════════════════════════════
('cap-01-what-is-cap',          'cap-m01', 'What is SAP CAP?',                        'Overview of the Cloud Application Programming Model — CDS, Node.js vs Java runtimes, and where CAP fits in the BTP ecosystem.',                       1, 'draft'),
('cap-02-setup',                'cap-m01', 'Setting Up Your Dev Environment',         'Install Node.js, @sap/cds-dk, VS Code with CAP extensions, and SAP Business Application Studio (BAS) alternatives.',                                    2, 'draft'),
('cap-03-first-project',        'cap-m01', 'Your First CAP Project',                  'Scaffold a CAP project with cds init, explore the generated folder structure, and start the dev server with cds watch.',                                  3, 'draft'),
('cap-04-project-structure',    'cap-m01', 'Understanding CAP Project Structure',     'Deep dive into db/, srv/, app/ directories — what belongs where and why. Package.json dependencies, .cdsrc.json, and profile configuration.',            4, 'draft'),
('cap-05-cds-basics',           'cap-m01', 'CDS Schema Basics',                       'Introduction to Core Data Services syntax — using, namespace, entity, type, and service keywords. Schema-first design philosophy.',                       5, 'draft'),
('cap-06-entities',             'cap-m01', 'Defining Entities & Types',               'Declare entities with key fields, built-in scalar types (String, Integer, Date, UUID), virtual fields, and computed elements.',                          6, 'draft'),
('cap-07-services',             'cap-m01', 'Service Definitions',                     'Define CDS services, expose entities, project columns, rename elements, and restrict which operations (CREATE/READ/UPDATE/DELETE) are exposed.',           7, 'draft'),
('cap-08-run-local',            'cap-m01', 'Running CAP Locally with cds watch',      'Use cds watch for hot-reload development, explore the built-in Fiori launchpad, test endpoints with the cds REPL and REST clients.',                     8, 'draft'),
('cap-09-odata',                'cap-m01', 'Understanding OData V4 in CAP',           'How CAP maps CDS service definitions to OData V4 — metadata document, system query options ($filter, $expand, $select, $top), and Batch requests.',      9, 'draft'),
('cap-10-generic-handlers',     'cap-m01', 'Generic Handlers & Automatic CRUD',       'CAP''s built-in generic service providers — what is handled for you (CREATE, READ, UPDATE, DELETE, deep operations) and when you need custom handlers.',  10, 'draft'),

-- ══════════════════════════════════════════════════════════════════════════════
-- MODULE 2: CDS DATA MODELING (12 lessons)
-- ══════════════════════════════════════════════════════════════════════════════
('cap-11-associations',         'cap-m02', 'Associations & Compositions',             'Model one-to-one, one-to-many, and many-to-many relationships. Difference between Association (reference) and Composition (owned child).',              1, 'draft'),
('cap-12-aspects',              'cap-m02', 'Aspects & Mixins',                        'Reuse model fragments with aspects. Use built-in SAP aspects: managed (createdBy, modifiedAt), cuid (UUID keys), and temporal (validFrom/To).',          2, 'draft'),
('cap-13-views',                'cap-m02', 'Views & Projections',                     'Create CDS views with SELECT, projection shortcuts, calculated fields, and cross-entity joins for denormalized read models.',                             3, 'draft'),
('cap-14-annotations',          'cap-m02', 'CDS Annotations Deep Dive',               'Apply UI, validation, search, and OData annotations. Understand annotation targets, layers, and how annotations flow to generated metadata.',              4, 'draft'),
('cap-15-namespaces',           'cap-m02', 'Namespaces, Imports & Reuse Models',      'Organize large models with namespaces, using keyword, and multi-file schemas. Import and reuse SAP standard models (sap.common, Analytics).',             5, 'draft'),
('cap-16-types',                'cap-m02', 'Custom Types & Enumerations',             'Define reusable types, structured types (records), enum types, and array types. Apply constraints like @assert.range and @assert.format.',                6, 'draft'),
('cap-17-localization',         'cap-m02', 'Localization & i18n in CDS',              'Use the localized keyword to generate translatable models. Maintain i18n message bundles, and serve content in the user''s locale via Accept-Language.',   7, 'draft'),
('cap-18-draft',                'cap-m02', 'Draft Mode & Fiori Draft Pattern',        'Enable @odata.draft.enabled for SAP Fiori draft capability. Understand draft activation, cancellation, and conflict handling in CAP.',                    8, 'draft'),
('cap-19-hierarchy',            'cap-m02', 'Hierarchical Data Modeling',              'Model parent-child and tree structures in CDS. Use recursive associations, CTE-based queries in HANA, and OData hierarchy annotations.',                  9, 'draft'),
('cap-20-extend',               'cap-m02', 'Extending & Annotating Models',           'Use extend and annotate keywords to add fields, associations, and annotations to existing entities without modifying the base model.',                     10, 'draft'),
('cap-21-input-validation',     'cap-m02', 'Input Validation & Constraints',          'Declare @mandatory, @assert.range, @assert.format, @assert.uniqueness constraints in CDS and see how CAP enforces them automatically.',                   11, 'draft'),
('cap-22-modeling-patterns',    'cap-m02', 'CDS Modeling Best Practices',             'Industry-level patterns: when to compose vs associate, model normalization, lean services over fat entities, and managing model complexity at scale.',     12, 'draft'),

-- ══════════════════════════════════════════════════════════════════════════════
-- MODULE 3: SERVICE DEVELOPMENT (12 lessons)
-- ══════════════════════════════════════════════════════════════════════════════
('cap-23-custom-handlers',      'cap-m03', 'Custom Service Handlers',                 'Write event handlers in Node.js with this.on(), this.before(), this.after(). Handler registration, chaining, and when to call next().',                  1, 'draft'),
('cap-24-before-after',         'cap-m03', 'Before / After / On Hooks in Depth',      'Detailed exploration of the three-phase request lifecycle in CAP. Add cross-cutting logic (logging, auditing, transformation) without modifying business logic.', 2, 'draft'),
('cap-25-actions',              'cap-m03', 'Actions & Functions',                     'Define bound and unbound OData actions (state-changing) and functions (read-only). Implement them as custom handlers and call from Fiori and REST clients.', 3, 'draft'),
('cap-26-error-handling',       'cap-m03', 'Error Handling & Custom Errors',          'Throw structured errors with cds.error(), map HTTP status codes, add @Core.Messages, and build consistent API error responses across the service.',       4, 'draft'),
('cap-27-events',               'cap-m03', 'Emitting & Handling CDS Events',          'Use cds.emit() for in-process events and cross-service communication. Subscribe with this.on() in remote services for decoupled architectures.',          5, 'draft'),
('cap-28-messaging',            'cap-m03', 'Async Messaging with SAP Event Mesh',     'Connect CAP services to SAP Event Mesh for asynchronous publish-subscribe. Configure messaging in .cdsrc.json and handle events reliably.',              6, 'draft'),
('cap-29-fiori-annotations',    'cap-m03', 'Fiori UI Annotations in CAP',             'Annotate services for Fiori List Report, Object Page, and Form patterns. Use @UI.LineItem, @UI.FieldGroup, @UI.Facets, and value helps.',                7, 'draft'),
('cap-30-query-api',            'cap-m03', 'CAP Query API (CQL & cds.ql)',            'Build and execute CDS queries programmatically using SELECT, INSERT, UPDATE, DELETE fluent API. Understand how queries translate to SQL and OData.',      8, 'draft'),
('cap-31-batch',                'cap-m03', 'Batch Requests & Deep Inserts',           'Process OData $batch requests, deep insert payloads, and deep update operations. Handle cascading creates/updates across composed entities.',            9, 'draft'),
('cap-32-file-upload',          'cap-m03', 'File Upload & Media Types',               'Expose file/document upload and download via OData media streams. Store files in Object Store or HANA, and stream responses efficiently.',               10, 'draft'),
('cap-33-remote-services',      'cap-m03', 'Consuming Remote Services',               'Import external OData APIs as CDS service definitions, configure destinations, and delegate requests to S/4HANA or other BTP services.',                 11, 'draft'),
('cap-34-extensibility',        'cap-m03', 'Service Extensibility Patterns',          'Industry-level patterns for building extensible services: plugin hooks, customer-exit patterns, extension fields, and side-effect annotations.',          12, 'draft'),

-- ══════════════════════════════════════════════════════════════════════════════
-- MODULE 4: PERSISTENCE & SAP HANA CLOUD (12 lessons)
-- ══════════════════════════════════════════════════════════════════════════════
('cap-35-sqlite',               'cap-m04', 'SQLite for Local Development',            'Configure cds.requires.db for SQLite, use cds deploy --to sqlite, manage data.json seed files, and understand the dev/prod parity strategy.',            1, 'draft'),
('cap-36-hana-basics',          'cap-m04', 'SAP HANA Cloud Fundamentals',             'Provision a HANA Cloud instance, understand HDI (HANA Deployment Infrastructure), and connect a CAP project to a real HANA Cloud database.',            2, 'draft'),
('cap-37-hdi',                  'cap-m04', 'HDI Containers & Deployment',             'Understand HDI container lifecycle, design-time artifacts (.hdbcds, .hdbtable), and how cds deploy generates and deploys HANA artifacts.',              3, 'draft'),
('cap-38-hana-types',           'cap-m04', 'HANA-Specific CDS Types & Features',      'Use HANA-native types (LargeString, Binary), spatial types, time series, and HANA-specific functions via cds.hana annotations.',                       4, 'draft'),
('cap-39-migrations',           'cap-m04', 'Schema Evolution & Migrations',           'Manage safe schema changes: additive vs destructive changes, using cds-dbm or @cap-js/sqlite migration tooling, and zero-downtime deployment strategies.', 5, 'draft'),
('cap-40-hana-views',           'cap-m04', 'HANA Calculation Views in CAP',           'Create HANA Calculation Views for complex analytics, expose them as CDS service projections, and consume them from CAP Fiori apps.',                    6, 'draft'),
('cap-41-stored-procs',         'cap-m04', 'Stored Procedures & Native SQL',          'Call HANA stored procedures from CAP using db.run() with native SQL, CREATE PROCEDURE via HDI artifacts, and when to use native HANA vs CDS queries.',  7, 'draft'),
('cap-42-full-text',            'cap-m04', 'Full-Text Search in HANA',                'Enable HANA full-text index on CDS entities, use the contains() function, configure fuzzy search, and build rich search APIs in CAP services.',          8, 'draft'),
('cap-43-rls',                  'cap-m04', 'Row-Level Security in HANA',              'Implement HANA Analytic Privileges and Structured Privileges for row-level data isolation in multi-user and multitenant apps.',                         9, 'draft'),
('cap-44-perf',                 'cap-m04', 'Performance Tuning & Indexing',           'Add secondary indexes via CDS annotations, profile slow queries, use HANA EXPLAIN PLAN, optimize $expand depth, and apply connection pooling.',         10, 'draft'),
('cap-45-audit-log',            'cap-m04', 'Audit Logging with SAP Audit Log Service','Enable @PersonalData.EntitySemantics, integrate SAP Audit Log Service, and ensure compliant logging of personal data access and changes.',              11, 'draft'),
('cap-46-personal-data',        'cap-m04', 'Personal Data & GDPR Compliance',         'Annotate entities with @PersonalData, implement right-to-erasure flows, data retention policies, and use the CAP Personal Data management plugin.',     12, 'draft'),

-- ══════════════════════════════════════════════════════════════════════════════
-- MODULE 5: AUTHENTICATION & AUTHORIZATION (10 lessons)
-- ══════════════════════════════════════════════════════════════════════════════
('cap-47-security-basics',      'cap-m05', 'BTP Security Fundamentals',               'Understand the BTP identity layer: Identity Authentication Service, SAP XSUAA, OAuth 2.0 flows, JWT tokens, and how they relate to CAP security.',      1, 'draft'),
('cap-48-xsuaa',                'cap-m05', 'XSUAA Service Setup',                     'Create and bind an XSUAA service instance, configure OAuth client credentials & authorization code flows, and connect CAP to the XSUAA service.',       2, 'draft'),
('cap-49-xs-security',          'cap-m05', 'xs-security.json Deep Dive',              'Author xs-security.json: declare scopes, role templates, role collections, and attribute-based access. Understand $ prefixes and wildcard scopes.',      3, 'draft'),
('cap-50-role-collections',     'cap-m05', 'Roles, Scopes & Role Collections',        'Map xs-security.json roles to BTP role collections, assign them to users/groups in BTP Cockpit, and verify token contents with JWT debugger.',          4, 'draft'),
('cap-51-requires',             'cap-m05', '@requires & @restrict Annotations',       'Protect CDS service operations with @requires (role-based) and @restrict (instance-based with where clause). Test with mock users and real JWTs.',       5, 'draft'),
('cap-52-jwt',                  'cap-m05', 'JWT Token Handling in Handlers',          'Access the JWT token in custom handlers via req.user, read attributes and roles, implement attribute-based data filters, and debug auth issues.',        6, 'draft'),
('cap-53-mock-auth',            'cap-m05', 'Mock Authentication in Development',      'Configure mock users in .cdsrc.json for local development, simulate multiple roles, and write integration tests with authenticated requests.',           7, 'draft'),
('cap-54-ias',                  'cap-m05', 'SAP Identity Authentication Service (IAS)','Set up IAS as a corporate identity provider, configure trust between IAS and XSUAA, and enable SSO for CAP apps in BTP.',                             8, 'draft'),
('cap-55-principal-prop',       'cap-m05', 'Principal Propagation',                   'Propagate user identity from CAP through Destination Service to backend SAP systems. Configure OAuth2SAMLBearerAssertion and TrustAll scenarios.',       9, 'draft'),
('cap-56-auth-patterns',        'cap-m05', 'Authorization Patterns & Best Practices', 'Industry patterns: fine-grained @restrict with where clauses, multi-tenant user isolation, avoiding privilege escalation, and security testing CAP.',   10, 'draft'),

-- ══════════════════════════════════════════════════════════════════════════════
-- MODULE 6: BTP SERVICES INTEGRATION (12 lessons)
-- ══════════════════════════════════════════════════════════════════════════════
('cap-57-destination',          'cap-m06', 'SAP Destination Service',                 'Create and manage destinations in BTP Cockpit. Use the Destination service client in CAP to resolve destinations at runtime for outbound calls.',        1, 'draft'),
('cap-58-connectivity',         'cap-m06', 'Connectivity Service & Cloud Connector',  'Set up SAP Cloud Connector for on-premise system access. Configure RFC and HTTP connections, and route CAP service calls through the Connectivity Service.', 2, 'draft'),
('cap-59-event-mesh',           'cap-m06', 'SAP Event Mesh — Advanced Topics',        'Configure Event Mesh namespaces, queues, and topic subscriptions. Implement guaranteed-delivery consumers, dead-letter queues, and at-least-once semantics.', 3, 'draft'),
('cap-60-notifications',        'cap-m06', 'SAP Alert Notification Service',          'Send real-time notifications (email, Slack, SAP Fiori) from CAP using Alert Notification Service. Configure conditions, consumers, and delivery channels.', 4, 'draft'),
('cap-61-s4hana',               'cap-m06', 'S/4HANA Integration via OData',           'Import S/4HANA API Business Hub OData services as CDS definitions. Configure OAuth2 destinations and delegate CRUD to S/4HANA from a CAP façade.',      5, 'draft'),
('cap-62-bapi-rfc',             'cap-m06', 'BAPI & RFC via Cloud Connector',          'Call SAP ABAP BAPIs and Function Modules from CAP using the @sap-cloud-sdk RFC client through Connectivity Service and Cloud Connector.',              6, 'draft'),
('cap-63-workflow',             'cap-m06', 'SAP Build Process Automation',            'Trigger SAP Build Process Automation workflows from CAP service handlers, query workflow instances, and implement approval flows in Fiori apps.',        7, 'draft'),
('cap-64-object-store',         'cap-m06', 'SAP Object Store Service',                'Upload, download, and manage files using SAP Object Store Service (AWS S3 or Azure Blob). Stream file content from CAP media endpoints.',               8, 'draft'),
('cap-65-job-scheduling',       'cap-m06', 'SAP Job Scheduling Service',              'Schedule recurring jobs in CAP using SAP Job Scheduling Service. Register job action endpoints, handle authentication, and monitor execution.',         9, 'draft'),
('cap-66-logging',              'cap-m06', 'SAP Application Logging Service',         'Configure structured logging in CAP to stream logs to SAP Application Logging Service (Kibana). Add correlation IDs, trace context, and log levels.',   10, 'draft'),
('cap-67-feature-flags',        'cap-m06', 'SAP Feature Flags Service',               'Use SAP Feature Flags Service for feature toggles in CAP. Evaluate flags at request time, roll out features gradually, and implement A/B testing.',     11, 'draft'),
('cap-68-html5-repo',           'cap-m06', 'HTML5 Application Repository & App Router','Deploy Fiori/UI5 frontends to the HTML5 Application Repository. Configure AppRouter for authentication, routing, and CORS in a full-stack BTP app.',   12, 'draft'),

-- ══════════════════════════════════════════════════════════════════════════════
-- MODULE 7: DEPLOYMENT & PRODUCTION (12 lessons)
-- ══════════════════════════════════════════════════════════════════════════════
('cap-69-mta-intro',            'cap-m07', 'Multi-Target Application (MTA) Basics',   'Understand MTA as the deployment unit for BTP. Learn mta.yaml structure — modules, resources, provides/requires — and how CF maps it to service bindings.', 1, 'draft'),
('cap-70-mta-yaml',             'cap-m07', 'mta.yaml Deep Dive',                      'Author a production mta.yaml for a full-stack CAP app: CAP backend, Fiori frontend, HANA HDI container, XSUAA, Destination, AppRouter modules.',        2, 'draft'),
('cap-71-cf-deploy',            'cap-m07', 'Cloud Foundry Deployment with MTA',       'Build the MTAR archive with mbt build, deploy with cf deploy, and understand CF staging, memory/disk quotas, buildpacks, and health checks.',           3, 'draft'),
('cap-72-btp-setup',            'cap-m07', 'BTP Subaccount Setup & Entitlements',     'Configure a BTP subaccount for production: enable services, assign entitlements, set up Cloud Foundry space, and manage service instance quotas.',     4, 'draft'),
('cap-73-cicd',                 'cap-m07', 'CI/CD with GitHub Actions & SAP CICD',   'Build a CI/CD pipeline with GitHub Actions: run cds build, execute unit tests, build MTAR, and deploy to CF Dev/QA/Prod using SAP CICD Service.',      5, 'draft'),
('cap-74-blue-green',           'cap-m07', 'Blue-Green & Canary Deployments',         'Implement blue-green deployment with cf deploy --strategy blue-green for zero-downtime releases. Set up canary routing and rollback procedures.',        6, 'draft'),
('cap-75-monitoring',           'cap-m07', 'Monitoring & Alerting in Production',     'Set up BTP Cockpit alerts, connect to SAP Cloud ALM or Dynatrace, configure health-check endpoints, and build runbooks for common CAP incidents.',     7, 'draft'),
('cap-76-structured-logging',   'cap-m07', 'Structured Logging & Distributed Tracing','Implement W3C Trace Context in CAP, propagate correlation IDs across services, and query logs in Kibana to debug production issues end-to-end.',       8, 'draft'),
('cap-77-multitenancy',         'cap-m07', 'Multitenancy with MTXS',                  'Build a multitenant CAP application using the MTXS (Multitenancy Extension Services) plugin. Implement tenant provisioning, onboarding, and isolation.', 9, 'draft'),
('cap-78-saas-registry',        'cap-m07', 'SaaS Provisioning & Registry',            'Register a CAP SaaS app in the BTP SaaS Provisioning Service. Handle subscribe/unsubscribe callbacks, tenant URLs, and dependency callbacks.',        10, 'draft'),
('cap-79-performance',          'cap-m07', 'Production Performance Tips',             'Optimize CAP for production: connection pooling, caching with req.cached(), lazy service loading, avoid N+1 with $expand limits, and CF autoscaling.', 11, 'draft'),
('cap-80-checklist',            'cap-m07', 'Production Readiness Checklist',          'End-to-end checklist before go-live: security hardening, GDPR audit, performance baseline, monitoring setup, runbooks, and SAP Enterprise Support.',  12, 'draft')

ON CONFLICT (slug) DO UPDATE SET
  title       = EXCLUDED.title,
  description = EXCLUDED.description,
  order_index = EXCLUDED.order_index;


-- ── 4. Verify ─────────────────────────────────────────────────────────────────
SELECT 'course inserted'     AS check, count(*) FROM public.courses  WHERE id = 'sap-cap'
UNION ALL
SELECT 'modules inserted',              count(*) FROM public.modules  WHERE course_id = 'sap-cap'
UNION ALL
SELECT 'topics inserted',               count(*) FROM public.topics   WHERE module_id IN (
  SELECT id FROM public.modules WHERE course_id = 'sap-cap'
);
