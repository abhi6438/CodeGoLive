-- ============================================================
-- SAP CAP Course — Module 3: Service Development
-- Run AFTER sap_cap_seed.sql
-- Lessons: cap-23 through cap-34 (12 lessons)
-- ============================================================

-- ── Lesson 23 — Custom Service Handlers ──────────────────────────────────────

UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 23 — Custom Service Handlers

## What you'll learn
- How CAP's generic provider works — and when it's not enough
- Registering handlers with `this.on()`, `this.before()`, `this.after()`
- The difference between replacing and extending default behaviour
- Calling `next()` to chain handlers
- Where to put handler code in a CAP project

## Why this matters
The generic service provider covers 90 % of CRUD with zero code. The remaining 10 % — business rules, side-effects, external system calls — needs custom handlers. Knowing *exactly* how to hook in without breaking the generic behaviour is the core skill of CAP service development.

## The request lifecycle (quick review)
```
[HTTP / OData request]
       ↓
  BEFORE phase   ← validate, enrich input
       ↓
  ON phase       ← execute the operation  ← generic handler lives here
       ↓
  AFTER phase    ← enrich output, side-effects
       ↓
[HTTP / OData response]
```

Every phase can have multiple registered handlers; they run in registration order.

## Registering your first handler

```js
// srv/cat-service.js
const cds = require('@sap/cds')

module.exports = class CatalogService extends cds.ApplicationService {
  async init () {

    // this.on  → replaces the default handler for an event
    this.on('READ', 'Books', async (req) => {
      const books = await SELECT.from('Books')
      return books
    })

    // IMPORTANT: always call super.init() LAST
    await super.init()
  }
}
```

> **Rule**: `await super.init()` wires up the generic handlers. Call it **after** your registrations so your handlers run first, or the generic one fires before yours for ON events.

## Accessing request data

```js
this.on('CREATE', 'Orders', async (req) => {
  const { data } = req          // payload from the request body
  const { user }  = req         // authenticated user (req.user.id, req.user.roles)
  const { query } = req         // CQL query object
  const tenant    = req.tenant  // tenant ID in multitenant apps

  console.log('Creating order for', user.id, 'data:', data)

  // delegate to generic handler after custom logic
  return this.emit('CREATE', 'Orders', req)   // or: return next()
})
```

## Returning data

| Return value | Effect |
|---|---|
| An array / object | Sent directly as the response |
| `undefined` / nothing | Continues to the next handler |
| `req.reject(...)` | Throws an HTTP error and stops the chain |
| `next()` | Passes control to the next registered handler |

## Handler scope patterns

```js
// All events on an entity
this.on(['CREATE','UPDATE'], 'Books', handler)

// Any entity (wildcard)
this.on('CREATE', '*', handler)

// Bound action defined in CDS
this.on('submitOrder', 'Orders', async (req) => { /* ... */ })

// Unbound action
this.on('pingSystem', async (req) => { /* ... */ })
```

## next() — chaining handlers

```js
this.on('READ', 'Books', async (req, next) => {
  console.log('Before generic READ')
  const result = await next()   // run the next handler (generic in this case)
  console.log('After generic READ, got', result.length, 'rows')
  return result
})
```

## Project structure for handlers

```
srv/
├── cat-service.cds          ← service definition
├── cat-service.js           ← main handlers (auto-loaded by name match)
└── lib/
    ├── orders-handler.js    ← imported manually if needed
    └── validation.js
```

CAP auto-loads `srv/foo-service.js` when `srv/foo-service.cds` defines `FooService`. For complex services, split handlers across files and import them in `init()`.

```js
// srv/cat-service.js
const { registerOrderHandlers } = require('./lib/orders-handler')

module.exports = class CatalogService extends cds.ApplicationService {
  async init () {
    registerOrderHandlers(this)   // pass `this` = the service instance
    await super.init()
  }
}
```

## Common mistakes

| Mistake | Symptom | Fix |
|---|---|---|
| Forgetting `await super.init()` | Generic handlers don't run | Always call it |
| Calling `super.init()` before registrations | Your handler runs after generic | Move registrations before `super.init()` |
| Returning `undefined` from `this.on()` | Request hangs | Return data or call `next()` |
| `this.on('read', ...)` (lowercase) | Handler silently ignored | Use uppercase: `'READ'` |

## Hands-on exercise

1. Scaffold `cds init bookshop && cd bookshop && cds add sample`
2. Create `srv/cat-service.js` extending `cds.ApplicationService`
3. Add a `this.before('CREATE', 'Orders', ...)` that sets `req.data.createdBy = req.user.id`
4. Add a `this.after('READ', 'Books', ...)` that adds `inStock: true` to books with `stock > 0`
5. Run `cds watch` and verify with a REST client

## Checkpoint ✓
- [ ] You can register `before`, `on`, and `after` handlers
- [ ] You understand when to call `next()` vs return data
- [ ] `await super.init()` is always your last init line
- [ ] You can split handlers across files and import them
$md$
WHERE slug = 'cap-23-custom-handlers';

-- ── Lesson 24 — Before / After / On Hooks in Depth ───────────────────────────

UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 24 — Before / After / On Hooks in Depth

## What you'll learn
- Precise semantics of each handler phase
- What `req` carries in each phase
- Cross-cutting concerns: logging, validation, audit
- Handler order and short-circuiting
- The `this.reject()` vs `req.reject()` distinction

## Why this matters
CAP's three-phase model maps directly to enterprise patterns: input validation (BEFORE), business logic (ON), and post-processing / side-effects (AFTER). Knowing which hook to use prevents subtle bugs where you validate data that's already been saved, or enrich a response that's already been sent.

## Phase semantics

### BEFORE
```
Purpose:   Validate or enrich the incoming request BEFORE execution.
req.data:  The payload as sent by the client (mutable — you can change it here).
req.query: The CQL query built from the OData URL.
Effect:    Call req.reject() to abort. Modify req.data to change what's saved.
```

```js
this.before('CREATE', 'Books', (req) => {
  if (!req.data.title) return req.reject(400, 'Title is required')
  req.data.createdAt = new Date().toISOString()   // enrich before save
})
```

### ON
```
Purpose:   Execute the operation (read from DB, write to DB, call external).
req.data:  Same as BEFORE; the generic handler uses it to build SQL.
Return:    Your return value becomes the response. Call next() to use generic.
```

```js
this.on('READ', 'Analytics', async (req) => {
  // Completely replace with custom logic
  return db.run(`SELECT department, SUM(salary) AS total FROM Employees GROUP BY department`)
})
```

### AFTER
```
Purpose:   Enrich or log the result AFTER execution.
data:      The result data (second argument). Mutable for READ results.
req.data:  The original request payload (still available).
Return:    Ignored for READ — mutate the array/object in place instead.
```

```js
this.after('READ', 'Books', (books, req) => {
  books.forEach(b => {
    b.priceFormatted = `€ ${b.price.toFixed(2)}`
    b.inStock = b.stock > 0
  })
  // No return needed — mutating the array is sufficient
})
```

## Execution order for multiple handlers

```js
// Handlers fire in registration order within each phase
this.before('READ', 'Books', authCheck)        // fires first
this.before('READ', 'Books', tenantFilter)     // fires second

this.on('READ', 'Books', next => next())       // defers to generic (fires first)
// generic READ handler wired by super.init()   // fires second (inside generic slot)

this.after('READ', 'Books', addComputedFields) // fires first
this.after('READ', 'Books', logAccess)         // fires second
```

## Cross-cutting patterns

### Audit logging (AFTER)
```js
this.after(['CREATE','UPDATE','DELETE'], '*', (data, req) => {
  auditLog.write({
    entity:    req.target.name,
    operation: req.event,
    user:      req.user.id,
    key:       req.data?.ID,
    at:        new Date()
  })
})
```

### Request enrichment (BEFORE)
```js
this.before('*', '*', (req) => {
  req.data = req.data || {}
  req.data._requestId = crypto.randomUUID()   // attach trace ID
})
```

### Response transformation (AFTER)
```js
this.after('READ', 'Products', (products) => {
  products.forEach(p => {
    delete p._internal_costBasis   // strip internal fields
  })
})
```

## Short-circuiting the chain

```js
this.before('DELETE', 'Orders', async (req) => {
  const order = await SELECT.one.from('Orders').where({ ID: req.data.ID })
  if (order.status === 'SHIPPED') {
    return req.reject(409, `Order ${req.data.ID} already shipped — cannot delete`)
    // Returning req.reject() stops ALL subsequent handlers (before, on, after)
  }
})
```

## `this.reject()` vs `req.reject()`

| | `req.reject(status, msg)` | `this.reject(status, msg)` |
|---|---|---|
| Returns | A rejected promise (throw-like) | Same |
| Use in | Handler function body | Outside handler (rare) |
| Best practice | Use `req.reject()` inside handlers | Avoid outside |

## Testing hooks in isolation

```js
// test/books.test.js
const cds = require('@sap/cds/lib')

describe('Books BEFORE handler', () => {
  const { GET, POST } = cds.test('.').in(__dirname + '/..')

  it('rejects create without title', async () => {
    const res = await POST('/catalog/Books', { stock: 5 })
    expect(res.status).toBe(400)
  })
})
```

## Hands-on exercise
1. Add `this.before('UPDATE', 'Books', ...)` — reject if `req.data.price < 0`
2. Add `this.after('READ', 'Books', ...)` — add `discountedPrice = price * 0.9` to all books
3. Add `this.after(['CREATE','UPDATE'], 'Books', ...)` — log the operation to console
4. Verify the order: put `console.log` in each hook and confirm sequence

## Checkpoint ✓
- [ ] BEFORE mutates `req.data`; AFTER mutates the result array
- [ ] Multiple handlers in the same phase fire in registration order
- [ ] `req.reject()` inside BEFORE stops the entire chain
- [ ] You can use wildcard `'*'` for cross-cutting concerns
$md$
WHERE slug = 'cap-24-before-after';

-- ── Lesson 25 — Actions & Functions ─────────────────────────────────────────

UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 25 — Actions & Functions

## What you'll learn
- Difference between OData Actions (state-changing) and Functions (read-only)
- Bound vs unbound variants
- Defining them in CDS, implementing in JS, calling from HTTP and Fiori
- Returning complex types and collections

## Why this matters
CRUD covers entity lifecycle; actions and functions cover *business operations* — approve an order, calculate a quote, trigger a workflow. They're the OData equivalent of RPC calls and are first-class citizens in CAP.

## CDS definitions

### Unbound action and function
```cds
// srv/orders-service.cds
service OrdersService {
  entity Orders as projection on my.Orders;

  // Action: modifies state, uses POST
  action  submitOrder (orderId : UUID)                   returns Order;

  // Function: read-only, uses GET
  function getOrderTotal (orderId : UUID)                returns Decimal;
  function topProducts   (limit   : Integer default 10) returns array of Product;
}
```

### Bound action and function
```cds
service OrdersService {
  entity Orders as projection on my.Orders {
    // bound to Orders entity
    action  cancel ()                  returns Orders;
    action  clone  (newTitle : String) returns Orders;
    function daysUntilDelivery ()      returns Integer;
  }
}
```

## Implementing actions & functions

### Unbound action
```js
// srv/orders-service.js
this.on('submitOrder', async (req) => {
  const { orderId } = req.data           // named parameters from CDS

  const order = await SELECT.one.from('Orders').where({ ID: orderId })
  if (!order) return req.reject(404, `Order ${orderId} not found`)
  if (order.status !== 'DRAFT') return req.reject(409, 'Order already submitted')

  await UPDATE('Orders').set({ status: 'SUBMITTED', submittedAt: new Date() })
                        .where({ ID: orderId })

  return SELECT.one.from('Orders').where({ ID: orderId })  // return updated order
})
```

### Bound action
```js
// Bound actions receive the bound entity key in req.params
this.on('cancel', 'Orders', async (req) => {
  const [{ ID }] = req.params    // key of the bound entity

  await UPDATE('Orders').set({ status: 'CANCELLED' }).where({ ID })
  return SELECT.one.from('Orders').where({ ID })
})
```

### Function (read-only)
```js
this.on('getOrderTotal', async (req) => {
  const { orderId } = req.data
  const items = await SELECT.from('OrderItems').where({ order_ID: orderId })
  return items.reduce((sum, i) => sum + i.price * i.quantity, 0)
})
```

## HTTP calls

```http
### Unbound action (POST, JSON body with named params)
POST http://localhost:4004/orders/submitOrder
Content-Type: application/json

{ "orderId": "c0f0b8a0-..." }

### Bound action (POST to entity instance)
POST http://localhost:4004/orders/Orders(c0f0b8a0-...)/cancel

### Unbound function (GET with query parameters)
GET http://localhost:4004/orders/getOrderTotal(orderId='c0f0b8a0-...')

### Function returning collection
GET http://localhost:4004/orders/topProducts(limit=5)
```

## Returning complex types

```cds
type OrderSummary {
  ID         : UUID;
  total      : Decimal;
  itemCount  : Integer;
  canCancel  : Boolean;
}

service OrdersService {
  function getOrderSummary (orderId : UUID) returns OrderSummary;
}
```

```js
this.on('getOrderSummary', async (req) => {
  const { orderId } = req.data
  const order = await SELECT.one.from('Orders').where({ ID: orderId })
  const items = await SELECT.from('OrderItems').where({ order_ID: orderId })

  return {
    ID:        order.ID,
    total:     items.reduce((s, i) => s + i.price * i.qty, 0),
    itemCount: items.length,
    canCancel: order.status === 'SUBMITTED'
  }
})
```

## Fiori UI5 call

```js
// In a Fiori controller
const oModel = this.getView().getModel()
oModel.callFunction('/submitOrder', {
  method: 'POST',
  urlParameters: { orderId: sOrderId },
  success: (data) => MessageToast.show('Order submitted!'),
  error:   (err)  => MessageBox.error(err.message)
})
```

## Common mistakes

| Mistake | Symptom | Fix |
|---|---|---|
| Using GET for an action | 405 Method Not Allowed | Actions always POST |
| Returning plain value from function that declares complex type | Serialization error | Return an object matching the CDS type |
| Forgetting `req.params` for bound actions | `ID` is undefined | Use `const [{ ID }] = req.params` |
| No `returns` clause in CDS | CAP infers void return | Add `returns <type>` for typed responses |

## Hands-on exercise
1. Add `action addToCart (bookId: UUID, quantity: Integer) returns Cart;` to your service
2. Implement it: find the cart for `req.user.id`, upsert the item, return the updated cart
3. Add `function cartTotal () returns Decimal;` and implement it
4. Test both with REST client: POST for action, GET for function

## Checkpoint ✓
- [ ] Actions use POST; functions use GET
- [ ] Bound actions receive entity key in `req.params`
- [ ] Both are defined in CDS and implemented in `this.on()`
- [ ] Complex return types defined in CDS serialize correctly
$md$
WHERE slug = 'cap-25-actions';

-- ── Lesson 26 — Error Handling & Custom Errors ───────────────────────────────

UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 26 — Error Handling & Custom Errors

## What you'll learn
- CAP error model and how it maps to OData and HTTP
- `req.reject()` vs `req.error()` — abort vs accumulate
- Structured errors with target field
- Custom error messages from i18n
- Global error handler pattern
- Testing error responses

## Why this matters
A consistent error API is a quality signal. Fiori apps expect `@odata.error` formatted responses; REST clients expect structured JSON. CAP gives you primitives to produce both from one place, with target-field-level errors that map directly to Fiori input field highlights.

## Error primitives

### `req.reject()` — abort immediately
```js
this.before('CREATE', 'Books', (req) => {
  if (!req.data.title)
    return req.reject(400, 'Book must have a title')
  // chain stops here; nothing else runs
})
```

### `req.error()` — accumulate, then abort
```js
this.before('CREATE', 'Books', (req) => {
  if (!req.data.title)
    req.error(400, 'Title is required', 'title')      // target = field name
  if (req.data.price < 0)
    req.error(400, 'Price must be positive', 'price')
  // Both errors collected; CAP auto-rejects with all messages after BEFORE phase
})
```

## Structured error with target

```js
req.error({
  code:    'INVALID_PRICE',
  message: 'Price must be between {0} and {1}',
  args:    [0, 9999],
  target:  'price',           // maps to Fiori field highlighting
  status:  400
})
```

### OData error response
```json
{
  "error": {
    "code":    "INVALID_PRICE",
    "message": "Price must be between 0 and 9999",
    "target":  "price",
    "@Common.numericSeverity": 4,
    "details": []
  }
}
```

## Error status codes

| Status | Use case |
|---|---|
| 400 | Bad request / validation failure |
| 401 | Not authenticated |
| 403 | Authenticated but not authorized |
| 404 | Entity not found |
| 409 | Conflict (e.g., already processed) |
| 422 | Semantic error (valid syntax, invalid business rule) |
| 500 | Unexpected server error |

## Throwing errors in async code

```js
this.on('submitOrder', async (req) => {
  const order = await SELECT.one.from('Orders').where({ ID: req.data.orderId })
  if (!order) return req.reject(404, `Order not found: ${req.data.orderId}`)

  try {
    await externalService.notify(order)
  } catch (e) {
    // Log internally, return friendly message to client
    console.error('Notification failed:', e)
    return req.reject(502, 'Failed to notify external service. Please retry.')
  }
})
```

## i18n error messages

```properties
# _i18n/messages.properties
ORDER_NOT_FOUND=Order {0} not found
PRICE_INVALID=Price must be between {0} and {1}
```

```js
req.reject(404, 'ORDER_NOT_FOUND', [req.data.orderId])
//              ↑ i18n key            ↑ substitution args
```

CAP resolves the key from `_i18n/messages_<locale>.properties` based on `Accept-Language`.

## Global error handler

```js
// Catch all unhandled errors across the service
this.on('error', (err, req) => {
  console.error(`[${req.event}] ${req.target?.name}:`, err.message)
  // Optionally transform error before it's sent
  if (err.code === 'SQLITE_CONSTRAINT') {
    err.status  = 409
    err.message = 'A duplicate entry already exists'
  }
})
```

## Error format — REST vs OData

CAP automatically formats errors based on the `Accept` header:

```
Accept: application/json        → OData error format
Accept: application/json;odata  → same
Content-Type: application/json  → same
```

```json
// OData format (Fiori-compatible)
{
  "error": {
    "code":    "400",
    "message": "Title is required",
    "target":  "title"
  }
}
```

## Testing errors

```js
const { POST } = cds.test('.').in(__dirname + '/..')

it('rejects book without title', async () => {
  const { status, data } = await POST('/catalog/Books', { price: 9.99 })
  expect(status).toBe(400)
  expect(data.error.message).toMatch(/title/i)
  expect(data.error.target).toBe('title')
})

it('returns 404 for missing order', async () => {
  const { status } = await POST('/orders/submitOrder', { orderId: 'non-existent' })
  expect(status).toBe(404)
})
```

## Hands-on exercise
1. Add validation in a BEFORE handler: reject if price > 10000, with target `'price'`
2. Add multi-field validation with `req.error()`: validate both title and price in one pass
3. Add an i18n message key for the error; test with `Accept-Language: de`
4. Add a global `this.on('error', ...)` handler that logs all errors with timestamp

## Checkpoint ✓
- [ ] `req.reject()` stops the chain; `req.error()` accumulates
- [ ] Target field in errors maps to Fiori input highlighting
- [ ] i18n keys in `req.reject()` are resolved from `_i18n/messages.properties`
- [ ] Global error handler catches all unhandled errors
$md$
WHERE slug = 'cap-26-error-handling';

-- ── Lesson 27 — Emitting & Handling CDS Events ───────────────────────────────

UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 27 — Emitting & Handling CDS Events

## What you'll learn
- The difference between OData operations and CDS events
- In-process event emission with `cds.emit()` and `this.emit()`
- Cross-service event subscriptions
- Event-driven design patterns in CAP
- How in-process events differ from async messaging (Event Mesh)

## Why this matters
Event-driven architecture decouples services: an order service doesn't need to know about the notification service, the audit service, or the loyalty service. CDS events let you build this within a single CAP deployment, cleanly and without message brokers for in-process cases.

## Events in CDS

```cds
// srv/orders-service.cds
service OrdersService {
  entity Orders as projection on my.Orders;

  event OrderSubmitted {
    ID     : UUID;
    amount : Decimal;
    buyer  : String;
  }

  event OrderCancelled {
    ID     : UUID;
    reason : String;
  }
}
```

Events are declared in the service that *emits* them. Other services subscribe to them.

## Emitting an event

```js
// srv/orders-service.js
this.on('submitOrder', async (req) => {
  const { orderId } = req.data

  await UPDATE('Orders').set({ status: 'SUBMITTED' }).where({ ID: orderId })
  const order = await SELECT.one.from('Orders').where({ ID: orderId })

  // Emit the event — all in-process subscribers receive it
  await this.emit('OrderSubmitted', {
    ID:     order.ID,
    amount: order.total,
    buyer:  req.user.id
  })

  return order
})
```

## Subscribing in the same service

```js
this.on('OrderSubmitted', async (msg) => {
  console.log('Order submitted:', msg.data.ID, 'by', msg.data.buyer)
  // msg.data carries the event payload
  // This runs in the same transaction if emitted from within a handler
})
```

## Cross-service subscription

```js
// srv/notification-service.js
const cds = require('@sap/cds')

module.exports = class NotificationService extends cds.ApplicationService {
  async init () {
    // Subscribe to events from another service
    const orders = await cds.connect.to('OrdersService')
    orders.on('OrderSubmitted', async (msg) => {
      await this.sendEmail({
        to:      msg.data.buyer,
        subject: `Order ${msg.data.ID} confirmed`,
        body:    `Total: €${msg.data.amount}`
      })
    })

    await super.init()
  }
}
```

## Event data access in handlers

```js
this.on('OrderSubmitted', async (msg) => {
  const { ID, amount, buyer } = msg.data    // typed payload from CDS event def
  const tenant  = msg.tenant                // for multitenant apps
  const headers = msg.headers               // optional headers
})
```

## Transactional vs fire-and-forget

By default, in-process events are **synchronous within the request transaction** — the event handler runs before the outer transaction commits.

```js
// Both the UPDATE and the audit log are in the same DB transaction
await UPDATE('Orders').set({ status: 'SUBMITTED' }).where({ ID })
await this.emit('OrderSubmitted', { ID, amount })   // audit runs here, same tx
```

For fire-and-forget (run after commit):
```js
cds.context = cds.context || {}
cds.spawn({ tenant: req.tenant }, async () => {
  await this.emit('OrderSubmitted', { ID, amount })
})
```

## Event-driven vs direct service call

| In-process event | Direct service call |
|---|---|
| Emitter doesn't know subscribers | Caller explicitly invokes callee |
| Loose coupling | Tight coupling |
| Multiple subscribers possible | One callee |
| Order of execution not guaranteed | Sequential |
| Use for: notifications, audit, side-effects | Use for: business logic that must complete |

## Design pattern: domain events

```js
// After any business operation, emit a domain event
this.after('CREATE', 'Orders',  (order, req) => this.emit('OrderCreated',   { ...order, actor: req.user.id }))
this.after('UPDATE', 'Orders',  (order, req) => this.emit('OrderUpdated',   { ...order, actor: req.user.id }))
this.on('cancelOrder', 'Orders', async (req) => {
  // ... cancel logic ...
  await this.emit('OrderCancelled', { ID, reason: req.data.reason })
})
```

## Hands-on exercise
1. Declare `event BookPurchased { bookId: UUID; quantity: Integer; buyer: String; }` in your service
2. Emit it from an `purchaseBook` action after updating stock
3. Add a subscriber that logs the event to a `PurchaseLog` entity
4. Add a cross-service subscriber in a separate `AnalyticsService` that counts purchases

## Checkpoint ✓
- [ ] Events declared in CDS with typed payload
- [ ] `this.emit()` fires in-process; all in-process subscribers receive it
- [ ] Cross-service subscription via `cds.connect.to('ServiceName').on('EventName', ...)`
- [ ] In-process events run in the same transaction unless you use `cds.spawn()`
$md$
WHERE slug = 'cap-27-events';

-- ── Lesson 28 — Async Messaging with SAP Event Mesh ─────────────────────────

UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 28 — Async Messaging with SAP Event Mesh

## What you'll learn
- When to use SAP Event Mesh vs in-process CDS events
- Configuring the `@sap/cds-messaging` plugin
- Publishing messages from a CAP service
- Consuming messages reliably (at-least-once delivery)
- Dead letter queues and error handling
- Local mock messaging for development

## Why this matters
In-process events work within one deployment. Event Mesh crosses deployment boundaries — a CAP app in one BTP subaccount can trigger a workflow in another, or react to S/4HANA business events. Event Mesh provides guaranteed delivery, durability, and fan-out across heterogeneous systems.

## Concepts

```
Producer CAP app  ──publish──►  Event Mesh (topic)  ──subscribe──►  Consumer CAP app
                                     │
                                     └──subscribe──►  Another consumer (e.g., workflow)
```

- **Topic**: logical channel, e.g. `sap/cap/bookshop/orders/v1/OrderCreated`
- **Queue**: durable subscriber — messages survive consumer restart
- **Topic subscription**: binds a queue to a topic pattern

## Installation

```bash
npm install @sap/xb-msg-amqp-v100 @sap/cds-messaging
```

## CDS declaration

```cds
// srv/bookshop-service.cds
service BookshopService {
  entity Orders as projection on my.Orders;

  event OrderCreated : {
    ID     : UUID;
    total  : Decimal;
    buyer  : String;
  }
}
```

## .cdsrc.json configuration

```json
{
  "requires": {
    "messaging": {
      "[production]": {
        "kind": "enterprise-messaging",
        "format": "cloudevents"
      },
      "[development]": {
        "kind": "file-based-messaging"
      }
    }
  }
}
```

- `enterprise-messaging` → real SAP Event Mesh
- `file-based-messaging` → local mock (writes events to `.mocks/` folder)

## Binding Event Mesh in BTP

```yaml
# mta.yaml (service resource)
- name: event-mesh
  type: org.cloudfoundry.managed-service
  parameters:
    service:      enterprise-messaging
    service-plan: default
    path:         ./em-config.json
```

```json
// em-config.json
{
  "emname":     "bookshop-em",
  "namespace":  "sap/cap/bookshop",
  "version":    "1.1.0",
  "options":    { "management": true, "messagingrest": true },
  "rules":      { "topicRules": { "publishFilter": ["*"], "subscribeFilter": ["*"] } }
}
```

## Publishing a message

```js
// srv/bookshop-service.js
const messaging = await cds.connect.to('messaging')

this.after('CREATE', 'Orders', async (order) => {
  await messaging.emit('sap/cap/bookshop/orders/v1/OrderCreated', {
    ID:    order.ID,
    total: order.total,
    buyer: order.buyer_ID
  })
})
```

## Consuming messages

```js
// srv/fulfillment-service.js
module.exports = class FulfillmentService extends cds.ApplicationService {
  async init () {
    const messaging = await cds.connect.to('messaging')

    messaging.on('sap/cap/bookshop/orders/v1/OrderCreated', async (msg) => {
      const { ID, total, buyer } = msg.data

      await INSERT.into('FulfillmentJobs').entries({
        order_ID: ID,
        status:   'PENDING',
        assignedAt: new Date()
      })
    })

    await super.init()
  }
}
```

## Error handling — dead letter queue

```js
messaging.on('sap/cap/bookshop/orders/v1/OrderCreated', async (msg) => {
  try {
    await processOrder(msg.data)
    await msg.ack()          // confirm successful processing
  } catch (err) {
    console.error('Processing failed:', err)
    await msg.nack()         // reject → message goes to DLQ after max retries
  }
})
```

## CloudEvents format

SAP Event Mesh uses the CloudEvents spec:

```json
{
  "specversion": "1.0",
  "type":        "sap.cap.bookshop.orders.v1.OrderCreated",
  "source":      "/sap/cap/bookshop",
  "id":          "abc-123",
  "time":        "2026-09-17T10:00:00Z",
  "data":        { "ID": "...", "total": 49.99, "buyer": "alice" }
}
```

CAP wraps/unwraps this automatically when `"format": "cloudevents"`.

## Local development

```bash
# Messages are written to .mocks/OrderCreated.json
# Consumer reads from that file — no Event Mesh service needed locally
cds watch
```

## Hands-on exercise
1. Add `"messaging"` to `.cdsrc.json` with `file-based-messaging` for dev
2. Emit an `OrderCreated` event after successful order creation
3. Create a `NotificationService` that subscribes and logs the message
4. Run `cds watch` and verify the `.mocks/` files are created

## Checkpoint ✓
- [ ] Event Mesh vs in-process events: use Event Mesh for cross-deployment
- [ ] `file-based-messaging` mocks locally; `enterprise-messaging` in production
- [ ] `msg.ack()` / `msg.nack()` controls at-least-once delivery
- [ ] CloudEvents format is auto-wrapped by CAP
$md$
WHERE slug = 'cap-28-messaging';


-- ── Lesson 29 — Fiori UI Annotations in CAP ──────────────────────────────────

UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 29 — Fiori UI Annotations in CAP

## What you'll learn
- The annotation vocabulary that drives Fiori List Report and Object Page
- `@UI.LineItem`, `@UI.HeaderInfo`, `@UI.Facets`, `@UI.FieldGroup`
- Value helps with `@Common.ValueList`
- Selection fields and field groups for Object Page
- Separating annotations into a dedicated file

## Why this matters
Fiori Elements generates the full UI from annotations — no custom JavaScript needed for standard layouts. Getting these annotations right means the UI builds itself. Getting them wrong means hours debugging why your Object Page has no fields.

## The Fiori Elements pattern

```
CDS Entity  →  Service Projection  →  Annotations  →  Fiori Elements renders UI
```

Annotations live in the service layer (or a separate `.cds` file), not on the DB entity.

## List Report annotations

```cds
// srv/annotations.cds
using OrdersService as svc from './orders-service';

annotate svc.Orders with @(
  UI.LineItem: [
    { Value: ID,          Label: 'Order ID'   },
    { Value: buyer.name,  Label: 'Buyer'      },
    { Value: status,      Label: 'Status'     },
    { Value: total,       Label: 'Total'      },
    { Value: createdAt,   Label: 'Created'    },
    {
      $Type:  'UI.DataFieldForAction',
      Action: 'OrdersService.submitOrder',
      Label:  'Submit'
    }
  ],
  UI.SelectionFields: [ status, createdAt, buyer_ID ],
  UI.PresentationVariant: {
    SortOrder: [{ Property: createdAt, Descending: true }]
  }
);
```

## Object Page — HeaderInfo

```cds
annotate svc.Orders with @(
  UI.HeaderInfo: {
    TypeName:       'Order',
    TypeNamePlural: 'Orders',
    Title:          { Value: ID },
    Description:    { Value: buyer.name }
  }
);
```

## Object Page — Facets & FieldGroups

```cds
annotate svc.Orders with @(
  UI.Facets: [
    {
      $Type:  'UI.ReferenceFacet',
      ID:     'GeneralInfo',
      Label:  'General Information',
      Target: '@UI.FieldGroup#GeneralInfo'
    },
    {
      $Type:  'UI.ReferenceFacet',
      ID:     'Items',
      Label:  'Order Items',
      Target: 'items/@UI.LineItem'
    }
  ],
  UI.FieldGroup#GeneralInfo: {
    Data: [
      { Value: status,     Label: 'Status'       },
      { Value: total,      Label: 'Total Amount'  },
      { Value: notes,      Label: 'Notes'         },
      { Value: createdAt,  Label: 'Created At'    }
    ]
  }
);
```

## Value help (dropdown)

```cds
// Enum-based value help from a Currencies entity
annotate svc.Orders with {
  currency @(
    Common.ValueList: {
      CollectionPath: 'Currencies',
      Parameters: [
        { $Type: 'Common.ValueListParameterOut', LocalDataProperty: currency_code, ValueListProperty: 'code' },
        { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'name' }
      ]
    },
    Common.ValueListWithFixedValues: true
  )
}
```

## Status criticality (colour coding)

```cds
annotate svc.Orders with {
  statusCriticality @UI.Hidden;   // used internally, not shown as column
}

annotate svc.Orders with @(
  UI.LineItem: [
    {
      Value:       status,
      Criticality: statusCriticality   // 1=grey, 2=red, 3=orange, 4=green
    }
  ]
);
```

```js
// Computed in AFTER handler
this.after('READ', 'Orders', (orders) => {
  orders.forEach(o => {
    o.statusCriticality = { DRAFT: 0, SUBMITTED: 2, SHIPPED: 3, DELIVERED: 4 }[o.status] ?? 0
  })
})
```

## Navigation properties (associations in LineItem)

```cds
annotate svc.OrderItems with @(
  UI.LineItem: [
    { Value: book.title,   Label: 'Book'      },
    { Value: quantity,     Label: 'Quantity'  },
    { Value: price,        Label: 'Price'     }
  ]
);
```

## Separate annotation file pattern

```
srv/
├── orders-service.cds        ← service definition
├── orders-service.js         ← handlers
└── fiori/
    ├── orders-annotations.cds  ← Fiori annotations
    └── catalog-annotations.cds
```

```cds
// srv/fiori/orders-annotations.cds
using OrdersService as svc from '../orders-service';
// all @UI, @Common, @Communication annotations here
```

## Hands-on exercise
1. Annotate your Books service with `@UI.LineItem` (title, author, price, stock)
2. Add `@UI.HeaderInfo` with title=title, description=author_name
3. Add an Object Page with two facets: General Info (price, stock) and Description
4. Add a value help for `genre` from a `Genres` entity
5. Open the Fiori preview in `cds watch` and verify the layout

## Checkpoint ✓
- [ ] `@UI.LineItem` drives the list report columns
- [ ] `@UI.Facets` + `@UI.FieldGroup` build the Object Page sections
- [ ] Value help uses `@Common.ValueList` with `CollectionPath`
- [ ] Criticality integer (0–4) maps to Fiori colour indicators
$md$
WHERE slug = 'cap-29-fiori-annotations';

-- ── Lesson 30 — CAP Query API (CQL & cds.ql) ─────────────────────────────────

UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 30 — CAP Query API (CQL & cds.ql)

## What you'll learn
- CDS Query Language (CQL) — the SQL superset used by CAP
- Fluent API: `SELECT`, `INSERT`, `UPDATE`, `DELETE` objects
- How queries translate to SQL
- Chaining clauses for complex queries
- Running queries with `db.run()` vs `cds.run()`

## Why this matters
CAP's query API is what keeps handlers database-agnostic. The same `SELECT.from('Books').where(...)` works on SQLite in dev and HANA in production. Understanding the API — including its limits — lets you write efficient, portable data access code.

## Basic SELECT

```js
// All books
const all = await SELECT.from('Books')

// With columns
const titles = await SELECT.from('Books').columns('title', 'price')

// With WHERE
const cheap = await SELECT.from('Books').where({ price: { '<=': 20 } })

// Shorthand where
const byId = await SELECT.from('Books', { ID: 'abc-123' })

// One row
const book = await SELECT.one.from('Books').where({ ID: req.data.ID })
```

## Column projection and aliases

```js
const result = await SELECT.from('Books').columns(b => {
  b.ID,
  b.title.as('bookTitle'),
  b.price,
  b('stock * price').as('inventory_value')
})
```

## WHERE with operators

```js
// Operator comparison
SELECT.from('Books').where('price >', 10)
SELECT.from('Books').where('price between', 10, 'and', 50)

// Object style
SELECT.from('Books').where({ price: { '>': 10 }, stock: { '>': 0 } })

// Parameterized (safe from injection)
SELECT.from('Books').where(`title like`, '%CAP%')

// OR conditions
SELECT.from('Books').where(`status = 'ACTIVE' or stock > 100`)
```

## ORDER BY, LIMIT, OFFSET

```js
const paginated = await SELECT.from('Books')
  .orderBy('price asc', 'title')
  .limit(20, 40)   // limit 20, skip 40 → page 3

// With columns
const topPriced = await SELECT.from('Books')
  .columns('title', 'price')
  .orderBy({ price: 'desc' })
  .limit(10)
```

## SELECT with expand (associations)

```js
// Inline expand
const orders = await SELECT.from('Orders').columns(o => {
  o.ID, o.status,
  o.items(i => { i.book_ID, i.quantity, i.price })
})
// Generates: SELECT ... FROM Orders LEFT JOIN OrderItems ON ...
```

## INSERT

```js
// Single row
await INSERT.into('Books').entries({
  ID:    cds.utils.uuid(),
  title: 'SAP CAP Handbook',
  price: 49.99
})

// Multiple rows
await INSERT.into('Books').entries([book1, book2, book3])

// Return inserted row (HANA / PostgreSQL)
const inserted = await INSERT.into('Books').entries(data).returning('*')
```

## UPDATE

```js
// Update by key
await UPDATE('Books', { ID: req.data.ID }).with({ price: 59.99 })

// Update with expression
await UPDATE('Books').set('stock -= 1').where({ ID: bookId })

// Conditional update
await UPDATE('Books')
  .set({ status: 'OUT_OF_STOCK' })
  .where({ stock: 0 })
```

## DELETE

```js
// Delete by key
await DELETE.from('Books', { ID: req.data.ID })

// Delete with WHERE
await DELETE.from('Books').where({ status: 'ARCHIVED', updatedAt: { '<': cutoff } })
```

## Running queries

```js
// Inside a handler: uses the request's transaction automatically
const db = await cds.connect.to('db')
const result = await db.run(SELECT.from('Books'))

// CAP shorthand — same as above when called from within a handler
const result = await cds.run(SELECT.from('Books'))

// Direct execute (no transaction wrapper)
await cds.db.run(`SELECT * FROM Books WHERE price < ?`, [50])
```

## Transaction control

```js
const tx = cds.transaction(req)   // attach to request transaction

await tx.run(INSERT.into('AuditLog').entries({ ... }))
await tx.run(UPDATE('Orders').set({ status: 'DONE' }).where({ ID }))
// Both committed when the request handler returns successfully
// Rolled back automatically if handler throws
```

## Limits to be aware of

| Feature | Support |
|---|---|
| Subqueries in WHERE | CQL does not support subqueries in WHERE — use JOIN or multiple queries |
| Database functions (HANA-specific) | Use `cds.hana` annotations or raw `db.run(native SQL)` |
| Aggregates in SELECT | Supported: `SUM(price)`, `COUNT(*)` |
| GROUP BY | Supported via `.groupBy('category')` |
| Unions | Not in fluent API — use raw SQL |

## Hands-on exercise
1. Write a handler for `GET /catalog/ExpensiveBooks` that returns books with `price > 30`, ordered by price desc, max 10
2. Write an `updateStock` action that uses `UPDATE('Books').set('stock -=', qty).where({ ID })`
3. Write a batch insert that creates 5 seed books from an array
4. Write a query that expands `author` inline and returns title + author name

## Checkpoint ✓
- [ ] `SELECT.one.from(...)` returns a single object or undefined
- [ ] `.where()` supports both object style and string expressions
- [ ] `INSERT.into().entries()` accepts single object or array
- [ ] `UPDATE().set().where()` supports computed expressions like `'stock -=', 1`
$md$
WHERE slug = 'cap-30-query-api';


-- ── Lesson 31 — Batch Requests & Deep Inserts ────────────────────────────────

UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 31 — Batch Requests & Deep Inserts

## What you'll learn
- OData `$batch` request format and when to use it
- How CAP handles batch requests automatically
- Deep insert — creating a parent and children in one request
- Deep update — updating composed entities
- Atomicity and error handling in batch

## Why this matters
UI5 applications batch multiple OData calls into one HTTP request to reduce latency. Deep inserts are the standard pattern for creating an Order with its Items in a single transaction. CAP handles both patterns automatically, but you need to know what arrives at your handlers.

## OData $batch format

```http
POST /orders/$batch
Content-Type: multipart/mixed; boundary=batch_1

--batch_1
Content-Type: application/http

POST /orders/Orders HTTP/1.1
Content-Type: application/json

{ "ID": "...", "status": "DRAFT" }

--batch_1
Content-Type: application/http

GET /orders/Orders?$top=5 HTTP/1.1

--batch_1--
```

CAP parses the multipart format, executes each request, and returns a multipart response. **No handler code needed** — it works automatically.

## Atomicity modes

### Default: individual transactions
```
Each request in the batch runs in its own transaction.
If request 2 fails, requests 1 and 3 are not rolled back.
```

### Change set: atomic group
```http
--batch_1
Content-Type: multipart/mixed; boundary=changeset_1

--changeset_1
Content-Type: application/http

POST /orders/Orders HTTP/1.1
{ ... }

--changeset_1
Content-Type: application/http

POST /orders/OrderItems HTTP/1.1
{ ... }

--changeset_1--
--batch_1--
```

Requests inside a change set share one transaction — if any fails, all are rolled back.

## Deep insert (parent + children)

```json
// POST /orders/Orders
{
  "ID":     "c0f0b8a0-0000-0000-0000-000000000001",
  "status": "DRAFT",
  "buyer":  "alice",
  "items": [
    { "book_ID": "book-001", "quantity": 2, "price": 29.99 },
    { "book_ID": "book-002", "quantity": 1, "price": 14.99 }
  ]
}
```

CAP inserts `Orders` first, then inserts each `items` row with `order_ID` set automatically — because `items` is a **Composition** in CDS.

```cds
entity Orders {
  key ID : UUID;
  // ...
  items : Composition of many OrderItems on items.order = $self;
}
```

Deep inserts only work on **Compositions** — not Associations.

## Handling deep inserts in a custom handler

```js
// The full nested payload arrives in req.data
this.before('CREATE', 'Orders', (req) => {
  const { items } = req.data

  if (!items || items.length === 0)
    return req.reject(400, 'Order must have at least one item')

  // Compute total from items
  req.data.total = items.reduce((sum, i) => sum + i.price * i.quantity, 0)
})
```

## Deep update

```json
// PATCH /orders/Orders('c0f0b8a0-...')
{
  "status": "SUBMITTED",
  "items": [
    { "ID": "item-001", "quantity": 3 },     // update existing item
    { "book_ID": "book-003", "quantity": 1, "price": 9.99 }  // add new item
  ]
}
```

CAP deep-updates composition children: existing items are matched by key and updated; items without a key are inserted.

## Programmatic batch (cds.ql)

```js
// Run multiple queries in sequence within one transaction
const tx = cds.transaction(req)

const [order, items] = await Promise.all([
  tx.run(INSERT.into('Orders').entries(orderData)),
  tx.run(INSERT.into('OrderItems').entries(itemsData.map(i => ({ ...i, order_ID: orderData.ID }))))
])
```

## Error response in batch

```json
// Multipart response — each part has its own status
--batch_response_1
Content-Type: application/http

HTTP/1.1 400 Bad Request
Content-Type: application/json

{
  "error": {
    "code": "400",
    "message": "Order must have at least one item"
  }
}
--batch_response_1--
```

CAP automatically wraps errors in the multipart format.

## UI5 automatic batching

```js
// UI5 OData V4 model batches all requests in one changeset by default
const oModel = this.getView().getModel()
oModel.setAutoExpandSelect(true)

// All pending operations submitted as one $batch
oModel.submitBatch('myBatchGroup')
```

## Hands-on exercise
1. Define `Orders` with `items: Composition of many OrderItems`
2. POST a deep insert with 3 items and verify all 4 rows (1 order + 3 items) are created
3. PATCH the order changing one item's quantity — verify only that item updates
4. Add a BEFORE handler that computes `total` from items on deep insert

## Checkpoint ✓
- [ ] `$batch` is handled automatically by CAP — no handler code needed
- [ ] Deep inserts only work on Composition (not Association) properties
- [ ] Change sets provide atomicity across multiple batch operations
- [ ] `req.data.items` contains the nested children in a deep insert handler
$md$
WHERE slug = 'cap-31-batch';

-- ── Lesson 32 — File Upload & Media Types ────────────────────────────────────

UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 32 — File Upload & Media Types

## What you'll learn
- OData media entity pattern (stream properties)
- Declaring media entities in CDS with `@Core.MediaType`
- Implementing upload and download handlers
- Storing files in the database (small files) vs Object Store (large files)
- Streaming large files efficiently

## Why this matters
Every business app needs file attachments — product images, invoice PDFs, contract documents. CAP's OData media entity pattern gives you a standardised upload/download API that Fiori Attachments works with out of the box.

## CDS media entity declaration

```cds
// db/schema.cds
entity Attachments {
  key ID       : UUID;
  order_ID     : UUID;
  filename     : String;
  mediaType    : String  @Core.IsMediaType;       // stores MIME type
  content      : LargeBinary @Core.MediaType: mediaType;  // the binary blob
  size         : Integer;
  createdAt    : Timestamp @cds.on.insert: $now;
}
```

```cds
// srv/orders-service.cds
service OrdersService {
  entity Attachments as projection on my.Attachments;
}
```

## Upload handler

```js
// srv/orders-service.js
const fs = require('fs')
const path = require('path')

this.on('PUT', 'Attachments', async (req) => {
  const { ID } = req.params[0]         // key from URL: PUT /Attachments(uuid)/$value
  const mediaType = req.headers['content-type']
  const filename  = req.headers['slug'] || 'upload'

  // For small files: buffer and store in DB
  const chunks = []
  for await (const chunk of req.data) chunks.push(chunk)
  const content = Buffer.concat(chunks)

  await UPSERT.into('Attachments').entries({
    ID,
    order_ID:  req.headers['x-order-id'],
    filename,
    mediaType,
    content,
    size: content.length
  })

  return { ID, filename, size: content.length }
})
```

## Download handler

```js
this.on('READ', 'Attachments', async (req) => {
  // When URL is /Attachments(uuid)/$value — streaming the binary
  if (req.params?.[0] && req._.req?.url?.endsWith('/$value')) {
    const { ID } = req.params[0]
    const row = await SELECT.one.from('Attachments').where({ ID })
    if (!row) return req.reject(404, 'Attachment not found')

    req._.res.setHeader('Content-Type',   row.mediaType)
    req._.res.setHeader('Content-Length', row.size)
    req._.res.setHeader('Content-Disposition', `inline; filename="${row.filename}"`)
    req._.res.end(row.content)
    return   // prevent CAP from sending its own response
  }

  // Normal metadata read
  return SELECT.from('Attachments').columns('ID','filename','mediaType','size','createdAt')
})
```

## SAP Object Store integration (large files)

```js
// For large files, stream to SAP Object Store instead of DB
const objectStore = await cds.connect.to('object-store')

this.on('PUT', 'Attachments', async (req) => {
  const { ID } = req.params[0]
  const key = `attachments/${ID}`

  // Stream directly to Object Store
  await objectStore.upload({ key, body: req.data, contentType: req.headers['content-type'] })

  await UPSERT.into('Attachments').entries({
    ID,
    storageKey: key,
    mediaType:  req.headers['content-type'],
    filename:   req.headers['slug']
  })
})
```

## Fiori V4 attachment upload

```js
// UI5: upload via OData V4 model
const oListBinding = oModel.bindList('/Attachments')
const oContext = oListBinding.create({ ID: uuid() })

const oBinding = oModel.bindProperty(`${oContext.getPath()}/$value`)
await oBinding.setValue(file)   // file is a File object from <input type="file">
```

## HTTP REST upload

```http
### Create metadata first
POST http://localhost:4004/orders/Attachments
Content-Type: application/json

{ "ID": "att-001", "order_ID": "ord-001", "filename": "invoice.pdf" }

### Then upload content
PUT http://localhost:4004/orders/Attachments('att-001')/$value
Content-Type: application/pdf
Slug: invoice.pdf

< ./invoice.pdf
```

## Common mistakes

| Mistake | Symptom | Fix |
|---|---|---|
| `@Core.MediaType` on wrong field | Download returns wrong MIME type | Annotate the mediaType *string* field |
| Buffering large files in memory | OOM error | Use streaming or Object Store |
| Missing `$value` segment in URL | Gets metadata, not file | Append `/$value` to download binary |
| Returning from download handler | Double response error | Return `undefined` after `res.end()` |

## Hands-on exercise
1. Add an `Attachments` entity to your bookshop schema
2. Implement PUT (upload) and GET (download) handlers
3. Test upload with `curl -X PUT .../Attachments('test')/$value --data-binary @file.pdf`
4. Verify Content-Type and Content-Disposition headers in the response

## Checkpoint ✓
- [ ] `@Core.IsMediaType` marks the MIME type field; `@Core.MediaType: mimeField` marks the binary
- [ ] PUT to `/$value` endpoint uploads the binary content
- [ ] For large files, stream to Object Store rather than buffering in memory
- [ ] Call `res.end()` and return `undefined` to avoid double-response errors
$md$
WHERE slug = 'cap-32-file-upload';

-- ── Lesson 33 — Consuming Remote Services ────────────────────────────────────

UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 33 — Consuming Remote Services

## What you'll learn
- Importing external OData APIs as CDS definitions
- Configuring destinations for remote calls
- Delegating requests from your service to a remote service
- Mashing up local and remote data
- Error handling for remote calls

## Why this matters
CAP apps rarely live alone — they call S/4HANA OData APIs, BTP services, and partner APIs. CAP's `cds.connect.to()` pattern abstracts the transport so your handler code is the same whether the remote service is a real S/4HANA system or a local mock.

## Step 1 — Import the external API

```bash
# Download the API definition from SAP API Business Hub (edmx format)
# Or use CDS introspection
cds import ./API_BUSINESS_PARTNER.edmx --as cds
```

This creates:
```
srv/external/
└── API_BUSINESS_PARTNER.cds    ← CDS model of the external API
```

```cds
// Auto-generated (excerpt)
service API_BUSINESS_PARTNER {
  entity A_BusinessPartner {
    key BusinessPartner : String(10);
    BusinessPartnerFullName : String;
    // ...
  }
}
```

## Step 2 — Reference in your service

```cds
// srv/orders-service.cds
using { API_BUSINESS_PARTNER as bp } from './external/API_BUSINESS_PARTNER';

service OrdersService {
  entity Orders as projection on my.Orders;

  // Expose a subset of the remote entity
  entity Suppliers as projection on bp.A_BusinessPartner {
    key BusinessPartner as ID,
        BusinessPartnerFullName as name
  }
}
```

## Step 3 — Configure the destination

```json
// .cdsrc.json
{
  "requires": {
    "API_BUSINESS_PARTNER": {
      "[production]": {
        "kind": "odata-v2",
        "model": "srv/external/API_BUSINESS_PARTNER",
        "destination": "S4HANA_DESTINATION",    // BTP Destination name
        "path": "/sap/opu/odata/sap"
      },
      "[development]": {
        "kind": "odata-v2",
        "model": "srv/external/API_BUSINESS_PARTNER",
        "credentials": {
          "url": "https://sandbox.api.sap.com/s4hanacloud/sap/opu/odata/sap",
          "headers": { "APIKey": "YOUR_API_KEY" }
        }
      }
    }
  }
}
```

## Step 4 — Implement the handler (delegate pattern)

```js
// srv/orders-service.js
module.exports = class OrdersService extends cds.ApplicationService {
  async init () {
    const bpApi = await cds.connect.to('API_BUSINESS_PARTNER')

    // Delegate all READ on Suppliers to the remote S/4HANA API
    this.on('READ', 'Suppliers', (req) => bpApi.run(req.query))

    await super.init()
  }
}
```

The `req.query` is the CQL query built from the OData request — CAP translates `$filter`, `$select`, `$top`, etc. and delegates them to the remote API automatically.

## Mashup: combine local and remote data

```js
this.on('READ', 'EnrichedOrders', async (req) => {
  // 1. Read local orders
  const orders = await SELECT.from('Orders')

  // 2. Get unique supplier IDs
  const supplierIds = [...new Set(orders.map(o => o.supplier_ID))]

  // 3. Fetch supplier names from S/4HANA
  const suppliers = await bpApi.run(
    SELECT.from('A_BusinessPartner')
      .where({ BusinessPartner: { in: supplierIds } })
      .columns('BusinessPartner', 'BusinessPartnerFullName')
  )

  // 4. Merge
  const supplierMap = Object.fromEntries(suppliers.map(s => [s.BusinessPartner, s.BusinessPartnerFullName]))
  return orders.map(o => ({ ...o, supplierName: supplierMap[o.supplier_ID] || 'Unknown' }))
})
```

## Mock for development

Create a CSV file to mock the remote entity locally:
```
srv/external/data/
└── API_BUSINESS_PARTNER-A_BusinessPartner.csv
```

```csv
BusinessPartner,BusinessPartnerFullName
1000000,ACME Corporation
1000001,GlobalTech Ltd
```

When `kind` is not set (no `.cdsrc.json` entry for dev), CAP auto-mocks using these CSV files.

## Error handling

```js
try {
  const suppliers = await bpApi.run(SELECT.from('A_BusinessPartner').where({ BusinessPartner: id }))
  return suppliers
} catch (err) {
  if (err.statusCode === 404) return req.reject(404, `Supplier ${id} not found in S/4HANA`)
  console.error('S/4HANA call failed:', err.message)
  return req.reject(502, 'Remote service temporarily unavailable')
}
```

## Common mistakes

| Mistake | Symptom | Fix |
|---|---|---|
| Passing `req` not `req.query` | Delegation error | Use `bpApi.run(req.query)` |
| No mock CSV for dev | Empty results in local testing | Add CSV under `srv/external/data/` |
| Missing `using` import | CDS model not found | Add `using { ... } from './external/...'` |
| Destination not configured in BTP | 404 in production | Create the destination in BTP Cockpit |

## Hands-on exercise
1. Download the SAP API Hub Business Partner API edmx and import it
2. Expose `Suppliers` as a projection in your service
3. Implement the delegate handler
4. Add mock CSV data; verify the mashup returns order + supplier name

## Checkpoint ✓
- [ ] `cds import` generates CDS from OData/edmx
- [ ] `cds.connect.to('ServiceName')` returns a service client
- [ ] `bpApi.run(req.query)` delegates the full query including filters
- [ ] Mock CSV files in `srv/external/data/` enable local development without a real backend
$md$
WHERE slug = 'cap-33-remote-services';

-- ── Lesson 34 — Service Extensibility Patterns ───────────────────────────────

UPDATE public.topics SET
  status     = 'published',
  content_md = $md$
# Episode 34 — Service Extensibility Patterns

## What you'll learn
- Plugin hooks: how to design a service others can extend
- Customer-exit pattern for partner/customer customisation
- Extension fields via `extend entity`
- Side-effect annotations (`@sap.fiori.draft.enabled`, `@Core.SideEffects`)
- Packaging a reusable CAP plugin npm package

## Why this matters
SAP-style platforms must be *extensible* — customers need to add fields, override business rules, and integrate without forking the base. These patterns are how enterprise CAP applications support that model cleanly.

## Plugin hook pattern

```js
// Base service — exposes hook points
module.exports = class BaseOrderService extends cds.ApplicationService {
  async init () {
    // Register hook slots other plugins can fill
    this.before('CREATE', 'Orders', this._beforeCreate.bind(this))
    this.on('CREATE', 'Orders', this._onCreate.bind(this))

    await super.init()
  }

  // Override these in subclass or plugin
  async _beforeCreate (req) { /* default: no-op */ }
  async _onCreate (req) {
    // ... default create logic
    await INSERT.into('Orders').entries(req.data)
    return SELECT.one.from('Orders').where({ ID: req.data.ID })
  }
}
```

```js
// Extended service (customer or partner)
const BaseOrderService = require('@company/base-orders')

module.exports = class CustomOrderService extends BaseOrderService {
  async _beforeCreate (req) {
    // Inject custom validation without touching base code
    if (!req.data.costCenter) return req.reject(400, 'Cost center required')
  }
}
```

## Customer-exit pattern (event-based)

```js
// Base service emits an extensibility event
this.before('CREATE', 'Orders', async (req) => {
  // Allow external plugins to veto or enrich
  await this.emit('BEFORE_CREATE_ORDERS', req.data)
})

// Customer plugin subscribes
const baseService = await cds.connect.to('OrderService')
baseService.before('BEFORE_CREATE_ORDERS', (req) => {
  req.data.customField = computeCustomValue(req.data)
})
```

## Extension fields

```cds
// Base model (not to be modified)
// db/base/schema.cds
namespace base;
entity Orders {
  key ID     : UUID;
  status     : String;
  total      : Decimal;
}
```

```cds
// Extension (in customer namespace)
// db/extensions/customer.cds
using base from '../../base/schema';

extend base.Orders with {
  costCenter   : String(10);
  projectCode  : String(20);
  approvedBy   : String;
}
```

```cds
// Also extend the service projection
using OrderService as svc from '../../srv/order-service';
extend projection svc.Orders with {
  costCenter,
  projectCode,
  approvedBy
}
```

## Side effects (`@Core.SideEffects`)

When changing one field triggers recalculation of another in Fiori:

```cds
annotate svc.OrderItems with @(
  Core.SideEffects #quantityChanges: {
    SourceProperties: [quantity, price],
    TargetProperties: ['_it/total', '_it/taxAmount']
  }
);
```

This tells Fiori: when `quantity` or `price` changes, re-fetch `total` and `taxAmount` from the server.

## Reusable CAP plugin npm package

```
my-cap-plugin/
├── package.json
├── index.js            ← plugin entry point
└── cds-plugin.js       ← auto-loaded by CAP on install
```

```json
// package.json
{
  "name": "@mycompany/cap-audit",
  "version": "1.0.0",
  "cds": {
    "plugin": true
  }
}
```

```js
// cds-plugin.js — runs at CDS bootstrap
const cds = require('@sap/cds')

// Hook into every service globally
cds.on('serving', (service) => {
  service.after(['CREATE','UPDATE','DELETE'], '*', (data, req) => {
    // Global audit log — applied to every entity in every service
    logAudit({ entity: req.target.name, op: req.event, user: req.user.id })
  })
})
```

Install in any CAP project with `npm install @mycompany/cap-audit` — the plugin registers automatically.

## Feature flags for extensions

```js
const featureFlags = await cds.connect.to('feature-flags')

this.before('CREATE', 'Orders', async (req) => {
  const enabled = await featureFlags.evaluate('newValidationRule', req.tenant)
  if (enabled) {
    // Run new validation only for tenants with the flag enabled
    await runNewValidation(req.data)
  }
})
```

## Extensibility checklist

| Item | Pattern |
|---|---|
| Add new fields | `extend entity` in customer namespace |
| Override business rule | Override `_beforeCreate` in subclass |
| Add cross-cutting logic | `cds-plugin.js` with `cds.on('serving', ...)` |
| Customer-specific workflow | Subscribe to domain events |
| Feature rollout | Feature flag evaluated per tenant |
| UI extensions | Separate annotation cds file via `extend projection` |

## Hands-on exercise
1. Move your service's validation logic into an overridable `_validate(req)` method
2. Create a subclass that overrides `_validate` with stricter rules
3. Create a `cds-plugin.js` that logs every CREATE across all services
4. Declare an extension field `priority` on `Orders` via `extend entity`

## Checkpoint ✓
- [ ] Subclass pattern allows overriding business logic without forking
- [ ] `extend entity` adds fields in a customer namespace (non-destructive)
- [ ] `cds-plugin.js` with `cds.on('serving', ...)` applies cross-service logic globally
- [ ] `@Core.SideEffects` tells Fiori which fields to re-fetch after a change
$md$
WHERE slug = 'cap-34-extensibility';

