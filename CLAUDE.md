# CodeGoLive — Project Memory

This file gives Claude full context on this project without needing the zip
re-uploaded or the history re-explained. Read this first in any new session.

## What this is
A course platform for a SAP BTP / CAP / SAPUI5 tutorial series (17 hands-on
apps across 6 modules, ending in a 4-part capstone). Delivers video + GitHub
link + written content per topic, gates progression topic-by-topic, and hosts
a threaded, moderated Q&A community (both per-topic and a general "Ask
Anything" section).

## Stack
- **Frontend:** React + Vite → deploys to Vercel
- **Backend:** FastAPI (Python) → deploys to Vercel as a serverless ASGI function
- **Database/Auth/Storage:** Supabase (Postgres + RLS + magic-link email auth)

## Repo layout
```
db/               schema.sql + seed.sql + rls.sql + certificates.sql
backend/          FastAPI app — api/index.py is the Vercel entrypoint
frontend/         React app (Vite)
README.md         full local setup + Vercel deploy steps
```

---

## STATUS: what's done

**Database**
- Full schema in `db/schema.sql`
- Auto-create-profile trigger on signup (`handle_new_user`)
- `db/seed.sql` — all 6 modules + 17 topics loaded and confirmed working
- `db/rls.sql` — RLS policies split into separate file for safe independent testing
- `db/certificates.sql` — certificates table + trigger that auto-issues cert when all 17 topics completed
- **RLS is currently NOT enabled** — run `db/rls.sql` in Supabase to enable (see Known Issues)

**Backend (all endpoints built and verified locally — 24 routes)**
- Auth: Supabase JWT verification, role resolution (learner/moderator/admin)
- `modules.py` — list modules, list topics per module
- `topics.py` — topic detail, mark progress, full-text search
- `questions.py` — create/list (topic-scoped AND general "Ask Anything"), tag attach/create
- `answers.py` — create (pending), accept, vote
- `replies.py` — create (nested, max depth 3, @mention resolution), vote
- `moderation.py` — pending queue (flagged-first), approve/reject
- `admin.py` — topic CRUD, user role management, tag merge, **tag listing** (`GET /api/admin/tags`)
- `notifications.py` — list, mark read
- `certificates.py` — `GET /api/certificates/me`, `GET /api/certificates/{user_id}/public`
- `moderation_filter.py` — word-list abuse pre-filter (flags only, never auto-rejects)

**Frontend (all pages built)**
- `Home.jsx` — module roadmap
- `ModulePage.jsx` — topic list with **live gating** (fetches user progress, locks topics until previous is completed)
- `TopicPage.jsx` — video embed, GitHub button, markdown content, Mark Complete, topic-scoped Q&A
- `Community.jsx` — general Ask Anything hub, activity stats, unanswered-nudge
- `QAThread.jsx` — full threaded Q&A: answers, nested replies, voting, accept-answer
- `Login.jsx` — magic-link email sign-in
- `SearchPage.jsx` — global full-text search wired to `/api/topics/search` (at `/search`)
- `CertificatePage.jsx` — `MyCertificatePage` at `/certificate`, `PublicCertificatePage` at `/certificates/:userId`
- `AdminDashboard.jsx` — now includes "Merge Tags" tile
- `AdminModeration.jsx` / `AdminTopics.jsx` / `AdminUsers.jsx`
- `AdminTopics.jsx` — topic content editor with **inline image upload** to Supabase Storage (`topic-images` bucket)
- `AdminTagMerge.jsx` — tag merge UI at `/admin/tags`
- `Navbar.jsx` — search link, 🔔 **notification bell** (dropdown, unread badge, mark-all-read), 🎓 My Cert link
- `NotificationBell.jsx` — standalone component consuming `/api/notifications`
- Navy/amber theme (`styles/global.css`)

**Confirmed working end-to-end (as of last session):**
- Backend loads, all routes register, server runs on :8000
- Frontend builds clean (`npm run build`), dev server runs on :5173
- Home page renders all 6 seeded modules correctly against live Supabase data

---

## STATUS: what's left

**Blocking / should do soon**
1. **Re-enable RLS properly.** Run `db/rls.sql` in the Supabase SQL editor.
   Once done, `AdminTopics.jsx` reads topics via the public Supabase client — this
   needs an admin-select policy or route through a FastAPI admin endpoint instead
   (see Known Issues).

**Not started at all**
2. **Seeding real content** — every topic's `video_url`, `github_url`, and
   `content_md` are currently empty. Fill in via `AdminTopics.jsx` (or bulk SQL)
   as episodes are recorded.
3. **Vercel deployment** — not yet deployed anywhere; still local-only.
   README has full deploy steps. `vercel.json` files exist in both `backend/` and
   `frontend/`. Need to create a `topic-images` Supabase Storage bucket (public)
   before the image upload widget works in production.

---

## Known issues / gotchas

- **RLS section of `schema.sql` fails when run in the Supabase web SQL editor.**
  Worked around by splitting RLS into `db/rls.sql`. Run it separately.
- **Copy/pasting large SQL files into Supabase's web editor is fragile** — paste
  in smaller chunks if errors occur.
- **`AdminTopics.jsx` reads topics via the public Supabase client** — works while
  RLS is off. Once RLS is enabled, add an admin-select policy or route through FastAPI.
- **Image upload bucket must be created manually** in Supabase Storage before the
  "Insert image" button works. Bucket name: `topic-images`, must be Public.

---

## Local dev quick-start (see README.md for full detail)
```bash
# backend
cd backend && source venv/bin/activate && uvicorn app.main:app --reload --port 8000

# frontend (separate terminal)
cd frontend && npm run dev
```
Promote yourself to admin after signing in:
```sql
update public.profiles set role = 'admin' where display_name = 'your-email-local-part';
```

## Conventions to keep consistent
- Topic slugs: lowercase, hyphenated, matching the `N-Name-Test` numbering
  (e.g. `3-crud-test`, `16-mp-1-test`)
- Every answer/reply ALWAYS requires moderator approval — never add an
  auto-approve path, even for "trusted" users, without deliberately
  revisiting that decision (it was an explicit product requirement)
- Brand name: **CodeGoLive** (one word, no "SAP" in the name — avoid
  trademark risk, see earlier design discussion)
