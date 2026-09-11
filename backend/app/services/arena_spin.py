import random
from datetime import datetime, timezone, timedelta
from fastapi import HTTPException, status
from ..supabase_client import get_supabase

PRIZES = [
    {"key": "ap_50",      "label": "+50 AP",          "type": "ap",      "value": 50,  "prob": 0.25, "color": "#00C8FF"},
    {"key": "ap_150",     "label": "+150 AP",          "type": "ap",      "value": 150, "prob": 0.20, "color": "#FFB300"},
    {"key": "powerup",    "label": "Time Freeze",       "type": "powerup", "value": 1,   "prob": 0.20, "color": "#00E676"},
    {"key": "cosmetic",   "label": "Cosmetic Badge",    "type": "cosmetic","value": 1,   "prob": 0.15, "color": "#A855F7"},
    {"key": "xp_100",     "label": "+100 XP",          "type": "xp",      "value": 100, "prob": 0.10, "color": "#00C8FF"},
    {"key": "ap_2x_next", "label": "2x AP Next Match", "type": "2x_ap",   "value": 2,   "prob": 0.06, "color": "#FF5722"},
    {"key": "jackpot",    "label": "JACKPOT +500 AP",  "type": "ap",      "value": 500, "prob": 0.02, "color": "#FFB300"},
    {"key": "try_again",  "label": "Try Again",        "type": "nothing", "value": 0,   "prob": 0.02, "color": "#3A4A68"},
]


def pick_prize() -> dict:
    r = random.random()
    cumulative = 0.0
    for prize in PRIZES:
        cumulative += prize["prob"]
        if r <= cumulative:
            return prize
    return PRIZES[-1]


async def get_free_spin_status(user_id: str) -> dict:
    sb = get_supabase()
    cutoff = (datetime.now(timezone.utc) - timedelta(hours=24)).isoformat()
    res = sb.table("arena_spin_log").select("spun_at").eq("user_id", user_id).eq("is_free", True).gte("spun_at", cutoff).order("spun_at", desc=True).limit(1).execute()
    if res.data:
        last_free = datetime.fromisoformat(res.data[0]["spun_at"].replace("Z", "+00:00"))
        next_free = last_free + timedelta(hours=24)
        return {"has_free_spin": False, "next_free_spin_at": next_free.isoformat()}
    return {"has_free_spin": True, "next_free_spin_at": None}


async def perform_spin(user_id: str, is_free: bool) -> dict:
    sb = get_supabase()
    if not is_free:
        profile_res = sb.table("profiles").select("arena_ap").eq("id", user_id).single().execute()
        if not profile_res.data or (profile_res.data.get("arena_ap") or 0) < 50:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, "Insufficient AP. Need 50 AP for an extra spin.")
        sb.table("profiles").update({"arena_ap": (profile_res.data["arena_ap"] - 50)}).eq("id", user_id).execute()

    prize = pick_prize()

    # Jackpot cap: max 1 jackpot per user per 7 days
    if prize["key"] == "jackpot":
        week_ago = (datetime.now(timezone.utc) - timedelta(days=7)).isoformat()
        jackpot_check = sb.table("arena_spin_log").select("id").eq("user_id", user_id).eq("prize_type", "jackpot").gte("spun_at", week_ago).execute()
        if jackpot_check.data:
            prize = next((p for p in PRIZES if p["key"] == "ap_150"), PRIZES[1])

    sb.table("arena_spin_log").insert({
        "user_id": user_id,
        "prize_type": prize["key"],
        "prize_label": prize["label"],
        "prize_value": prize["value"],
        "is_free": is_free,
        "spun_at": datetime.now(timezone.utc).isoformat(),
    }).execute()

    profile_res = sb.table("profiles").select("arena_xp, arena_ap").eq("id", user_id).single().execute()
    current_xp = (profile_res.data or {}).get("arena_xp", 0) or 0
    current_ap = (profile_res.data or {}).get("arena_ap", 0) or 0
    new_xp, new_ap = current_xp, current_ap

    if prize["type"] == "ap":
        new_ap = current_ap + prize["value"]
        sb.table("profiles").update({"arena_ap": new_ap}).eq("id", user_id).execute()
    elif prize["type"] == "xp":
        new_xp = current_xp + prize["value"]
        sb.table("profiles").update({"arena_xp": new_xp}).eq("id", user_id).execute()

    return {"prize": prize, "new_ap": new_ap, "new_xp": new_xp}


async def get_spin_history(user_id: str, limit: int = 10) -> list[dict]:
    sb = get_supabase()
    res = sb.table("arena_spin_log").select("prize_label, prize_value, prize_type, is_free, spun_at").eq("user_id", user_id).order("spun_at", desc=True).limit(limit).execute()
    return res.data or []
