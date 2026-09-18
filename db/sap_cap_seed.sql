-- =============================================================================
-- SAP CAP Course Seed — 7 Modules, 80 Lessons
-- Uses module numbers 200–206 (AI uses 100–108, BTP uses other ranges)
-- Run BEFORE the sap_cap_m*_content.sql files
-- =============================================================================

-- ─── 1. COURSE ───────────────────────────────────────────────────────────────
INSERT INTO public.courses (id, title, subtitle, description, status, icon, accent_color, accent_light, tags, level, estimated_hours, order_index)
VALUES (
  'sap-cap',
  'SAP BTP CAP Development',
  'Master the Cloud Application Programming Model from core to production',
  'A complete, industry-level course on SAP''s Cloud Application Programming Model (CAP). Build real-world apps using CDS data modeling, Node.js service handlers, SAP HANA Cloud, XSUAA authentication, and BTP services — then deploy with MTA and CI/CD.',
  'available',
  '🛠️',
  '#00A36C',
  '#e6f7f2',
  ARRAY['CAP', 'CDS', 'HANA Cloud', 'XSUAA', 'MTA', 'Node.js'],
  'Core → Advanced → Industry',
  60,
  2
)
ON CONFLICT (id) DO UPDATE SET
  title           = EXCLUDED.title,
  subtitle        = EXCLUDED.subtitle,
  description     = EXCLUDED.description,
  status          = EXCLUDED.status,
  icon            = EXCLUDED.icon,
  accent_color    = EXCLUDED.accent_color,
  accent_light    = EXCLUDED.accent_light,
  tags            = EXCLUDED.tags,
  level           = EXCLUDED.level,
  estimated_hours = EXCLUDED.estimated_hours,
  order_index     = EXCLUDED.order_index;

-- ─── 2. MODULES + TOPICS (PL/pgSQL block) ────────────────────────────────────
DO $$
DECLARE
  m1 uuid; m2 uuid; m3 uuid; m4 uuid; m5 uuid; m6 uuid; m7 uuid;
BEGIN

  -- MODULE 1: CAP Foundations (number 200)
  INSERT INTO public.modules (number, title, subtitle, order_index, course_id)
  VALUES (200, 'CAP Foundations', 'Project structure, CDS basics, OData V4, and generic handlers', 1, 'sap-cap')
  ON CONFLICT (number) DO UPDATE SET title = EXCLUDED.title, subtitle = EXCLUDED.subtitle, course_id = EXCLUDED.course_id
  RETURNING id INTO m1;
  IF m1 IS NULL THEN SELECT id INTO m1 FROM public.modules WHERE number = 200; END IF;

  -- MODULE 2: CDS Data Modeling (number 201)
  INSERT INTO public.modules (number, title, subtitle, order_index, course_id)
  VALUES (201, 'CDS Data Modeling', 'Aspects, associations, views, validation, drafts, and i18n', 2, 'sap-cap')
  ON CONFLICT (number) DO UPDATE SET title = EXCLUDED.title, subtitle = EXCLUDED.subtitle, course_id = EXCLUDED.course_id
  RETURNING id INTO m2;
  IF m2 IS NULL THEN SELECT id INTO m2 FROM public.modules WHERE number = 201; END IF;

  -- MODULE 3: Service Development (number 202)
  INSERT INTO public.modules (number, title, subtitle, order_index, course_id)
  VALUES (202, 'Service Development', 'Handlers, actions, error handling, messaging, and remote services', 3, 'sap-cap')
  ON CONFLICT (number) DO UPDATE SET title = EXCLUDED.title, subtitle = EXCLUDED.subtitle, course_id = EXCLUDED.course_id
  RETURNING id INTO m3;
  IF m3 IS NULL THEN SELECT id INTO m3 FROM public.modules WHERE number = 202; END IF;

  -- MODULE 4: Persistence & SAP HANA Cloud (number 203)
  INSERT INTO public.modules (number, title, subtitle, order_index, course_id)
  VALUES (203, 'Persistence & SAP HANA Cloud', 'SQLite dev, HDI containers, migrations, full-text search, and audit logging', 4, 'sap-cap')
  ON CONFLICT (number) DO UPDATE SET title = EXCLUDED.title, subtitle = EXCLUDED.subtitle, course_id = EXCLUDED.course_id
  RETURNING id INTO m4;
  IF m4 IS NULL THEN SELECT id INTO m4 FROM public.modules WHERE number = 203; END IF;

  -- MODULE 5: Authentication & Authorization (number 204)
  INSERT INTO public.modules (number, title, subtitle, order_index, course_id)
  VALUES (204, 'Authentication & Authorization', 'XSUAA, JWT, @requires/@restrict, IAS, and principal propagation', 5, 'sap-cap')
  ON CONFLICT (number) DO UPDATE SET title = EXCLUDED.title, subtitle = EXCLUDED.subtitle, course_id = EXCLUDED.course_id
  RETURNING id INTO m5;
  IF m5 IS NULL THEN SELECT id INTO m5 FROM public.modules WHERE number = 204; END IF;

  -- MODULE 6: BTP Services Integration (number 205)
  INSERT INTO public.modules (number, title, subtitle, order_index, course_id)
  VALUES (205, 'BTP Services Integration', 'Destination, Event Mesh, S/4HANA, Workflow, Object Store, and more', 6, 'sap-cap')
  ON CONFLICT (number) DO UPDATE SET title = EXCLUDED.title, subtitle = EXCLUDED.subtitle, course_id = EXCLUDED.course_id
  RETURNING id INTO m6;
  IF m6 IS NULL THEN SELECT id INTO m6 FROM public.modules WHERE number = 205; END IF;

  -- MODULE 7: Deployment & Production (number 206)
  INSERT INTO public.modules (number, title, subtitle, order_index, course_id)
  VALUES (206, 'Deployment & Production', 'MTA, CF Deploy, blue-green, CI/CD, monitoring, multitenancy, and go-live', 7, 'sap-cap')
  ON CONFLICT (number) DO UPDATE SET title = EXCLUDED.title, subtitle = EXCLUDED.subtitle, course_id = EXCLUDED.course_id
  RETURNING id INTO m7;
  IF m7 IS NULL THEN SELECT id INTO m7 FROM public.modules WHERE number = 206; END IF;

  -- ── MODULE 1 TOPICS ──────────────────────────────────────────────────────
  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m1,'cap-01','cap-01-what-is-cap','01 · What is SAP CAP?','Ecosystem Overview',
    'Overview of the Cloud Application Programming Model — CDS, Node.js vs Java runtimes, and where CAP fits in the BTP ecosystem.',
    'Diagram showing CAP''s position in the BTP stack',1,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m1,'cap-02','cap-02-setup','02 · Setting Up Your Dev Environment','Tooling & Install',
    'Install Node.js, @sap/cds-dk, VS Code with CAP extensions, and explore SAP Business Application Studio.',
    'A working cds --version output and a running dev server',2,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m1,'cap-03','cap-03-first-project','03 · Your First CAP Project','cds init & Watch',
    'Scaffold a CAP project with cds init, explore the generated folder structure, and start the dev server with cds watch.',
    'A running CAP app with a Books entity served as OData V4',3,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m1,'cap-04','cap-04-project-structure','04 · CAP Project Structure','Folder Conventions',
    'Deep dive into db/, srv/, app/ directories — what belongs where and why. Package.json, .cdsrc.json, and profile configuration.',
    'Annotated project tree with each folder''s purpose explained',4,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m1,'cap-05','cap-05-cds-basics','05 · CDS Schema Basics','Schema-First Design',
    'Introduction to Core Data Services syntax — using, namespace, entity, type, and service keywords.',
    'A CDS schema with two related entities served as OData',5,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m1,'cap-06','cap-06-entities','06 · Defining Entities & Types','CDS Types',
    'Declare entities with key fields, built-in scalar types, virtual fields, and computed elements.',
    'Entity with UUID key, all scalar types, and a virtual field',6,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m1,'cap-07','cap-07-services','07 · Service Definitions','Expose & Restrict',
    'Define CDS services, expose entities, project columns, rename elements, and restrict which operations are exposed.',
    'Service exposing a subset of entity fields with read-only projection',7,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m1,'cap-08','cap-08-run-local','08 · Running CAP Locally','cds watch',
    'Use cds watch for hot-reload development, explore the built-in Fiori launchpad, and test endpoints with REST clients.',
    'Working OData endpoint tested via Postman/curl',8,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m1,'cap-09','cap-09-odata','09 · OData V4 in CAP','$filter & $expand',
    'How CAP maps CDS service definitions to OData V4 — metadata, system query options ($filter, $expand, $select, $top), and Batch.',
    'OData queries with $filter, $expand, and $select working correctly',9,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m1,'cap-10','cap-10-generic-handlers','10 · Generic Handlers & CRUD','Auto-Provided CRUD',
    'CAP''s built-in generic service providers — what is handled for you and when you need custom handlers.',
    'Full CRUD on an entity with zero custom handler code',10,'draft')
  ON CONFLICT (slug) DO NOTHING;

  -- ── MODULE 2 TOPICS ──────────────────────────────────────────────────────
  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m2,'cap-11','cap-11-aspects','11 · Aspects & Reuse Types','DRY Data Modeling',
    'Define reusable aspects (managed, cuid, temporal) and custom types. Compose them into multiple entities without duplication.',
    'Three entities sharing managed and cuid aspects',1,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m2,'cap-12','cap-12-associations','12 · Associations & Compositions','Relations in CDS',
    'Model to-one and to-many associations, compositions, backlinks, and when to use each. Understand the OData expand behavior.',
    'Order–LineItems composition with $expand working',2,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m2,'cap-13','cap-13-projections','13 · Views & Projections','CDS Query Language',
    'Create CDS views using SELECT, extend existing entities, add computed columns, and understand when views vs projections apply.',
    'A reporting view that aggregates data from two entities',3,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m2,'cap-14','cap-14-annotations','14 · Annotations Deep Dive','Metadata Decoration',
    'Use @title, @description, @mandatory, @readonly, @assert.range, and UI annotations. Understand annotation propagation.',
    'Entity with full annotation coverage and Fiori rendering',4,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m2,'cap-15','cap-15-input-validation','15 · Input Validation','@assert & @mandatory',
    'Use @assert.range, @assert.format, @mandatory, and custom validators in handlers. Return structured error messages.',
    'Entity that rejects invalid input with clear error messages',5,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m2,'cap-16','cap-16-draft','16 · Draft Enablement','@odata.draft.enabled',
    'Enable draft support for entities, understand the draft state machine, and use the Fiori draft flow.',
    'Draft-enabled entity with save/activate lifecycle',6,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m2,'cap-17','cap-17-temporal','17 · Temporal Data','Valid Time Slices',
    'Model time-dependent data with @cds.valid.from / @cds.valid.to. Query data as-of a specific date.',
    'Price history entity queryable at any historical date',7,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m2,'cap-18','cap-18-i18n','18 · Internationalisation','i18n & Translations',
    'Externalise labels and messages into _i18n/messages.properties files. Support multiple locales in a single CAP deployment.',
    'Service returning translated labels based on Accept-Language header',8,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m2,'cap-19','cap-19-enums','19 · Enums & Code Lists','Controlled Vocabularies',
    'Define CDS enum types, use @Common.IsNativeEnumType, and generate value help from code list entities.',
    'Status enum with automatic value help in Fiori UI',9,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m2,'cap-20','cap-20-managed','20 · Managed Data & Timestamps','createdAt / modifiedBy',
    'Use the managed aspect for automatic createdAt, createdBy, modifiedAt, modifiedBy population.',
    'Entity that auto-stamps user and timestamp on every mutation',10,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m2,'cap-21','cap-21-extend','21 · Extending Models','Plugin & Extension Pattern',
    'Use extend entity, extend service, and mixin patterns to add fields and handlers without modifying the base model.',
    'Base entity extended with additional fields in a separate .cds file',11,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m2,'cap-22','cap-22-schema-design','22 · Schema Design Patterns','Real-World Modeling',
    'Design patterns for complex real-world schemas: polymorphism with type discriminators, hierarchies, and many-to-many.',
    'A category-product-tag schema with many-to-many and hierarchy',12,'draft')
  ON CONFLICT (slug) DO NOTHING;

  -- ── MODULE 3 TOPICS ──────────────────────────────────────────────────────
  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m3,'cap-23','cap-23-custom-handlers','23 · Custom Service Handlers','this.on / before / after',
    'Write custom handlers with this.on(), this.before(), this.after(). Understand the handler chain and next().',
    'Handler that validates and enriches data before DB write',1,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m3,'cap-24','cap-24-before-after','24 · Before & After Phases','Cross-Cutting Patterns',
    'Use BEFORE for validation/enrichment, AFTER for side effects. Implement cross-cutting concerns without modifying entity handlers.',
    'Audit trail populated automatically via AFTER handlers',2,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m3,'cap-25','cap-25-actions','25 · OData Actions & Functions','Bound & Unbound',
    'Define and implement bound/unbound OData actions (POST) and functions (GET). Pass parameters and return complex types.',
    'Approve action on Orders that changes status and sends notification',3,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m3,'cap-26','cap-26-error-handling','26 · Error Handling','req.reject & req.error',
    'Use req.reject() vs req.error(), return structured errors with target fields, and wire i18n error message keys.',
    'Service that returns field-level validation errors with OData format',4,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m3,'cap-27','cap-27-events','27 · Custom Events','this.emit & Subscribe',
    'Emit and subscribe to in-process events using this.emit(). Decouple handler logic with event-driven communication.',
    'OrderPlaced event triggering an inventory check in a separate handler',5,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m3,'cap-28','cap-28-messaging','28 · Messaging & Event Mesh','Async Events',
    'Connect CAP to SAP Event Mesh. Publish and subscribe to CloudEvents messages across services.',
    'CAP service publishing an event consumed by a second service',6,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m3,'cap-29','cap-29-fiori-annotations','29 · Fiori UI Annotations','@UI Vocabulary',
    'Add @UI.LineItem, @UI.HeaderInfo, @UI.Facets, @UI.FieldGroup, and value help annotations for Fiori Elements rendering.',
    'Entity rendered as a Fiori List Report with detail page',7,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m3,'cap-30','cap-30-query-api','30 · CQL Query API','SELECT / INSERT / UPDATE',
    'Use the CQL fluent API for SELECT, INSERT, UPDATE, DELETE. Understand transactions and the difference from raw SQL.',
    'Handler using CQL for complex conditional update logic',8,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m3,'cap-31','cap-31-batch','31 · OData $batch & Deep Inserts','Atomic Operations',
    'Use OData $batch for multiple operations in one HTTP call. Implement deep inserts for compositions.',
    'Batch request creating an Order with LineItems in one round trip',9,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m3,'cap-32','cap-32-file-upload','32 · File Upload & Media Types','@Core.MediaType',
    'Use @Core.MediaType for binary attachments. Integrate with SAP Object Store for scalable file storage.',
    'Document upload stored in Object Store with metadata in HANA',10,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m3,'cap-33','cap-33-remote-services','33 · Remote Services','cds.connect.to()',
    'Import OData metadata with cds import, connect to external services with cds.connect.to(), and use the delegate pattern.',
    'CAP service proxying S/4HANA OData calls with local caching',11,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m3,'cap-34','cap-34-extensibility','34 · Extensibility Patterns','Plugin Hooks',
    'Implement customer-exit hooks, extend entities at runtime, use cds-plugin.js, and @Core.SideEffects.',
    'Plugin that adds a computed field to any entity without modifying its source',12,'draft')
  ON CONFLICT (slug) DO NOTHING;

  -- ── MODULE 4 TOPICS ──────────────────────────────────────────────────────
  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m4,'cap-35','cap-35-sqlite','35 · SQLite for Development','Dev Profile DB',
    'Use SQLite as the development database with cds deploy, CSV seed files, and understand dev/prod parity gaps.',
    'Seeded SQLite DB with test data loaded via CSV files',1,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m4,'cap-36','cap-36-hana-basics','36 · SAP HANA Cloud Basics','HDI Provisioning',
    'Provision a HANA Cloud free tier instance, configure cds build --for hana, and connect from local dev.',
    'CAP app running against a real HANA Cloud HDI container',2,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m4,'cap-37','cap-37-hdi','37 · HDI Containers & Deployer','HDI Artifacts',
    'Understand HDI container architecture, artifact types, safe vs unsafe schema changes, and the HDI deployer.',
    'Schema deployed to HANA via HDI deployer with correct artifact types',3,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m4,'cap-38','cap-38-hana-types','38 · HANA-Specific Types','LargeString & ST_POINT',
    'Use HANA-specific types: LargeString (NCLOB), LargeBinary (BLOB), hana.ST_POINT, and hana.tableType.',
    'Entity using LargeString and ST_POINT with correct HANA mapping',4,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m4,'cap-39','cap-39-migrations','39 · Schema Migrations','Zero-Downtime Changes',
    'Implement safe schema migrations in HDI using expand/contract. Understand cds migrate and the undeploy list.',
    'Schema migration that adds a nullable column without downtime',5,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m4,'cap-40','cap-40-hana-views','40 · HANA Views & Functions','Calculation Views',
    'Create CDS views vs Calculation Views, use HANA table functions, and run native SQL from CAP.',
    'Reporting endpoint backed by a HANA Calculation View',6,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m4,'cap-41','cap-41-stored-procs','41 · Stored Procedures','HDBPROCEDURE Artifacts',
    'Create .hdbprocedure artifacts and call stored procedures from CAP handlers with parameters.',
    'CAP action delegating to a HANA stored procedure',7,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m4,'cap-42','cap-42-full-text','42 · Full-Text Search','@hana.fullTextIndex',
    'Enable fuzzy full-text search with @hana.fullTextIndex, use OData $search, and tune FUZZY() thresholds.',
    'Search endpoint returning fuzzy-matched results from HANA',8,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m4,'cap-43','cap-43-rls','43 · Row-Level Security','Data Isolation',
    'Implement row-level security with @restrict where clauses, handler-based filters, and HANA Analytic Privileges.',
    'Multi-user entity where each user sees only their own rows',9,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m4,'cap-44','cap-44-perf','44 · Performance Optimization','N+1 & Indexes',
    'Eliminate N+1 queries with CQL expand, add CDS index annotations, and use EXPLAIN PLAN in HANA.',
    'Before/after comparison showing N+1 fix reducing query count',10,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m4,'cap-45','cap-45-audit-log','45 · Audit Logging','@cap-js/audit-logging',
    'Enable @PersonalData.IsPotentiallyPersonal and @cap-js/audit-logging for automatic CRUD audit trails.',
    'Audit log entries generated for every personal data access',11,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m4,'cap-46','cap-46-personal-data','46 · Personal Data Management','GDPR Compliance',
    'Use the @PersonalData vocabulary, @cap-js/personal-data plugin, right-to-erasure (anonymise), and data portability.',
    'Service exposing erasure and export endpoints for GDPR compliance',12,'draft')
  ON CONFLICT (slug) DO NOTHING;

  -- ── MODULE 5 TOPICS ──────────────────────────────────────────────────────
  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m5,'cap-47','cap-47-security-basics','47 · Security Basics & IAS vs XSUAA','Auth Landscape',
    'Understand IAS vs XSUAA, OAuth 2.0 flows, JWT structure, and the req.user API in CAP.',
    'Diagram of the AppRouter–XSUAA–CAP JWT flow',1,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m5,'cap-48','cap-48-xsuaa','48 · XSUAA Service Binding','xs-security.json Basics',
    'Create an xs-security.json, bind XSUAA, obtain a service key, and configure local .env for development.',
    'Local dev setup with XSUAA token acquisition working',2,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m5,'cap-49','cap-49-xs-security','49 · xs-security.json Deep Dive','Scopes & Attributes',
    'Full xs-security.json vocabulary: scopes, attributes, role-templates, oauth2-configuration, and $XSAPPNAME.',
    'xs-security.json with three role templates and tenant modes',3,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m5,'cap-50','cap-50-role-collections','50 · Role Collections','Scope → User Chain',
    'Trace the full scope → role template → role → role collection → user assignment chain in BTP Cockpit.',
    'Working role collection granting admin access to a test user',4,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m5,'cap-51','cap-51-requires','51 · @requires & @restrict','Declarative Auth',
    'Gate entire services with @requires and filter entity rows with @restrict. Combine operation-level and entity-level controls.',
    'Service where readers see all rows but editors only see their own',5,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m5,'cap-52','cap-52-jwt','52 · JWT & req.user API','Token Inspection',
    'Use req.user.id, roles, is(), attr, tenant, and tokenInfo. Prevent privilege escalation by never setting security fields from req.data.',
    'Handler that reads user attributes from JWT and filters data',6,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m5,'cap-53','cap-53-mock-auth','53 · Mock Authentication','Local Dev Auth',
    'Configure .cdsrc.json mock users with roles and attributes. Write positive and negative auth tests with cds.test().',
    'Test suite with role-based positive and negative test cases',7,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m5,'cap-54','cap-54-ias','54 · SAP Identity Authentication Service','Corporate SSO',
    'Configure IAS as the IdP, establish trust in BTP Cockpit, add custom attributes, and enable risk-based MFA.',
    'SAP IAS login flow working with a custom attribute in the JWT',8,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m5,'cap-55','cap-55-principal-prop','55 · Principal Propagation','On-Premise Identity',
    'Implement OAuth2SAMLBearerAssertion flow to propagate BTP user identity to on-premise systems via Cloud Connector.',
    'CAP calling an on-premise service with the logged-in user''s identity',9,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m5,'cap-56','cap-56-auth-patterns','56 · Advanced Auth Patterns','Hierarchical Roles',
    'Implement hierarchical roles, status-based restrictions, multi-tenant isolation, and a security test matrix.',
    'Security test matrix covering all role/scenario combinations',10,'draft')
  ON CONFLICT (slug) DO NOTHING;

  -- ── MODULE 6 TOPICS ──────────────────────────────────────────────────────
  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m6,'cap-57','cap-57-destination','57 · SAP Destination Service','Connection Registry',
    'Configure the Destination Service, understand auth types, and use cds.connect.to() with destination-backed services.',
    'Remote OData service called via a named BTP destination',1,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m6,'cap-58','cap-58-connectivity','58 · SAP Cloud Connector','On-Premise Tunnel',
    'Configure Cloud Connector, expose an on-premise system as a virtual host, and call it from CAP via the Destination Service.',
    'CAP service calling an on-premise RFC endpoint via Cloud Connector',2,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m6,'cap-59','cap-59-event-mesh','59 · SAP Event Mesh','Async Messaging',
    'Connect CAP to Event Mesh, design topic namespaces, publish CloudEvents, handle DLQ, and ack/nack messages.',
    'Two CAP services exchanging events via Event Mesh with DLQ handling',3,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m6,'cap-60','cap-60-notifications','60 · SAP Alert Notification Service','Multi-Channel Alerts',
    'Set up ANS, use @cap-js/notifications, configure condition-based routing, and integrate with Fiori Notification Hub.',
    'Error alert delivered to Slack and email from a CAP handler',4,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m6,'cap-61','cap-61-s4hana','61 · S/4HANA OData Integration','Delegate Pattern',
    'Import S/4HANA OData metadata, connect via Destination Service, and implement the delegate pattern.',
    'CAP service proxying S/4HANA BusinessPartner API with local cache',5,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m6,'cap-62','cap-62-bapi-rfc','62 · BAPI & RFC Integration','Cloud Connector RFC',
    'Configure RFC destinations via Cloud Connector, call BAPIs from CAP, handle the RETURN table, and commit transactions.',
    'CAP action calling a BAPI with BAPI_TRANSACTION_COMMIT handling',6,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m6,'cap-63','cap-63-workflow','63 · SAP Build Process Automation','Workflow Triggers',
    'Trigger workflow instances from CAP AFTER handlers, receive approval callbacks, and query instance status.',
    'Purchase order approval workflow triggered and confirmed from CAP',7,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m6,'cap-64','cap-64-object-store','64 · SAP Object Store Service','Binary File Storage',
    'Bind Object Store, upload binary files, generate pre-signed download URLs, and stream large file uploads.',
    'Document upload with pre-signed URL download and metadata in HANA',8,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m6,'cap-65','cap-65-job-scheduling','65 · SAP Job Scheduling Service','Recurring Jobs',
    'Register scheduled jobs programmatically, implement secure job endpoints, and monitor run history.',
    'Nightly aggregation job registered in JSS and verified in cockpit',9,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m6,'cap-66','cap-66-logging','66 · SAP Application Logging Service','Structured Logs',
    'Bind Application Logging, configure @sap/logging middleware, emit structured JSON with correlation IDs, and query Kibana.',
    'Kibana dashboard showing correlated log entries for one request',10,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m6,'cap-67','cap-67-feature-flags','67 · SAP Feature Flags Service','Runtime Toggles',
    'Read boolean and string flag values at runtime, gate handlers and UI routes behind flags, and manage rollout percentage.',
    'Feature flag toggling a new code path without redeployment',11,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m6,'cap-68','cap-68-html5-repo','68 · HTML5 App Repository & AppRouter','Frontend Hosting',
    'Package a React SPA for HTML5 App Repository, configure AppRouter routing, and propagate user JWT to CAP.',
    'Full-stack deployment with AppRouter serving SPA and proxying CAP API',12,'draft')
  ON CONFLICT (slug) DO NOTHING;

  -- ── MODULE 7 TOPICS ──────────────────────────────────────────────────────
  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m7,'cap-69','cap-69-mta-intro','69 · MTA Introduction','mta.yaml Structure',
    'Understand MTA modules, resources, and dependencies. Write a valid mta.yaml for a CAP + SPA + AppRouter stack.',
    'Built .mtar archive from a valid mta.yaml with all three modules',1,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m7,'cap-70','cap-70-cf-deploy','70 · CF Deploy','cf deploy Lifecycle',
    'Use the MTA CF Plugin to deploy, monitor, resume failures, do staged deploys with --no-start, and undeploy.',
    'Successful cf deploy to a Cloud Foundry space with all services bound',2,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m7,'cap-71','cap-71-btp-setup','71 · BTP Setup & Entitlements','Account Hierarchy',
    'Understand global account → subaccount → CF org → space hierarchy. Assign entitlements and create production spaces.',
    'Production subaccount with all required services entitled and provisioned',3,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m7,'cap-72','cap-72-blue-green','72 · Blue-Green Deployment','Zero Downtime',
    'Deploy with --strategy blue-green, test the green version, switch traffic atomically, and roll back when needed.',
    'Zero-downtime deployment with smoke test and traffic switch verified',4,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m7,'cap-73','cap-73-cicd','73 · CI/CD with SAP Build Code','Pipeline Stages',
    'Connect a Git repository, write .pipeline/config.yml with multi-environment stages, and gate production with manual approval.',
    'Working pipeline deploying to dev on push and prod on approval',5,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m7,'cap-74','cap-74-monitoring','74 · Monitoring & Alerting','/health & ANS',
    'Expose a /health endpoint, configure ANS error-rate alerts, and use cf app / cf logs for incident triage.',
    'Uptime monitor polling /health with ANS alert firing on error spike',6,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m7,'cap-75','cap-75-tracing','75 · Distributed Tracing','OpenTelemetry',
    'Enable OpenTelemetry tracing in CAP, propagate trace context, export to SAP Cloud ALM, and read span trees.',
    'Trace in Cloud ALM showing the slow span in a multi-service request',7,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m7,'cap-76','cap-76-multitenancy','76 · Multitenancy Basics','@sap/cds-mtxs',
    'Configure cds-mtxs, understand per-tenant HDI containers, req.tenant routing, and the subscribe/unsubscribe lifecycle.',
    'Two mock tenants with fully isolated data in the same CAP deployment',8,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m7,'cap-77','cap-77-saas-registry','77 · SaaS Registry','Subscription Flow',
    'Register a CAP app in the SaaS Registry, configure onSubscription URLs, and secure with the mtcallback scope.',
    'Customer subscription flow working end-to-end in a test subaccount',9,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m7,'cap-78','cap-78-performance','78 · Performance Tuning','N+1 & Indexes',
    'Profile slow requests, eliminate N+1 with CQL expand, add indexes, use EXPLAIN PLAN, and enforce $top limits.',
    'Before/after benchmark showing >5x improvement after fixes',10,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m7,'cap-79','cap-79-security-hardening','79 · Production Security Hardening','CSP & CSRF',
    'Configure CSP/HSTS headers in AppRouter, enable CSRF, add rate limiting, and scan for committed secrets.',
    'Security checklist fully signed off with headers verified in DevTools',11,'draft')
  ON CONFLICT (slug) DO NOTHING;

  INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
  VALUES (m7,'cap-80','cap-80-checklist','80 · Go-Live Checklist','Production Launch',
    'Work through the complete pre-launch checklist, run smoke tests, hand over to operations, and monitor the first 24 hours.',
    'All checklist items signed off and app live in production',12,'draft')
  ON CONFLICT (slug) DO NOTHING;

END $$;
