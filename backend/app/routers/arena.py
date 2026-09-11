import math
import random
import string
from datetime import datetime, timezone
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from ..supabase_client import get_supabase
from ..auth import get_current_user, CurrentUser
from ..services.arena_score import calculate_score, server_timestamp_check
from ..services.arena_quests import (
    get_or_create_daily_quests, get_or_create_weekly_quests,
    update_quest_progress, claim_quest
)
from ..services.arena_achievements import (
    get_user_achievements, check_match_achievements, check_spin_achievement
)
from ..services.arena_spin import get_free_spin_status, perform_spin, get_spin_history, PRIZES

router = APIRouter(prefix="/api/arena", tags=["arena"])


# ── Level & Streak helpers ────────────────────────────────────────────────

def compute_level(xp: int) -> int:
    """Level 1 at 0 XP, grows with sqrt. Level ~10 at 4050 XP, ~20 at 19050 XP."""
    if xp <= 0:
        return 1
    return int(math.sqrt(xp / 50)) + 1

def xp_for_level(level: int) -> int:
    """Minimum XP to reach `level`."""
    if level <= 1:
        return 0
    return (level - 1) ** 2 * 50

def level_progress(xp: int) -> dict:
    lvl        = compute_level(xp)
    cur_floor  = xp_for_level(lvl)
    next_floor = xp_for_level(lvl + 1)
    xp_in      = xp - cur_floor
    xp_range   = next_floor - cur_floor
    pct        = min(100, round((xp_in / xp_range) * 100)) if xp_range > 0 else 100
    return {
        "level":            lvl,
        "xp":               xp,
        "xp_in_level":      xp_in,
        "xp_for_next_level": xp_range,
        "xp_to_next":       max(0, next_floor - xp),
        "progress_pct":     pct,
    }

def streak_multiplier(streak_days: int) -> float:
    if streak_days >= 30: return 2.0
    if streak_days >= 7:  return 1.5
    if streak_days >= 3:  return 1.2
    return 1.0

def _update_activity_streak(sb, user_id: str, profile: dict) -> tuple:
    """
    Update activity streak for user. Returns (new_streak_days, is_first_match_today, xp_multiplier).
    Modifies profiles in-place and returns the multiplier to apply to XP earned this match.
    """
    from datetime import date as _date
    today         = datetime.now(timezone.utc).date()
    last_raw      = profile.get("last_activity_date")
    cur_streak    = profile.get("activity_streak_days", 0) or 0

    if last_raw:
        last_date = _date.fromisoformat(str(last_raw)[:10])
        delta     = (today - last_date).days
        if delta == 0:
            # Already played today — no streak change, no daily bonus
            mult = streak_multiplier(cur_streak)
            return cur_streak, False, mult
        elif delta == 1:
            new_streak = cur_streak + 1
        else:
            new_streak = 1   # missed days → reset
    else:
        new_streak = 1

    mult = streak_multiplier(new_streak)
    sb.table("profiles").update({
        "activity_streak_days": new_streak,
        "last_activity_date":   today.isoformat(),
    }).eq("id", user_id).execute()
    return new_streak, True, mult   # True = first match today


DAILY_AP_BONUS = 25   # AP awarded on first match of each day


def _apply_progression(sb, user_id: str, earned_xp: int, earned_ap: int, is_winner: bool) -> dict:
    """
    Fetch profile, apply streak multiplier to XP, add daily AP bonus if first match today,
    recompute level, persist everything, and return the final amounts awarded.
    """
    pr = (sb.table("profiles")
            .select("arena_xp, arena_ap, arena_wins, arena_streak, activity_streak_days, last_activity_date, arena_level")
            .eq("id", user_id).single().execute().data or {})

    streak_days, first_today, mult = _update_activity_streak(sb, user_id, pr)

    final_xp = round(earned_xp * mult)
    final_ap = earned_ap + (DAILY_AP_BONUS if first_today else 0)

    new_xp    = (pr.get("arena_xp") or 0) + final_xp
    new_ap    = (pr.get("arena_ap") or 0) + final_ap
    new_level = compute_level(new_xp)

    upd: dict = {
        "arena_xp":    new_xp,
        "arena_ap":    new_ap,
        "arena_level": new_level,
    }
    if is_winner:
        upd["arena_wins"]   = (pr.get("arena_wins")   or 0) + 1
        upd["arena_streak"] = (pr.get("arena_streak") or 0) + 1
    else:
        upd["arena_streak"] = 0   # win-streak resets on loss

    sb.table("profiles").update(upd).eq("id", user_id).execute()

    return {
        "xp_earned":     final_xp,
        "ap_earned":     final_ap,
        "streak_mult":   mult,
        "daily_bonus":   first_today,
        "streak_days":   streak_days,
        "new_level":     new_level,
        "leveled_up":    new_level > compute_level(new_xp - final_xp),
    }


def _gen_code(n=6):
    return "".join(random.choices(string.ascii_uppercase + string.digits, k=n))


# ── Pydantic models ────────────────────────────────────────────────────────

class CreateMatchRequest(BaseModel):
    topic_id: str = "sap-btp"
    max_questions: int = 10

class JoinMatchRequest(BaseModel):
    room_code: str

class SubmitAnswerRequest(BaseModel):
    match_id: str
    question_id: str
    answer_index: int
    time_remaining: int
    question_sent_at: str

class ChatRequest(BaseModel):
    match_id: str
    message: str

class TauntRequest(BaseModel):
    match_id: str
    taunt_key: str

class SpinRequest(BaseModel):
    is_free: bool

class ClaimQuestRequest(BaseModel):
    quest_id: str


# ── Match ──────────────────────────────────────────────────────────────────

@router.post("/match/create")
async def create_match(body: CreateMatchRequest, user: CurrentUser = Depends(get_current_user)):
    sb = get_supabase()
    room_code = _gen_code()
    res = sb.table("arena_matches").insert({
        "host_id": user.id,
        "topic_id": body.topic_id,
        "room_code": room_code,
        "max_questions": body.max_questions,
        "status": "waiting",
    }).execute()
    if not res.data:
        raise HTTPException(status.HTTP_500_INTERNAL_SERVER_ERROR, "Failed to create match")
    match = res.data[0]
    sb.table("arena_match_players").insert({
        "match_id": match["id"], "user_id": user.id, "is_host": True,
    }).execute()
    return {"match_id": match["id"], "room_code": room_code}


@router.post("/match/join")
async def join_match(body: JoinMatchRequest, user: CurrentUser = Depends(get_current_user)):
    sb = get_supabase()
    res = sb.table("arena_matches").select("*").eq("room_code", body.room_code.upper().strip()).execute()
    if not res.data:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Room not found")
    match = res.data[0]
    if match["status"] != "waiting":
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Match already started")
    existing = sb.table("arena_match_players").select("id").eq("match_id", match["id"]).eq("user_id", user.id).execute()
    if not existing.data:
        sb.table("arena_match_players").insert({
            "match_id": match["id"], "user_id": user.id, "is_host": False,
        }).execute()
    return {"match_id": match["id"], "room_code": match["room_code"]}


@router.get("/match/open")
async def open_matches(user: CurrentUser = Depends(get_current_user)):
    sb = get_supabase()
    rows = sb.table("arena_matches").select("id, room_code, topic_id, max_questions, created_at").eq("status", "waiting").order("created_at", desc=True).limit(20).execute().data or []
    return rows


@router.get("/match/{match_id}")
async def get_match(match_id: str, user: CurrentUser = Depends(get_current_user)):
    sb = get_supabase()
    match = sb.table("arena_matches").select("*").eq("id", match_id).single().execute().data
    if not match:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Match not found")
    players = sb.table("arena_match_players").select("*").eq("match_id", match_id).execute().data or []
    ids = [p["user_id"] for p in players]
    profs = {}
    if ids:
        pr = sb.table("profiles").select("id, display_name").in_("id", ids).execute().data or []
        profs = {p["id"]: p["display_name"] for p in pr}
    for p in players:
        p["display_name"] = profs.get(p["user_id"], "Player")
    questions = []
    if match.get("status") == "active" and match.get("question_ids"):
        q_rows = sb.table("assessment_questions").select("id, question, options").in_("id", match["question_ids"]).execute().data or []
        q_map = {q["id"]: q for q in q_rows}
        questions = [{"id": qid, "question": q_map[qid]["question"], "options": q_map[qid]["options"]} for qid in match["question_ids"] if qid in q_map]
    return {"match": match, "players": players, "questions": questions}


@router.post("/match/{match_id}/start")
async def start_match(match_id: str, user: CurrentUser = Depends(get_current_user)):
    sb = get_supabase()
    match = sb.table("arena_matches").select("*").eq("id", match_id).single().execute().data
    if not match:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Match not found")
    if match["host_id"] != user.id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Only host can start")
    if match["status"] != "waiting":
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Cannot start")
    topic_id = match.get("topic_id", "sap-btp") or "sap-btp"
    q_query = sb.table("assessment_questions").select("id, question, options, correct_option").eq("course_id", topic_id)
    qs = q_query.limit(300).execute().data or []
    # Fallback to all questions if topic has none
    if not qs:
        qs = sb.table("assessment_questions").select("id, question, options, correct_option").limit(300).execute().data or []
    random.shuffle(qs)
    qs = qs[:match.get("max_questions", 10)]
    q_ids = [q["id"] for q in qs]
    sb.table("arena_matches").update({
        "status": "active",
        "started_at": datetime.now(timezone.utc).isoformat(),
        "question_ids": q_ids,
        "current_question_index": 0,
    }).eq("id", match_id).execute()
    # Pick a random first player
    players_in_match = sb.table("arena_match_players").select("user_id").eq("match_id", match_id).execute().data or []
    first_player_id = random.choice(players_in_match)["user_id"] if players_in_match else match["host_id"]
    # Emit the first turn event so both players know who goes first
    try:
        sb.table("arena_match_events").insert({
            "match_id": match_id, "user_id": user.id,
            "event_type": "turn_change",
            "payload": {
                "active_player_id": first_player_id,
                "question_index": 0,
                "reason": "start",
                "total_questions": len(q_ids),
            },
        }).execute()
    except Exception:
        pass  # fallback: frontend uses match.host_id directly when no events exist
    return {"status": "active", "questions": [{"id": q["id"], "question": q["question"], "options": q["options"]} for q in qs]}


@router.post("/match/answer")
async def submit_answer(body: SubmitAnswerRequest, user: CurrentUser = Depends(get_current_user)):
    sb = get_supabase()
    match = sb.table("arena_matches").select("*").eq("id", body.match_id).single().execute().data
    if not match or match["status"] != "active":
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Match not active")

    # ── Get current turn state from latest turn_change event ──
    turn_events = sb.table("arena_match_events").select("payload").eq("match_id", body.match_id).eq("event_type", "turn_change").order("created_at", desc=True).limit(1).execute().data or []
    if turn_events:
        turn = turn_events[0]["payload"]
        active_id = turn.get("active_player_id")
        q_index = turn.get("question_index", 0)
        total_qs = turn.get("total_questions", match.get("max_questions", 10))
    else:
        # Fallback: no turn_change events yet (migration not applied or first turn not emitted)
        # Allow host to go first at question 0
        active_id = match.get("host_id")
        q_index = match.get("current_question_index", 0)
        total_qs = match.get("max_questions", 10)

    # ── Only the active player can submit ──
    if user.id != active_id:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Not your turn")

    player = sb.table("arena_match_players").select("*").eq("match_id", body.match_id).eq("user_id", user.id).single().execute().data
    if not player:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Not in match")

    # answer_index == -1 means timeout (no answer)
    timeout = body.answer_index == -1
    correct = False
    score = {"xp": 0, "ap": 0, "streak_after": 0, "tier": "none", "tier_emoji": ""}

    if not timeout:
        question = sb.table("assessment_questions").select("correct_option").eq("id", body.question_id).single().execute().data
        if not question:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "Question not found")
        correct = body.answer_index == question["correct_option"]
        try:
            q_sent = datetime.fromisoformat(body.question_sent_at.replace("Z", "+00:00"))
            auth_time = server_timestamp_check(body.time_remaining, q_sent)
        except Exception:
            auth_time = max(0, min(30, body.time_remaining))
        if correct:
            streak = (player.get("streak", 0) or 0)
            score = calculate_score(auth_time, streak, correct)
            sb.table("arena_match_players").update({
                "score_xp": (player.get("score_xp") or 0) + score["xp"],
                "score_ap": (player.get("score_ap") or 0) + score["ap"],
                "streak": score["streak_after"],
                "correct_count": (player.get("correct_count") or 0) + 1,
                "total_answered": (player.get("total_answered") or 0) + 1,
            }).eq("match_id", body.match_id).eq("user_id", user.id).execute()
        else:
            sb.table("arena_match_players").update({
                "streak": 0,
                "total_answered": (player.get("total_answered") or 0) + 1,
            }).eq("match_id", body.match_id).eq("user_id", user.id).execute()

    # ── Determine next turn ──
    players = sb.table("arena_match_players").select("user_id").eq("match_id", body.match_id).execute().data or []
    other_id = next((p["user_id"] for p in players if p["user_id"] != user.id), None)

    if correct:
        # Correct: advance question, other player gets next question first
        next_index = q_index + 1
        if next_index >= total_qs or not match.get("question_ids") or next_index >= len(match["question_ids"]):
            # All questions done — end match
            all_players = sb.table("arena_match_players").select("*").eq("match_id", body.match_id).order("score_xp", desc=True).execute().data or []
            winner_id = all_players[0]["user_id"] if all_players else None
            sb.table("arena_matches").update({
                "status": "finished",
                "finished_at": datetime.now(timezone.utc).isoformat(),
                "winner_id": winner_id,
                "current_question_index": next_index,
            }).eq("id", body.match_id).execute()
            for p in all_players:
                _apply_progression(sb, p["user_id"], p.get("score_xp") or 0, p.get("score_ap") or 0, p["user_id"] == winner_id)
            sb.table("arena_match_events").insert({
                "match_id": body.match_id, "user_id": user.id,
                "event_type": "match_end",
                "payload": {"winner_id": winner_id},
            }).execute()
            # Advance tournament bracket if applicable
            tm_row = (sb.table("arena_tournament_matches")
                        .select("tournament_id")
                        .eq("match_id", body.match_id)
                        .maybe_single().execute().data)
            if tm_row and winner_id:
                try:
                    _advance_tournament(sb, tm_row["tournament_id"], body.match_id, winner_id)
                except Exception:
                    pass  # Never break a match over tournament logic
            return {"correct": True, "score": score, "match_ended": True, "winner_id": winner_id}
        # Advance to next question, other player goes first
        next_active = other_id if other_id else user.id
        sb.table("arena_matches").update({"current_question_index": next_index}).eq("id", body.match_id).execute()
        sb.table("arena_match_events").insert({
            "match_id": body.match_id, "user_id": user.id,
            "event_type": "turn_change",
            "payload": {"active_player_id": next_active, "question_index": next_index, "reason": "correct", "total_questions": total_qs},
        }).execute()
    else:
        # Wrong or timeout — pass turn to other player, SAME question
        next_active = other_id if other_id else user.id
        reason = "timeout" if timeout else "wrong"
        sb.table("arena_match_events").insert({
            "match_id": body.match_id, "user_id": user.id,
            "event_type": "turn_change",
            "payload": {"active_player_id": next_active, "question_index": q_index, "reason": reason, "total_questions": total_qs},
        }).execute()

    return {"correct": correct, "timeout": timeout, "score": score, "match_ended": False}


@router.post("/match/{match_id}/end")
async def end_match(match_id: str, user: CurrentUser = Depends(get_current_user)):
    sb = get_supabase()
    match = sb.table("arena_matches").select("*").eq("id", match_id).single().execute().data
    if not match:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Match not found")
    if match["host_id"] != user.id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Only host can end")
    players = sb.table("arena_match_players").select("*").eq("match_id", match_id).order("score_xp", desc=True).execute().data or []
    winner_id = players[0]["user_id"] if players else None
    sb.table("arena_matches").update({
        "status": "finished",
        "finished_at": datetime.now(timezone.utc).isoformat(),
        "winner_id": winner_id,
    }).eq("id", match_id).execute()
    for p in players:
        _apply_progression(sb, p["user_id"], p.get("score_xp") or 0, p.get("score_ap") or 0, p["user_id"] == winner_id)
    sb.table("arena_match_events").insert({
        "match_id": match_id, "user_id": user.id,
        "event_type": "match_end",
        "payload": {"winner_id": winner_id},
    }).execute()
    # Advance tournament bracket if applicable
    tm_row = (sb.table("arena_tournament_matches")
                .select("tournament_id")
                .eq("match_id", match_id)
                .maybe_single().execute().data)
    if tm_row and winner_id:
        try:
            _advance_tournament(sb, tm_row["tournament_id"], match_id, winner_id)
        except Exception:
            pass
    return {"winner_id": winner_id, "players": players}


# ── Chat / Taunts ─────────────────────────────────────────────────────────

TAUNTS = {
    "too_slow": {"emoji": "🐢", "text": "Too slow!"},
    "not_bad":  {"emoji": "👏", "text": "Not bad…"},
    "nice_try": {"emoji": "😅", "text": "Nice try!"},
    "gg":       {"emoji": "🤝", "text": "GG!"},
    "on_fire":  {"emoji": "🔥", "text": "I'm on fire!"},
    "scared":   {"emoji": "😱", "text": "Are you scared?"},
    "easy":     {"emoji": "😎", "text": "Too easy."},
}


@router.post("/match/chat")
async def send_chat(body: ChatRequest, user: CurrentUser = Depends(get_current_user)):
    sb = get_supabase()
    sb.table("arena_match_events").insert({
        "match_id": body.match_id, "user_id": user.id,
        "event_type": "chat", "payload": {"message": body.message[:200]},
    }).execute()
    return {"ok": True}


@router.post("/match/taunt")
async def send_taunt(body: TauntRequest, user: CurrentUser = Depends(get_current_user)):
    sb = get_supabase()
    taunt = TAUNTS.get(body.taunt_key, {"emoji": "⚡", "text": "!"})
    sb.table("arena_match_events").insert({
        "match_id": body.match_id, "user_id": user.id,
        "event_type": "taunt", "payload": {"taunt_key": body.taunt_key, **taunt},
    }).execute()
    return {"ok": True}


@router.get("/match/{match_id}/events")
async def get_events(match_id: str, since: Optional[str] = None, user: CurrentUser = Depends(get_current_user)):
    sb = get_supabase()
    q = sb.table("arena_match_events").select("*").eq("match_id", match_id).order("created_at").limit(100)
    if since:
        q = q.gt("created_at", since)
    return q.execute().data or []


# ── Leaderboard ────────────────────────────────────────────────────────────

@router.get("/leaderboard")
async def leaderboard(user: CurrentUser = Depends(get_current_user)):
    sb = get_supabase()
    rows = (sb.table("profiles")
            .select("id, display_name, arena_xp, arena_ap, arena_wins, arena_streak")
            .order("arena_xp", desc=True).limit(50).execute().data or [])
    return rows


# ── Quests ─────────────────────────────────────────────────────────────────

@router.get("/quests")
async def get_quests(user: CurrentUser = Depends(get_current_user)):
    daily = await get_or_create_daily_quests(user.id)
    weekly = await get_or_create_weekly_quests(user.id)
    return {"daily": daily, "weekly": weekly}


@router.post("/quests/claim")
async def claim_quest_endpoint(body: ClaimQuestRequest, user: CurrentUser = Depends(get_current_user)):
    return await claim_quest(user.id, body.quest_id)


# ── Trophies ───────────────────────────────────────────────────────────────

@router.get("/trophies")
async def get_trophies(user: CurrentUser = Depends(get_current_user)):
    return await get_user_achievements(user.id)


# ── Spin Wheel ─────────────────────────────────────────────────────────────

@router.get("/spin/status")
async def spin_status(user: CurrentUser = Depends(get_current_user)):
    return {
        "spin_status": await get_free_spin_status(user.id),
        "history": await get_spin_history(user.id),
        "prizes": PRIZES,
    }


@router.post("/spin")
async def do_spin(body: SpinRequest, user: CurrentUser = Depends(get_current_user)):
    result = await perform_spin(user.id, body.is_free)
    if result["prize"]["key"] == "jackpot":
        await check_spin_achievement(user.id, "jackpot")
    return result


# ── Stats ──────────────────────────────────────────────────────────────────

@router.get("/stats")
async def arena_stats(user: CurrentUser = Depends(get_current_user)):
    sb = get_supabase()
    profile = sb.table("profiles").select(
        "arena_xp, arena_ap, arena_wins, arena_streak, activity_streak_days, last_activity_date, arena_level"
    ).eq("id", user.id).single().execute().data or {}
    matches_played = sb.table("arena_match_players").select("match_id", count="exact").eq("user_id", user.id).execute().count or 0
    xp = profile.get("arena_xp", 0) or 0
    lp = level_progress(xp)
    streak_days = profile.get("activity_streak_days", 0) or 0
    return {
        "xp": xp,
        "ap": profile.get("arena_ap", 0) or 0,
        "wins": profile.get("arena_wins", 0) or 0,
        "streak": profile.get("arena_streak", 0) or 0,
        "matches_played": matches_played,
        "level": lp["level"],
        "xp_in_level": lp["xp_in_level"],
        "xp_for_next_level": lp["xp_for_next_level"],
        "xp_to_next": lp["xp_to_next"],
        "level_progress_pct": lp["progress_pct"],
        "activity_streak_days": streak_days,
        "streak_multiplier": streak_multiplier(streak_days),
    }


# ── Rematch ────────────────────────────────────────────────────────────────

@router.post("/match/{match_id}/rematch")
async def rematch(match_id: str, user: CurrentUser = Depends(get_current_user)):
    sb = get_supabase()
    orig = sb.table("arena_matches").select("*").eq("id", match_id).single().execute().data
    if not orig:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Original match not found")

    # Both players from original match
    orig_players = sb.table("arena_match_players").select("user_id").eq("match_id", match_id).execute().data or []
    if not any(p["user_id"] == user.id for p in orig_players):
        raise HTTPException(status.HTTP_403_FORBIDDEN, "You were not in this match")

    # Generate room code
    import string
    room_code = "".join(random.choices(string.ascii_uppercase + string.digits, k=6))

    # Create new match
    new_match = sb.table("arena_matches").insert({
        "host_id": user.id,
        "room_code": room_code,
        "topic_id": orig.get("topic_id"),
        "max_questions": orig.get("max_questions", 10),
        "status": "waiting",
    }).execute().data
    if not new_match:
        raise HTTPException(status.HTTP_500_INTERNAL_SERVER_ERROR, "Failed to create rematch")

    new_match_id = new_match[0]["id"]

    # Auto-join both players
    for p in orig_players:
        # Fetch display_name
        profile = sb.table("profiles").select("display_name").eq("id", p["user_id"]).single().execute().data or {}
        sb.table("arena_match_players").insert({
            "match_id": new_match_id,
            "user_id": p["user_id"],
            "display_name": profile.get("display_name", "Player"),
            "score_xp": 0, "score_ap": 0, "streak": 0,
            "correct_count": 0, "total_answered": 0,
        }).execute()

    return {"match_id": new_match_id, "room_code": room_code}


# ── Match History ──────────────────────────────────────────────────────────

@router.get("/history")
async def match_history(user: CurrentUser = Depends(get_current_user)):
    """Return the last 50 finished/cancelled matches the user participated in."""
    from collections import defaultdict
    sb = get_supabase()

    # 1. Matches this user played in
    my_rows = (sb.table("arena_match_players")
               .select("match_id, score_xp, score_ap, correct_count, total_answered")
               .eq("user_id", user.id).execute().data or [])
    if not my_rows:
        return []

    match_ids = [r["match_id"] for r in my_rows]
    my_stats = {r["match_id"]: r for r in my_rows}

    # 2. Match metadata
    matches = (sb.table("arena_matches")
               .select("id, topic_id, max_questions, winner_id, status, started_at, finished_at, created_at")
               .in_("id", match_ids).order("created_at", desc=True).limit(50).execute().data or [])

    matches = [m for m in matches if m["status"] in ("finished", "cancelled")]
    if not matches:
        return []

    finished_ids = [m["id"] for m in matches]

    # 3. All player rows for finished matches (batch)
    all_players = (sb.table("arena_match_players")
                   .select("match_id, user_id, score_xp, correct_count, total_answered")
                   .in_("match_id", finished_ids).execute().data or [])

    by_match: dict = defaultdict(list)
    for p in all_players:
        by_match[p["match_id"]].append(p)

    # 4. Opponent profiles (batch)
    opp_ids = list({p["user_id"] for p in all_players if p["user_id"] != user.id})
    profiles: dict = {}
    if opp_ids:
        prof_rows = (sb.table("profiles")
                     .select("id, display_name").in_("id", opp_ids).execute().data or [])
        profiles = {p["id"]: p for p in prof_rows}

    results = []
    for m in matches:
        mid = m["id"]
        my  = my_stats.get(mid, {})
        players = by_match.get(mid, [])
        opp = next((p for p in players if p["user_id"] != user.id), None)
        opp_profile = profiles.get(opp["user_id"]) if opp else None

        winner_id = m.get("winner_id")
        if winner_id == user.id:
            result = "win"
        elif winner_id:
            result = "loss"
        elif m["status"] == "finished":
            result = "draw"
        else:
            result = "cancelled"

        results.append({
            "match_id": mid,
            "topic_id":     m.get("topic_id", ""),
            "max_questions": m.get("max_questions", 10),
            "result":       result,
            "my_xp":        my.get("score_xp",       0) or 0,
            "my_correct":   my.get("correct_count",   0) or 0,
            "my_total":     my.get("total_answered",  0) or 0,
            "opp_name":     opp_profile.get("display_name", "Unknown") if opp_profile else "Unknown",
            "opp_xp":       opp.get("score_xp",      0) if opp else 0,
            "opp_correct":  opp.get("correct_count",  0) if opp else 0,
            "finished_at":  m.get("finished_at") or m.get("started_at") or m.get("created_at"),
        })

    return results


# ── 50/50 Power-up ────────────────────────────────────────────────────────

@router.get("/match/{match_id}/fifty/{question_id}")
async def fifty_fifty(match_id: str, question_id: str, user: CurrentUser = Depends(get_current_user)):
    """Return two wrong option indices to eliminate for the 50/50 power-up."""
    sb = get_supabase()
    # Verify user is in this match
    players = sb.table("arena_match_players").select("user_id").eq("match_id", match_id).execute().data or []
    if not any(p["user_id"] == user.id for p in players):
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Not in this match")

    q = sb.table("assessment_questions").select("correct_option, options").eq("id", question_id).single().execute().data
    if not q:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Question not found")

    correct = q["correct_option"]
    n_opts  = len(q.get("options") or [])
    wrong_indices = [i for i in range(n_opts) if i != correct]
    random.shuffle(wrong_indices)
    to_hide = wrong_indices[:2]  # hide 2 wrong answers
    return {"hide": to_hide}


# ── Seasons & Ranks ────────────────────────────────────────────────────────

AP_TIERS = [
    {"key": "unranked",  "label": "Unranked",  "icon": "⬛", "min_ap": 0,     "max_ap": 99,    "color": "#5A6A8A"},
    {"key": "bronze",    "label": "Bronze",    "icon": "🥉", "min_ap": 100,   "max_ap": 499,   "color": "#CD7F32"},
    {"key": "silver",    "label": "Silver",    "icon": "🥈", "min_ap": 500,   "max_ap": 1499,  "color": "#C0C0C0"},
    {"key": "gold",      "label": "Gold",      "icon": "🥇", "min_ap": 1500,  "max_ap": 3999,  "color": "#FFB300"},
    {"key": "platinum",  "label": "Platinum",  "icon": "💎", "min_ap": 4000,  "max_ap": 9999,  "color": "#A8CFFF"},
    {"key": "diamond",   "label": "Diamond",   "icon": "💠", "min_ap": 10000, "max_ap": 24999, "color": "#00C8FF"},
    {"key": "legend",    "label": "Legend",    "icon": "👑", "min_ap": 25000, "max_ap": None,  "color": "#FF6B35"},
]


def get_ap_tier(ap: int) -> dict:
    for tier in reversed(AP_TIERS):
        if ap >= tier["min_ap"]:
            return tier
    return AP_TIERS[0]


def get_ap_progress(ap: int) -> dict:
    tier = get_ap_tier(ap)
    if tier["max_ap"] is None:
        # Legend — maxed out
        return {"tier": tier, "ap_in_tier": ap - tier["min_ap"], "ap_for_next": 0, "progress_pct": 100}
    ap_in_tier = ap - tier["min_ap"]
    tier_range  = tier["max_ap"] - tier["min_ap"] + 1
    pct = min(100, round((ap_in_tier / tier_range) * 100))
    return {
        "tier": tier,
        "ap_in_tier":   ap_in_tier,
        "ap_for_next":  tier["max_ap"] + 1 - ap,
        "progress_pct": pct,
    }


@router.get("/season")
async def season_ranks(user: CurrentUser = Depends(get_current_user)):
    """Return current season info, the user's AP rank, and tier distribution."""
    from datetime import date, timezone as tz
    import calendar

    sb = get_supabase()

    # Season = current calendar month
    now = datetime.now(timezone.utc)
    year, month = now.year, now.month
    last_day = calendar.monthrange(year, month)[1]
    ends_at  = datetime(year, month, last_day, 23, 59, 59, tzinfo=timezone.utc)
    days_rem = (ends_at.date() - now.date()).days + 1
    season_name = f"Season {now.strftime('%b %Y')}"

    # My AP
    my_profile = (sb.table("profiles")
                  .select("display_name, arena_ap, arena_xp, arena_wins")
                  .eq("id", user.id).single().execute().data or {})
    my_ap  = my_profile.get("arena_ap", 0) or 0
    my_prog = get_ap_progress(my_ap)

    # All players AP for distribution + position
    all_players = (sb.table("profiles")
                   .select("id, display_name, arena_ap, arena_xp, arena_wins")
                   .order("arena_ap", desc=True).limit(500).execute().data or [])

    # Rank position (1-indexed, only players with >0 AP)
    ranked = [p for p in all_players if (p.get("arena_ap") or 0) > 0]
    my_position = next((i+1 for i, p in enumerate(ranked) if p["id"] == user.id), None)

    # Tier distribution
    distribution = {t["key"]: 0 for t in AP_TIERS}
    for p in all_players:
        t = get_ap_tier(p.get("arena_ap", 0) or 0)
        distribution[t["key"]] += 1

    # Top 20 by AP for the leaderboard section
    top20 = []
    for i, p in enumerate(all_players[:20]):
        tp = get_ap_tier(p.get("arena_ap", 0) or 0)
        top20.append({
            "rank":     i + 1,
            "id":       p["id"],
            "name":     p.get("display_name") or "Anonymous",
            "ap":       p.get("arena_ap", 0) or 0,
            "xp":       p.get("arena_xp", 0) or 0,
            "wins":     p.get("arena_wins", 0) or 0,
            "tier_key":   tp["key"],
            "tier_label": tp["label"],
            "tier_icon":  tp["icon"],
            "tier_color": tp["color"],
        })

    return {
        "season": {
            "name":        season_name,
            "ends_at":     ends_at.isoformat(),
            "days_remaining": days_rem,
        },
        "my_rank": {
            "ap":            my_ap,
            "display_name":  my_profile.get("display_name", ""),
            "tier_key":      my_prog["tier"]["key"],
            "tier_label":    my_prog["tier"]["label"],
            "tier_icon":     my_prog["tier"]["icon"],
            "tier_color":    my_prog["tier"]["color"],
            "ap_in_tier":    my_prog["ap_in_tier"],
            "ap_for_next":   my_prog["ap_for_next"],
            "progress_pct":  my_prog["progress_pct"],
            "position":      my_position,
        },
        "tier_distribution": distribution,
        "top_players": top20,
        "all_tiers": AP_TIERS,
    }


# ── Tournaments ────────────────────────────────────────────────────────────

class CreateTournamentRequest(BaseModel):
    topic_id: str = "sap-btp"
    max_questions: int = 10
    max_players: int = 4   # 4 or 8

class JoinTournamentRequest(BaseModel):
    room_code: str


def _advance_tournament(sb, tournament_id: str, finished_match_id: str, winner_id: str):
    """Called when a tournament match finishes. Advances the bracket."""
    # Mark tournament match as finished
    tm = (sb.table("arena_tournament_matches")
            .select("*")
            .eq("tournament_id", tournament_id)
            .eq("match_id", finished_match_id)
            .maybe_single().execute().data)
    if not tm:
        return
    sb.table("arena_tournament_matches").update({
        "winner_id": winner_id, "status": "finished",
    }).eq("id", tm["id"]).execute()

    t = sb.table("arena_tournaments").select("*").eq("id", tournament_id).single().execute().data
    current_round = t["current_round"]
    max_players   = t["max_players"]

    # Fetch all matches in current round
    round_matches = (sb.table("arena_tournament_matches")
                       .select("*")
                       .eq("tournament_id", tournament_id)
                       .eq("round", current_round)
                       .order("bracket_slot").execute().data or [])

    # Are all finished?
    if not all(m["status"] == "finished" for m in round_matches):
        return  # Still waiting for other matches

    winners = [m["winner_id"] for m in round_matches]
    total_rounds = 2 if max_players == 4 else 3  # 4-player=2 rounds, 8-player=3 rounds

    if current_round >= total_rounds:
        # Tournament over — champion is the winner of this final
        champion_id = winners[0]
        sb.table("arena_tournaments").update({
            "status": "finished", "winner_id": champion_id,
            "finished_at": datetime.now(timezone.utc).isoformat(),
        }).eq("id", tournament_id).execute()
        # Mark final position
        for i, uid in enumerate(winners):
            sb.table("arena_tournament_players").update({
                "final_position": i + 1, "is_eliminated": i > 0,
            }).eq("tournament_id", tournament_id).eq("user_id", uid).execute()
        return

    # Create next round matches
    next_round = current_round + 1
    sb.table("arena_tournaments").update({"current_round": next_round}).eq("id", tournament_id).execute()

    # Pair winners: slot 0 winner vs slot 1 winner, etc.
    for slot in range(0, len(winners), 2):
        if slot + 1 >= len(winners):
            break
        p1, p2 = winners[slot], winners[slot + 1]
        room_code = _gen_code()
        match_res = sb.table("arena_matches").insert({
            "host_id": p1,
            "topic_id": t["topic_id"],
            "room_code": room_code,
            "max_questions": t["max_questions"],
            "status": "waiting",
        }).execute()
        new_match_id = match_res.data[0]["id"] if match_res.data else None
        if new_match_id:
            sb.table("arena_match_players").insert([
                {"match_id": new_match_id, "user_id": p1, "is_host": True},
                {"match_id": new_match_id, "user_id": p2, "is_host": False},
            ]).execute()
            sb.table("arena_tournament_matches").insert({
                "tournament_id": tournament_id,
                "match_id":      new_match_id,
                "round":         next_round,
                "bracket_slot":  slot // 2,
                "player1_id":    p1,
                "player2_id":    p2,
                "status":        "active",
            }).execute()

    # Eliminate losers from this round
    for m in round_matches:
        loser = m["player1_id"] if m["winner_id"] == m["player2_id"] else m["player2_id"]
        if loser:
            sb.table("arena_tournament_players").update({
                "is_eliminated": True, "eliminated_round": current_round,
            }).eq("tournament_id", tournament_id).eq("user_id", loser).execute()


@router.post("/tournament/create")
async def create_tournament(body: CreateTournamentRequest, user: CurrentUser = Depends(get_current_user)):
    if body.max_players not in (4, 8):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "max_players must be 4 or 8")
    sb = get_supabase()
    room_code = _gen_code()
    res = sb.table("arena_tournaments").insert({
        "host_id":      user.id,
        "room_code":    room_code,
        "topic_id":     body.topic_id,
        "max_questions": body.max_questions,
        "max_players":  body.max_players,
        "status":       "waiting",
    }).execute()
    if not res.data:
        raise HTTPException(status.HTTP_500_INTERNAL_SERVER_ERROR, "Failed to create tournament")
    t = res.data[0]
    sb.table("arena_tournament_players").insert({
        "tournament_id": t["id"], "user_id": user.id, "is_host": True,
    }).execute()
    return {"tournament_id": t["id"], "room_code": room_code}


@router.post("/tournament/join")
async def join_tournament(body: JoinTournamentRequest, user: CurrentUser = Depends(get_current_user)):
    sb = get_supabase()
    t = (sb.table("arena_tournaments")
           .select("*").eq("room_code", body.room_code.strip().upper())
           .maybe_single().execute().data)
    if not t:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Tournament not found")
    if t["status"] != "waiting":
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Tournament already started")
    players = (sb.table("arena_tournament_players")
                 .select("user_id").eq("tournament_id", t["id"]).execute().data or [])
    if any(p["user_id"] == user.id for p in players):
        return {"tournament_id": t["id"]}  # Already in
    if len(players) >= t["max_players"]:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Tournament is full")
    sb.table("arena_tournament_players").insert({
        "tournament_id": t["id"], "user_id": user.id,
    }).execute()
    return {"tournament_id": t["id"]}


@router.get("/tournament/{tournament_id}")
async def get_tournament(tournament_id: str, user: CurrentUser = Depends(get_current_user)):
    sb = get_supabase()
    t = sb.table("arena_tournaments").select("*").eq("id", tournament_id).maybe_single().execute().data
    if not t:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Tournament not found")

    players_raw = (sb.table("arena_tournament_players")
                     .select("*").eq("tournament_id", tournament_id).execute().data or [])
    player_ids  = [p["user_id"] for p in players_raw]
    profiles    = {}
    if player_ids:
        for pr in (sb.table("profiles").select("id, display_name, arena_xp").in_("id", player_ids).execute().data or []):
            profiles[pr["id"]] = pr

    players = []
    for p in players_raw:
        pr = profiles.get(p["user_id"], {})
        players.append({**p, "display_name": pr.get("display_name", "Player")})

    bracket_matches = (sb.table("arena_tournament_matches")
                         .select("*").eq("tournament_id", tournament_id)
                         .order("round").order("bracket_slot").execute().data or [])

    # Find my active match (if any)
    my_active_match = None
    for m in bracket_matches:
        if m["status"] == "active" and user.id in (m.get("player1_id"), m.get("player2_id")):
            my_active_match = m["match_id"]
            break

    # Check if I'm in the tournament
    is_participant = any(p["user_id"] == user.id for p in players_raw)
    is_host        = t["host_id"] == user.id

    return {
        "tournament": t,
        "players":    players,
        "bracket":    bracket_matches,
        "my_active_match": my_active_match,
        "is_participant":  is_participant,
        "is_host":         is_host,
        "player_count":    len(players_raw),
    }


@router.post("/tournament/{tournament_id}/start")
async def start_tournament(tournament_id: str, user: CurrentUser = Depends(get_current_user)):
    sb = get_supabase()
    t = sb.table("arena_tournaments").select("*").eq("id", tournament_id).single().execute().data
    if not t:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Not found")
    if t["host_id"] != user.id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Only host can start")
    if t["status"] != "waiting":
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Already started")

    players_raw = (sb.table("arena_tournament_players")
                     .select("user_id").eq("tournament_id", tournament_id).execute().data or [])
    if len(players_raw) < 4:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, f"Need at least 4 players (have {len(players_raw)})")

    # Random seeding
    player_ids = [p["user_id"] for p in players_raw]
    random.shuffle(player_ids)
    seeded = player_ids[: t["max_players"]]  # cap to max_players

    # Update seeds
    for i, uid in enumerate(seeded):
        sb.table("arena_tournament_players").update({"seed": i + 1}).eq("tournament_id", tournament_id).eq("user_id", uid).execute()

    # Create round 1 matches: seed 1 vs last, seed 2 vs second-last, etc.
    n = len(seeded)
    pairs = [(seeded[i], seeded[n - 1 - i]) for i in range(n // 2)]

    sb.table("arena_tournaments").update({
        "status": "active", "current_round": 1,
        "started_at": datetime.now(timezone.utc).isoformat(),
    }).eq("id", tournament_id).execute()

    for slot, (p1, p2) in enumerate(pairs):
        room_code = _gen_code()
        match_res = sb.table("arena_matches").insert({
            "host_id":       p1,
            "topic_id":      t["topic_id"],
            "room_code":     room_code,
            "max_questions": t["max_questions"],
            "status":        "waiting",
        }).execute()
        new_match_id = match_res.data[0]["id"] if match_res.data else None
        if new_match_id:
            sb.table("arena_match_players").insert([
                {"match_id": new_match_id, "user_id": p1, "is_host": True},
                {"match_id": new_match_id, "user_id": p2, "is_host": False},
            ]).execute()
            sb.table("arena_tournament_matches").insert({
                "tournament_id": tournament_id,
                "match_id":      new_match_id,
                "round":         1,
                "bracket_slot":  slot,
                "player1_id":    p1,
                "player2_id":    p2,
                "status":        "active",
            }).execute()

    return {"started": True, "round": 1, "pairs": len(pairs)}
