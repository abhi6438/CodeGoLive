# ⚔️ CodeGoLive Arena — Implementation Tracker

> **Goal:** Build a real-time competitive quiz system on top of CodeGoLive.
> Track progress by checking off items as they are completed.

---

## Phase 1 — Foundation: Database + Scoring Engine
**Week 1–2**

### Supabase Schema (`supabase/migrations/arena_schema.sql`)
- [ ] Create `arena_matches` table
- [ ] Create `arena_match_players` table
- [ ] Create `arena_match_events` table (chat / reactions / taunts)
- [ ] Create `arena_teams` table
- [ ] Create `arena_team_members` table
- [ ] Create `arena_challenges` table
- [ ] Create `arena_quests` table
- [ ] Create `arena_achievements` table
- [ ] Create `arena_leaderboard` table
- [ ] Create `arena_spin_log` table
- [ ] Add RLS policies for all 10 tables
- [ ] Add `total_xp`, `total_ap`, `arena_wins`, `streak` columns to `profiles`
- [ ] Enable Realtime on `arena_matches`, `arena_match_players`, `arena_match_events`

### Backend Services
- [ ] `backend/services/arena_score.py` — time multiplier + combo engine
- [ ] `backend/routers/arena.py` — POST `/api/arena/match/create`
- [ ] `backend/routers/arena.py` — POST `/api/arena/match/join`
- [ ] `backend/routers/arena.py` — POST `/api/arena/match/answer` (server-side scoring)
- [ ] `backend/routers/arena.py` — GET `/api/arena/match/{id}/result`
- [ ] Register arena router in `backend/main.py`
- [ ] Write unit tests for scoring engine

---

## Phase 2 — Live Match: React + Realtime
**Week 3–4**

- [ ] `frontend/src/hooks/useArenaMatch.js` — Supabase Realtime hook
- [ ] `frontend/src/pages/ArenaLobby.jsx` — Create / Join room tabs
- [ ] `frontend/src/pages/ArenaMatch.jsx` — Timer ring, questions, answer buttons
- [ ] Wire answer submission → `/api/arena/match/answer` → update score UI
- [ ] `frontend/src/pages/ArenaResult.jsx` — XP/AP breakdown, winner reveal
- [ ] Add `/arena/lobby`, `/arena/match/:id`, `/arena/result/:id` routes to `App.jsx`

---

## Phase 3 — Social: Chat, Reactions, Taunts, Challenges
**Week 5–6**

- [ ] `frontend/src/components/arena/ArenaChatPanel.jsx`
- [ ] `frontend/src/components/arena/ArenaProvokeModal.jsx`
- [ ] Add reaction bar (5 emoji buttons) to `ArenaMatch.jsx`
- [ ] `backend/routers/arena.py` — POST `/api/arena/challenge/send`
- [ ] `backend/routers/arena.py` — POST `/api/arena/challenge/respond`
- [ ] Challenge + My Team tabs in `ArenaLobby.jsx`
- [ ] `frontend/src/components/arena/ArenaChallengeCard.jsx`

---

## Phase 4 — Engagement: Quests, Trophies, Leaderboard, Spin Wheel
**Week 7–8**

- [ ] `backend/services/arena_quests.py` + `/api/arena/quests/*` endpoints
- [ ] `backend/services/arena_achievements.py` + achievement check on match end
- [ ] `frontend/src/pages/ArenaQuests.jsx`
- [ ] `frontend/src/pages/ArenaTrophies.jsx`
- [ ] `frontend/src/pages/ArenaLeaderboard.jsx`
- [ ] `backend/services/arena_spin.py` + `/api/arena/spin` endpoint
- [ ] `frontend/src/pages/ArenaSpinWheel.jsx`
- [ ] Supabase cron job: weekly leaderboard reset (Mondays 00:00 UTC)

---

## Phase 5 — Polish: Hub, Dashboard Integration, Deploy
**Week 9**

- [x] `frontend/src/pages/ArenaHub.jsx` — Arena home screen ✅
- [x] Add ⚔️ Arena link to `Sidebar.jsx` ✅
- [x] Add `/arena` route to `App.jsx` ✅
- [ ] Add Arena entry card to `Dashboard.jsx`
- [ ] Add `<SEO>` to all Arena pages
- [ ] Wire push notifications for challenge invites
- [ ] End-to-end test: lobby → match → result → XP/AP credited
- [ ] Deploy and verify on Vercel

---

## Scoring Engine Reference

| Window | Tier | Mult |
|--------|------|------|
| 0–3 s  | ⚡ LIGHTNING | 5× |
| 3–6 s  | 🎯 SWIFT    | 3× |
| 6–12 s | ✓ SHARP     | 2× |
| 12–22 s| STEADY      | 1× |
| 22–30 s| 🐢 SLOW     | 0.5× |
| timeout| ✗ MISS      | 0× |

Combo: 3-in-a-row = 1.5×, 5+ in a row = 2×  
Formula: `xp = base_xp × time_mult × combo_mult`

---

## Spin Wheel Prizes

| Prize | Probability |
|-------|-------------|
| +50 AP | 25% |
| +150 AP | 20% |
| Power-Up | 20% |
| Cosmetic | 15% |
| +100 XP | 10% |
| 2× AP Next | 6% |
| 💰 JACKPOT +500 AP | 2% |
| Try Again | 2% |

1 free spin/day · Extra spins cost 50 AP · Jackpot capped 1×/week/user

---

*Last updated: Phase 5 started — ArenaHub live at `/arena`*
