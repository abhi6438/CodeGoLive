# CodeGoLive

A course platform for the SAP BTP / CAP / SAPUI5 tutorial series — content delivery
(video + GitHub + explanation), gated topic-by-topic progression, and a threaded,
moderated Q&A community (both per-topic and general "Ask Anything").

## Stack
- **Frontend:** React (Vite) — deployed to Vercel
- **Backend:** FastAPI (Python) — deployed to Vercel as a serverless ASGI function
- **Database/Auth/Storage:** Supabase (Postgres + Row Level Security + magic-link auth)

## Project layout
```
db/           SQL schema + seed data (run in the Supabase SQL editor)
backend/      FastAPI app (Vercel serverless entrypoint in backend/api/index.py)
frontend/     React app (Vite)
```

---

## 1. Set up Supabase

1. Create a project at https://supabase.com.
2. Open the **SQL Editor** and run `db/schema.sql`, then `db/seed.sql`.
3. Go to **Authentication > Providers** and make sure **Email** (magic link) is enabled.
4. Go to **Project Settings > API** and copy:
   - `Project URL`
   - `anon public` key
   - `service_role` key (⚠️ secret — backend only, never in frontend code)
5. Go to **Project Settings > API > JWT Settings** and copy the **JWT Secret**.

## 2. Run the backend locally

```bash
cd backend
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env      # fill in SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, SUPABASE_JWT_SECRET
uvicorn app.main:app --reload --port 8000
```

Visit `http://localhost:8000/docs` to see the auto-generated API docs and confirm
it's running.

## 3. Run the frontend locally

```bash
cd frontend
npm install
cp .env.example .env      # fill in VITE_SUPABASE_URL, VITE_SUPABASE_ANON_KEY, VITE_API_URL
npm run dev
```

Visit `http://localhost:5173`.

## 4. Make yourself an admin

New signups default to the `learner` role. To promote your own account to `admin`
so you can reach `/admin`, run this once in the Supabase SQL editor after signing up:

```sql
update public.profiles set role = 'admin' where display_name = 'your-email-local-part';
```

---

## 5. Deploy to Vercel

Create **two separate Vercel projects** from this one repo (cleaner env vars/logs
than a single monorepo project):

### Backend project
- **Root directory:** `backend`
- **Framework preset:** Other
- Vercel auto-detects `backend/api/index.py` as a Python serverless function via
  `backend/vercel.json`.
- **Environment variables:** `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`,
  `SUPABASE_JWT_SECRET`, `ALLOWED_ORIGINS` (set this to your frontend's Vercel URL
  once you have it, comma-separated if you need more than one).

### Frontend project
- **Root directory:** `frontend`
- **Framework preset:** Vite
- **Environment variables:** `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`,
  `VITE_API_URL` (set this to your deployed backend project's URL, e.g.
  `https://codegolive-api.vercel.app`).

After both are deployed, go back to the **backend** project's env vars and update
`ALLOWED_ORIGINS` to the frontend's real Vercel URL, then redeploy the backend so
CORS allows requests from it.

---

## What's implemented vs. stubbed

**Fully implemented:**
- Course content (modules → topics), video embed, GitHub link, markdown content
  (code blocks, project structure, images)
- Gated progress marking (`Mark as Complete`)
- Threaded Q&A: questions (topic-scoped + general), answers, nested replies
  (max depth 3), voting, accept-answer
- Dual tagging: `#topic-tags` (free labels) and `@mentions` (resolved to real users)
- Moderation: every answer/reply requires approval; a lightweight word-list filter
  flags likely-abusive content to the top of the queue, but never auto-rejects
- Role-based access (learner / moderator / admin) with an admin panel for topics,
  users, and the moderation queue
- In-app notifications table (answered / mentioned / accepted)
- Full-text search indexes on questions and topics (Postgres `tsvector`)

**Stubbed / next steps (schema is ready, UI/wiring is not built yet):**
- Certificates on completing all topics
- Global search UI (the DB indexes exist; no search page yet)
- Notification bell/inbox UI (endpoints exist; no frontend view yet)
- Client-side gating UI on the module/topic list (currently shows all topics
  unlocked — wire `progress_status` from `/api/topics/{slug}` into the list view)
- Tag merge UI (endpoint exists in `/api/admin/tags/merge`)
- Image upload UI for topic content (use Supabase Storage; paste the resulting
  URL into the markdown editor for now)

---

## 6. Supabase Storage — image uploads

The topic content editor supports direct image uploads. Before using it:

1. Go to **Supabase Dashboard → Storage** and create a new bucket named **`topic-images`**.
2. Set the bucket to **Public** (so uploaded images render in the markdown).
3. (Optional) Add a Storage policy restricting uploads to `admin` role users only.

Images are uploaded from the Admin → Manage Topics editor and the public URL is
inserted as a markdown `![alt](url)` snippet at the cursor position.

---

## 7. Certificates

Certificates are auto-issued via a Postgres trigger (`db/certificates.sql`) the moment
a learner marks their last topic complete. To enable:

1. Run `db/certificates.sql` in the Supabase SQL editor (after `schema.sql`).
2. Learners can view their certificate at `/certificate`.
3. Public shareable links are at `/certificates/<user_id>`.

---

## 8. RLS (Row Level Security)

RLS policies are now in a separate file `db/rls.sql` — run it independently after
`schema.sql` so any policy errors don't affect the core schema. Once enabled,
`AdminTopics.jsx` must be updated to read topics via the FastAPI admin endpoint
instead of the public Supabase client (see CLAUDE.md Known Issues).
