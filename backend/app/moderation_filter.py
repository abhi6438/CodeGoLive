"""
Lightweight abuse pre-filter with three-tier decision:

  - "reject"  → clearly abusive content; the API returns HTTP 422 immediately,
                 the content is never saved.
  - "review"  → borderline content; saved as status="pending" so a moderator
                 can inspect it.  auto_flagged=True sorts it to the top of the
                 moderation queue.
  - "approve" → clean content; saved as status="approved" and shown immediately.

Swap _HARD_REJECT / _REVIEW_WORDS for a proper moderation API (e.g. an
LLM-based classifier) when ready; the calling code only uses moderate().
"""

_HARD_REJECT = {
    # Clearly abusive — immediate rejection, never stored
    "fuck", "shit", "bitch", "cunt", "asshole", "motherfucker",
    "faggot", "retard", "nigger", "spic", "kike", "chink", "whore",
    "bastard", "dickhead", "prick",
}

_REVIEW_WORDS = {
    # Borderline — save as pending for moderator review
    "idiot", "stupid", "shut up", "dumb", "hate you",
    "loser", "jerk", "moron", "useless", "trash", "garbage",
}


def moderate(text: str) -> str:
    """Return 'reject', 'review', or 'approve'."""
    lowered = text.lower()
    if any(w in lowered for w in _HARD_REJECT):
        return "reject"
    if any(w in lowered for w in _REVIEW_WORDS):
        return "review"
    return "approve"


# Backward-compatible helper used by older call sites
def contains_abuse(text: str) -> bool:
    return moderate(text) != "approve"
