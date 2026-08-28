-- CodeGoLive - seed data
-- Run AFTER schema.sql. Safe to re-run (uses upsert-style ON CONFLICT).

insert into public.modules (number, title, subtitle, order_index) values
  (0, 'Orientation', 'Theory + your first hands-on setup', 0),
  (1, 'UI5 Fundamentals', 'Standalone apps, local JSON data - no backend yet', 1),
  (2, 'CAP Fundamentals', 'Backend only - build and test a real service', 2),
  (3, 'Full-Stack Integration', 'Rebuild Module 1 apps against real CAP data', 3),
  (4, 'Production Ready', 'Auth, destinations, approuter, deployment', 4),
  (5, 'Capstone Project', 'One real application, built across 4 episodes', 5)
on conflict (number) do nothing;

-- Module 0
insert into public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index)
select id, '0', '0-sp-test', '0-SP-Test (Setup Project)', 'Setup Project',
  'Your first hands-on moment - create the trial, open BAS, scaffold the smallest possible project, and see it running in the browser.',
  'Environment confidence - before any real concept is taught', 0
from public.modules where number = 0
on conflict (slug) do nothing;

-- Module 1
insert into public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index)
select id, '1', '1-ss-test', '1-SS-Test', 'Single Screen',
  'Bootstrapping, index.html, Component, XML views, sap.m controls, data binding basics.',
  'A working single-screen SAPUI5 app', 0
from public.modules where number = 1
on conflict (slug) do nothing;

insert into public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index)
select id, '2', '2-ms-test', '2-MS-Test', 'Multi Screen',
  'manifest.json routing, routes/targets, navTo(), attachPatternMatched(), back navigation.',
  'Main to Detail navigation working end-to-end', 1
from public.modules where number = 1
on conflict (slug) do nothing;

insert into public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index)
select id, '3', '3-crud-test', '3-CRUD-Test', 'CRUD (local)',
  'Create / Read / Update / Delete against a local JSON model, dialogs, list refresh.',
  'Full CRUD loop against a local model', 2
from public.modules where number = 1
on conflict (slug) do nothing;

insert into public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index)
select id, '4', '4-f4-test', '4-F4-Test', 'Value Help',
  'Fragments, Dialog lifecycle, valueHelpRequest, pushing a selected value back into an Input.',
  'Working Value Help dialog', 3
from public.modules where number = 1
on conflict (slug) do nothing;

-- Module 2
insert into public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index)
select id, '5', '5-cap-1-test', '5-CAP-1-TEST', 'First CAP Project',
  'cds init, db/ srv/ app/ package.json, entities, services, JS event handlers, testing via browser/Postman.',
  'A tested CAP service, no UI5 yet', 0
from public.modules where number = 2
on conflict (slug) do nothing;

insert into public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index)
select id, '6', '6-sqllite-test', '6-SqlLite-Test', 'Real Persistence',
  'Schema definition, seed CSVs, cds deploy --to sqlite.',
  'A CAP service backed by real SQLite persistence', 1
from public.modules where number = 2
on conflict (slug) do nothing;

-- Module 3
insert into public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index)
select id, '7', '7-cap-ss-test', '7-CAP-SS-TEST', 'CAP + Single Screen',
  'Rebuild of 1-SS-Test - swap the local JSON model for a live OData model.',
  'Same UI, now backed by live CAP data', 0
from public.modules where number = 3
on conflict (slug) do nothing;

insert into public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index)
select id, '8', '8-cap-ms-test', '8-CAP-MS-TEST', 'CAP + Multi Screen + CRUD',
  'Rebuild of 2-MS + 3-CRUD combined - full CRUD loop against real CAP handlers and SQLite persistence.',
  'Full-stack CRUD loop, UI5 to database', 1
from public.modules where number = 3
on conflict (slug) do nothing;

insert into public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index)
select id, '9', '9-cap-f4-test', '9-CAP-F4-TEST', 'CAP + Value Help',
  'Value Help dialog now searches live CAP data instead of a static array.',
  'Value Help filtering a real backend entity', 2
from public.modules where number = 3
on conflict (slug) do nothing;

-- Module 4
insert into public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index)
select id, '10', '10-validation-test', '10-Validation-Test', 'Validation & Messages',
  'Input validation, MessageToast / MessageBox, MessageManager for model-bound errors.',
  'Forms that validate and report errors cleanly', 0
from public.modules where number = 4
on conflict (slug) do nothing;

insert into public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index)
select id, '11', '11-filter-sort-test', '11-Filter-Sort-Test', 'Search / Filter / Sort',
  'SearchField bound to a Filter, Sorter, oBinding.filter() / .sort().',
  'Searchable, sortable list', 1
from public.modules where number = 4
on conflict (slug) do nothing;

insert into public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index)
select id, '12', '12-auth-test', '12-Auth-Test', 'Authentication (XSUAA)',
  '@requires on CDS services, xs-security.json, roles vs. scopes.',
  'A secured CAP service', 2
from public.modules where number = 4
on conflict (slug) do nothing;

insert into public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index)
select id, '13', '13-destination-test', '13-Destination-Test', 'Destinations',
  'What a BTP Destination is and why hardcoded URLs break in production.',
  'A destination-driven connection', 3
from public.modules where number = 4
on conflict (slug) do nothing;

insert into public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index)
select id, '14', '14-approuter-test', '14-AppRouter-Test', 'App Router',
  'Standalone approuter, xs-app.json, routing UI5 + CAP + auth together.',
  'A working approuter in front of UI5 + CAP', 4
from public.modules where number = 4
on conflict (slug) do nothing;

insert into public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index)
select id, '15', '15-deploy-test', '15-Deploy-Test', 'BTP Deployment',
  'mta.yaml, cds build --production, cf deploy, verifying the live app end-to-end.',
  'A secured, deployed, production-shaped application on BTP', 5
from public.modules where number = 4
on conflict (slug) do nothing;

-- Module 5 - Capstone
insert into public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index)
select id, '16', '16-mp-1-test', '16-MP-1-Test', 'Data Model + CAP Service',
  'Design entities and associations from scratch and expose the service - unaided this time.',
  'A capstone CAP service, self-designed', 0
from public.modules where number = 5
on conflict (slug) do nothing;

insert into public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index)
select id, '17', '17-mp-2-test', '17-MP-2-Test', 'Full UI5 Front-End',
  'Multi-screen navigation, full CRUD, and Value Help built end-to-end without step-by-step guidance.',
  'A complete capstone front-end', 1
from public.modules where number = 5
on conflict (slug) do nothing;

insert into public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index)
select id, '18', '18-mp-3-test', '18-MP-3-Test', 'Polish',
  'Validation, messages, search, filter, and sort - making it feel like a finished product.',
  'A polished, production-feeling capstone app', 2
from public.modules where number = 5
on conflict (slug) do nothing;

insert into public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index)
select id, '19', '19-mp-4-test', '19-MP-4-Test', 'Secure & Deploy',
  'Auth, destination, approuter, and a live BTP deployment - the actual finish line.',
  'A deployed, portfolio-worthy CAP + UI5 application', 3
from public.modules where number = 5
on conflict (slug) do nothing;

-- Starter tags
insert into public.tags (name) values ('routing'), ('crud'), ('odata'), ('value-help'), ('auth'), ('deployment')
on conflict (name) do nothing;

-- Module 6 - Real-World Troubleshooting
insert into public.modules (number, title, subtitle, order_index) values
  (6, 'Real-World Troubleshooting', '40 problems every SAP BTP developer actually faces', 6)
on conflict (number) do nothing;

insert into public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index)
select id, '20', '20-rtp-test', '20-RTP-Test (Real-Time Problems)', 'Real-Time Problems',
  '40 documented real-world errors — binding issues, CORS, auth failures, deployment crashes, BAS quirks — each with the exact fix.',
  'A living reference you will return to throughout your career', 0
from public.modules where number = 6
on conflict (slug) do nothing;
