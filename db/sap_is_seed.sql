-- ─────────────────────────────────────────────────────────────────────────────
-- SAP Integration Suite — course + modules + topics + content
-- Run in Supabase SQL editor
-- ─────────────────────────────────────────────────────────────────────────────

-- ── 1. Course ──────────────────────────────────────────────────────────────────
INSERT INTO public.courses (id, title, subtitle, description, status, icon, order_index)
VALUES (
  'sap-is',
  'SAP Integration Suite',
  'Build enterprise integrations with SAP Integration Suite & iFlows',
  'Master SAP Integration Suite to connect cloud and on-premise systems. Build iFlows with adapters, mappings, and error handling — then deploy and monitor real-world integration scenarios on BTP.',
  'coming_soon',
  '🔌',
  3
)
ON CONFLICT (id) DO UPDATE SET
  title       = EXCLUDED.title,
  subtitle    = EXCLUDED.subtitle,
  description = EXCLUDED.description,
  status      = EXCLUDED.status,
  icon        = EXCLUDED.icon,
  order_index = EXCLUDED.order_index;

-- ── 2. Modules + Topics (DO block so we can capture UUIDs) ────────────────────
DO $$ DECLARE m201 uuid; m202 uuid; m203 uuid; m204 uuid; m205 uuid; BEGIN

-- ── Module 201: IS Foundations ────────────────────────────────────────────────
INSERT INTO public.modules (number, title, subtitle, order_index, course_id)
VALUES (201, 'IS Foundations', 'Overview, tenant setup, your first iFlow', 1, 'sap-is')
ON CONFLICT (number) DO UPDATE SET title = EXCLUDED.title, subtitle = EXCLUDED.subtitle, course_id = EXCLUDED.course_id
RETURNING id INTO m201;
IF m201 IS NULL THEN SELECT id INTO m201 FROM public.modules WHERE number = 201; END IF;

INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
VALUES (m201, 'is-01', 'is-01-intro', '01 · What is SAP Integration Suite?', 'IS Overview',
  'Understand SAP Integration Suite: capabilities, licensing, tenant setup on BTP, and the Cloud Integration (CPI) runtime.',
  'A running IS tenant with one deployed test iFlow', 0, 'draft')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
VALUES (m201, 'is-02', 'is-02-first-iflow', '02 · Your First iFlow', 'Hello World Integration',
  'Create and deploy a simple REST-to-REST iFlow end-to-end: HTTP trigger → content modifier → HTTP receiver.',
  'A deployed iFlow returning "Hello from IS"', 1, 'draft')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
VALUES (m201, 'is-03', 'is-03-message-model', '03 · Message Model & Exchange', 'Headers, Properties, Body',
  'Understand the message exchange model: how body, headers, properties, and attachments flow through processing steps.',
  'An iFlow that reads and modifies headers and body', 2, 'draft')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
VALUES (m201, 'is-04', 'is-04-design-patterns', '04 · Integration Patterns', 'Sync vs Async, Routing',
  'Learn classic enterprise integration patterns: point-to-point, hub-and-spoke, content-based routing, and splitter/aggregator.',
  'A routing iFlow that sends messages to different receivers', 3, 'draft')
ON CONFLICT (slug) DO NOTHING;

-- ── Module 202: Adapters & Connectivity ───────────────────────────────────────
INSERT INTO public.modules (number, title, subtitle, order_index, course_id)
VALUES (202, 'Adapters & Connectivity', 'HTTP, OData, SOAP, SFTP, IDoc, RFC', 2, 'sap-is')
ON CONFLICT (number) DO UPDATE SET title = EXCLUDED.title, subtitle = EXCLUDED.subtitle, course_id = EXCLUDED.course_id
RETURNING id INTO m202;
IF m202 IS NULL THEN SELECT id INTO m202 FROM public.modules WHERE number = 202; END IF;

INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
VALUES (m202, 'is-05', 'is-05-http-odata', '05 · HTTP & OData Adapters', 'REST & OData Connectivity',
  'Consume and expose REST/OData services. Configure HTTP sender and receiver adapters with OAuth2 and Basic Auth.',
  'An iFlow that fetches OData from Northwind and returns JSON', 0, 'draft')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
VALUES (m202, 'is-06', 'is-06-soap', '06 · SOAP Adapter', 'SOAP/WSDL Integration',
  'Connect to SOAP services: import WSDL, configure WS-Security, handle faults, and map SOAP to REST responses.',
  'An iFlow bridging a SOAP backend to a REST caller', 1, 'draft')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
VALUES (m202, 'is-07', 'is-07-sftp', '07 · SFTP & File Adapter', 'File-based Integration',
  'Poll CSV/XML files from SFTP, process each record, route to downstream API, and archive processed files.',
  'An iFlow that polls SFTP and posts each row to an API', 2, 'draft')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
VALUES (m202, 'is-08', 'is-08-idoc-rfc', '08 · IDoc & RFC Adapters', 'SAP ERP Connectivity',
  'Connect SAP S/4HANA or ECC via IDoc (orders, invoices) and RFC (BAPIs). Configure logical system and RFC destinations.',
  'An iFlow receiving an IDoc and posting to a REST API', 3, 'draft')
ON CONFLICT (slug) DO NOTHING;

-- ── Module 203: Message Mapping ───────────────────────────────────────────────
INSERT INTO public.modules (number, title, subtitle, order_index, course_id)
VALUES (203, 'Message Mapping', 'Graphical, XSLT, Groovy, Content Modifier', 3, 'sap-is')
ON CONFLICT (number) DO UPDATE SET title = EXCLUDED.title, subtitle = EXCLUDED.subtitle, course_id = EXCLUDED.course_id
RETURNING id INTO m203;
IF m203 IS NULL THEN SELECT id INTO m203 FROM public.modules WHERE number = 203; END IF;

INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
VALUES (m203, 'is-09', 'is-09-graphical-map', '09 · Graphical Message Mapping', 'Drag-and-Drop Mapping',
  'Map source XML structure to target structure using the graphical mapping editor. Use standard and custom functions.',
  'A mapping that transforms an order XML to an invoice XML', 0, 'draft')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
VALUES (m203, 'is-10', 'is-10-xslt', '10 · XSLT Mapping', 'Stylesheet Transformations',
  'Write XSLT 2.0 stylesheets for complex structural transformations: conditionals, loops, string functions, and namespaces.',
  'An XSLT that converts SAP IDoc XML to a REST JSON payload', 1, 'draft')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
VALUES (m203, 'is-11', 'is-11-groovy', '11 · Groovy Script', 'Dynamic Payload Manipulation',
  'Use Groovy to read/write message body and headers, call external APIs, and implement business logic not possible with graphical mapping.',
  'A Groovy script that enriches payload with live exchange rates', 2, 'draft')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
VALUES (m203, 'is-12', 'is-12-content-mod', '12 · Content Modifier & Splitter', 'Routing & Splitting',
  'Set message headers and properties with Content Modifier. Split bulk payloads with Splitter, process each item, and aggregate results.',
  'An iFlow that splits 100 orders and processes each independently', 3, 'draft')
ON CONFLICT (slug) DO NOTHING;

-- ── Module 204: Error Handling & Security ─────────────────────────────────────
INSERT INTO public.modules (number, title, subtitle, order_index, course_id)
VALUES (204, 'Error Handling & Security', 'Retry, credentials, certificates, encryption', 4, 'sap-is')
ON CONFLICT (number) DO UPDATE SET title = EXCLUDED.title, subtitle = EXCLUDED.subtitle, course_id = EXCLUDED.course_id
RETURNING id INTO m204;
IF m204 IS NULL THEN SELECT id INTO m204 FROM public.modules WHERE number = 204; END IF;

INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
VALUES (m204, 'is-13', 'is-13-error-handling', '13 · Exception Subprocesses', 'Error Handling Patterns',
  'Catch errors with Exception Subprocess, send email alerts, implement dead-letter queues, and build exponential retry logic.',
  'An iFlow with retry, fallback, and email alert on failure', 0, 'draft')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
VALUES (m204, 'is-14', 'is-14-credentials', '14 · Credentials & Certificates', 'Secure Connectivity',
  'Manage OAuth2, Basic Auth, and certificate-based credentials in the IS Security Material store. Reference them from adapters.',
  'An iFlow using credential aliases — no hardcoded passwords', 1, 'draft')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
VALUES (m204, 'is-15', 'is-15-security', '15 · Payload Encryption & Signing', 'PGP & PKI',
  'Encrypt message payloads with PGP, sign messages with X.509 certificates, and verify sender identity on inbound flows.',
  'An iFlow that encrypts outbound payload and verifies inbound signature', 2, 'draft')
ON CONFLICT (slug) DO NOTHING;

-- ── Module 205: Deploy & Monitor ──────────────────────────────────────────────
INSERT INTO public.modules (number, title, subtitle, order_index, course_id)
VALUES (205, 'Deploy & Monitor', 'Deployment, Operations cockpit, alerting, CI/CD', 5, 'sap-is')
ON CONFLICT (number) DO UPDATE SET title = EXCLUDED.title, subtitle = EXCLUDED.subtitle, course_id = EXCLUDED.course_id
RETURNING id INTO m205;
IF m205 IS NULL THEN SELECT id INTO m205 FROM public.modules WHERE number = 205; END IF;

INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
VALUES (m205, 'is-16', 'is-16-deploy', '16 · Deploying iFlows', 'Packages & Versioning',
  'Create integration packages, version artifacts, promote from Dev to Test to Prod transport landscape, and configure deployment parameters.',
  'A versioned iFlow promoted through Dev→Test→Prod', 0, 'draft')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
VALUES (m205, 'is-17', 'is-17-monitor', '17 · Operations Cockpit & Alerting', 'Runtime Monitoring',
  'Use the Operations view to monitor message processing logs, set up email/webhook alerts for failures, and analyse performance metrics.',
  'A monitoring setup with alert rules for your iFlows', 1, 'draft')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO public.topics (module_id, number, slug, title, focus, description, deliverable_note, order_index, status)
VALUES (m205, 'is-18', 'is-18-cicd', '18 · CI/CD for Integration Suite', 'Transport REST API',
  'Automate iFlow deployment with the IS Transport REST API and Jenkins/GitHub Actions. Promote artifacts without manual UI steps.',
  'A GitHub Actions pipeline that deploys an iFlow on every push', 2, 'draft')
ON CONFLICT (slug) DO NOTHING;

END $$;

-- ── 3. Content (explanation → code → key lines → common mistakes → checkpoint) ─

UPDATE public.topics SET content_md = $md$
## What Is SAP Integration Suite?

SAP Integration Suite (formerly SAP Cloud Platform Integration / CPI) is SAP's middleware-as-a-service on BTP. It connects cloud apps, on-premise systems, and third-party APIs — all without writing infrastructure code.

## Why It Matters

Every enterprise has dozens of systems that never talk to each other natively: SAP S/4HANA, Salesforce, external logistics APIs, legacy SOAP services. Integration Suite is the hub that routes, transforms, and orchestrates messages between them at scale.

## Core Capabilities

- **Cloud Integration (iFlow designer)** — visual drag-and-drop flow builder
- **API Management** — publish, throttle, and secure APIs
- **Open Connectors** — 170+ pre-built SaaS adapters
- **Integration Advisor** — B2B mapping templates (EDI, EDIFACT)
- **Trading Partner Management** — B2B partner onboarding

## Setting Up a Trial Tenant

```
1. Go to https://www.sap.com/products/technology-platform/trial.html
2. Create or log in to your SAP Universal ID
3. Access the BTP Cockpit → trial subaccount
4. Find "Integration Suite" in Service Marketplace → subscribe (free trial)
5. Assign the role collection "Integration_Provisioner" to your user
6. Open Integration Suite from your subaccount → Instances and Subscriptions
```

## Key Lines Explained

```
Integration_Provisioner   ← grants access to IS launchpad and design tools
Integration Suite URL     ← https://<tenant>.integrationsuite.cfapps.<region>.hana.ondemand.com
iFlow                     ← an integration flow: the unit of deployment
Artifact                  ← an iFlow, message mapping, or script packaged together
Package                   ← a versioned container holding related artifacts
```

## Common Mistakes

- **Role not assigned** → After subscribing, you must manually assign the `Integration_Provisioner` role collection to your BTP user — it is not automatic.
- **Wrong region** → IS trial is only available in specific CF regions (eu10, us10). Pick the one closest to you.
- **Confusing CPI and IS** → Cloud Integration (CPI) is the iFlow runtime capability inside Integration Suite. They are the same product, different names.

## ✅ Checkpoint

You should now have an Integration Suite tenant URL you can open, and at least one role assigned that lets you enter the Design workspace.
$md$ WHERE slug = 'is-01-intro';


UPDATE public.topics SET content_md = $md$
## Your First iFlow

An iFlow (Integration Flow) is the core building block in Integration Suite. It defines the path a message takes from a sender, through processing steps, to a receiver.

## Why It Matters

Even a trivial iFlow teaches you the IS design surface: how to drag components, configure adapters, and deploy. Once you can deploy "Hello World", you can deploy anything.

## Step-by-Step

### 1 — Open the Design workspace
In your IS tenant → click **Design** → **Create** → new Package → Add → Integration Flow.

### 2 — Add a sender (HTTP trigger)

```
Drag "Sender" shape onto canvas
Click the arrow → select "HTTP" adapter
Config:
  Address: /hello
  CSRF Protected: false
  Authorization: None (for now)
```

### 3 — Add a Content Modifier

```
From palette → Message Transformers → Content Modifier
Double-click → Message Body tab
Type: Expression
Body: Hello from Integration Suite!
```

### 4 — Connect and save

```
Draw arrow: Sender → Content Modifier → End Event
Click Save → Deploy
```

### 5 — Test it

```bash
# Get your iFlow endpoint URL from Monitor → Manage Integration Content
curl https://<your-iflow-url>/hello \
  -H "Authorization: Basic <base64(user:pass)>"
# Expected: Hello from Integration Suite!
```

## Key Lines Explained

```
Address: /hello          ← the URL path your iFlow listens on
Content Modifier         ← overwrites the message body with a static value
Deploy                   ← compiles + starts the iFlow on the CPI runtime
Monitor view             ← shows deployed artifacts and their endpoints
```

## Common Mistakes

- **400 on test** → CSRF protection is ON by default; disable it or send `X-CSRF-Token: fetch` first.
- **Can't find endpoint URL** → Go to Monitor → Manage Integration Content → click your iFlow → copy the endpoint.
- **Deploy button greyed out** → Save the iFlow first; the Deploy button becomes active after save.

## ✅ Checkpoint

Call your iFlow URL with curl and get `Hello from Integration Suite!` in the response body.
$md$ WHERE slug = 'is-02-first-iflow';


UPDATE public.topics SET content_md = $md$
## Message Model & Exchange

Every message in Integration Suite travels inside a **Message Exchange** object. Understanding what it holds — and how steps read/write it — is essential to building correct iFlows.

## Why It Matters

Processing steps like Content Modifier, Groovy Script, and Routing all read from and write to the exchange. If you don't know where your data lives, you'll spend hours debugging wrong headers.

## The Exchange Object

```
Exchange
├── Message (IN)
│   ├── Body         ← the payload (XML, JSON, CSV, binary)
│   ├── Headers      ← HTTP headers + custom headers (String values)
│   └── Attachments  ← MIME attachments (files, PDFs)
└── Properties       ← flow-level variables (not sent to receiver by default)
```

## Reading & Writing in Groovy

```groovy
import com.sap.gateway.ip.core.customdev.util.Message

def Message processData(Message message) {
    // Read body as string
    def body = message.getBody(String)

    // Read a header
    def orderId = message.getHeaders().get("OrderId")

    // Set a property
    message.setProperty("processedAt", new Date().toString())

    // Overwrite body
    message.setBody("Processed: " + orderId)

    return message
}
```

## Key Lines Explained

```groovy
message.getBody(String)           ← reads body as String (can also use InputStream)
message.getHeaders().get("X")     ← reads header named X (case-sensitive)
message.setProperty("k", "v")    ← sets a flow-level variable
message.setBody("new body")       ← replaces the message payload
```

## Common Mistakes

- **Header vs Property** → Headers are sent to the next system; Properties are internal to the iFlow. Don't use headers for sensitive internal state.
- **Case sensitivity** → Header names ARE case-sensitive in IS. `orderId` ≠ `OrderId`.
- **Body consumed** → Once you read the body as `InputStream`, it is consumed. Switch to `String` if you need to read it more than once.

## ✅ Checkpoint

Build an iFlow that reads a custom header `X-Order-Id` from the HTTP request, stores it as a property, and returns it in the response body.
$md$ WHERE slug = 'is-03-message-model';


UPDATE public.topics SET content_md = $md$
## Integration Patterns

Enterprise Integration Patterns (EIP) are reusable solutions to common messaging problems. Integration Suite has built-in components for most of them.

## Why It Matters

Picking the wrong pattern leads to brittle integrations. A synchronous iFlow that calls a slow downstream causes timeouts. An unbounded splitter without an aggregator leaks messages.

## Core Patterns in IS

### Content-Based Router

```
Sender → Router → [condition 1] → Receiver A
                → [condition 2] → Receiver B
                → [otherwise]  → Dead Letter
```

In IS: drag a **Router** step → add conditions (XPath or header expressions).

### Splitter / Aggregator

```
Sender → Splitter → [item 1] → Process → Aggregator → Receiver
                  → [item 2] → Process ↗
```

Use the **General Splitter** to split an XML with 100 orders into 100 individual messages, process each, then aggregate.

### Message Filter

```groovy
// In Router condition:
${header.type} = 'INVOICE'     ← only route if header matches
```

### Request-Reply (sync call to external system)

```
Sender → Request Reply → [HTTP Receiver]
                      ← response flows back automatically
```

## Key Lines Explained

```
Router condition: ${header.X} = 'Y'   ← SpEL expression on header
General Splitter: XPath = /orders/order ← splits at each <order> element
Aggregator strategy: Combine           ← merges all split results back
Request Reply                          ← synchronous outbound call with response
```

## Common Mistakes

- **Forgetting otherwise in Router** → Without a default route, unmatched messages are dropped silently. Always add an "otherwise" branch.
- **Splitter without Aggregator** → Every split message becomes an independent flow instance. Don't forget to aggregate if you need a combined response.
- **Sync iFlow calling slow API** → IS has a 5-minute timeout on HTTP sender. For long operations, switch to async (JMS queue).

## ✅ Checkpoint

Build a router iFlow that sends messages with header `type=ORDER` to one log step and `type=INVOICE` to another. Test both paths.
$md$ WHERE slug = 'is-04-design-patterns';


UPDATE public.topics SET content_md = $md$
## HTTP & OData Adapters

The HTTP and OData adapters are the most-used connectivity options in Integration Suite. HTTP is for plain REST; OData is for SAP-style REST with metadata.

## Why It Matters

Most modern integrations involve REST APIs. Understanding how to configure authentication, headers, and query parameters in these adapters covers 70% of real-world integration scenarios.

## HTTP Sender (expose as API)

```
Sender HTTP adapter config:
  Address:          /api/orders
  HTTP Methods:     POST
  CSRF Protected:   true (enable for production)
  Authorization:    Basic (or OAuth2)
```

## HTTP Receiver (call external API)

```
Receiver HTTP adapter config:
  Address:          https://api.example.com/orders
  Method:           POST
  Authentication:   OAuth2 Client Credentials
  Credential Name:  myOAuthCred   ← references Security Material store
  Request Headers:  Content-Type: application/json
```

## OData Receiver (call SAP or standard OData service)

```
OData V2 Receiver:
  Address:    https://services.odata.org/V2/Northwind/Northwind.svc
  Entity Set: Orders
  Operation:  Query (GET)
  Parameters: $top=10&$filter=ShipCountry eq 'Germany'
```

## Key Lines Explained

```
Credential Name     ← alias pointing to OAuth2/Basic creds in Security Material
CSRF Protected      ← adds X-CSRF-Token fetch/validate handshake (needed for SAP backends)
Address             ← relative path (sender) or full URL (receiver)
$filter             ← OData query filter, safe to set dynamically via headers
```

## Common Mistakes

- **Hardcoding credentials in adapter** → Always use Credential Name (alias). Hardcoded passwords break on rotation.
- **Missing Content-Type** → HTTP receivers default to no Content-Type. Set `application/json` explicitly for REST APIs.
- **CSRF on receiver** → Only SAP systems need CSRF. Enable it only for SAP backends; it adds an extra round-trip for others.

## ✅ Checkpoint

Build an iFlow that receives a POST request, calls the Northwind OData service for the top 5 orders, and returns them as a JSON response.
$md$ WHERE slug = 'is-05-http-odata';


UPDATE public.topics SET content_md = $md$
## SOAP Adapter

SOAP is still common in legacy SAP landscapes. The IS SOAP adapter handles WSDL import, WS-Security, fault handling, and SOAP-to-REST bridging.

## Why It Matters

Many SAP ERP custom web services (SE37 function modules exposed via SOAMANAGER) are SOAP. You'll need this any time you integrate with older SAP systems or insurance/banking backends.

## Configure SOAP Receiver

```
Receiver SOAP adapter config:
  Address:        https://legacy.example.com/ws/OrderService
  Service:        OrderService
  Endpoint:       processOrder
  WSDL URL:       https://legacy.example.com/ws/OrderService?wsdl
  Authentication: Basic
  WS-Security:    Username Token (for legacy SAP)
```

## Map REST input to SOAP envelope

Use **Message Mapping** to transform incoming JSON/XML to the SOAP request structure:

```xml
<!-- Source (incoming JSON, converted to XML) -->
<order>
  <id>1234</id>
  <amount>500.00</amount>
</order>

<!-- Target (SOAP envelope) -->
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
  <soapenv:Body>
    <ord:processOrder>
      <orderId>1234</orderId>
      <total>500.00</total>
    </ord:processOrder>
  </soapenv:Body>
</soapenv:Envelope>
```

## Handle SOAP Faults

```groovy
// In Exception Subprocess, read SOAP fault
def body = message.getBody(String)
if (body.contains("<faultcode>")) {
    def fault = body =~ /<faultstring>(.*?)<\/faultstring>/
    message.setProperty("soapError", fault[0][1])
}
```

## Key Lines Explained

```
WSDL URL            ← IS reads the WSDL to auto-populate operations
WS-Security         ← adds UsernameToken or X.509 to SOAP header
faultstring         ← SOAP error message inside <soap:Fault>
processOrder        ← the SOAP operation name (from WSDL portType)
```

## Common Mistakes

- **Importing WSDL from internal URL** → If the WSDL is behind a VPN, IS can't reach it. Download it manually and upload as a resource.
- **Forgetting namespace** → SOAP body elements must use the correct XML namespace from the WSDL. Namespace mismatches = silent empty responses.
- **WS-Security on non-SAP systems** → Most modern REST APIs don't need WS-Security. Only enable it for older SAP SOAP services.

## ✅ Checkpoint

Build an iFlow that receives an HTTP POST with an order JSON, maps it to a SOAP request, calls a test SOAP service (e.g., dneonline.com/calculator.asmx), and returns the result.
$md$ WHERE slug = 'is-06-soap';


UPDATE public.topics SET content_md = $md$
## SFTP & File Adapter

File-based integration is common for batch scenarios: nightly uploads from HR systems, bank statements, logistics EDI files. The SFTP adapter polls a server and processes each file.

## Why It Matters

Many legacy systems can only export data as files. The SFTP adapter lets you pull these files on a schedule, process each record individually, and archive the original.

## Configure SFTP Sender (polling)

```
SFTP Sender config:
  Host:            sftp.example.com
  Port:            22
  Directory:       /orders/incoming
  File Name:       *.csv
  After Processing: Move to /orders/processed/%timestamp%
  Poll Interval:   60 (seconds)
  Credential Name: sftpCreds
```

## Process Each File with Splitter

```
SFTP Sender → Converter (CSV→XML) → Splitter → Process Row → HTTP Receiver
```

CSV to XML conversion config:
```
Field Separator:   ,
Record Marker:     \n
Skip Header Line:  true
XML Output Tag:    row
```

## Archive and Error Handling

```
SFTP Sender config:
  After Processing (success):  Move to /processed/%timestamp%_${file:name}
  After Processing (error):    Move to /error/${file:name}
```

## Key Lines Explained

```
%timestamp%         ← IS macro for current timestamp in filename
${file:name}        ← header set by SFTP adapter with original filename
Poll Interval       ← how often IS checks for new files (in seconds)
Move to (success)   ← prevents re-processing the same file
Skip Header Line    ← skips the CSV column header row
```

## Common Mistakes

- **Not moving processed files** → Without "After Processing → Move", the same file gets processed on every poll. Always move or delete.
- **Forgetting the splitter** → Without a splitter, the whole CSV is processed as one message. Use splitter to process row by row.
- **File encoding** → Default is UTF-8. For SAP-generated files, sometimes ISO-8859-1. Mismatch causes garbled German/French characters.

## ✅ Checkpoint

Build an iFlow that polls an SFTP folder for CSV files, splits each row, and POSTs each row as JSON to an HTTP endpoint. Move processed files to an archive folder.
$md$ WHERE slug = 'is-07-sftp';


UPDATE public.topics SET content_md = $md$
## IDoc & RFC Adapters

IDoc (Intermediate Document) is SAP's standard format for async B2B messaging. RFC is the synchronous function-module call protocol. Both are essential for integrating SAP ERP (S/4HANA, ECC) with modern cloud services.

## Why It Matters

Every SAP-to-SAP integration or ERP-to-cloud flow (orders, invoices, master data) uses IDoc or RFC. Mastering these adapters unlocks the ERP integration scenarios that enterprises pay the most for.

## IDoc Receiver (send IDoc to SAP)

```
IDoc Receiver config:
  Address:          https://s4hana.example.com:44300
  System ID:        S4H
  Client:           100
  Logical System:   CLNT100
  Port:             SAP_S4H
  Authentication:   Basic
  IDoc Type:        ORDERS05   ← purchase order IDoc
```

## IDoc Sender (receive IDoc from SAP)

Configure in SAP (SM59 + WE21 + WE20):
```
SM59: Create HTTP destination → IS iFlow URL
WE21: Create port → type HTTP → link to SM59 destination
WE20: Create partner profile → outbound params → IDoc type + port
```

## RFC Receiver (call BAPI/function module)

```
RFC Receiver config:
  Address:          rfcs://s4hana.example.com:33100
  Authentication:   Basic
  Function Module:  BAPI_SALESORDER_GETLIST
```

## Key Lines Explained

```
Logical System      ← SAP system identifier (Transaction SCC4)
ORDERS05            ← IDoc message type for purchase orders (05 = version 5)
SM59                ← SAP transaction to configure RFC destinations
WE21                ← SAP transaction to create IDoc ports
BAPI_SALESORDER_GETLIST  ← standard RFC function to fetch sales orders
```

## Common Mistakes

- **Logical system mismatch** → The logical system in IS must exactly match the entry in SAP transaction BDLS. Case-sensitive.
- **IDoc type vs message type** → ORDERS05 is the basic type; ORDERS is the message type. IS needs the basic type.
- **Missing RFC port in SAP** → The RFC connection only works if the target system has a corresponding SM59 entry pointing back.

## ✅ Checkpoint

Configure an iFlow that receives a POST with an order JSON, maps it to an ORDERS05 IDoc structure using graphical mapping, and calls the IDoc receiver adapter (use a mock endpoint if no SAP system is available).
$md$ WHERE slug = 'is-08-idoc-rfc';


UPDATE public.topics SET content_md = $md$
## Graphical Message Mapping

The graphical message mapping editor lets you map source XML elements to target XML elements visually — without writing code for simple field assignments.

## Why It Matters

Most integrations need format transformation: an S/4HANA IDoc has different field names than a Salesforce REST payload. Graphical mapping handles 80% of this without a single line of code.

## Create a Mapping

### 1 — Add source and target schemas

```
In your iFlow → add Message Mapping artifact
Upload or define:
  Source: order_sap.xsd   ← SAP order schema
  Target: order_sf.xsd    ← Salesforce opportunity schema
```

### 2 — Drag connections

```
Source              Target
OrderId      →→→→→  OpportunityId
OrderDate    →→→→→  CloseDate
NetAmount    →→→→→  Amount
CustomerName →→→→→  AccountName
```

### 3 — Use standard functions

```
Source: FirstName + " " + LastName → Target: FullName

Steps:
  FirstName → concat (function) → FullName
  " "       ↗
  LastName  ↗
```

### 4 — Use a custom Java function for complex logic

```java
// In mapping editor → create custom function
public String formatDate(String sapDate) {
    // SAP date: 20240115 → ISO: 2024-01-15
    return sapDate.substring(0,4) + "-" + sapDate.substring(4,6) + "-" + sapDate.substring(6,8);
}
```

## Key Lines Explained

```
XSD schema         ← defines the structure IS uses to build the mapping tree
concat function    ← IS built-in: concatenates multiple string values
1:1 mapping        ← direct field-to-field assignment (drag line)
Custom function    ← Java code executed during mapping for complex transformations
```

## Common Mistakes

- **Wrong namespace in XSD** → If the source XML uses a namespace not declared in the XSD, elements won't appear in the mapping tree.
- **Unmapped required fields** → IS doesn't warn if required target fields are unmapped. Missing fields produce invalid output silently.
- **Using mapping for Groovy logic** → Graphical mapping is for structural transformation. For business rules and conditionals, use Groovy instead.

## ✅ Checkpoint

Create a message mapping that transforms a simple order XML (OrderId, Amount, CustomerName) into a Salesforce-style JSON-equivalent XML structure (id, value, account). Test it with the mapping test tool.
$md$ WHERE slug = 'is-09-graphical-map';


UPDATE public.topics SET content_md = $md$
## XSLT Mapping

XSLT (Extensible Stylesheet Language Transformations) is the most powerful transformation tool in IS. Use it when graphical mapping can't express the logic you need.

## Why It Matters

Complex scenarios — conditional elements, looping with filters, multi-source merges, namespace rewriting — are impossible or fragile in graphical mapping. XSLT handles them elegantly.

## Basic XSLT Structure

```xml
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:ord="http://sap.com/xi/orders">

  <xsl:output method="xml" indent="yes"/>

  <!-- Match root element -->
  <xsl:template match="/ord:Order">
    <SalesforceOpportunity>
      <Id><xsl:value-of select="ord:OrderId"/></Id>
      <Amount><xsl:value-of select="ord:NetAmount"/></Amount>
      <!-- Conditional element -->
      <xsl:if test="ord:NetAmount > 10000">
        <Priority>High</Priority>
      </xsl:if>
    </SalesforceOpportunity>
  </xsl:template>

</xsl:stylesheet>
```

## Loop over child elements

```xml
<Items>
  <xsl:for-each select="ord:Items/ord:Item">
    <Item>
      <ProductId><xsl:value-of select="@productId"/></ProductId>
      <Quantity><xsl:value-of select="ord:Quantity"/></Quantity>
    </Item>
  </xsl:for-each>
</Items>
```

## Add XSLT to iFlow

```
In iFlow palette → Message Transformers → XSLT Mapping
Upload your .xsl file as a resource
Connect: previous step → XSLT → next step
```

## Key Lines Explained

```xslt
xsl:value-of select="..."    ← outputs the text value of the XPath expression
xsl:if test="..."            ← conditional — only outputs element if true
xsl:for-each select="..."   ← loops over a node-set
@productId                   ← XPath to read an XML attribute
xmlns:ord="..."              ← must match the namespace in source XML
```

## Common Mistakes

- **Wrong namespace prefix** → The `xmlns:ord` declaration must match the actual namespace URI in the source document exactly.
- **XSLT 1.0 vs 2.0** → IS supports XSLT 2.0. Features like `xsl:function` and `xsl:sequence` don't exist in 1.0.
- **Whitespace in output** → `<xsl:output indent="yes"/>` adds whitespace for readability. Remove it for compact production output if size matters.

## ✅ Checkpoint

Write an XSLT that transforms an order XML (with multiple `<Item>` children) into a flattened list of `<LineItem>` elements, skipping items with `quantity = 0`. Test it in an iFlow.
$md$ WHERE slug = 'is-10-xslt';


UPDATE public.topics SET content_md = $md$
## Groovy Script

Groovy is the scripting language embedded in Integration Suite. It gives you full Java API access with concise syntax — perfect for payload manipulation, external API calls, and logic that graphical tools can't express.

## Why It Matters

Groovy scripts cover the gap between what graphical components offer and what the business actually needs. Real-world iFlows almost always need at least one Groovy step.

## Basic Script Structure

```groovy
import com.sap.gateway.ip.core.customdev.util.Message
import groovy.json.JsonSlurper
import groovy.json.JsonOutput

def Message processData(Message message) {
    // 1. Read body
    def body = message.getBody(String)

    // 2. Parse JSON
    def json = new JsonSlurper().parseText(body)

    // 3. Enrich with live exchange rate (HTTP call)
    def url = "https://api.exchangerate.host/latest?base=EUR&symbols=USD"
    def rate = new URL(url).getText()
    def rateJson = new JsonSlurper().parseText(rate)
    def usdRate = rateJson.rates.USD

    // 4. Add field to payload
    json.amountUSD = json.amountEUR * usdRate

    // 5. Write back
    message.setBody(JsonOutput.toJson(json))
    return message
}
```

## Read and set headers

```groovy
def orderId = message.getHeaders().get("OrderId")
message.setHeader("ProcessedBy", "IS-Groovy")
message.setProperty("startTime", System.currentTimeMillis().toString())
```

## Key Lines Explained

```groovy
message.getBody(String)          ← reads entire body as String
new JsonSlurper().parseText(b)   ← parses JSON string to Map/List
new URL(url).getText()           ← makes a synchronous HTTP GET
message.setBody(...)             ← replaces the message payload
JsonOutput.toJson(json)          ← converts Map/List back to JSON string
```

## Common Mistakes

- **Not returning message** → Every Groovy script must end with `return message`. Missing it causes a null pointer exception.
- **Calling slow external APIs synchronously** → IS has a timeout. For slow external calls, cache results in a property or use async patterns.
- **Consuming InputStream** → `message.getBody(InputStream)` consumes the stream. After that, `getBody(String)` returns empty. Always use `String` if you need to read more than once.

## ✅ Checkpoint

Write a Groovy script that reads a `price` field from a JSON body, fetches a live EUR→USD rate from an open API, adds a `priceUSD` field to the JSON, and writes it back.
$md$ WHERE slug = 'is-11-groovy';


UPDATE public.topics SET content_md = $md$
## Content Modifier & Splitter

The Content Modifier sets body, headers, and properties. The Splitter breaks a bulk message into individual messages so each can be processed independently.

## Why It Matters

Bulk processing without a splitter means one failure kills all 1000 records. With a splitter, each item gets its own trace, retry, and error context.

## Content Modifier — set a static header

```
Content Modifier → Headers tab:
  Name:   X-Source-System
  Type:   Constant
  Value:  SAP-IS
```

## Content Modifier — set body from expression

```
Content Modifier → Message Body tab:
  Type:    Expression
  Body:    Order ${header.OrderId} received at ${date:now:yyyy-MM-dd}
```

## General Splitter (split XML)

```
Splitter config:
  Expression Type:   XPath
  XPath Expression:  /orders/order
  Parallel Processing: false   ← sequential is safer for ordered scenarios
```

This turns:
```xml
<orders>
  <order><id>1</id></order>
  <order><id>2</id></order>
  <order><id>3</id></order>
</orders>
```
Into 3 separate messages, one per `<order>`.

## Aggregator (collect split results)

```
Aggregator config:
  Correlation Expression:   ${header.SAP_MessageProcessingLogID}
  Aggregation Algorithm:    Combine
  Completion Condition:     Sequence Number == Maximum Sequence Number
```

## Key Lines Explained

```
${header.X}                  ← SpEL expression to read header X in Content Modifier
${date:now:yyyy-MM-dd}       ← IS date macro for current date
XPath: /orders/order         ← IS splits at each node matching this path
SAP_MessageProcessingLogID   ← IS system header — uniquely identifies the split batch
Completion Condition         ← tells aggregator when all split items have arrived
```

## Common Mistakes

- **Parallel splitter with ordered receiver** → Parallel processing is faster but doesn't guarantee order. Use sequential if the receiver is order-sensitive.
- **Aggregator never completes** → If one split item fails, the aggregator waits forever. Add a timeout to the aggregator config.
- **Setting headers in receiver adapter** → HTTP adapter strips unknown headers before sending. Move business data to the body, not headers.

## ✅ Checkpoint

Build an iFlow that receives an XML with 5 orders, splits each, adds a `X-Processed-By` header via Content Modifier, POSTs each to an endpoint, and aggregates all 5 responses into one combined XML.
$md$ WHERE slug = 'is-12-content-mod';


UPDATE public.topics SET content_md = $md$
## Exception Subprocesses & Retry

IS gives you structured error handling via Exception Subprocess, dead-letter queues, and built-in retry. Every production iFlow needs at least one.

## Why It Matters

Without error handling, a failed HTTP call crashes the entire iFlow and the message is lost. With proper handling, you get retries, alerts, and a message store for manual replay.

## Add an Exception Subprocess

```
In your iFlow:
1. Right-click on the process box → Add → Exception Subprocess
2. It appears as a bordered sub-area attached to the main process
3. Inside: add your error steps (send email, write to data store, set error header)
```

## Send Email Alert on Failure

```
Exception Subprocess → Mail Receiver adapter:
  Host:     smtp.gmail.com
  Port:     587
  From:     alerts@yourcompany.com
  To:       team@yourcompany.com
  Subject:  IS Error: ${header.SAP_MessageProcessingLogID}
  Body:     iFlow failed: ${exception.message}
```

## Configure Retry on Receiver

```
HTTP Receiver adapter → Retry tab:
  Retry Interval:    10 (seconds)
  Maximum Retries:   3
  Exponential Backoff: true
```

## Dead-Letter Queue (JMS)

```
On failure, write to JMS queue for replay:
JMS Receiver:
  Queue:  error_queue
  Body:   ${in.body}
```

## Key Lines Explained

```groovy
${exception.message}    ← IS variable containing the error message text
${exception.class}      ← Java exception class name
SAP_MessageProcessingLogID  ← unique trace ID for this message (use in alerts)
Retry → Exponential Backoff ← doubles wait time: 10s, 20s, 40s, up to max
JMS Queue               ← persistent store for failed messages (replay later)
```

## Common Mistakes

- **Exception Subprocess not connected** → The subprocess must be inside the same Integration Process box. If it's floating, it never fires.
- **Email adapter not configured** → Mail sender needs a valid SMTP credential in Security Material. Test it with a simple static iFlow first.
- **Retry on non-idempotent receivers** → Only retry if the receiver can handle duplicate messages. Some APIs create duplicates on retry.

## ✅ Checkpoint

Build an iFlow with a deliberate failure (call a non-existent URL). Add an Exception Subprocess that writes the error message to a Data Store and sends a log entry. Verify the error appears in the Data Store.
$md$ WHERE slug = 'is-13-error-handling';


UPDATE public.topics SET content_md = $md$
## Credentials & Certificates

Hard-coding passwords in adapters is a security anti-pattern. Integration Suite's Security Material store provides credential aliases that decouple configuration from secret values.

## Why It Matters

When passwords rotate (they do, every 90 days in most enterprises), you update the credential store once — not every adapter in every iFlow. Certificate expiry alerts prevent integration outages.

## Add User Credentials

```
IS Launchpad → Monitor → Security Material → Add
  Type:     User Credentials
  Name:     mySalesforceCredentials   ← this is the alias
  User:     integration_user@company.com
  Password: ••••••••
```

Reference in adapter:
```
HTTP Receiver → Authentication: Basic
Credential Name: mySalesforceCredentials
```

## OAuth2 Client Credentials

```
Security Material → Add:
  Type:           OAuth2 Client Credentials
  Name:           myOAuthAlias
  Token Service URL: https://login.salesforce.com/services/oauth2/token
  Client ID:      3MVG9...
  Client Secret:  ••••••
  Scope:          api
```

## Upload a Certificate (outbound TLS)

```
Security Material → Keystore → Add Certificate:
  Upload .cer or .pem file from the target system
  Alias: targetSystemCert
```

## Key Lines Explained

```
Credential Name       ← alias used in adapter — never the actual password
OAuth2 Client Creds   ← IS fetches token automatically before each call
Keystore              ← stores IS's own private key + public certificate
Truststore            ← stores certificates of external systems IS trusts
Certificate Alias     ← how you reference a cert in adapter config
```

## Common Mistakes

- **Deploying after credential change** → Credential updates are live immediately — you do NOT need to redeploy the iFlow.
- **Wrong OAuth token URL** → The token endpoint URL is system-specific. Copy it exactly from the API documentation.
- **Certificate CN mismatch** → If the certificate's Common Name doesn't match the hostname IS is connecting to, TLS fails with a hostname verification error.

## ✅ Checkpoint

Create a User Credential and an OAuth2 Credential in Security Material. Build an iFlow that uses the OAuth2 credential to call a protected API without the token URL or client secret appearing anywhere in the iFlow.
$md$ WHERE slug = 'is-14-credentials';


UPDATE public.topics SET content_md = $md$
## Payload Encryption & Signing

When messages carry sensitive business data (PII, financial records), encrypt the payload end-to-end and sign it so the receiver can verify the sender's identity.

## Why It Matters

TLS only protects data in transit. If an intermediate system logs the message, the plain-text payload is exposed. Payload-level encryption (PGP) ensures only the intended receiver can read it.

## PGP Encryption (outbound)

```
iFlow: Sender → Encryptor → HTTP Receiver

Encryptor step config:
  Type:               PGP
  Operation:          Encrypt
  Receipient Key:     receiverPublicKey   ← alias in Keystore
  Symmetric Algorithm: AES-256
```

## PGP Decryption (inbound)

```
iFlow: HTTP Sender → Decryptor → Process

Decryptor step config:
  Type:     PGP
  Private Key: myPrivateKey   ← alias in Keystore
```

## Digital Signing (XML/PKCS7)

```
Signer step config:
  Type:      PKCS7/CMS
  Operation: Sign
  Private Key Alias: mySigningKey
  Hash Algorithm:    SHA-256
```

## Signature Verification

```
Verifier step config:
  Signer Public Key Alias: partnerPublicKey
  Fail on Invalid Signature: true
```

## Key Lines Explained

```
Recipient Key Alias       ← the receiver's PUBLIC key (you encrypt with their public key)
Private Key Alias         ← YOUR private key (you decrypt with your private key)
PGP vs PKCS7              ← PGP for file/payload encryption; PKCS7 for XML signing
SHA-256                   ← hashing algorithm used to create the digital signature
Fail on Invalid Signature ← rejects messages with invalid or missing signature
```

## Common Mistakes

- **Wrong key direction** → Encrypt with the RECEIVER'S public key. Decrypt with YOUR private key. Confusion here means nobody can read the message.
- **PGP key expiry** → PGP keys have expiry dates. Upload partner key rotations proactively — IS will refuse to encrypt with an expired key.
- **Signing vs Encryption** → Signing proves identity (non-repudiation). Encryption hides content. Many scenarios need both in sequence.

## ✅ Checkpoint

Build an iFlow that receives a plain-text payload, encrypts it with PGP using a test public key, sends it to an endpoint, receives it back, and decrypts it — verifying the round-trip produces the original message.
$md$ WHERE slug = 'is-15-security';


UPDATE public.topics SET content_md = $md$
## Deploying iFlows

Professional IS development uses transport landscapes: Dev → Test → Prod. IS supports this with packages, versioning, and the Content Agent (transport tool).

## Why It Matters

Deploying directly to production without a test landscape is risky. Versioning lets you roll back. Packages let you transport multiple related artifacts together as one unit.

## Create and Version a Package

```
Design → Create Package
  Name:    Order Integration v1.0
  Version: 1.0.0

Add iFlows, mappings, and scripts to the package.
```

## Deploy to target runtime

```
Design → select iFlow → Deploy
  Runtime Profile: Cloud Integration
  Status → check Monitor → Manage Integration Content
```

## Transport to Test/Prod with Content Agent

```
Integration Suite → Settings → Transport → Content Agent
Configure:
  Source:      Dev IS tenant
  Target:      Test IS tenant
  Package:     Order Integration v1.0
```

Export from Dev:
```
Package → Export → Download .zip
```

Import to Test:
```
Test tenant → Design → Import → upload .zip
Deploy each artifact
```

## Key Lines Explained

```
Runtime Profile       ← IS has one default profile per tenant; no config needed for basic
Version 1.0.0         ← semantic versioning: MAJOR.MINOR.PATCH
Content Agent         ← SAP tool for transport between IS tenants
Export .zip           ← includes all artifacts in the package (iFlows, mappings, scripts)
Manage Integration Content  ← shows deployed artifacts and their status (started/error)
```

## Common Mistakes

- **Forgetting to save before deploy** → IS will deploy the last saved version, not the current editor state. Always save first.
- **Deploying without testing** → Use the Monitor's MPL (Message Processing Log) to test the iFlow with a trace before promoting.
- **Package version not updated** → If you change an iFlow, bump the package version too. Otherwise the transport history is confusing.

## ✅ Checkpoint

Create a package, add an existing iFlow, deploy it, and verify it shows "Started" in Monitor → Manage Integration Content. Export the package as a .zip.
$md$ WHERE slug = 'is-16-deploy';


UPDATE public.topics SET content_md = $md$
## Operations Cockpit & Alerting

The Operations view is your runtime control center. It shows every message that passed through IS, whether it succeeded or failed, and lets you replay failed messages.

## Why It Matters

In production, integrations fail. A downstream API goes down, a payload is malformed, a certificate expires. The Operations cockpit is how you find out and recover — before the business notices.

## Message Processing Log (MPL)

```
Monitor → Monitor Message Processing → Overview

Filters:
  Status:        Failed / Completed / Processing
  Time:          Last 1 hour / Custom range
  Component:     specific iFlow name
  Correlation ID: for tracing end-to-end

Click a failed message → Trace View → see exactly which step failed
```

## Enable Trace-Level Logging

```
Monitor → Manage Integration Content → select iFlow
Set Log Level: Trace (only for debugging — disable after, costs performance)

Now in MPL: each processing step shows its input/output payload
```

## Configure Alert Rules

```
Monitor → Manage Security → Alert Management → Add Rule:
  Condition:   Integration Flow Status = Error
  Notification: Email to team@company.com
  Frequency:   Once per occurrence (not per message)
```

## Key Lines Explained

```
MPL                   ← Message Processing Log — one entry per processed message
Trace Level           ← logs payload at every step; only use for debugging
Correlation ID        ← links related messages across different iFlows
Replay               ← resend a failed message without re-triggering the sender
Alert Rule           ← sends notification when conditions are met (error, threshold)
```

## Common Mistakes

- **Leaving Trace on in production** → Trace logs every payload, which fills storage and slows the runtime. Switch back to Info after debugging.
- **Not setting up alerts** → Without alerts, a silent failure can run for hours before someone notices. Set up email alerts for error status on every production iFlow.
- **Missing Correlation ID** → For multi-step flows across several iFlows, set a custom Correlation ID header at the entry point so you can trace end-to-end in MPL.

## ✅ Checkpoint

Deliberately trigger a failure in a test iFlow (e.g., call a bad URL). Find the failed message in MPL, open the Trace, identify the failing step, fix the iFlow, and replay the message successfully.
$md$ WHERE slug = 'is-17-monitor';


UPDATE public.topics SET content_md = $md$
## CI/CD for Integration Suite

Manual deployment through the UI doesn't scale. The IS Transport REST API lets you trigger deployments from GitHub Actions, Jenkins, or any CI/CD system — pushing a button becomes a git push.

## Why It Matters

When 5 developers work on 50 iFlows, you need automated testing and deployment. CI/CD for IS reduces deployment time from 30 minutes of clicking to 2 minutes of automation.

## IS Transport REST API

Base URL: `https://<tenant>.integrationsuite.cfapps.<region>.hana.ondemand.com`

```bash
# 1. Get OAuth token (client credentials)
curl -X POST https://<oauth-server>/oauth/token \
  -d "grant_type=client_credentials&client_id=<id>&client_secret=<secret>" \
  | jq .access_token

# 2. List packages
curl -H "Authorization: Bearer $TOKEN" \
  "<BASE>/api/v1/IntegrationPackages"

# 3. Deploy an iFlow
curl -X POST \
  -H "Authorization: Bearer $TOKEN" \
  "<BASE>/api/v1/DeployIntegrationDesigntimeArtifact
    ?Id='MyiFlow'&Version='active'"
```

## GitHub Actions workflow

```yaml
# .github/workflows/deploy-is.yml
name: Deploy to IS

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Get OAuth Token
        id: token
        run: |
          TOKEN=$(curl -s -X POST "${{ secrets.IS_TOKEN_URL }}" \
            -d "grant_type=client_credentials" \
            -u "${{ secrets.IS_CLIENT_ID }}:${{ secrets.IS_CLIENT_SECRET }}" \
            | jq -r .access_token)
          echo "TOKEN=$TOKEN" >> $GITHUB_ENV

      - name: Deploy iFlow
        run: |
          curl -X POST \
            -H "Authorization: Bearer $TOKEN" \
            "${{ secrets.IS_BASE_URL }}/api/v1/DeployIntegrationDesigntimeArtifact\
?Id='OrderIntegration'&Version='active'"
```

## Key Lines Explained

```
DeployIntegrationDesigntimeArtifact  ← API endpoint to trigger a deployment
Version='active'                     ← deploys the current draft version
client_credentials                   ← OAuth2 flow for machine-to-machine auth
GITHUB_ENV                           ← GitHub Actions way to share variables between steps
IS_BASE_URL                          ← stored as GitHub secret, not hardcoded
```

## Common Mistakes

- **Using user credentials in CI/CD** → Always use OAuth2 client credentials (a service user), never a human user's password in automation.
- **Deploying unvalidated changes** → Add a step before deploy that calls the IS Validate API, or run iFlow unit tests with the IS Testing Framework.
- **Not checking deploy status** → The deploy API returns immediately; the actual deployment is async. Poll `GET .../DeployedArtifacts` until status = "STARTED".

## ✅ Checkpoint

Create a GitHub Actions workflow that authenticates to IS using client credentials stored as GitHub Secrets and deploys one iFlow. Verify the deployment succeeds by checking the iFlow status in Monitor.
$md$ WHERE slug = 'is-18-cicd';

-- Verify
SELECT c.id, c.status,
  COUNT(DISTINCT m.id) AS modules,
  COUNT(DISTINCT t.id) AS topics
FROM public.courses c
LEFT JOIN public.modules m ON m.course_id = c.id
LEFT JOIN public.topics t ON t.module_id = m.id
WHERE c.id = 'sap-is'
GROUP BY c.id, c.status;
