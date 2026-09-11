from datetime import datetime, timezone
from typing import Tuple

BASE_XP = 20
BASE_AP = 10

TIERS = [
    (27, "LIGHTNING", 5.0, "#00C8FF"),
    (24, "SWIFT",     3.0, "#00E676"),
    (18, "SHARP",     2.0, "#FFB300"),
    (8,  "STEADY",    1.0, "#A0B8D0"),
    (1,  "SLOW",      0.5, "#607080"),
    (0,  "MISS",      0.0, "#3A4A68"),
]

TIER_EMOJIS = {
    "LIGHTNING": "⚡",
    "SWIFT":     "🎯",
    "SHARP":     "✓",
    "STEADY":    "—",
    "SLOW":      "🐢",
    "MISS":      "✗",
}


def get_time_multiplier(time_remaining: int) -> Tuple[float, str, str]:
    """Return (multiplier, tier_name, color) for the given remaining seconds."""
    for threshold, tier, mult, color in TIERS:
        if time_remaining >= threshold:
            return mult, tier, color
    return 0.0, "MISS", "#3A4A68"


def get_combo_multiplier(streak: int) -> float:
    """Return combo bonus multiplier for the current answer streak."""
    if streak >= 5:
        return 2.0
    if streak >= 3:
        return 1.5
    return 1.0


def get_combo_label(streak: int) -> str | None:
    if streak >= 5:
        return "⚡ INFERNO"
    if streak >= 3:
        return "🔥 CHAIN"
    return None


def server_timestamp_check(
    client_time_remaining: int,
    question_sent_at: datetime,
    question_time_limit: int = 30,
) -> int:
    """
    Validate client-reported time_remaining against server clock.
    If difference > 3s, use the server-computed value.
    Returns the authoritative time_remaining.
    """
    now = datetime.now(timezone.utc)
    if question_sent_at.tzinfo is None:
        question_sent_at = question_sent_at.replace(tzinfo=timezone.utc)
    elapsed = (now - question_sent_at).total_seconds()
    server_remaining = max(0, question_time_limit - int(elapsed))
    if abs(client_time_remaining - server_remaining) > 3:
        return server_remaining
    return client_time_remaining


def calculate_score(
    time_remaining: int,
    streak: int,
    correct: bool,
) -> dict:
    """
    Calculate XP and AP earned for a single answer.

    Returns dict with keys:
        xp, ap, time_mult, combo_mult, tier, tier_emoji,
        streak_after, combo_label, is_correct
    """
    if not correct:
        return {
            "xp": 0,
            "ap": 0,
            "time_mult": 0.0,
            "combo_mult": 1.0,
            "tier": "MISS",
            "tier_emoji": "✗",
            "streak_after": 0,
            "combo_label": None,
            "is_correct": False,
        }

    time_mult, tier, _ = get_time_multiplier(time_remaining)
    streak_after = streak + 1
    combo_mult = get_combo_multiplier(streak_after)
    combo_label = get_combo_label(streak_after)

    xp = round(BASE_XP * time_mult * combo_mult)
    ap = round(BASE_AP * time_mult * combo_mult)

    return {
        "xp": xp,
        "ap": ap,
        "time_mult": time_mult,
        "combo_mult": combo_mult,
        "tier": tier,
        "tier_emoji": TIER_EMOJIS.get(tier, ""),
        "streak_after": streak_after,
        "combo_label": combo_label,
        "is_correct": True,
    }


ACHIEVEMENT_TRIGGERS = [
    {"key": "first_blood",   "condition": "wins_total >= 1"},
    {"key": "on_fire",       "condition": "max_combo_this_match >= 5"},
    {"key": "perfect_shot",  "condition": "lightning_count_this_match >= 5"},
    {"key": "btp_master",    "condition": "btp_wins >= 20"},
    {"key": "rival_slayer",  "condition": "same_opponent_wins >= 3"},
    {"key": "speed_demon",   "condition": "total_lightning_all_time >= 10"},
    {"key": "untouchable",   "condition": "win_streak >= 5"},
    {"key": "comeback_king", "condition": "comeback_win == True"},
    {"key": "champion",      "condition": "weekly_rank == 1"},
    {"key": "lucky",         "condition": "jackpot_hit == True"},
]
