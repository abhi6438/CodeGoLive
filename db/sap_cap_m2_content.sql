-- ─────────────────────────────────────────────────────────────────────────────
-- SAP CAP Course — Module 2: CDS Data Modeling — Full Content
-- ─────────────────────────────────────────────────────────────────────────────

UPDATE public.topics SET status = 'published', content_md = $md$
# Lesson 11 — Associations & Compositions

## What you'll learn
The difference between Association and Composition, when to use each, how to define one-to-one, one-to-many, and many-to-many relationships, and how CAP handles them in OData and SQL.

---

## Associations — references between entities

An **Association** is a reference from one entity to another — like a foreign key. The referenced entity has its own lifecycle; deleting the parent does NOT delete the referenced entity.

```cds
entity Books {
  key ID     : UUID;
      title  : String(100);
      author : Association to Authors;  // FK to Authors
}

entity Authors {
  key ID   : UUID;
      name : String(100);
}
```

In the database, CAP creates a `author_ID` column in `Books` as a foreign key.

In OData, you can navigate: `GET /Books(1)?$expand=author`

---

## Compositions — owned children

A **Composition** is a parent-owns-child relationship. The child cannot exist without the parent. Deleting the parent **cascades** to delete all children automatically.

```cds
entity Orders {
  key ID    : UUID;
      total : Decimal(10,2);
      items : Composition of many OrderItems on items.order = $self;
}

entity OrderItems {
  key ID      : UUID;
      order   : Association to Orders;
      product : String(100);
      qty     : Integer;
      price   : Decimal(10,2);
}
```

**Deep insert** — create Order + Items in one POST:
```json
POST /odata/v4/orders/Orders
{
  "items": [
    { "product": "Book A", "qty": 2, "price": 25.00 },
    { "product": "Book B", "qty": 1, "price": 39.99 }
  ]
}
```
CAP automatically inserts the Order and all OrderItems in one transaction.

---

## One-to-one association

```cds
entity Users {
  key ID      : UUID;
      profile : Association to one UserProfiles;
}

entity UserProfiles {
  key ID     : UUID;
      user   : Association to Users;
      bio    : LargeString;
      avatar : String(500);
}
```

---

## One-to-many — backlink association

```cds
entity Authors {
  key ID    : UUID;
      name  : String(100);
      books : Association to many Books on books.author = $self;
}

entity Books {
  key ID     : UUID;
      title  : String;
      author : Association to Authors;
}
```

The `on books.author = $self` clause defines the join condition. `$self` refers to the current Authors instance.

---

## Many-to-many — link table

CDS doesn't have a native many-to-many keyword. You create it explicitly with a link entity:

```cds
entity Books {
  key ID     : UUID;
      title  : String;
      genres : Association to many Books_Genres on genres.book = $self;
}

entity Genres {
  key ID   : Integer;
      name : String(50);
}

// Link table
entity Books_Genres {
  key book  : Association to Books;
  key genre : Association to Genres;
}
```

---

## Association vs Composition — decision guide

| Situation | Use |
|-----------|-----|
| Child can exist without parent (e.g. Author exists without a Book) | Association |
| Child cannot exist without parent (e.g. OrderItem without an Order) | Composition |
| You want cascade delete | Composition |
| You want deep insert/update | Composition |
| You reference a lookup/master table | Association |

---

## Navigating associations in OData

```
# Expand association
GET /odata/v4/catalog/Books?$expand=author

# Navigate to related entity
GET /odata/v4/catalog/Authors(guid'...')/books

# Nested expand with select
GET /odata/v4/catalog/Orders?$expand=items($select=product,qty,price)

# Multi-level expand
GET /odata/v4/catalog/Orders?$expand=items($expand=product($select=title))
```

---

## Checkpoint ✓
- [ ] Can you model an Order with OrderItems using Composition?
- [ ] Can you define a many-to-many relationship?
- [ ] Do you know when to use Association vs Composition?
$md$ WHERE slug = 'cap-11-associations';


UPDATE public.topics SET status = 'published', content_md = $md$
# Lesson 12 — Aspects & Mixins

## What you'll learn
How to define and use CDS aspects to reuse model fragments — and the built-in SAP aspects (`managed`, `cuid`, `temporal`) that every production CAP app should use.

---

## What is an Aspect?

An aspect is a **reusable CDS fragment** that you can mix into any entity. Think of it as a TypeScript interface or a Java mixin — it adds fields and annotations without inheritance.

```cds
aspect Timestamps {
  createdAt  : Timestamp;
  modifiedAt : Timestamp;
}

entity Books : Timestamps {
  key ID    : UUID;
      title : String;
  // createdAt and modifiedAt are inherited from Timestamps
}

entity Orders : Timestamps {
  key ID    : UUID;
      total : Decimal;
  // same fields available here too
}
```

---

## Built-in SAP aspects from `@sap/cds/common`

SAP ships three production-ready aspects. Import them with:

```cds
using { cuid, managed, temporal } from '@sap/cds/common';
```

### `cuid` — UUID primary key

```cds
entity Books : cuid {
  title : String(100);
}
// Equivalent to:
entity Books {
  key ID : UUID;
  title  : String(100);
}
```

### `managed` — audit trail fields

```cds
entity Books : managed {
  key ID : UUID;
  title  : String;
}
// Adds:
//   createdAt  : Timestamp @cds.on.insert: $now
//   createdBy  : String    @cds.on.insert: $user
//   modifiedAt : Timestamp @cds.on.insert: $now  @cds.on.update: $now
//   modifiedBy : String    @cds.on.insert: $user @cds.on.update: $user
```

CAP fills these automatically — no handler code needed.

### `temporal` — time-based validity

```cds
entity Prices : temporal {
  key product : Association to Products;
      amount  : Decimal(10,2);
}
// Adds:
//   validFrom : DateTime;
//   validTo   : DateTime;
```

Used for time-slice data — e.g. price valid from Jan 1 to Mar 31. CAP automatically filters by current date when you query.

---

## Combining aspects

```cds
using { cuid, managed, temporal } from '@sap/cds/common';

entity Products : cuid, managed {
  name   : String(100) not null;
  price  : Decimal(10,2);
  status : String(20) default 'active';
}

entity PriceHistory : cuid, managed, temporal {
  product : Association to Products;
  price   : Decimal(10,2);
  currency: String(3) default 'USD';
}
```

---

## Custom aspects with annotations

Aspects can include annotations, not just fields:

```cds
aspect SoftDelete {
  deletedAt  : Timestamp;
  deletedBy  : String(100);
  isDeleted  : Boolean default false;
}

@(restrict: [{ grant: 'DELETE', where: 'isDeleted = false' }])
entity Orders : cuid, managed, SoftDelete {
  total : Decimal;
}
```

---

## Aspect inheritance

Aspects can extend other aspects:

```cds
aspect Base : cuid, managed { }

aspect SoftDeletable : Base {
  isDeleted : Boolean default false;
}

entity Orders : SoftDeletable {
  total : Decimal;
}
// Orders has: ID, createdAt, createdBy, modifiedAt, modifiedBy, isDeleted, total
```

---

## Reusing SAP Common types

`@sap/cds/common` also provides useful types:

```cds
using { sap.common.CodeList, Currency, Country, Language } from '@sap/cds/common';

entity Products : cuid {
  name     : String(100);
  currency : Currency;    // ISO 4217 currency code
  country  : Country;     // ISO 3166 country code
  language : Language;    // ISO 639 language code
}
```

These come with built-in value lists that Fiori UI can use for dropdowns automatically.

---

## Checkpoint ✓
- [ ] Can you define a custom aspect and apply it to 2 entities?
- [ ] Can you use `cuid`, `managed`, and `temporal` in a single entity?
- [ ] Do you know what fields `managed` adds and when CAP populates them?
$md$ WHERE slug = 'cap-12-aspects';


UPDATE public.topics SET status = 'published', content_md = $md$
# Lesson 13 — Views & Projections

## What you'll learn
How to create CDS views for denormalized reads, calculated columns, aggregations, and how service projections differ from database views.

---

## Service projections vs CDS views

**Service projection** — in `srv/`, exposes a subset of fields for an OData consumer:
```cds
service CatalogService {
  entity Books as select from db.Books { ID, title, price };
}
```

**CDS view** — in `db/`, a reusable query that lives at the database level:
```cds
// db/schema.cds
define view BooksSummary as select from Books {
  ID,
  title,
  price,
  stock,
  stock * price as inventoryValue : Decimal(12,2)
};
```

Use database views for complex queries reused across multiple services. Use service projections for per-service field control.

---

## Basic projection

```cds
// Expose only public fields
entity PublicBooks as select from Books {
  ID,
  title,
  price,
  author.name as authorName  // flatten the association
};
```

---

## Calculated columns

```cds
define view OrdersWithTotal as select from Orders {
  *,
  (select sum(price * qty) from OrderItems where order_ID = Orders.ID)
    as computedTotal : Decimal(12,2)
};
```

Or in SQLite-friendly CAP syntax:
```cds
entity Books as select from db.Books {
  *,
  stock > 0        as inStock     : Boolean,
  stock * price    as stockValue  : Decimal(12,2),
  case
    when price < 20 then 'budget'
    when price < 50 then 'standard'
    else 'premium'
  end              as priceRange  : String(20)
};
```

---

## Joining multiple entities

```cds
define view BookDetails as select from Books
  left join Authors on Books.author_ID = Authors.ID
  left join Genres  on Books.genre_ID  = Genres.ID
{
  Books.ID,
  Books.title,
  Books.price,
  Authors.name  as authorName,
  Genres.name   as genreName
};
```

---

## Aggregation views

```cds
define view AuthorStats as select from Books
  group by author_ID
{
  author_ID,
  count(*) as bookCount : Integer,
  avg(price) as avgPrice : Decimal(10,2),
  min(price) as minPrice : Decimal(10,2),
  max(price) as maxPrice : Decimal(10,2)
};
```

---

## Redirecting associations in projections

When you project an entity, associations need to be redirected to the projected version (not the database entity) to keep navigation working in OData:

```cds
service CatalogService {
  entity Books as projection on db.Books {
    *,
    author: redirected to Authors  // ← point to the service-level Authors
  };
  entity Authors as projection on db.Authors;
}
```

Without `redirected to`, OData navigation to `author` would try to reach `db.Authors` which isn't exposed in this service.

---

## Using projections for row-level security

```cds
service OrderService {
  // Each user only sees their own orders
  entity MyOrders as select from db.Orders
    where createdBy = $user.id
  {
    *
  };
}
```

`$user.id` is resolved by CAP at runtime from the JWT token. This adds a `WHERE` clause to every query on `MyOrders`.

---

## Checkpoint ✓
- [ ] Can you create a CDS view with a calculated column?
- [ ] Can you join two entities in a view?
- [ ] Can you add a `where $user.id` filter for row-level security?
$md$ WHERE slug = 'cap-13-views';


UPDATE public.topics SET status = 'published', content_md = $md$
# Lesson 14 — CDS Annotations Deep Dive

## What you'll learn
How to apply UI5/Fiori annotations, OData vocabulary annotations, and validation annotations in CDS — and how they affect the generated metadata and UI.

---

## What are annotations?

Annotations are **metadata** attached to entities, fields, or services. They don't change the data structure — they describe how data should be displayed, validated, and behaved.

```cds
@title: 'Books Catalog'         // OData Core annotation
entity Books {
  key ID    : UUID;

  @title: 'Book Title'
  @mandatory                    // validation
  title : String(100);

  @Measures.ISOCurrency: currency  // SAP UI5 annotation
  price : Decimal(10,2);

  currency : String(3);
}
```

---

## Annotation syntax

```cds
// Simple value
@title: 'My Title'

// Record value
@UI.LineItem: [{ Value: title, Label: 'Book Title' }]

// Inline on a field
entity Books {
  @(title: 'Price', Measures.ISOCurrency: currency)
  price : Decimal(10,2);
}
```

---

## OData Core annotations

```cds
@Core.Description: 'The main catalog of books'   // service/entity description
@Core.LongDescription: '...'
@Core.Computed                                    // field is server-managed
@Core.Immutable                                   // field cannot be updated after create

entity Books {
  key ID    : UUID @Core.Computed;
  
  @Core.Description: 'The full book title'
  title     : String(100);
  
  @Core.IsURL
  coverUrl  : String(500);
}
```

---

## Fiori UI annotations

These annotations drive SAP Fiori Elements apps — the page layout, columns, forms, and navigation are all generated from these.

```cds
annotate CatalogService.Books with @(
  UI: {
    // List Report columns
    LineItem: [
      { Value: title,      Label: 'Title'  },
      { Value: price,      Label: 'Price'  },
      { Value: author.name,Label: 'Author' },
      { Value: stock,      Label: 'Stock'  }
    ],

    // Object Page header
    HeaderInfo: {
      TypeName      : 'Book',
      TypeNamePlural: 'Books',
      Title         : { Value: title },
      Description   : { Value: author.name }
    },

    // Object Page sections
    Facets: [
      {
        $Type : 'UI.ReferenceFacet',
        Label : 'General',
        Target: '@UI.FieldGroup#General'
      }
    ],

    FieldGroup#General: {
      Data: [
        { Value: title  },
        { Value: price  },
        { Value: stock  },
        { Value: author }
      ]
    }
  }
);
```

---

## Validation annotations

```cds
entity Products {
  key ID : UUID;

  @mandatory                          // must be provided on create
  @title: 'Product Name'
  name : String(100);

  @assert.range: [0.01, 99999.99]    // value must be in range
  price : Decimal(10,2);

  @assert.format: '^[A-Z]{2}[0-9]{4}$'  // regex validation
  sku : String(6);

  @assert.unique                      // unique across all rows
  barcode : String(13);
}
```

CAP enforces these constraints on CREATE and UPDATE automatically — no handler code needed.

---

## Value help (dropdown) annotations

```cds
entity Orders {
  key ID     : UUID;
  
  @Common.ValueList: {
    CollectionPath: 'Customers',
    Parameters: [
      { $Type: 'Common.ValueListParameterOut', LocalDataProperty: customer_ID, ValueListProperty: 'ID' },
      { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'name' }
    ]
  }
  customer : Association to Customers;
}
```

This creates a searchable dropdown in Fiori UI — no UI code needed.

---

## Search annotations

```cds
entity Books {
  key ID    : UUID;

  @Search.defaultSearchElement  // included in $search queries
  title  : String(100);

  @Search.defaultSearchElement
  author : String(100);

  price  : Decimal(10,2);       // not searchable
}
```

```
GET /odata/v4/catalog/Books?$search=clean code
// Searches title and author fields only
```

---

## Separating annotations from the model

Best practice: put UI annotations in a separate file to keep the data model clean:

```
db/
  schema.cds          ← entity definitions only
srv/
  catalog-service.cds ← service definition
  fiori-annotations.cds ← all UI annotations
```

```cds
// srv/fiori-annotations.cds
using CatalogService from './catalog-service';

annotate CatalogService.Books with @(
  UI.LineItem: [ ... ],
  UI.HeaderInfo: { ... }
);
```

---

## Checkpoint ✓
- [ ] Can you add `@title`, `@mandatory`, and `@assert.range` to fields?
- [ ] Can you define a `@UI.LineItem` with 4 columns?
- [ ] Can you add `@Search.defaultSearchElement` to 2 fields?
$md$ WHERE slug = 'cap-14-annotations';


UPDATE public.topics SET status = 'published', content_md = $md$
# Lesson 15 — Namespaces, Imports & Reuse Models

## What you'll learn
How to structure large multi-file CDS projects with namespaces and imports, and how to reuse SAP's standard model packages.

---

## Why namespaces matter

Without namespaces, two entities named `Status` from different files would collide. Namespaces prevent this:

```cds
// db/products.cds
namespace com.myapp.products;
entity Status { key ID: Integer; name: String; }

// db/orders.cds
namespace com.myapp.orders;
entity Status { key ID: Integer; name: String; }
// No collision — full names are different
```

---

## Multi-file project structure

For large projects, split by domain:

```
db/
├── common.cds          ← Shared types, aspects, enums
├── products/
│   ├── schema.cds      ← Product entities
│   └── annotations.cds
├── orders/
│   ├── schema.cds      ← Order entities
│   └── annotations.cds
└── index.cds           ← Imports all files (optional, for convenience)
```

```cds
// db/index.cds
using from './common';
using from './products/schema';
using from './orders/schema';
```

---

## The `using` keyword — import patterns

```cds
// Import everything from a file
using from '../db/schema';

// Import a namespace with alias
using com.myapp.products as products from '../db/products/schema';
entity Basket { product: Association to products.Products; }

// Import specific types
using { com.myapp.types.Price, com.myapp.types.Status } from '../db/common';
```

---

## SAP standard models — `@sap/cds/common`

SAP ships a standard model package with reusable types and code lists:

```cds
using {
  Currency,              // ISO 4217 currency codes (USD, EUR, ...)
  Country,               // ISO 3166 country codes
  Language,              // ISO 639 language codes
  sap.common.CodeList,   // Base aspect for all code lists
  cuid,                  // UUID key aspect
  managed,               // Audit trail aspect
  temporal               // Time-validity aspect
} from '@sap/cds/common';
```

**Using Currency with automatic Fiori integration:**
```cds
entity Products : cuid {
  name     : String(100);
  price    : Decimal(10,2);
  currency : Currency;    // Fiori renders this as a currency selector
}
```

---

## Building your own reuse model

Publish a reuse model as an npm package for sharing across projects:

```
my-company-common/
├── index.cds
└── package.json
```

```cds
// index.cds
namespace com.mycompany.common;

aspect AuditInfo {
  auditedBy   : String(100);
  auditedAt   : Timestamp;
  auditReason : String(500);
}

type ApprovalStatus : String enum {
  draft    = 'draft';
  pending  = 'pending';
  approved = 'approved';
  rejected = 'rejected';
}
```

In another project:
```bash
npm install my-company-common
```
```cds
using { com.mycompany.common } from 'my-company-common';
entity Orders : cuid, com.mycompany.common.AuditInfo { ... }
```

---

## Checkpoint ✓
- [ ] Can you split a schema across 3 files and import them all?
- [ ] Can you use `Currency` from `@sap/cds/common` in an entity?
- [ ] Do you know when to use a namespace alias vs full path imports?
$md$ WHERE slug = 'cap-15-namespaces';


UPDATE public.topics SET status = 'published', content_md = $md$
# Lesson 16 — Custom Types & Enumerations

## What you'll learn
How to define reusable scalar types, enum types, structured types, and array types — and how CAP validates them automatically.

---

## Why custom types?

Without custom types, you repeat yourself:
```cds
// ❌ Inconsistent — which String length is right?
entity Books   { price: Decimal(10,2); }
entity Orders  { price: Decimal(10,2); }
entity Invoices{ price: Decimal(12,2); }  // Different!
```

With a custom type:
```cds
// ✅ Consistent everywhere
type Price : Decimal(10,2);

entity Books    { price: Price; }
entity Orders   { price: Price; }
entity Invoices { price: Price; }
```

---

## Scalar types

```cds
// db/types.cds
namespace com.myapp.types;

type ID        : UUID;
type ShortText : String(100);
type LongText  : LargeString;
type Price     : Decimal(10, 2);
type Quantity  : Integer;
type Email     : String(254) @assert.format: '^[^@]+@[^@]+\.[^@]+$';
type PhoneNo   : String(20)  @assert.format: '^\+?[0-9\s\-]{7,20}$';
type URL       : String(2000) @Core.IsURL;
```

---

## Enum types

Enums restrict a field to a set of known values. CAP validates them on write.

```cds
type OrderStatus : String enum {
  draft     = 'draft';
  submitted = 'submitted';
  confirmed = 'confirmed';
  shipped   = 'shipped';
  delivered = 'delivered';
  cancelled = 'cancelled';
}

type Priority : Integer enum {
  low    = 1;
  medium = 2;
  high   = 3;
  urgent = 4;
}

entity Orders {
  key ID      : UUID;
      status  : OrderStatus default 'draft';
      priority: Priority    default 2;
}
```

**Enum validation**: `POST /Orders { "status": "invalid" }` → CAP returns HTTP 400.

---

## Structured types (records)

```cds
type Address {
  street  : String(100);
  city    : String(50);
  state   : String(50);
  zip     : String(10);
  country : String(2);
}

type ContactInfo {
  email   : String(254);
  phone   : String(20);
  address : Address;       // nested structure
}

entity Customers {
  key ID      : UUID;
      name    : String(100);
      billing : Address;
      shipping: Address;
      contact : ContactInfo;
}
```

In SQLite: fields are flattened (`billing_street`, `billing_city`, etc.).
In HANA: stored as a structured type column.

---

## Array types

```cds
entity Articles {
  key ID   : UUID;
      tags : array of String(50);      // array of scalars
      scores: array of Integer;
}

type Tag { name: String(50); color: String(7); }

entity Products {
  key ID   : UUID;
      tags : array of Tag;             // array of records
}
```

Arrays are stored as JSON. Don't use arrays for data you need to filter, join, or aggregate — use a separate entity with a Composition for that.

---

## Using types across files

```cds
// db/types.cds
namespace com.myapp;
type Price : Decimal(10,2);
type Email : String(254);

// db/schema.cds
using { com.myapp.Price, com.myapp.Email } from './types';

entity Products {
  key ID    : UUID;
      price : Price;
}

entity Users {
  key ID    : UUID;
      email : Email;
}
```

---

## Annotating types (propagation)

Annotations on a type propagate to every field that uses it:

```cds
@title: 'Price (USD)'
@Measures.ISOCurrency: 'USD'
type USDPrice : Decimal(10,2);

entity Books {
  price: USDPrice;
  // ↑ automatically gets @title and @Measures.ISOCurrency
}
```

---

## Checkpoint ✓
- [ ] Can you define 3 custom scalar types in a `types.cds` file?
- [ ] Can you create an enum with 4 values and use it on an entity?
- [ ] Can you define a structured `Address` type and embed it twice in one entity?
$md$ WHERE slug = 'cap-16-types';


UPDATE public.topics SET status = 'published', content_md = $md$
# Lesson 17 — Localization & i18n in CDS

## What you'll learn
How to make your CAP service multilingual — `localized` keyword, i18n message bundles, locale-aware queries, and serving content in the user's language.

---

## The `localized` keyword

The `localized` keyword tells CAP to generate a translations table automatically:

```cds
entity Books {
  key ID    : UUID;
      price : Decimal(10,2);
      
      localized title  : String(100);  // translatable
      localized descr  : LargeString;  // translatable
      currency         : String(3);    // NOT translatable
}
```

CAP generates a sibling `Books.texts` entity:
```cds
// Auto-generated by CAP:
entity Books.texts {
  key locale : String(5);          // e.g. 'en', 'de', 'fr'
  key ID     : UUID;
      title  : String(100);
      descr  : LargeString;
}
```

---

## Providing translations

Create CSV files per locale:

```
db/data/
├── my.bookshop-Books.csv            ← default (English) values
└── my.bookshop-Books.texts.csv      ← translations
```

`my.bookshop-Books.texts.csv`:
```csv
locale,ID,title,descr
de,f1f1...,Sauberer Code,Leitfaden für agile Software-Handwerker
fr,f1f1...,Code Propre,Guide pratique pour le développement agile
```

---

## How locale-aware queries work

CAP reads the `Accept-Language` HTTP header and filters the `texts` table:

```http
GET /odata/v4/catalog/Books
Accept-Language: de
```

CAP automatically returns German titles if available, English (default) if not. The `title` field in the response is the localized value.

---

## i18n message bundles for UI labels

For labels, buttons, error messages — not data — use `.properties` files:

```
_i18n/
├── i18n.properties          ← English (default)
├── i18n_de.properties       ← German
└── i18n_fr.properties       ← French
```

`i18n.properties`:
```properties
Books.title = Books
Books.price = Price
Books.createAction = Create Book
error.priceNegative = Price cannot be negative
```

`i18n_de.properties`:
```properties
Books.title = Bücher
Books.price = Preis
Books.createAction = Buch erstellen
error.priceNegative = Preis darf nicht negativ sein
```

---

## Using i18n keys in CDS annotations

```cds
entity Books {
  @title: '{i18n>Books.title}'       // resolved at runtime
  key ID    : UUID;
  
  @title: '{i18n>Books.price}'
  price : Decimal(10,2);
}
```

---

## Throwing localized errors in handlers

```javascript
const cds = require('@sap/cds');

module.exports = class BookService extends cds.ApplicationService {
  async init() {
    this.before('CREATE', 'Books', req => {
      if (req.data.price < 0) {
        // Key from i18n bundle — translated based on user's locale
        req.error('error.priceNegative');
      }
    });
    await super.init();
  }
}
```

---

## Querying specific locales programmatically

```javascript
// In a handler
const books = await SELECT.from('Books')
  .where({ ID: req.params[0].ID })
  .localized('de');  // force German

// Or use the default locale from the request
const books = await SELECT.from('Books').where({ ID: id });
// locale comes from req.locale automatically
```

---

## Checkpoint ✓
- [ ] Can you mark 2 fields as `localized` and provide German translations?
- [ ] Can you create an `i18n_de.properties` file?
- [ ] Do you know how CAP picks the locale at runtime?
$md$ WHERE slug = 'cap-17-localization';


UPDATE public.topics SET status = 'published', content_md = $md$
# Lesson 18 — Draft Mode & Fiori Draft Pattern

## What you'll learn
How to enable SAP Fiori draft capability in CAP, the draft lifecycle (create, edit, save, cancel), conflict handling, and testing drafts with REST Client.

---

## What is Draft Mode?

SAP Fiori Elements uses a "draft" pattern for editing:
1. User opens a form → CAP creates a **draft** record
2. User edits fields → changes saved to draft automatically
3. User clicks **Save** → CAP **activates** the draft (becomes the real record)
4. User clicks **Cancel** → CAP **discards** the draft

This enables multi-user editing with conflict detection and prevents data loss on browser crashes.

---

## Enabling draft

Just add `@odata.draft.enabled`:

```cds
service OrderService {
  @odata.draft.enabled
  entity Orders as projection on db.Orders;
}
```

CAP automatically:
- Creates a `DraftAdministrativeData` shadow table
- Adds `IsActiveEntity`, `HasActiveEntity`, `HasDraftEntity` fields to OData
- Handles all draft CRUD operations
- Activates drafts on save action

---

## Draft lifecycle via OData

```http
### 1. Create a new draft
POST /odata/v4/orders/Orders
Content-Type: application/json
{ "total": 0 }
# Returns: { "ID": "xxx", "IsActiveEntity": false }

### 2. Edit an existing record (create edit draft)
POST /odata/v4/orders/Orders(ID=guid'xxx',IsActiveEntity=true)/draftEdit
Content-Type: application/json
{}
# Returns draft copy: IsActiveEntity=false

### 3. Update the draft
PATCH /odata/v4/orders/Orders(ID=guid'xxx',IsActiveEntity=false)
Content-Type: application/json
{ "total": 150.00 }

### 4. Activate (Save) the draft
POST /odata/v4/orders/Orders(ID=guid'xxx',IsActiveEntity=false)/draftActivate
Content-Type: application/json
{}
# Draft becomes active record: IsActiveEntity=true

### 5. Cancel (Discard) the draft
DELETE /odata/v4/orders/Orders(ID=guid'xxx',IsActiveEntity=false)
```

---

## Filtering active vs draft records

```http
# Get only active records (what customers see)
GET /odata/v4/orders/Orders?$filter=IsActiveEntity eq true

# Get all my drafts
GET /odata/v4/orders/Orders?$filter=IsActiveEntity eq false
```

---

## Handling draft activation in a handler

You can run business logic during activation:

```javascript
this.on('draftActivate', 'Orders', async (req) => {
  const order = req.data;
  
  // Validate before activation
  if (order.total <= 0) {
    req.error(400, 'Order total must be greater than 0');
    return;
  }
  
  // Call next to complete standard activation
  return next();
});
```

---

## Conflict detection

If two users edit the same record simultaneously, CAP detects the conflict:
- User A creates an edit draft
- User B tries to create an edit draft for the same record
- CAP returns HTTP 409 Conflict

Your Fiori app can display a "Another user is editing" message using the `HasDraftEntity` field.

---

## Draft with compositions

Drafts work recursively through Compositions:

```cds
@odata.draft.enabled
entity Orders as projection on db.Orders;
// OrderItems (Composition of Orders) automatically gets draft support too
```

Editing an Order draft also tracks edits to its OrderItems in draft.

---

## When to use draft

✅ Use draft when:
- Complex forms with many fields
- Business processes requiring review before save
- Multi-step wizards

❌ Skip draft for:
- Simple lookup/codelist maintenance
- Admin-only tables
- Real-time data (it adds overhead)

---

## Checkpoint ✓
- [ ] Can you enable draft on a service entity?
- [ ] Can you walk through the full draft lifecycle in REST Client?
- [ ] Do you know what `IsActiveEntity` and `HasDraftEntity` mean?
$md$ WHERE slug = 'cap-18-draft';


UPDATE public.topics SET status = 'published', content_md = $md$
# Lesson 19 — Hierarchical Data Modeling

## What you'll learn
How to model tree and parent-child structures in CDS, recursive associations, and how to query hierarchies efficiently in HANA.

---

## Modeling a hierarchy with recursive association

```cds
entity Categories {
  key ID     : UUID;
      name   : String(100) not null;
      parent : Association to Categories;       // self-reference
      children: Association to many Categories
                  on children.parent = $self;   // backlink
}
```

This creates a simple parent-child tree. Any Category can have a parent and multiple children.

---

## Querying a hierarchy

```http
# Get root categories (no parent)
GET /odata/v4/catalog/Categories?$filter=parent_ID eq null

# Get children of a category
GET /odata/v4/catalog/Categories?$filter=parent_ID eq guid'abc-123'

# Expand one level
GET /odata/v4/catalog/Categories?$expand=children&$filter=parent_ID eq null

# Expand multiple levels (OData V4 supports nested expand)
GET /odata/v4/catalog/Categories
  ?$filter=parent_ID eq null
  &$expand=children($expand=children($expand=children))
```

---

## Flat hierarchy with path column

For deep trees (BOM, org charts), store a path string for efficient queries:

```cds
entity OrgNodes {
  key ID    : UUID;
      name  : String(100);
      parent: Association to OrgNodes;
      level : Integer;
      path  : String(1000);   // e.g. '/root/dept/team/alice'
}
```

```javascript
// Before create — set path and level
this.before('CREATE', 'OrgNodes', async (req) => {
  if (req.data.parent_ID) {
    const parent = await SELECT.one.from('OrgNodes').where({ ID: req.data.parent_ID });
    req.data.path  = `${parent.path}/${req.data.name}`;
    req.data.level = parent.level + 1;
  } else {
    req.data.path  = `/${req.data.name}`;
    req.data.level = 0;
  }
});
```

Query all descendants of a node efficiently:
```http
GET /odata/v4/catalog/OrgNodes?$filter=startswith(path,'/root/dept')
```

---

## OData Hierarchy annotations (Fiori Gantt/Tree Tables)

```cds
annotate CatalogService.Categories with @(
  Hierarchy.RecursiveHierarchy#: {
    NodeProperty            : ID,
    ParentNavigationProperty: parent,
    LevelProperty           : level,
    ExternalKeyProperty     : name
  }
);
```

With this annotation, SAP Fiori Tree Table can display the hierarchy natively.

---

## HANA Hierarchy functions (advanced)

In HANA, you can use built-in hierarchy functions via native SQL in a stored procedure:

```sql
-- Get all descendants of a node
SELECT * FROM HIERARCHY (
  SOURCE Categories
  JOIN PARENT KEY parent_ID
  SEARCH DEPTH FIRST
  START WHERE ID = '...'
);
```

Call this from CAP using `db.run()` with a native SQL statement.

---

## Bill of Materials (BOM) pattern

A common industry pattern — products made of sub-products:

```cds
entity BOMItems {
  key assembly  : Association to Products;   // parent product
  key component : Association to Products;   // child component
      quantity  : Decimal(10,3);
      unit      : String(3) default 'EA';
}
```

To get all components recursively (explode BOM):
```javascript
// Use HANA Hierarchy or a recursive CTE query
const sql = `
  WITH RECURSIVE bom AS (
    SELECT component_ID, quantity, 1 as level
    FROM BOMItems WHERE assembly_ID = ?
    UNION ALL
    SELECT b.component_ID, b.quantity, bom.level + 1
    FROM BOMItems b JOIN bom ON b.assembly_ID = bom.component_ID
  )
  SELECT * FROM bom
`;
const result = await db.run(sql, [assemblyId]);
```

---

## Checkpoint ✓
- [ ] Can you define a self-referencing `Categories` entity?
- [ ] Can you query root nodes and expand one level?
- [ ] Do you understand the path column optimization for deep trees?
$md$ WHERE slug = 'cap-19-hierarchy';


UPDATE public.topics SET status = 'published', content_md = $md$
# Lesson 20 — Extending & Annotating Models

## What you'll learn
How to use `extend` and `annotate` to add fields, associations, and annotations to existing CDS models — essential for plug-in architectures, extensibility, and keeping base models clean.

---

## `extend` — add fields to existing entities

```cds
// Base model (e.g. in a shared package)
entity Orders {
  key ID    : UUID;
      total : Decimal(10,2);
      status: String(20);
}

// Extension (in your project)
extend Orders with {
  deliveryDate  : Date;
  specialNotes  : LargeString;
  priority      : Integer default 2;
}
```

After extending, `Orders` has all original fields PLUS the new ones. The extension is applied at compile time.

---

## Extending from another file

```cds
// my-extensions.cds
using { com.myapp.Orders } from '../db/schema';

extend com.myapp.Orders with {
  internalRef : String(30);
  costCenter  : String(10);
}
```

---

## `annotate` — add annotations to existing elements

```cds
// Add Fiori annotations to a model you don't own
using CatalogService from './catalog-service';

annotate CatalogService.Books with @(
  UI.LineItem: [
    { Value: title,  Label: 'Title'  },
    { Value: price,  Label: 'Price'  },
    { Value: stock,  Label: 'In Stock' }
  ]
);

// Annotate a specific field
annotate CatalogService.Books with {
  title @(
    title: 'Book Title',
    UI.HiddenFilter: true
  );
  price @(
    title: 'List Price (USD)',
    Measures.ISOCurrency: 'USD'
  );
};
```

---

## Best practice: separate annotation files

Keep your data model clean by putting all UI annotations in a separate file:

```
srv/
├── catalog-service.cds           ← service definition (no UI annotations)
├── catalog-service.js            ← handlers
├── fiori/
│   ├── books-list.cds            ← List Report annotations
│   └── books-detail.cds          ← Object Page annotations
```

```cds
// srv/fiori/books-list.cds
using CatalogService from '../catalog-service';

annotate CatalogService.Books with @(
  UI.LineItem: [ ... ],
  UI.SelectionFields: [ price, author_ID ]
);
```

---

## Extending associations

```cds
entity Customers {
  key ID   : UUID;
      name : String;
}

// Add a backlink association
extend Customers with {
  orders: Association to many Orders on orders.customer = $self;
}
```

---

## Extending services

```cds
// Add a new entity to an existing service
extend service CatalogService with {
  entity Promotions as projection on db.Promotions;
  action applyDiscount(bookID: UUID, pct: Decimal) returns Books;
}
```

---

## Conditional extensions with aspects

A clean pattern for SaaS extensibility — let customers add fields without modifying the base model:

```cds
// Base: core fields only
entity Orders : cuid, managed {
  total  : Decimal(10,2);
  status : OrderStatus;
}

// Extension point defined in base
extend Orders with CustomerExtension;

// Customer A's extension (in their namespace)
aspect CustomerExtension {
  customerPO  : String(30);
  budgetCode  : String(10);
}
```

---

## Annotation precedence

When multiple annotations target the same element, the last one wins:

```cds
// File 1
annotate Books with { title @title: 'Title'; }

// File 2 (loaded after File 1)
annotate Books with { title @title: 'Book Title'; }
// Result: @title is 'Book Title'
```

Control load order with explicit `using` statements or directory structure.

---

## Checkpoint ✓
- [ ] Can you add 3 new fields to an existing entity with `extend`?
- [ ] Can you add `@UI.LineItem` to a service entity using `annotate` in a separate file?
- [ ] Do you understand the difference between `extend` (adds fields) and `annotate` (adds metadata)?
$md$ WHERE slug = 'cap-20-extend';


UPDATE public.topics SET status = 'published', content_md = $md$
# Lesson 21 — Input Validation & Constraints

## What you'll learn
All the ways CAP validates input automatically — schema-level constraints, custom handler validation, and best practices for consistent error handling across your service.

---

## Automatic constraints from CDS

CAP enforces these constraints on every CREATE and UPDATE without any handler code:

| CDS Declaration | What CAP validates |
|-----------------|-------------------|
| `not null` | Field must be present and non-null |
| `@mandatory` | Field must be present and non-empty |
| `enum` type | Value must be in the enum list |
| `@assert.range: [min, max]` | Number must be in range |
| `@assert.format: 'regex'` | String must match the regex |
| `@assert.unique` | Value must be unique in the table |
| `String(n)` | String length cannot exceed n |
| `Decimal(p,s)` | Number precision/scale must fit |

---

## Practical validation setup

```cds
entity Products {
  key ID : UUID;

  @mandatory
  @title: 'Product Name'
  name : String(100);

  @assert.range: [0.01, 999999.99]
  price : Decimal(10,2);

  @assert.range: [0, 999999]
  stock : Integer default 0;

  @assert.unique
  @assert.format: '^[A-Z]{3}-[0-9]{6}$'
  sku : String(10);

  status : ProductStatus;   // enum — validated automatically
}
```

POST with invalid data:
```json
{ "price": -5, "sku": "wrong" }
```
Returns HTTP 400 with structured errors for every violation.

---

## Custom validation in handlers

For business rules that can't be expressed in CDS:

```javascript
this.before('CREATE', 'Orders', async (req) => {
  const { items } = req.data;

  // Check that order has at least one item
  if (!items || items.length === 0) {
    req.error(400, 'ORDER_EMPTY', 'An order must have at least one item');
  }

  // Check stock availability
  for (const item of items || []) {
    const product = await SELECT.one.from('Products')
      .columns('stock')
      .where({ ID: item.product_ID });
    
    if (!product) {
      req.error(404, 'PRODUCT_NOT_FOUND', `Product ${item.product_ID} not found`);
    }
    if (product.stock < item.qty) {
      req.error(409, 'INSUFFICIENT_STOCK', 
        `Only ${product.stock} units of product ${item.product_ID} available`);
    }
  }
});
```

---

## `req.error` vs `req.reject`

```javascript
// req.error — collects errors, continues processing (all items validated)
req.error(400, 'Field X is invalid');
req.error(400, 'Field Y is also invalid');
// Response includes BOTH errors

// req.reject — throws immediately, stops processing
req.reject(403, 'You do not have permission');
// Only this error is returned
```

---

## Structured error messages

```javascript
req.error({
  code    : 'STOCK_INSUFFICIENT',
  message : `Only {0} units available, {1} requested`,
  args    : [product.stock, item.qty],
  target  : 'qty',           // highlight this field in the UI
  status  : 409
});
```

The `target` field tells Fiori Elements which form field to highlight in red.

---

## Cross-field validation

```javascript
this.before(['CREATE', 'UPDATE'], 'Promotions', (req) => {
  const { validFrom, validTo, discountPct } = req.data;
  
  if (validFrom && validTo && validFrom >= validTo) {
    req.error(400, 'Valid-from must be before valid-to', 'validFrom');
  }
  
  if (discountPct !== undefined && (discountPct < 1 || discountPct > 99)) {
    req.error(400, 'Discount must be between 1% and 99%', 'discountPct');
  }
});
```

---

## Validate on UPDATE — partial data challenge

On PATCH, only changed fields are in `req.data`. To validate against the full record, merge with existing data:

```javascript
this.before('UPDATE', 'Products', async (req) => {
  // Load current state
  const current = await SELECT.one.from('Products').where({ ID: req.params[0].ID });
  
  // Merge: current + incoming changes
  const merged = { ...current, ...req.data };
  
  // Validate the merged result
  if (merged.price < merged.minPrice) {
    req.error(400, `Price ${merged.price} cannot be below minimum ${merged.minPrice}`);
  }
});
```

---

## Checkpoint ✓
- [ ] Can you add `@mandatory`, `@assert.range`, `@assert.format`, and `@assert.unique` to a single entity?
- [ ] Can you write a handler that validates stock before creating an order?
- [ ] Do you know when to use `req.error` vs `req.reject`?
$md$ WHERE slug = 'cap-21-input-validation';


UPDATE public.topics SET status = 'published', content_md = $md$
# Lesson 22 — CDS Modeling Best Practices

## What you'll learn
Industry-level patterns for designing CDS models that scale — normalization rules, when to compose vs associate, lean services, and managing complexity in large enterprise projects.

---

## Rule 1: Entity = thing, Service = task

**Entity** = a noun that your business cares about (Order, Product, Customer)
**Service** = a task a user performs (Place an Order, Browse Products, Manage Customers)

```cds
// ❌ Bad: one mega-service exposing everything
service EverythingService {
  entity Orders, Products, Customers, Invoices, Payments ...
}

// ✅ Good: task-oriented services
service ShopService     { @readonly entity Products; entity Cart; entity Orders; }
service BackofficeService { entity Products; entity Pricing; entity Inventory; }
service FinanceService  { @readonly entity Orders; entity Invoices; entity Payments; }
```

---

## Rule 2: Composition for ownership, Association for reference

```cds
// ✅ Composition — items owned by order
entity Orders {
  items: Composition of many OrderItems on items.order = $self;
}

// ✅ Association — product referenced (exists independently)
entity OrderItems {
  product: Association to Products;
}

// ❌ Wrong — Products don't belong to an order
entity Orders {
  products: Composition of many Products on ...;  // wrong!
}
```

**Decision rule**: Can the child exist without the parent? Yes → Association. No → Composition.

---

## Rule 3: Separate data model from service model

```cds
// db/schema.cds — full database schema (all fields)
entity Products : cuid, managed {
  name, price, cost, margin, internalCode, supplierRef, ...
}

// srv/shop.cds — expose only what customers need
service ShopService {
  entity Products as select from db.Products {
    ID, name, price
    // cost, margin, internalCode NOT exposed
  }
}
```

Never put service-only projections or annotations in your `db/` files.

---

## Rule 4: Use aspects for cross-cutting concerns

Instead of duplicating fields:

```cds
// ❌ Repeating audit fields in every entity
entity Orders   { createdAt: Timestamp; createdBy: String; ... }
entity Products { createdAt: Timestamp; createdBy: String; ... }
entity Customers{ createdAt: Timestamp; createdBy: String; ... }

// ✅ Use managed aspect
entity Orders    : managed { ... }
entity Products  : managed { ... }
entity Customers : managed { ... }
```

Define your own aspects for domain-specific cross-cutting fields:
```cds
aspect Reviewable {
  reviewedBy : String(100);
  reviewedAt : Timestamp;
  reviewNote : String(500);
}

entity Contracts : cuid, managed, Reviewable { ... }
entity Invoices  : cuid, managed, Reviewable { ... }
```

---

## Rule 5: Avoid over-normalization

Don't normalize everything just because you can:

```cds
// ❌ Over-normalized — pointless join for a simple string
entity Countries { key code: String(2); name: String(50); }
entity Addresses { country: Association to Countries; }

// ✅ Good enough — unless you need to query by country name
entity Addresses { country: String(2); }
```

Normalize when you need referential integrity, reporting by the FK value, or when the child data changes independently of the parent.

---

## Rule 6: Keep entities focused

An entity should represent exactly one concept. If an entity has more than ~15 fields, ask: is this two entities?

```cds
// ❌ God entity
entity Orders {
  // Order fields... x10
  // Customer fields... x5 (should be Customer entity)
  // Shipping fields... x5 (should be ShippingDetails composition)
  // Payment fields... x8 (should be Payment composition)
}

// ✅ Split by concern
entity Orders : cuid, managed {
  customer  : Association to Customers;
  shipping  : Composition of one ShippingDetails on shipping.order = $self;
  payment   : Composition of one PaymentDetails  on payment.order  = $self;
  items     : Composition of many OrderItems      on items.order   = $self;
  total     : Decimal(12,2);
  status    : OrderStatus;
}
```

---

## Rule 7: Version your public APIs

For services exposed externally, use versioned paths:

```cds
@(path: '/api/v1/catalog')
service CatalogServiceV1 { ... }

@(path: '/api/v2/catalog')
service CatalogServiceV2 { ... }
```

This lets you evolve the API without breaking existing clients.

---

## Rule 8: Document with comments and @Core.Description

```cds
/**
 * The central product catalog.
 * Updated by the Merchandise team.
 */
@Core.Description: 'Product catalog — read-only for all authenticated users'
service CatalogService {

  /**
   * Books available for purchase.
   * Filtered to show only active books (status = 'active').
   */
  @readonly
  entity Books as select from db.Books where status = 'active';
}
```

These comments appear in the OData metadata and OpenAPI documentation automatically.

---

## Checklist before releasing a model

- [ ] Every entity has a UUID key via `cuid`
- [ ] Mutable entities use `managed` for audit trail
- [ ] Composition used for parent-child (not Association)
- [ ] Service layer exposes only the fields consumers need
- [ ] Validation annotations on all user-input fields
- [ ] Annotations in separate `fiori-annotations.cds` file
- [ ] Namespaces match `com.company.project` convention

**Module 2 complete!** In Module 3 we move to service development — writing custom handlers, actions, error handling, and connecting to external systems.
$md$ WHERE slug = 'cap-22-modeling-patterns';

-- Verify Module 2
SELECT slug, status, LEFT(content_md, 60) AS preview
FROM public.topics WHERE slug LIKE 'cap-1%' OR slug LIKE 'cap-2%' ORDER BY slug;
