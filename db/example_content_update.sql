-- Run this in the Supabase SQL editor to see the full content_md rendering
-- (explanation + code blocks + project structure + images) working on the
-- 0-SP-Test topic page. Uses dollar-quoting ($md$...$md$) instead of single
-- quotes so nothing inside the content (quotes, code, etc.) needs escaping -
-- this avoids the exact copy/paste quote issues we hit earlier.

update public.topics
set content_md = $md$
## What you'll do in this episode

Before touching any CAP or UI5 code, you need proof that your BTP trial and
Business Application Studio (BAS) actually work end to end. This episode is
that proof - the smallest possible project, scaffolded and running in the
browser.

### Step 1 - Create a Dev Space

Open BAS and create a **Full Stack Cloud Application** Dev Space. Give it any
name - this is throwaway, just for this episode.

### Step 2 - Scaffold the project

Open a terminal inside BAS and run:

```bash
mkdir 0-sp-test
cd 0-sp-test
npm init -y
npx cds init
```

### Step 3 - Project structure

Once `cds init` finishes, you should see this structure:

```
0-sp-test/
|-- app/
|-- db/
|-- srv/
|-- package.json
`-- README.md
```

Nothing in `db/` or `srv/` yet - that's fine, this episode is only proving
the tooling works, not building anything real.

### Step 4 - Run it

```bash
cds watch
```

You should see output ending in something like:

```
[cds] - server listening on { url: 'http://localhost:4004' }
```

Open the preview URL BAS gives you. You should land on a basic CAP welcome
page.

### What it should look like

![CDS welcome page in the browser](https://placehold.co/800x400/1e2761/ffffff?text=CDS+Welcome+Page)

*(Replace this with a real screenshot once you've recorded the episode -
upload it via the Admin panel or Supabase Storage, then swap the URL above.)*

---

If you saw the welcome page, your environment is confirmed working. Every
following episode builds on exactly this same toolchain.
$md$
where slug = '0-sp-test';
