from datetime import datetime, timezone
from ..supabase_client import get_supabase

BADGES: dict = {
    "first_blood":   {"title": "First Blood",   "emoji": "⚡", "rarity": "common",    "description": "Win your first Arena match"},
    "on_fire":       {"title": "On Fire",        "emoji": "🔥", "rarity": "rare",      "description": "Reach a 5-combo in any match"},
    "perfect_shot":  {"title": "Perfect Shot",   "emoji": "🎯", "rarity": "rare",      "description": "5 LIGHTNING answers in one match"},
    "btp_master":    {"title": "BTP Master",     "emoji": "💎", "rarity": "epic",      "description": "Win 20 matches in SAP BTP topic"},
    "rival_slayer":  {"title": "Rival Slayer",   "emoji": "⚔️", "rarity": "epic",      "description": "Beat the same player 3 times"},
    "speed_demon":   {"title": "Speed Demon",    "emoji": "🚀", "rarity": "epic",      "description": "10 LIGHTNING answers across all matches"},
    "untouchable":   {"title": "Untouchable",    "emoji": "🛡️", "rarity": "epic",      "description": "Win 5 matches in a row"},
    "comeback_king": {"title": "Comeback King",  "emoji": "💪", "rarity": "legendary", "description": "Win after being 3 questions behind"},
    "champion":      {"title": "Champion",       "emoji": "👑", "rarity": "legendary", "description": "Reach #1 on the weekly leaderboard"},
    "lucky":         {"title": "Lucky",          "emoji": "🎰", "rarity": "rare",      "description": "Hit the jackpot on the spin wheel"},
}


async def get_user_achievements(user_id: str) -> list[dict]:
    sb = get_supabase()
    res = sb.table("arena_achievements").select("badge_key, unlocked_at, rarity").eq("user_id", user_id).execute()
    unlocked = {r["badge_key"]: r for r in (res.data or [])}
    result = []
    for key, meta in BADGES.items():
        row = {"badge_key": key, **meta, "unlocked": key in unlocked, "unlocked_at": None}
        if key in unlocked:
            row["unlocked_at"] = unlocked[key]["unlocked_at"]
        result.append(row)
    return result


async def unlock_achievement(user_id: str, badge_key: str) -> dict | None:
    if badge_key not in BADGES:
        return None
    sb = get_supabase()
    existing = sb.table("arena_achievements").select("id").eq("user_id", user_id).eq("badge_key", badge_key).execute()
    if existing.data:
        return None
    badge = BADGES[badge_key]
    res = sb.table("arena_achievements").insert({
        "user_id": user_id,
        "badge_key": badge_key,
        "rarity": badge["rarity"],
        "unlocked_at": datetime.now(timezone.utc).isoformat(),
    }).execute()
    return res.data[0] if res.data else None


async def check_match_achievements(user_id: str, match_stats: dict) -> list[str]:
    newly_unlocked = []
    checks = [
        ("first_blood",   match_stats.get("wins_total", 0) >= 1),
        ("on_fire",       match_stats.get("max_combo_this_match", 0) >= 5),
        ("perfect_shot",  match_stats.get("lightning_count_this_match", 0) >= 5),
        ("btp_master",    match_stats.get("btp_wins", 0) >= 20),
        ("rival_slayer",  match_stats.get("same_opponent_wins", 0) >= 3),
        ("speed_demon",   match_stats.get("total_lightning_all_time", 0) >= 10),
        ("untouchable",   match_stats.get("win_streak", 0) >= 5),
        ("comeback_king", bool(match_stats.get("comeback_win", False))),
    ]
    for badge_key, condition in checks:
        if condition:
            result = await unlock_achievement(user_id, badge_key)
            if result:
                newly_unlocked.append(badge_key)
    return newly_unlocked


async def check_leaderboard_achievement(user_id: str, rank: int) -> list[str]:
    if rank == 1:
        result = await unlock_achievement(user_id, "champion")
        return ["champion"] if result else []
    return []


async def check_spin_achievement(user_id: str, prize_key: str) -> list[str]:
    if prize_key == "jackpot":
        result = await unlock_achievement(user_id, "lucky")
        return ["lucky"] if result else []
    return []
