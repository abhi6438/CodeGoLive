from datetime import datetime, timezone, timedelta
import random
from fastapi import HTTPException, status
from ..supabase_client import get_supabase

DAILY_QUEST_CATALOG = [
    {"key": "speed_merchant", "title": "Speed Merchant",  "description": "Answer 3 questions in LIGHTNING tier (under 3s)", "target": 3,  "xp_reward": 60,  "ap_reward": 80,  "metric": "lightning_answers"},
    {"key": "sharpshooter",   "title": "Sharpshooter",    "description": "Win a match without any wrong answers",             "target": 1,  "xp_reward": 100, "ap_reward": 120, "metric": "perfect_wins"},
    {"key": "daily_grind",    "title": "Daily Grind",     "description": "Complete 1 Arena match",                            "target": 1,  "xp_reward": 40,  "ap_reward": 50,  "metric": "matches_played"},
    {"key": "combo_king",     "title": "Combo King",      "description": "Build a 5-answer combo streak",                    "target": 1,  "xp_reward": 70,  "ap_reward": 90,  "metric": "combo_5"},
    {"key": "answer_10",      "title": "Answer Machine",  "description": "Answer 10 questions correctly today",              "target": 10, "xp_reward": 50,  "ap_reward": 60,  "metric": "correct_answers"},
]

WEEKLY_QUEST_CATALOG = [
    {"key": "rival_slayer",       "title": "Rival Slayer",       "description": "Beat the same opponent twice this week",              "target": 2,  "xp_reward": 300, "ap_reward": 500, "metric": "same_opponent_wins"},
    {"key": "knowledge_gauntlet", "title": "Knowledge Gauntlet", "description": "Complete 10 matches across at least 2 topics",        "target": 10, "xp_reward": 500, "ap_reward": 800, "metric": "matches_multi_topic"},
    {"key": "week_warrior",       "title": "Week Warrior",       "description": "Log in 5 days this week",                             "target": 5,  "xp_reward": 150, "ap_reward": 200, "metric": "login_days"},
    {"key": "win_streak_5",       "title": "5-Win Streak",       "description": "Win 5 Arena matches this week",                       "target": 5,  "xp_reward": 400, "ap_reward": 600, "metric": "weekly_wins"},
]


def _midnight_utc_today() -> datetime:
    now = datetime.now(timezone.utc)
    return now.replace(hour=0, minute=0, second=0, microsecond=0) + timedelta(days=1)


def _monday_utc() -> datetime:
    now = datetime.now(timezone.utc)
    days_until_monday = (7 - now.weekday()) % 7 or 7
    reset = now.replace(hour=0, minute=0, second=0, microsecond=0) + timedelta(days=days_until_monday)
    return reset


async def get_or_create_daily_quests(user_id: str) -> list[dict]:
    sb = get_supabase()
    today_start = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)
    res = sb.table("arena_quests").select("*").eq("user_id", user_id).eq("type", "daily").gte("resets_at", today_start.isoformat()).execute()
    if res.data:
        return res.data
    quests = random.sample(DAILY_QUEST_CATALOG, min(3, len(DAILY_QUEST_CATALOG)))
    resets_at = _midnight_utc_today().isoformat()
    rows = [{"user_id": user_id, "type": "daily", "resets_at": resets_at, **q} for q in quests]
    insert_res = sb.table("arena_quests").insert(rows).execute()
    return insert_res.data or rows


async def get_or_create_weekly_quests(user_id: str) -> list[dict]:
    sb = get_supabase()
    now = datetime.now(timezone.utc)
    week_start = (now - timedelta(days=now.weekday())).replace(hour=0, minute=0, second=0, microsecond=0)
    res = sb.table("arena_quests").select("*").eq("user_id", user_id).eq("type", "weekly").gte("resets_at", week_start.isoformat()).execute()
    if res.data:
        return res.data
    resets_at = _monday_utc().isoformat()
    rows = [{"user_id": user_id, "type": "weekly", "resets_at": resets_at, **q} for q in WEEKLY_QUEST_CATALOG]
    insert_res = sb.table("arena_quests").insert(rows).execute()
    return insert_res.data or rows


async def update_quest_progress(user_id: str, metric: str, increment: int = 1) -> list[dict]:
    sb = get_supabase()
    now_iso = datetime.now(timezone.utc).isoformat()
    res = sb.table("arena_quests").select("*").eq("user_id", user_id).eq("metric", metric).is_("claimed_at", "null").gte("resets_at", now_iso).execute()
    updated = []
    for quest in (res.data or []):
        new_progress = min(quest["progress"] + increment, quest["target"])
        upd = sb.table("arena_quests").update({"progress": new_progress}).eq("id", quest["id"]).execute()
        if upd.data:
            updated.append(upd.data[0])
    return updated


async def claim_quest(user_id: str, quest_id: str) -> dict:
    sb = get_supabase()
    res = sb.table("arena_quests").select("*").eq("id", quest_id).eq("user_id", user_id).single().execute()
    if not res.data:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Quest not found")
    quest = res.data
    if quest.get("claimed_at"):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Quest already claimed")
    if quest["progress"] < quest["target"]:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, f"Quest not complete: {quest['progress']}/{quest['target']}")
    sb.table("arena_quests").update({"claimed_at": datetime.now(timezone.utc).isoformat()}).eq("id", quest_id).execute()
    profile_res = sb.table("profiles").select("arena_xp, arena_ap").eq("id", user_id).single().execute()
    if profile_res.data:
        new_xp = (profile_res.data.get("arena_xp") or 0) + quest["xp_reward"]
        new_ap = (profile_res.data.get("arena_ap") or 0) + quest["ap_reward"]
        sb.table("profiles").update({"arena_xp": new_xp, "arena_ap": new_ap}).eq("id", user_id).execute()
    return {"success": True, "xp_earned": quest["xp_reward"], "ap_earned": quest["ap_reward"]}


async def check_and_update_login_streak(user_id: str) -> int:
    sb = get_supabase()
    res = sb.table("profiles").select("arena_streak, last_arena_activity").eq("id", user_id).single().execute()
    if not res.data:
        return 0
    last = res.data.get("last_arena_activity")
    streak = res.data.get("arena_streak") or 0
    today = datetime.now(timezone.utc).date()
    if last:
        last_date = datetime.fromisoformat(last.replace("Z", "+00:00")).date()
        if last_date == today:
            return streak
        elif last_date == today - timedelta(days=1):
            streak += 1
        else:
            streak = 1
    else:
        streak = 1
    sb.table("profiles").update({"arena_streak": streak, "last_arena_activity": datetime.now(timezone.utc).isoformat()}).eq("id", user_id).execute()
    return streak
