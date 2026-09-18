-- ============================================================
-- SAP CAP Course — Module 6: BTP Services Integration
-- Run AFTER sap_cap_seed.sql
-- Lessons: cap-57 through cap-68 (12 lessons)
-- ============================================================

-- ── Lesson 57 — SAP Destination Service ──────────────────────────────────────

UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 57 — SAP Destination Service

## What you'll learn
- What the SAP Destination Service does and when to use it
- Creating HTTP and RFC destinations in BTP Cockpit
- Reading destinations at runtime in CAP
- Authentication types: BasicAuthentication, OAuth2ClientCredentials, OAuth2SAMLBearerAssertion
- Environment-based destination configuration for dev/prod

## Why this matters
Hardcoding external system URLs and credentials is a deployment anti-pattern. The Destination Service centralises all connection parameters — URL, auth type, credentials, proxy settings — so CAP code never contains secrets, and ops teams can change targets without code deployments.

## What is a Destination?

A destination is a named connection configuration stored in BTP:

```json
{
  "Name":              "S4HANA_SYSTEM",
  "Type":              "HTTP",
  "URL":               "https://s4hana.company.com:443",
  "Authentication":    "OAuth2ClientCredentials",
  "TokenServiceURL":   "https://..../oauth/token",
  "ClientId":          "cap-integration-client",
  "ClientSecret":      "...",
  "ProxyType":         "Internet",
  "HTML5.DynamicDestination": "true"
}
```

## Creating a destination in BTP Cockpit

1. BTP Cockpit → Subaccount → Connectivity → Destinations → New Destination
2. Fill: Name, Type=HTTP, URL, Authentication type
3. Additional Properties: `HTML5.DynamicDestination=true` (for AppRouter forwarding)
4. Click "Save" then "Check Connection" to verify

## Binding Destination Service to CAP

```yaml
# mta.yaml
resources:
  - name: destination-service
    type: org.cloudfoundry.managed-service
    parameters:
      service:      destination
      service-plan: lite

modules:
  - name: bookshop-srv
    requires:
      - name: destination-service
```

## Reading a destination in CAP

```js
// srv/integration-service.js
const cds = require('@sap/cds')

module.exports = class IntegrationService extends cds.ApplicationService {
  async init () {
    this.on('READ', 'ExternalProducts', async (req) => {
      // CAP connects to a service defined in .cdsrc.json using a named destination
      const remoteService = await cds.connect.to('ExternalProductAPI')
      return remoteService.run(req.query)
    })

    await super.init()
  }
}
```

```json
// .cdsrc.json
{
  "requires": {
    "ExternalProductAPI": {
      "[production]": {
        "kind":        "odata-v4",
        "destination": "S4HANA_SYSTEM",     // ← Destination name in BTP Cockpit
        "path":        "/sap/opu/odata/sap"
      },
      "[development]": {
        "kind":  "odata-v4",
        "credentials": {
          "url": "https://sandbox.api.sap.com/..."
        }
      }
    }
  }
}
```

## Authentication types reference

| Auth Type | Use case | Secret stored where |
|---|---|---|
| `NoAuthentication` | Public APIs | n/a |
| `BasicAuthentication` | Legacy systems, RFC | Destination (never in code) |
| `OAuth2ClientCredentials` | Service-to-service | Destination |
| `OAuth2SAMLBearerAssertion` | Principal propagation | Destination + XSUAA |
| `OAuth2JWTBearer` | User context propagation | Destination + XSUAA |
| `SAMLAssertion` | S/4HANA on-prem | Destination |

## Instance vs subaccount destinations

- **Subaccount level**: visible to all apps in the subaccount (shared secrets risk)
- **Service instance level**: specific to one app — preferred for production

```bash
# Check which destinations a service instance provides
cf service-key destination-service destination-key | jq '.["instanceDestinations","subaccountDestinations"]'
```

## Local dev without Destination Service

```json
// .cdsrc.json — use direct credentials locally
{
  "requires": {
    "ExternalProductAPI": {
      "[development]": {
        "kind": "odata-v4",
        "credentials": {
          "url":     "https://sandbox.api.sap.com/s4hanacloud",
          "headers": { "APIKey": "YOUR_DEV_API_KEY" }
        }
      }
    }
  }
}
```

## Hands-on exercise
1. Create a destination in your BTP trial for the SAP API Business Hub sandbox
2. Bind the Destination Service to your CAP app via mta.yaml
3. Change your remote service config to use `"destination": "MY_DEST_NAME"`
4. Deploy and verify the call succeeds without credentials in the code

## Checkpoint ✓
- [ ] Destinations centralise all connection parameters — no secrets in code
- [ ] `"destination": "DEST_NAME"` in `.cdsrc.json` uses BTP Destination Service at runtime
- [ ] Instance-level destinations are preferred over subaccount-level for isolation
- [ ] Dev uses direct credentials; production uses named destinations
$md$
WHERE slug = 'cap-57-destination';

-- ── Lesson 58 — Connectivity Service & Cloud Connector ───────────────────────

UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 58 — Connectivity Service & Cloud Connector

## What you'll learn
- What SAP Cloud Connector does
- Installing and configuring Cloud Connector
- Exposing on-premise systems to BTP
- Connectivity Service binding and proxy settings
- Testing the on-premise connection from CAP

## Why this matters
Most enterprises have critical data in on-premise ERP systems. Cloud Connector is the secure tunnel that lets CAP call those systems without opening firewall ports or installing a DMZ proxy.

## Architecture

```
BTP (Cloud Foundry)
│
│  CAP app → Connectivity Service → SAP Cloud Connector tunnel
│
Firewall ────────────────────────────────────────────────────
│
On-Premise Network
│
├── SAP Cloud Connector (reverse proxy, installed on-prem)
│      │
│      └── S/4HANA, ECC, SAP Gateway, any HTTP/RFC system
```

The connection is **initiated from on-premise to BTP** — no inbound firewall rule needed.

## Installing Cloud Connector

1. Download from SAP Tool Center (Java-based, runs on any OS)
2. `./go.sh` (Linux) or `cloudconnector.exe` (Windows)
3. Access admin UI: https://localhost:8443
4. Initial login: Administrator / manage (change immediately!)
5. Connect to BTP:
   - Region: your BTP region (e.g., `cf.eu10.hana.ondemand.com`)
   - Subaccount ID: from BTP Cockpit Overview
   - Logon email + password (or certificate)

## Exposing an on-prem system

In Cloud Connector admin UI → Access Control → Cloud to On-Premise → Add:

```
Back-end Type:    SAP ABAP System (or non-SAP)
Protocol:         HTTPS
Internal Host:    s4hana.corp.internal   (real hostname)
Internal Port:    443
Virtual Host:     s4hana-virtual          (alias BTP sees)
Virtual Port:     443
Check Internal Host: ✓  (tests connectivity)
```

Resources within the system to allow:
```
URL Path: /sap/opu/odata/          ← allow OData calls
Access Policy: Path And All Sub-Paths
```

## Binding Connectivity Service

```yaml
# mta.yaml
resources:
  - name: connectivity
    type: org.cloudfoundry.managed-service
    parameters:
      service:      connectivity
      service-plan: lite

modules:
  - name: bookshop-srv
    requires:
      - name: connectivity
      - name: destination-service
```

## Destination for on-premise

```
In BTP Cockpit → Destinations:
Name:             S4HANA_ONPREM
Type:             HTTP
URL:              http://s4hana-virtual:443   ← virtual host from SCC
ProxyType:        OnPremise                   ← tells CAP to use Cloud Connector
Authentication:   BasicAuthentication (or OAuth2SAMLBearerAssertion)
```

## CAP configuration

```json
// .cdsrc.json
{
  "requires": {
    "S4HANA": {
      "[production]": {
        "kind":        "odata-v2",
        "destination": "S4HANA_ONPREM"   // BTP Destination with ProxyType: OnPremise
      }
    }
  }
}
```

CAP + Destination Service automatically route through Cloud Connector when `ProxyType: OnPremise`.

## RFC connections

For BAPI/RFC calls (not OData):
```
Cloud Connector → Access Control → Cloud to On-Premise → Add RFC
Internal Host:   sapgw00.corp.internal
Internal Port:   3300
Virtual Host:    sapgw00-virtual
Virtual Port:    3300
Protocol:        RFC
```

```json
// Destination for RFC
{
  "Name":        "S4HANA_RFC",
  "Type":        "RFC",
  "jco.client.r3name": "S4H",
  "jco.client.client": "100",
  "jco.destination.pool_capacity": "5"
}
```

## Troubleshooting Cloud Connector

```bash
# Verify SCC is connected to BTP
# BTP Cockpit → Connectivity → Cloud Connectors → Should show your SCC as Connected

# Check SCC audit log
# SCC admin UI → Logs → Audit Log

# Test from BTP directly
cf ssh bookshop-srv
# Inside the container:
curl -v http://s4hana-virtual/sap/opu/odata/sap/...
```

## Hands-on exercise
1. Install Cloud Connector locally (or in a VM)
2. Connect it to your BTP trial subaccount
3. Expose `localhost:4004` (your other CAP app) as a virtual host
4. Create an OnPremise destination pointing to the virtual host
5. Call the virtual host from another CAP service

## Checkpoint ✓
- [ ] SCC is installed on-premise; the tunnel is **outbound from on-prem to BTP** (no inbound firewall rule)
- [ ] Virtual host in SCC = the name BTP uses to refer to the on-prem system
- [ ] `ProxyType: OnPremise` in the BTP Destination routes the call through SCC
- [ ] RFC connections use a separate Destination Type: RFC
$md$
WHERE slug = 'cap-58-connectivity';


-- ── Lesson 59 — SAP Event Mesh Advanced Topics ───────────────────────────────

UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 59 — SAP Event Mesh — Advanced Topics

## What you'll learn
- Event Mesh namespace design and topic hierarchies
- Queue-based vs topic subscription patterns
- Guaranteed delivery and at-least-once semantics
- Dead letter queues and retry policies
- Monitoring Event Mesh in BTP Cockpit

## Why this matters
Lesson 28 covered the basics. This lesson covers production patterns — what happens when messages fail, how to design namespaces for multi-service systems, and how to monitor message flows in production.

## Namespace and topic hierarchy

```
Format: <namespace>/<service>/<version>/<entity>/<event>
Example: sap/cap/bookshop/orders/v1/OrderCreated
         ├── sap             ← org root
         ├── cap/bookshop    ← application namespace
         ├── orders          ← service/domain
         ├── v1              ← version (never break consumers)
         └── OrderCreated    ← event name
```

Namespace is configured in `em-config.json`:
```json
{
  "emname":    "bookshop-em",
  "namespace": "sap/cap/bookshop",
  "version":   "1.1.0",
  "options":   { "management": true }
}
```

## Queue design patterns

### Fan-out (one topic, multiple consumers)
```
topic: orders/v1/OrderCreated
    ├── queue: fulfillment-consumer    (fulfillment service reads)
    ├── queue: notification-consumer   (notification service reads)
    └── queue: analytics-consumer      (analytics service reads)
```

Each consumer gets **every** message, independently.

### Competing consumers (one queue, multiple workers)
```
topic: orders/v1/ProcessQueue → queue: order-processor
    worker-1 ─┐
    worker-2 ─┤ compete for messages (each message delivered to ONE worker)
    worker-3 ─┘
```

Use for horizontal scaling of a single consumer.

## em-config.json — production setup

```json
{
  "emname":    "bookshop-em",
  "namespace": "sap/cap/bookshop",
  "version":   "1.2.0",
  "options": {
    "management":    true,
    "messagingrest": true
  },
  "rules": {
    "topicRules": {
      "publishFilter":   ["*"],          // producers can publish to any topic
      "subscribeFilter": ["*"]           // consumers can subscribe to any topic
    },
    "queueRules": {
      "publishFilter":   ["*"],
      "subscribeFilter": ["*"]
    }
  },
  "services": [
    {
      "name": "bookshop-q1",
      "type": "queue",
      "subscribeFilter": ["sap/cap/bookshop/+/+/+"]   // wildcard subscription
    }
  ]
}
```

## Dead letter queue (DLQ)

When a consumer repeatedly fails to process a message:

```
topic: orders/v1/OrderCreated
    → queue: fulfillment-consumer
        Message fails 3 times (maxRetries=3)
            → dead-letter-queue: fulfillment-consumer/dlq
```

```js
messaging.on('sap/cap/bookshop/orders/v1/OrderCreated', async (msg) => {
  try {
    await processOrder(msg.data)
    await msg.ack()
  } catch (err) {
    console.error(`[NACK] Order processing failed:`, err.message)
    await msg.nack()   // Message goes back; after maxRetries → DLQ
  }
})
```

## DLQ consumer for monitoring and replaying

```js
// Consume from DLQ to alert and optionally replay
messaging.on('sap/cap/bookshop/orders/v1/OrderCreated/dlq', async (msg) => {
  await alertTeam({
    subject: 'Order processing failed after retries',
    body:    JSON.stringify(msg.data)
  })
  // Log to database for manual review/replay
  await INSERT.into('FailedMessages').entries({
    topic:   msg.headers['x-original-topic'],
    data:    JSON.stringify(msg.data),
    error:   msg.headers['x-original-error'],
    receivedAt: new Date()
  })
  await msg.ack()   // Ack from DLQ — prevents infinite DLQ growth
})
```

## Message headers (CloudEvents)

```js
messaging.on('...', async (msg) => {
  // Standard CloudEvents headers
  console.log(msg.headers['ce-id'])           // message UUID
  console.log(msg.headers['ce-type'])         // event type
  console.log(msg.headers['ce-source'])       // publishing service
  console.log(msg.headers['ce-time'])         // UTC timestamp

  // SAP-specific
  console.log(msg.headers['x-em-timestamp'])  // Event Mesh receipt time
})
```

## Publishing with metadata

```js
await messaging.emit('sap/cap/bookshop/orders/v1/OrderCreated', {
  ID: order.ID, total: order.total
}, {
  headers: {
    'x-correlation-id': req.headers['x-correlation-id'],
    'x-user-id':        req.user.id
  }
})
```

## Monitoring in BTP Cockpit

BTP Cockpit → Instances → Event Mesh → Manage:
- **Messages**: queue size, in-flight, DLQ count
- **Subscriptions**: active consumers, connection state
- **Metrics**: publish/consume rate, latency P95
- **Alerts**: configure max queue depth thresholds

## Hands-on exercise
1. Create two consumer services that subscribe to the same `OrderCreated` topic
2. Publish 5 orders and verify both consumers receive all 5
3. Make one consumer fail on even-numbered orders — verify DLQ fills
4. Write a DLQ consumer that inserts failed messages to a `FailedEvents` table

## Checkpoint ✓
- [ ] Namespaces: `org/app/service/v1/EventName` — include version to avoid breaking changes
- [ ] Fan-out: one topic, multiple queues — each queue gets every message
- [ ] `msg.nack()` retries; after maxRetries the message moves to DLQ
- [ ] Always ack from DLQ (even just to log it) — prevents infinite growth
$md$
WHERE slug = 'cap-59-event-mesh';

-- ── Lesson 60 — SAP Alert Notification Service ────────────────────────────────

UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 60 — SAP Alert Notification Service

## What you'll learn
- What SAP Alert Notification Service (ANS) does
- Sending events from CAP to ANS
- Configuring delivery channels: email, Slack, SAP Fiori, Microsoft Teams
- Condition-based filtering
- Alerting for system events (app crashes, DLQ overflow)

## Why this matters
`console.error` doesn't page the on-call engineer at 3am. ANS connects your CAP app to real notification channels — email, Slack, PagerDuty via webhooks — with filtering and routing so the right people get the right alerts.

## What ANS provides

```
CAP App → ANS → Routing Engine (conditions) → Delivery Channels
                                               ├── Email (SMTP)
                                               ├── Slack webhook
                                               ├── Microsoft Teams
                                               ├── SAP Fiori Launchpad notification
                                               └── Custom webhook
```

## Binding ANS

```yaml
# mta.yaml
resources:
  - name: alert-notification
    type: org.cloudfoundry.managed-service
    parameters:
      service:      alert-notification
      service-plan: standard

modules:
  - name: bookshop-srv
    requires:
      - name: alert-notification
```

## Connecting from CAP

```json
// .cdsrc.json
{
  "requires": {
    "notifications": {
      "[production]": {
        "kind": "alert-notification",
        "vcap": { "label": "alert-notification" }
      },
      "[development]": {
        "kind": "@cap-js/notifications",
        "impl": "@cap-js/notifications/lib/console-logger"  // logs to console in dev
      }
    }
  }
}
```

```bash
npm install @cap-js/notifications
```

## Sending a notification from a handler

```js
const notif = await cds.connect.to('notifications')

this.on('submitOrder', async (req) => {
  const { orderId } = req.data
  const order = await SELECT.one.from('Orders').where({ ID: orderId })

  // Business notification to the buyer
  await notif.notify({
    NotificationTypeKey:     'OrderConfirmed',
    NotificationTypeVersion: '1',
    Priority:                'MEDIUM',
    Properties: [
      { Key: 'orderId',    Value: order.ID   },
      { Key: 'orderTotal', Value: String(order.total) }
    ],
    Recipients: [{ RecipientId: order.buyer_email }]
  })

  return order
})
```

## System alerts from CAP errors

```js
// Global error handler — alert on 5xx errors
this.on('error', async (err, req) => {
  if (err.status >= 500) {
    await notif.notify({
      NotificationTypeKey: 'SystemError',
      Priority:            'HIGH',
      Properties: [
        { Key: 'errorMessage', Value: err.message },
        { Key: 'operation',    Value: `${req.event} ${req.target?.name}` },
        { Key: 'user',         Value: req.user?.id || 'anonymous' }
      ],
      Recipients: [{ RecipientId: 'ops-team@company.com' }]
    })
  }
})
```

## Notification types (defined in ANS admin)

In ANS Cockpit (BTP → Instances → alert-notification → Manage):
1. **Notification Types** → Create:
   - Key: `OrderConfirmed`
   - Version: `1`
   - Template for email subject: "Order {{orderId}} confirmed"
   - Template for email body: "Your order total: {{orderTotal}}"

2. **Actions** → Create:
   - Type: `EMAIL`
   - Email address: buyer's email
   - Condition: `NotificationTypeKey = 'OrderConfirmed'`

## Condition-based routing

```
Conditions in ANS:
  Priority == 'HIGH'                        → PagerDuty webhook
  NotificationTypeKey == 'SystemError'      → Slack #ops-alerts
  NotificationTypeKey == 'OrderConfirmed'   → Email to buyer
  Region == 'EMEA'                          → EMEA support team
```

## Fiori Notification Hub integration

```js
// Fiori notifications appear in the Fiori Shell notification bell
await notif.notify({
  NotificationTypeKey: 'ApprovalRequired',
  Priority:            'HIGH',
  Properties: [
    { Key: 'documentId', Value: req.data.ID },
    { Key: 'amount',     Value: String(req.data.amount) }
  ],
  Recipients:          [{ RecipientId: req.data.approver_email }],
  // NavigationTargetObject: target Fiori app to open on click
  NavigationTargetObject:   'PurchaseOrder',
  NavigationTargetAction:    'approve',
  NavigationTargetParams: [{ Key: 'documentId', Value: req.data.ID }]
})
```

## Hands-on exercise
1. Install `@cap-js/notifications` and configure it for development (console logger)
2. Send a notification when an order is submitted — verify the console output
3. In BTP trial ANS, create a notification type and an email action
4. Deploy and trigger the notification — verify the email arrives

## Checkpoint ✓
- [ ] ANS decouples the notification concern from the CAP handler — no SMTP code in handlers
- [ ] Notification types defined in ANS admin control the template; handler provides the data
- [ ] Condition-based routing in ANS sends different events to different channels
- [ ] `@cap-js/notifications` in dev mode logs to console — no ANS service needed locally
$md$
WHERE slug = 'cap-60-notifications';


-- ── Lesson 61 — S/4HANA Integration via OData ────────────────────────────────

UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 61 — S/4HANA Integration via OData

## What you'll learn
- Importing S/4HANA OData APIs from SAP API Business Hub
- Configuring OAuth2 destination for S/4HANA Cloud
- Delegate pattern vs mashup pattern
- Handling S/4HANA OData V2 quirks
- Error mapping from S/4HANA errors to CAP errors

## Why this matters
S/4HANA is the core ERP for most enterprises on BTP. CAP apps routinely extend S/4HANA — reading master data, creating documents, subscribing to business events. This is the most common real-world integration pattern in the SAP ecosystem.

## Import the API

```bash
# Download from SAP API Business Hub (API Hub)
# https://api.sap.com → search "Business Partner" → Download API Specification → EDMX

cds import ./API_BUSINESS_PARTNER.edmx --as cds
# Creates srv/external/API_BUSINESS_PARTNER.cds
```

## Service projection

```cds
// srv/procurement-service.cds
using { API_BUSINESS_PARTNER as bp } from './external/API_BUSINESS_PARTNER';

service ProcurementService {
  entity Suppliers as projection on bp.A_BusinessPartner {
    key BusinessPartner   as ID,
        BusinessPartnerFullName as name,
        Country           as country,
        to_BusinessPartnerAddress as addresses
  }
}
```

## S/4HANA Cloud destination (BTP Cockpit)

```
Name:              S4HANA_CLOUD
Type:              HTTP
URL:               https://<tenant>.s4hana.ondemand.com
Authentication:    OAuth2ClientCredentials
Token Service URL: https://<tenant>.authentication.eu20.hana.ondemand.com/oauth/token
Client ID:         sb-<service-instance>!<id>
Client Secret:     <communication arrangement secret>
```

Create a **Communication Arrangement** in S/4HANA for the specific API (e.g., SAP_COM_0008 for Business Partner API), then copy the credentials to the destination.

## CAP configuration

```json
// .cdsrc.json
{
  "requires": {
    "API_BUSINESS_PARTNER": {
      "kind":        "odata-v2",
      "model":       "srv/external/API_BUSINESS_PARTNER",
      "[production]": {
        "destination": "S4HANA_CLOUD",
        "path":        "/sap/opu/odata/sap"
      },
      "[development]": {
        "credentials": {
          "url":     "https://sandbox.api.sap.com/s4hanacloud/sap/opu/odata/sap",
          "headers": { "APIKey": "YOUR_DEV_KEY" }
        }
      }
    }
  }
}
```

## Delegate pattern (read-through)

```js
// srv/procurement-service.js
const s4 = await cds.connect.to('API_BUSINESS_PARTNER')

// Delegate all READs on Suppliers to S/4HANA
this.on('READ', 'Suppliers', (req) => s4.run(req.query))
```

CAP translates `$filter`, `$select`, `$expand`, `$top`, `$skip` and sends them to S/4HANA.

## Mashup: local + S/4HANA data

```js
this.on('READ', 'PurchaseOrders', async (req) => {
  // 1. Read local POs
  const orders = await SELECT.from('PurchaseOrders')

  // 2. Deduplicate supplier IDs
  const supplierIds = [...new Set(orders.map(o => o.supplier_ID))]

  // 3. Fetch supplier names from S/4HANA in one call
  const suppliers = await s4.run(
    SELECT.from('A_BusinessPartner')
      .where({ BusinessPartner: { in: supplierIds } })
      .columns('BusinessPartner', 'BusinessPartnerFullName')
  )

  // 4. Merge
  const map = Object.fromEntries(suppliers.map(s => [s.BusinessPartner, s.BusinessPartnerFullName]))
  return orders.map(o => ({ ...o, supplierName: map[o.supplier_ID] ?? 'Unknown' }))
})
```

## S/4HANA OData V2 quirks

| Quirk | Workaround |
|---|---|
| Dates as `/Date(timestamp)/` | CAP converts automatically with `kind: odata-v2` |
| CSRF token required for write | CAP fetches and sends `X-CSRF-Token` automatically |
| `$batch` uses V2 format | CAP handles automatically |
| Error in `d.error` vs `error` | CAP normalises to standard OData error format |
| Association naming (`_to_`) | Use the generated CDS model — it maps names correctly |

## Error handling

```js
this.on('createPurchaseOrder', async (req) => {
  try {
    const result = await s4.run(
      INSERT.into('A_PurchaseOrder').entries(req.data)
    )
    return result
  } catch (err) {
    // S/4HANA errors come back as structured OData errors
    if (err.statusCode === 400) {
      return req.reject(400, `S/4HANA rejected the PO: ${err.message}`)
    }
    if (err.statusCode === 403) {
      return req.reject(403, 'Insufficient authorizations in S/4HANA')
    }
    throw err   // unexpected — rethrow for CAP global error handler
  }
})
```

## Hands-on exercise
1. Download the Business Partner EDMX from SAP API Hub and import it
2. Create a Suppliers projection and delegate READ to S/4HANA sandbox
3. Test: `GET /procurement/Suppliers?$top=5`
4. Add a mashup: local Orders joined with S/4HANA Supplier names

## Checkpoint ✓
- [ ] `cds import ./file.edmx --as cds` generates a CDS model from EDMX
- [ ] `kind: odata-v2` handles OData V2 quirks (dates, CSRF) automatically
- [ ] Delegate with `s4.run(req.query)` — full OData query forwarding
- [ ] Communication Arrangements in S/4HANA grant access; store credentials in BTP Destination
$md$
WHERE slug = 'cap-61-s4hana';

-- ── Lesson 62 — BAPI & RFC via Cloud Connector ───────────────────────────────

UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 62 — BAPI & RFC via Cloud Connector

## What you'll learn
- When to use BAPI/RFC vs OData for S/4HANA
- SAP Cloud SDK JCo client in CAP
- Configuring an RFC destination via Cloud Connector
- Calling a BAPI from a CAP handler
- Error handling for RFC exceptions

## Why this matters
Some critical SAP business logic is only available as BAPIs — not via OData. Payment posting, batch processing, complex material movements — these still route through RFC. Knowing how to call them from CAP keeps you unblocked when the API Hub doesn't have what you need.

## RFC vs OData — when to choose RFC

| Use OData | Use BAPI/RFC |
|---|---|
| Standard CRUD, reporting | Complex business transactions |
| Available on API Hub | Business logic only in ABAP |
| Performance not critical | Atomic multi-step operations |
| New S/4HANA systems | Legacy ECC/S/4 on-prem |
| S/4HANA Cloud (no RFC) | S/4HANA on-prem |

> S/4HANA Cloud Public Edition does **not** support RFC. RFC is for on-prem or private-cloud systems.

## SAP Cloud SDK setup

```bash
npm install @sap-cloud-sdk/connectivity @sap-cloud-sdk/http-client
# For JCo/RFC: add the JCo client library (requires SAP SDK download)
```

## RFC destination configuration

In SCC admin → Access Control → Cloud to On-Premise → Add:
```
Back-end Type:  SAP ABAP System
Protocol:       RFC
Internal Host:  sapgw00.corp.internal
Internal Port:  3300
Virtual Host:   sapgw00-virtual
Virtual Port:   3300
```

In BTP Cockpit → Destinations → New:
```
Name:              SAP_ECC_RFC
Type:              RFC
jco.client.r3name: ECC
jco.client.client: 100
jco.client.lang:   EN
jco.destination.pool_capacity: 5
Authentication:    BasicAuthentication
User:              BAPI_USER
Password:          ****
ProxyType:         OnPremise
```

## Calling a BAPI via SAP Cloud SDK

```js
// srv/legacy-service.js
const { executeHttpRequest } = require('@sap-cloud-sdk/http-client')
const { buildHeadersForDestination } = require('@sap-cloud-sdk/connectivity')

// For BAPIs, use the RFC function module API via SAP Cloud SDK RFC module
// (requires @sap/cloud-sdk-core with JCo support — enterprise license)

this.on('getCustomerCredit', async (req) => {
  const { customerId } = req.data

  // Direct BAPI call via Cloud SDK
  const result = await SoapRfcClient.execute({
    destination:    'SAP_ECC_RFC',
    functionModule: 'BAPI_CUSTOMER_GET_CREDIT',
    importing: {
      KUNNR: customerId.padStart(10, '0')   // ABAP convention: left-pad with zeros
    }
  })

  return {
    creditLimit:  result.EXPORTING.CREDIT_LIMIT,
    creditUsed:   result.EXPORTING.CREDIT_USED,
    currency:     result.EXPORTING.CURRENCY
  }
})
```

## Simpler: BAPI via SAP Gateway (OData wrapper)

The preferred approach on modern systems is to call BAPI via SAP Gateway's OData wrapper:

```
ABAP BAPI → SAP Gateway (OData V2) → BTP Destination → CAP
```

```bash
# In ABAP developer tools, create a Gateway project that wraps the BAPI
# Then consume via cds import / odata-v2 connector (same as Lesson 61)
```

## Error handling for RFC

```js
try {
  const result = await rfcClient.execute({ functionModule: 'BAPI_ORDER_CREATE1', ... })

  // BAPI return messages are in RETURN table (not exceptions)
  const errors = result.TABLES.RETURN?.filter(r => r.TYPE === 'E' || r.TYPE === 'A')
  if (errors?.length > 0) {
    return req.reject(400, errors.map(e => e.MESSAGE).join('; '))
  }

  // Commit the BAPI work (required for state-changing BAPIs)
  await rfcClient.execute({ functionModule: 'BAPI_TRANSACTION_COMMIT' })

  return result

} catch (err) {
  if (err.rfcErrorCode) {
    // RFC-specific errors (connection, auth, etc.)
    console.error('RFC error:', err.rfcErrorCode, err.message)
    return req.reject(502, 'SAP system temporarily unavailable')
  }
  throw err
}
```

## BAPI_TRANSACTION_COMMIT — the gotcha

Most state-changing BAPIs require an explicit commit:
```js
// Step 1: Call the BAPI
await rfcClient.execute({ functionModule: 'BAPI_SALESORDER_CREATE', ... })

// Step 2: Check RETURN table for errors
// Step 3: Only commit if no errors
await rfcClient.execute({ functionModule: 'BAPI_TRANSACTION_COMMIT', importing: { WAIT: 'X' } })
```

Never skip the `BAPI_TRANSACTION_COMMIT` — the order won't be created.

## Hands-on exercise
1. Create an RFC destination in Cloud Connector pointing to a local ABAP system or sandbox
2. Implement a `getSystemInfo` action that calls `RFC_SYSTEM_INFO`
3. Parse the result and return the system ID and release
4. Test error handling by temporarily breaking the RFC destination

## Checkpoint ✓
- [ ] RFC requires on-prem or private-cloud S/4HANA — S/4HANA Cloud Public Edition uses OData only
- [ ] Cloud Connector exposes RFC via a virtual host with Protocol=RFC
- [ ] BAPIs return errors in a RETURN table — check `TYPE = 'E'/'A'` rows
- [ ] State-changing BAPIs require `BAPI_TRANSACTION_COMMIT` after successful execution
$md$
WHERE slug = 'cap-62-bapi-rfc';


-- ─────────────────────────────────────────────────────────────────────────────
-- Episode 63 — SAP Build Process Automation
-- ─────────────────────────────────────────────────────────────────────────────
UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 63 — SAP Build Process Automation

## What you'll learn
- What SAP Build Process Automation (SBPA) is and how it fits in the BTP ecosystem
- How to trigger a workflow instance from a CAP service using REST
- How to model approval steps and user tasks in the Workflow Editor
- How to receive callbacks from completed workflow instances
- How to handle errors, timeouts, and escalations in long-running processes

## Why this matters
Business processes rarely fit inside a single synchronous request — approvals, multi-step sign-offs, SLA escalations all need orchestration. SAP Build Process Automation provides a low-code workflow engine on BTP. Connecting it to your CAP backend lets you trigger approvals from data changes, receive decisions back, and audit every step without building a custom state machine.

## How SAP Build Process Automation works

SBPA is the successor to SAP Workflow Management. It provides:

| Component | Role |
|---|---|
| Process Editor | Low-code drag-and-drop flow designer |
| Workflow Runtime | Executes instances; stores audit trail |
| My Inbox (Fiori) | Task UI for human approvers |
| Rest API | Trigger instances, fetch status, send decisions |
| BTP Service | `workflow` service plan on Cloud Foundry |

The key resource is a **Process Definition** (like a class) from which you create **Instances** at runtime.

## Setting up the service binding

```bash
# Create a Workflow service instance (standard plan)
cf create-service workflow standard my-workflow

# Create a service key for local testing
cf create-service-key my-workflow my-workflow-key

# View credentials
cf service-key my-workflow my-workflow-key
```

The service key contains:
```json
{
  "endpoints": {
    "workflow_rest_url": "https://api.workflow.cfapps.eu10.hana.ondemand.com/workflow/rest/v1"
  },
  "uaa": {
    "clientid": "sb-my-workflow!t1234",
    "clientsecret": "...",
    "url": "https://my-subaccount.authentication.eu10.hana.ondemand.com"
  }
}
```

Add to `cds.requires` in `.cdsrc.json`:
```json
{
  "requires": {
    "WorkflowAPI": {
      "kind": "rest",
      "credentials": {
        "destination": "MY_WORKFLOW_DESTINATION"
      }
    }
  }
}
```

Or bind the service key directly for local development:
```bash
cds bind workflow --to my-workflow:my-workflow-key
```

## Triggering a workflow instance from CAP

```javascript
// srv/purchase-order-service.js
const cds = require('@sap/cds');

module.exports = class PurchaseOrderService extends cds.ApplicationService {
  async init() {
    const { PurchaseOrders } = this.entities;

    this.after('CREATE', PurchaseOrders, async (po, req) => {
      if (po.totalAmount > 10000) {
        await this._triggerApprovalWorkflow(po, req);
      }
    });

    await super.init();
  }

  async _triggerApprovalWorkflow(po, req) {
    const workflow = await cds.connect.to('WorkflowAPI');

    const instance = await workflow.post('/v1/workflow-instances', {
      definitionId: 'po-approval-process',   // process definition ID in SBPA
      context: {
        purchaseOrderId: po.ID,
        amount:          po.totalAmount,
        requestedBy:     req.user.id,
        requestedByName: req.user.name,
        currency:        po.currency
      }
    });

    // Persist the workflow instance ID so we can query status later
    const db = await cds.connect.to('db');
    await db.update(PurchaseOrders, po.ID)
      .with({ workflowInstanceId: instance.id, status: 'PendingApproval' });
  }
};
```

## Receiving the approval callback

SBPA can call a webhook (your CAP endpoint) when the workflow completes. Define an OData action on your service:

```cds
// srv/purchase-order-service.cds
service PurchaseOrderService {
  entity PurchaseOrders as projection on db.PurchaseOrders;

  // Called by SBPA when approval workflow completes
  action workflowCallback(
    instanceId  : String,
    decision    : String,   // 'Approved' | 'Rejected'
    comment     : String,
    approvedBy  : String
  ) returns String;
}
```

```javascript
this.on('workflowCallback', async req => {
  const { instanceId, decision, comment, approvedBy } = req.data;

  const db = await cds.connect.to('db');
  const po  = await db.read(PurchaseOrders).where({ workflowInstanceId: instanceId });

  if (!po) return req.reject(404, `PO not found for workflow instance ${instanceId}`);

  if (decision === 'Approved') {
    await db.update(PurchaseOrders, po.ID)
      .with({ status: 'Approved', approvedBy, approvedAt: new Date() });
    await this._sendToBackend(po);
  } else {
    await db.update(PurchaseOrders, po.ID)
      .with({ status: 'Rejected', rejectionComment: comment });
  }

  return 'Callback processed';
});
```

Secure the callback endpoint — SBPA will include an OAuth token from its own XSUAA tenant:
```cds
@requires: 'WorkflowSystem'   // a dedicated scope for the SBPA service principal
action workflowCallback(...) returns String;
```

## Querying workflow instance status

```javascript
async getApprovalStatus(req) {
  const { poId } = req.data;
  const db       = await cds.connect.to('db');
  const workflow = await cds.connect.to('WorkflowAPI');

  const po = await db.read(PurchaseOrders, poId);
  if (!po.workflowInstanceId) return { status: 'NoWorkflow' };

  const instance = await workflow.get(
    `/v1/workflow-instances/${po.workflowInstanceId}`
  );

  return {
    status:    instance.status,           // RUNNING | COMPLETED | ERRONEOUS
    startedAt: instance.startedAt,
    subject:   instance.subject
  };
}
```

## Handling errors and escalations

Design defensive workflows:
- Set **task deadlines** in the Process Editor (e.g., 48 h) with auto-escalation to a manager group
- Use a **boundary error event** on each task to catch technical failures
- Log the SBPA instance ID immediately so you can query `/v1/workflow-instances/{id}/execution-logs`

```javascript
// Poll for stuck instances (run as a scheduled job)
const stuck = await workflow.get('/v1/workflow-instances?status=RUNNING&startedBefore=2d');
for (const inst of stuck.value) {
  logger.warn(`Workflow ${inst.id} has been running for >2 days`);
}
```

## Common mistakes

| Mistake | Fix |
|---|---|
| Storing workflow credentials in code | Use BTP Destination Service |
| Calling SBPA synchronously in a `CREATE` handler | Move to `AFTER` to avoid blocking the DB commit |
| Not persisting the instance ID | You lose the ability to correlate callbacks |
| Hardcoding process definition ID | Put it in an environment variable / feature flag |
| Forgetting BAPI_TRANSACTION_COMMIT equivalent | Commit your CAP changes before calling SBPA |

## Checkpoint ✓

You can trigger a workflow instance from a CAP `AFTER CREATE` handler, store the returned instance ID, and handle the approval callback via an `@requires`-protected OData action. You know how to query instance status and where to look for execution logs when a workflow gets stuck.
$md$
WHERE slug = 'cap-63-workflow';

-- ─────────────────────────────────────────────────────────────────────────────
-- Episode 64 — SAP Object Store Service
-- ─────────────────────────────────────────────────────────────────────────────
UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 64 — SAP Object Store Service

## What you'll learn
- What SAP Object Store Service is and when to use it instead of storing binary data in HANA
- How to bind the service and obtain credentials for S3-compatible operations
- How to upload, download, and delete objects from CAP using `@sap/objectstore-client`
- How to model attachments in CDS and return download URLs securely
- How to handle large files without blocking the Node.js event loop

## Why this matters
CAP's built-in `@Core.MediaType` support writes binary data directly into the database — fine for small attachments but a serious problem at scale. SAP Object Store Service provides S3-compatible blob storage on BTP (backed by AWS S3, Azure Blob, or GCS depending on your landscape). Storing files there keeps your HANA footprint small, enables direct browser uploads without routing through your service, and gives you CDN-friendly URLs.

## Service plans and binding

```bash
# Create an Object Store instance (s3-standard plan on AWS landscapes)
cf create-service objectstore s3-standard my-objectstore

# Bind to your app
cf bind-service my-cap-app my-objectstore

# Or add to MTA descriptor
resources:
  - name: my-objectstore
    type: org.cloudfoundry.managed-service
    parameters:
      service: objectstore
      service-plan: s3-standard
```

Credentials structure after binding:
```json
{
  "bucket": "my-bucket-abc123",
  "region": "eu-central-1",
  "access_key_id": "AKI...",
  "secret_access_key": "...",
  "host": "s3.amazonaws.com",
  "uri": "s3://my-bucket-abc123"
}
```

## Installing the client library

```bash
npm install @sap/objectstore-client
```

The library abstracts over S3, Azure Blob, and GCS using the same API.

## CDS model for attachments

```cds
// db/schema.cds
entity Documents {
  key ID          : UUID;
      name        : String(255);
      mimeType    : String(100);
      storageKey  : String(500);  // object key in Object Store
      sizeBytes   : Integer64;
      uploadedAt  : Timestamp;
      uploadedBy  : String(100);
}

service DocumentService @(path:'/documents') {
  entity Documents as projection on db.Documents
    excluding { storageKey };  // never expose storage key to clients

  action upload(name: String, mimeType: String, content: LargeBinary): UUID;
  function download(documentId: UUID): LargeBinary;
  action  deleteDoc(documentId: UUID): Boolean;
}
```

## Uploading files

```javascript
// srv/document-service.js
const cds      = require('@sap/cds');
const OSClient = require('@sap/objectstore-client');
const { v4: uuid } = require('uuid');

let osClient;

async function getOSClient() {
  if (osClient) return osClient;
  const vcapServices = JSON.parse(process.env.VCAP_SERVICES || '{}');
  const creds = vcapServices.objectstore?.[0]?.credentials;
  if (!creds) throw new Error('Object Store not bound');
  osClient = new OSClient(creds);
  return osClient;
}

module.exports = class DocumentService extends cds.ApplicationService {
  async init() {
    this.on('upload', async req => {
      const { name, mimeType, content } = req.data;
      const os  = await getOSClient();

      // Generate a unique storage key (folder/uuid/filename)
      const storageKey = `documents/${uuid()}/${name}`;

      // Upload the binary content
      await os.upload({
        objectName: storageKey,
        data:       Buffer.isBuffer(content) ? content : Buffer.from(content, 'base64'),
        mimeType
      });

      // Persist metadata in DB
      const db  = await cds.connect.to('db');
      const doc = await db.insert(this.entities.Documents).entries({
        ID:         uuid(),
        name,
        mimeType,
        storageKey,
        sizeBytes:  content.length,
        uploadedAt: new Date(),
        uploadedBy: req.user.id
      });

      return doc.ID;
    });

    this.on('download', async req => {
      const { documentId } = req.data;
      const db  = await cds.connect.to('db');
      const doc = await db.read(this.entities.Documents).where({ ID: documentId });

      if (!doc) return req.reject(404, 'Document not found');

      const os   = await getOSClient();
      const data = await os.download({ objectName: doc.storageKey });

      // Return as base64 for OData binary response
      return data.toString('base64');
    });

    this.on('deleteDoc', async req => {
      const { documentId } = req.data;
      const db  = await cds.connect.to('db');
      const doc = await db.read(this.entities.Documents).where({ ID: documentId });

      if (!doc) return req.reject(404, 'Document not found');

      const os = await getOSClient();
      await os.delete({ objectName: doc.storageKey });
      await db.delete(this.entities.Documents).where({ ID: documentId });

      return true;
    });

    await super.init();
  }
};
```

## Generating pre-signed download URLs

For large files, avoid routing the binary through your CAP service. Instead, generate a pre-signed URL that the browser can download directly from Object Store:

```javascript
this.on('getDownloadUrl', async req => {
  const { documentId } = req.data;
  const db  = await cds.connect.to('db');
  const doc = await db.read(this.entities.Documents).where({ ID: documentId });

  const os  = await getOSClient();

  // Pre-signed URL valid for 15 minutes
  const url = await os.getSignedUrl({
    objectName: doc.storageKey,
    expiresIn:  900   // seconds
  });

  return url;
});
```

The client calls `GET /documents/getDownloadUrl(documentId='...')` and receives a temporary URL — no large binary traffic through your service tier.

## Handling multipart / streaming uploads

For files > a few MB, avoid loading the whole file into memory:

```javascript
// Use Node.js stream API
const stream = require('stream');

this.on('uploadStream', async req => {
  const os    = await getOSClient();
  const input = req._.req; // raw IncomingMessage (HTTP stream)

  const storageKey = `documents/${uuid()}/upload`;
  await os.uploadStream({ objectName: storageKey, stream: input });
  // ...persist metadata
});
```

Wire this to a dedicated `@Core.MediaType` endpoint or a custom route registered in `server.js`.

## Common mistakes

| Mistake | Fix |
|---|---|
| Storing the storage key in the OData response | Exclude `storageKey` from the projection — return only the document ID |
| Loading entire file into memory for large uploads | Use streaming upload |
| Not deleting from Object Store on entity delete | Always implement a `deleteDoc` handler that calls `os.delete()` |
| Hardcoding bucket name | Read from VCAP_SERVICES credentials |
| Not scoping access | Add `@requires` on upload/download/delete actions |

## Checkpoint ✓

You can bind SAP Object Store, upload binary attachments with metadata stored in HANA, generate pre-signed URLs for direct downloads, and delete objects in sync with entity deletes. You know why you exclude the storage key from OData projections and how streaming avoids memory pressure on large files.
$md$
WHERE slug = 'cap-64-object-store';


-- ─────────────────────────────────────────────────────────────────────────────
-- Episode 65 — SAP Job Scheduling Service
-- ─────────────────────────────────────────────────────────────────────────────
UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 65 — SAP Job Scheduling Service

## What you'll learn
- What SAP Job Scheduling Service (JSS) does and why cron expressions alone are not enough
- How to bind JSS and register job definitions from your CAP service
- How to implement a job endpoint that JSS calls on schedule
- How to handle retries, timeouts, and failures in scheduled jobs
- How to monitor job run history in the BTP cockpit

## Why this matters
Running background tasks with `setInterval()` inside a Node.js process works locally but breaks in Cloud Foundry the moment your app scales to multiple instances — every instance fires the same job. SAP Job Scheduling Service solves this: it calls your HTTP endpoint on a schedule, handles retries and SLA monitoring, and shows run history in the cockpit. It is the standard BTP approach to reliable recurring jobs.

## How JSS works

JSS is a **scheduler as a service**. You register jobs — each job is an HTTP endpoint on your app plus a cron or recurring schedule. JSS calls your endpoint when the job fires, passing a `JobID` and `ScheduleID` in the body. Your endpoint does the work and returns `200 OK` or an error; JSS logs the result and retries on failure.

```
BTP Job Scheduling Service
       │ POST /jobs/run/nightly-rollup
       ▼
  Your CAP service endpoint
       │ do work
       │ return 200 OK
       ▼
JSS records success / failure, retries up to N times
```

## Binding the service

```bash
cf create-service jobscheduler standard my-jobscheduler
cf bind-service my-cap-app my-jobscheduler
```

MTA descriptor:
```yaml
resources:
  - name: my-jobscheduler
    type: org.cloudfoundry.managed-service
    parameters:
      service: jobscheduler
      service-plan: standard
```

## Registering a job programmatically

JSS exposes a REST API for managing jobs. Register jobs on application startup:

```javascript
// srv/jobs/job-registry.js
const cds = require('@sap/cds');

module.exports = async function registerJobs() {
  const jssCredentials = getJSSCredentials();
  const token          = await getJSSToken(jssCredentials);

  const baseUrl = jssCredentials.endpoints.scheduler_rest_url;

  // Check if job already exists
  const existing = await fetch(`${baseUrl}/scheduler/jobs?name=nightly-rollup`, {
    headers: { Authorization: `Bearer ${token}` }
  }).then(r => r.json());

  if (existing.total > 0) {
    console.log('[Jobs] nightly-rollup already registered');
    return;
  }

  // Register the job
  await fetch(`${baseUrl}/scheduler/jobs`, {
    method:  'POST',
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      name:        'nightly-rollup',
      description: 'Nightly aggregation of daily metrics',
      action:      `${process.env.APP_URL}/jobs/run/nightly-rollup`,
      active:      true,
      httpMethod:  'POST',
      schedules: [{
        cron:        '0 2 * * *',  // 02:00 UTC every day
        active:      true,
        description: 'Nightly at 02:00 UTC'
      }]
    })
  });

  console.log('[Jobs] nightly-rollup registered');
};

function getJSSCredentials() {
  const vcap = JSON.parse(process.env.VCAP_SERVICES || '{}');
  return vcap.jobscheduler?.[0]?.credentials;
}

async function getJSSToken(creds) {
  const res = await fetch(`${creds.uaa.url}/oauth/token`, {
    method:  'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type:    'client_credentials',
      client_id:     creds.uaa.clientid,
      client_secret: creds.uaa.clientsecret
    })
  });
  return (await res.json()).access_token;
}
```

Call `registerJobs()` from `server.js` after the app starts:
```javascript
// srv/server.js
const cds = require('@sap/cds');
cds.on('served', async () => {
  const { registerJobs } = require('./jobs/job-registry');
  await registerJobs();
});
```

## Implementing the job endpoint

```javascript
// srv/jobs/nightly-rollup.js  — registered as a custom express route
module.exports = function (app) {
  app.post('/jobs/run/nightly-rollup', verifyJSSRequest, async (req, res) => {
    const { JobID, ScheduleID, RunID } = req.body;
    const logger = cds.log('jobs');

    logger.info(`[nightly-rollup] Starting — RunID: ${RunID}`);

    try {
      const db = await cds.connect.to('db');

      // Example: aggregate yesterday's orders
      const yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);
      const dateStr = yesterday.toISOString().slice(0, 10);

      await db.run(`
        INSERT INTO DailyMetrics (date, totalOrders, totalRevenue)
        SELECT '${dateStr}', COUNT(*), SUM(amount)
        FROM Orders
        WHERE DATE(createdAt) = '${dateStr}'
        ON CONFLICT (date) DO UPDATE SET
          totalOrders   = EXCLUDED.totalOrders,
          totalRevenue  = EXCLUDED.totalRevenue
      `);

      logger.info(`[nightly-rollup] Done — RunID: ${RunID}`);
      res.status(200).json({ message: 'OK', runId: RunID });

    } catch (err) {
      logger.error(`[nightly-rollup] Failed — RunID: ${RunID}`, err);
      res.status(500).json({ error: err.message });   // JSS will retry
    }
  });
};

// Verify the request comes from JSS (check the Authorization header)
function verifyJSSRequest(req, res, next) {
  const auth = req.headers.authorization;
  if (!auth?.startsWith('Bearer ')) return res.status(401).send('Unauthorized');
  // In production: verify JWT signature against JSS XSUAA instance
  next();
}
```

Register the route in `server.js`:
```javascript
cds.on('bootstrap', app => {
  require('./jobs/nightly-rollup')(app);
});
```

## Monitoring job runs

In the BTP Cockpit navigate to **Job Scheduling Service → your instance → Jobs**. Each job shows:
- Last run timestamp and status
- Run history (up to 30 days)
- Retry count per run
- Response body from your endpoint

You can also query the JSS API:
```bash
GET /scheduler/jobs/{jobId}/runs?page=1&results=20
```

## Common mistakes

| Mistake | Fix |
|---|---|
| Using `setInterval()` for production jobs | Use JSS — setInterval fires on every CF instance |
| Not verifying the JSS JWT | Anyone can hit your `/jobs/run/*` endpoint |
| Returning 200 before the work is done | Do the work synchronously in the handler; return 200 only on success |
| Not idempotent job handlers | JSS retries on failure — ensure re-running the same job is safe |
| Hardcoding the APP_URL | Use `process.env.APP_URL` which CF sets from the application route |

## Checkpoint ✓

You can bind JSS, register jobs programmatically on app startup, implement a secure job endpoint that returns 200 on success and 500 to trigger retries, and monitor run history in the cockpit. You understand why `setInterval()` breaks on multi-instance CF deployments.
$md$
WHERE slug = 'cap-65-job-scheduling';

-- ─────────────────────────────────────────────────────────────────────────────
-- Episode 66 — SAP Application Logging Service
-- ─────────────────────────────────────────────────────────────────────────────
UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 66 — SAP Application Logging Service

## What you'll learn
- What SAP Application Logging Service (ALS) provides beyond `console.log`
- How to bind ALS and configure structured JSON logging in CAP
- How to use `@sap/logging` to emit structured log entries with correlation IDs
- How to search and filter logs in the Kibana dashboard in BTP
- How to set up alerting on error-rate thresholds

## Why this matters
`console.log` writes to stdout. On Cloud Foundry you can read stdout with `cf logs`, but logs disappear when the app restarts and you cannot search across instances. SAP Application Logging Service ships every log line to an Elasticsearch cluster with a Kibana UI. Structured JSON logs let you filter by tenant, user, request ID, or error level — turning a flood of text into queryable operational intelligence.

## Binding the service

```bash
cf create-service application-logs standard my-app-logs
cf bind-service my-cap-app my-app-logs
```

MTA:
```yaml
resources:
  - name: my-app-logs
    type: org.cloudfoundry.managed-service
    parameters:
      service: application-logs
      service-plan: standard
```

Once bound, the `@sap/logging` library auto-detects the binding and configures the transport — you do not need to supply credentials in code.

## Installing and configuring `@sap/logging`

```bash
npm install @sap/logging
```

```javascript
// srv/server.js
const logging = require('@sap/logging');
const cds     = require('@sap/cds');

cds.on('bootstrap', app => {
  // Attach the logging middleware — adds correlation ID to every request
  app.use(logging.middleware({ app }));
});
```

## Using the logger in handlers

```javascript
// srv/purchase-order-service.js
const cds    = require('@sap/cds');
const logging = require('@sap/logging');

module.exports = class PurchaseOrderService extends cds.ApplicationService {
  async init() {
    const { PurchaseOrders } = this.entities;

    this.before('CREATE', PurchaseOrders, async req => {
      // Get a logger scoped to this request (carries correlation ID automatically)
      const logger = logging.createLogger({ layer: 'purchase-order-service' });

      logger.info('Creating purchase order', {
        user:        req.user.id,
        supplier:    req.data.supplierId,
        totalAmount: req.data.totalAmount
      });

      if (req.data.totalAmount > 1_000_000) {
        logger.warn('Very large purchase order', {
          amount:   req.data.totalAmount,
          currency: req.data.currency
        });
      }
    });

    this.on('error', (err, req) => {
      const logger = logging.createLogger({ layer: 'purchase-order-service' });
      logger.error('Unhandled error in PurchaseOrderService', {
        error:   err.message,
        stack:   err.stack,
        user:    req.user?.id,
        path:    req.path
      });
    });

    await super.init();
  }
};
```

## Log levels

| Level | Method | When to use |
|---|---|---|
| DEBUG | `logger.debug()` | Verbose diagnostic — disabled in production |
| INFO | `logger.info()` | Normal operations — request received, entity created |
| WARNING | `logger.warn()` | Unexpected but recoverable — large transaction, slow query |
| ERROR | `logger.error()` | Caught errors that were handled — validation failure |
| FATAL | `logger.fatal()` | Unrecoverable errors — service cannot start |

Set the minimum level via env var:
```bash
# In manifest.yml
env:
  SAP_LOG_LEVEL: warn    # only warn, error, fatal in production
```

## Correlation IDs

Every HTTP request that goes through the `logging.middleware()` gets a correlation ID — either from the `X-CorrelationID` header (if the caller is another BTP service) or auto-generated. The ID is injected into every log line from that request, so you can trace a single user action across multiple log entries:

```json
{
  "level": "INFO",
  "msg": "Creating purchase order",
  "correlationId": "abc-123-def",
  "layer": "purchase-order-service",
  "user": "P0012345",
  "totalAmount": 45000
}
```

In Kibana, filter `correlationId: "abc-123-def"` to see every log from that one request.

## Searching in Kibana

Navigate to: BTP Cockpit → **Services → Application Logging → Open Dashboard (Kibana)**

Useful Kibana queries:
```
# All errors in the last hour
level: ERROR AND @timestamp:[now-1h TO now]

# Specific user's actions
user: "P0012345"

# Slow requests (custom field you logged)
durationMs: [500 TO *]

# By correlation ID
correlationId: "abc-123-def"
```

## Setting up log-based alerts

In Kibana create a **Watcher** (Elasticsearch alerting):
1. Go to **Stack Management → Watcher → Create Threshold Alert**
2. Index: `cap-app-logs-*`
3. Condition: `COUNT(level:ERROR) > 10` within 5 minutes
4. Action: send email / call webhook

Or use SAP Alert Notification Service (Episode 60) to route alerts raised from your CAP error handlers.

## Common mistakes

| Mistake | Fix |
|---|---|
| `console.log` in production | Use `@sap/logging` — `console.log` is not structured |
| Not attaching `logging.middleware()` | Correlation IDs will not be populated |
| Logging sensitive data (passwords, tokens) | Scrub PII before logging — GDPR applies |
| DEBUG level in production | Set `SAP_LOG_LEVEL=warn` in production manifest |
| Logging inside a tight loop | Log at entry/exit points, not per-iteration |

## Checkpoint ✓

You can bind SAP Application Logging Service, configure `@sap/logging` middleware, emit structured log entries with correlation IDs from CAP handlers, and query logs in Kibana by level, user, or correlation ID. You know how to set an appropriate log level for production.
$md$
WHERE slug = 'cap-66-logging';


-- ─────────────────────────────────────────────────────────────────────────────
-- Episode 67 — SAP Feature Flags Service
-- ─────────────────────────────────────────────────────────────────────────────
UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 67 — SAP Feature Flags Service

## What you'll learn
- What SAP Feature Flags Service is and when to use feature flags in a CAP app
- How to bind the service and read flag values from Node.js at runtime
- How to gate CAP handlers and UI routes behind feature flags
- How to use percentage rollouts and user-segment targeting
- How to manage flag lifecycle: create, test, roll out, retire

## Why this matters
Feature flags decouple code deployment from feature activation. You can merge incomplete features behind a flag, roll them out to internal users first, increase the percentage incrementally, and roll back instantly without a new deployment. On BTP, SAP Feature Flags Service stores the flag configuration centrally so all app instances see the same state without a restart.

## How Feature Flags Service works

The service stores **feature flag definitions** (name + current state) in a central store. Your application queries the REST API (or uses the Node.js client) to get the current value at request time. The service supports:

| Flag type | Description |
|---|---|
| Boolean | Simple on/off |
| Number | Numeric variants (A/B test weights) |
| String | Named strategy variants |

Each flag supports **targeting rules**: user ID lists, tenant IDs, attribute-based matchers, and percentage-based rollouts.

## Binding the service

```bash
cf create-service feature-flags standard my-feature-flags
cf bind-service my-cap-app my-feature-flags
```

Install the client:
```bash
npm install @sap/feature-flags-node-sdk
```

## Initialising the client

```javascript
// srv/feature-flags.js
const FeatureFlags = require('@sap/feature-flags-node-sdk');

let client;

module.exports.getFF = function () {
  if (!client) {
    const vcap = JSON.parse(process.env.VCAP_SERVICES || '{}');
    const creds = vcap['feature-flags']?.[0]?.credentials;
    if (!creds) throw new Error('Feature Flags Service not bound');

    client = new FeatureFlags({
      instanceUrl: creds.uri,
      clientId:    creds.username,
      clientSecret: creds.password
    });
  }
  return client;
};
```

## Reading a flag value

```javascript
const { getFF } = require('./feature-flags');

// Boolean flag — is the new approval UI enabled?
async function isApprovalV2Enabled(userId, tenantId) {
  const ff = getFF();
  return ff.getBooleanVariation('approval-workflow-v2', false, {
    identifier: userId,
    attributes: { tenant: tenantId }
  });
}

// String flag — which email template to use?
async function getEmailTemplate(userId) {
  const ff = getFF();
  const variant = await ff.getStringVariation('email-template', 'classic', {
    identifier: userId
  });
  return variant;   // 'classic' | 'modern' | 'minimal'
}
```

`getBooleanVariation(flagName, defaultValue, context)` — returns the default if the service is unavailable. Always provide a sensible default so a flag service outage degrades gracefully.

## Gating CAP handlers behind flags

```javascript
// srv/approval-service.js
module.exports = class ApprovalService extends cds.ApplicationService {
  async init() {
    const { Approvals } = this.entities;

    this.on('submitForApproval', async req => {
      const ff      = require('./feature-flags').getFF();
      const useV2   = await ff.getBooleanVariation(
        'approval-workflow-v2', false,
        { identifier: req.user.id }
      );

      if (useV2) {
        return this._submitV2(req);
      } else {
        return this._submitV1(req);
      }
    });

    await super.init();
  }
};
```

## Gating front-end routes

Expose a lightweight `/feature-flags` endpoint from your CAP service:

```cds
service FeatureFlagService @(path:'/feature-flags') {
  @readonly function evaluate(flag: String) returns Boolean;
}
```

```javascript
this.on('evaluate', async req => {
  const { flag }  = req.data;
  const ff        = require('./feature-flags').getFF();
  const ALLOWED   = ['approval-workflow-v2', 'arena-season-2'];

  if (!ALLOWED.includes(flag)) return req.reject(400, `Unknown flag: ${flag}`);

  return ff.getBooleanVariation(flag, false, {
    identifier: req.user.id,
    attributes: { tenant: req.tenant }
  });
});
```

React side:
```javascript
const v2 = await fetch('/feature-flags/evaluate(flag=\'approval-workflow-v2\')').then(r => r.json());
if (v2.value) { /* render new UI */ }
```

## Managing flags in the BTP Cockpit

1. Navigate to: **Services → Feature Flags → your instance → Dashboard**
2. Create a flag: name + type + default value
3. Add **targeting rules** (user segment, tenant list, or percentage rollout)
4. Toggle the flag on — no deployment required

**Percentage rollout workflow:**
- Start at 0% (off for everyone)
- Set to 5% → monitor error rates in Kibana (Episode 66)
- Increase to 25%, 50%, 100% over days or weeks
- Once stable at 100%, remove the flag from code and retire it

## Flag lifecycle hygiene

| Stage | Action |
|---|---|
| Development | Create flag; default `false`; gate the new code path |
| Internal test | Enable for specific user list |
| Beta | 10% percentage rollout |
| GA | 100% rollout |
| Retired | Remove flag check from code; delete flag in cockpit |

Stale flags are tech debt — schedule a review every quarter.

## Common mistakes

| Mistake | Fix |
|---|---|
| Calling `getBooleanVariation` in a hot loop without caching | Cache the result per request, not per call |
| No default value | Provide sensible defaults — service outages must not break the app |
| Exposing all flags via the evaluate endpoint | Allowlist flags that the frontend is permitted to query |
| Never retiring flags | Flags accumulate; stale ones make the code unreadable |
| Different flag names in dev/prod | Use the same flag name everywhere; control the value per environment |

## Checkpoint ✓

You can bind Feature Flags Service, read boolean and string flag values at runtime, gate CAP handlers and UI routes behind flags, use percentage rollouts to reduce risk, and manage the flag lifecycle from development to retirement.
$md$
WHERE slug = 'cap-67-feature-flags';

-- ─────────────────────────────────────────────────────────────────────────────
-- Episode 68 — HTML5 App Repository & App Router
-- ─────────────────────────────────────────────────────────────────────────────
UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 68 — HTML5 App Repository & App Router

## What you'll learn
- What the HTML5 App Repository and SAP AppRouter do in a BTP landscape
- How to package a Vite/React frontend into the HTML5 App Repository
- How to configure AppRouter to route `/api/*` to your CAP service and `/*` to the SPA
- How to propagate user identity from AppRouter to CAP using JWT
- How to configure custom domains, CORS, and logout

## Why this matters
When you deploy a full-stack BTP app you need more than just a backend. Users must authenticate before reaching the UI, the UI bundle must be served efficiently, and the backend must trust the caller's identity. The HTML5 App Repository stores the static frontend assets and the AppRouter acts as the single entry point: it handles XSUAA login, serves the SPA, and forwards API calls to your CAP service with the user's JWT attached.

## Architecture overview

```
Browser
  │
  ▼
AppRouter  (your-app.cfapps.eu10.hana.ondemand.com)
  │   ├─ GET /  → HTML5 App Repository (serves index.html + JS/CSS)
  │   └─ /api/* → CAP service (forwards with Authorization: Bearer <JWT>)
  │
XSUAA (login redirect, token exchange)
```

The AppRouter is a pre-built Node.js app (`@sap/approuter`) that you configure, not code.

## Packaging the frontend for HTML5 App Repository

```bash
# Build your Vite app
cd frontend && npm run build   # outputs dist/

# Create the xs-app.json inside dist/
```

`frontend/dist/xs-app.json`:
```json
{
  "welcomeFile": "/index.html",
  "authenticationMethod": "route",
  "routes": [
    {
      "source": "^/api/(.*)$",
      "target": "/api/$1",
      "destination": "cap-backend",
      "authenticationType": "xsuaa"
    },
    {
      "source": "^(.*)$",
      "target": "$1",
      "service": "html5-apps-repo-rt",
      "authenticationType": "xsuaa"
    }
  ]
}
```

## AppRouter configuration (`xs-app.json` at root)

The root `xs-app.json` (in the AppRouter package, not the SPA) defines top-level routing:

```json
{
  "authenticationMethod": "route",
  "logout": {
    "logoutEndpoint": "/do/logout",
    "logoutPage": "/"
  },
  "routes": [
    {
      "source": "^/api/(.*)$",
      "target": "/api/$1",
      "destination": "cap-backend",
      "csrfProtection": true,
      "authenticationType": "xsuaa"
    },
    {
      "source": "^(.*)$",
      "target": "$1",
      "service": "html5-apps-repo-rt",
      "authenticationType": "xsuaa"
    }
  ]
}
```

The `cap-backend` destination is defined in the BTP Destination Service:
```
URL:           https://my-cap-app.cfapps.eu10.hana.ondemand.com
ProxyType:     Internet
Authentication: OAuth2UserTokenExchange
TokenServiceInstanceName: my-xsuaa
```

`OAuth2UserTokenExchange` exchanges the AppRouter user token for a token scoped to the CAP service — this is how user identity is propagated.

## AppRouter `package.json`

```json
{
  "name": "approuter",
  "version": "1.0.0",
  "dependencies": {
    "@sap/approuter": "^14"
  },
  "scripts": {
    "start": "node node_modules/@sap/approuter/approuter.js"
  }
}
```

## MTA descriptor wiring

```yaml
modules:
  - name: my-app-approuter
    type: approuter.nodejs
    path: approuter
    requires:
      - name: my-xsuaa
      - name: my-html5-runtime
      - name: my-destination-service
    parameters:
      disk-quota: 256M
      memory: 256M

  - name: my-app-ui-deployer
    type: com.sap.application.content
    path: frontend/dist
    requires:
      - name: my-html5-repo-host
        parameters:
          content-target: true
    build-parameters:
      build-result: dist
      requires:
        - name: frontend
          artifacts:
            - dist.zip
          target-path: resources/

resources:
  - name: my-xsuaa
    type: org.cloudfoundry.managed-service
    parameters:
      service: xsuaa
      service-plan: application
      path: ./xs-security.json

  - name: my-html5-repo-host
    type: org.cloudfoundry.managed-service
    parameters:
      service: html5-apps-repo
      service-plan: app-host

  - name: my-html5-runtime
    type: org.cloudfoundry.managed-service
    parameters:
      service: html5-apps-repo
      service-plan: app-runtime

  - name: my-destination-service
    type: org.cloudfoundry.managed-service
    parameters:
      service: destination
      service-plan: lite
```

## Verifying identity in CAP

When AppRouter forwards a request with `OAuth2UserTokenExchange`, CAP receives a JWT where `req.user.id` is the authenticated user's XSUAA subject. No extra code needed — CAP's `@sap/cds-security` verifies the token automatically.

```javascript
this.before('*', req => {
  console.log('Authenticated user:', req.user.id);    // P0012345
  console.log('Tenant:', req.tenant);                  // my-subaccount
});
```

## CORS for local development

During local development, the React dev server (`:5173`) talks directly to the CAP server (`:4004`) without AppRouter. Configure CORS in CAP:

```javascript
// srv/server.js
cds.on('bootstrap', app => {
  if (process.env.NODE_ENV !== 'production') {
    app.use(require('cors')({ origin: 'http://localhost:5173', credentials: true }));
  }
});
```

In production, AppRouter handles same-origin routing — CORS headers are not needed.

## Common mistakes

| Mistake | Fix |
|---|---|
| Forgetting `xs-app.json` in the SPA bundle | The HTML5 App Repository requires this file at the bundle root |
| Using `NoAuthentication` on API routes | Always use `xsuaa` for API routes — otherwise JWT is not forwarded |
| Hardcoding backend URL in React | Use relative paths (`/api/...`) — AppRouter routes them to CAP |
| Not enabling CSRF protection | Set `"csrfProtection": true` on mutation routes |
| Exposing AppRouter credentials to the browser | Never — AppRouter handles auth server-side |

## Checkpoint ✓

You can package a React SPA for the HTML5 App Repository, configure AppRouter to serve the SPA and proxy API calls to CAP with the user JWT, wire the MTA descriptor to bind XSUAA, HTML5 Repo, and Destination Service, and propagate user identity end-to-end from browser to CAP handler.
$md$
WHERE slug = 'cap-68-html5-repo';

