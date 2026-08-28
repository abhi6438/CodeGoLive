import re
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from ..supabase_client import get_supabase
from ..auth import get_current_user, CurrentUser
from ..moderation_filter import moderate

router = APIRouter(prefix="/api/replies", tags=["replies"])

MAX_DEPTH = 3
MENTION_RE = re.compile(r"@([a-zA-Z0-9_\.]+)")


class ReplyCreate(BaseModel):
    answer_id: str
    parent_reply_id: str | None = None
    body: str


def _depth(sb, parent_reply_id: str | None) -> int:
    depth = 0
    current = parent_reply_id
    while current:
        row = sb.table("replies").select("parent_reply_id").eq("id", current).maybe_single().execute()
        if not row.data:
            break
        depth += 1
        current = row.data["parent_reply_id"]
    return depth


@router.post("")
async def create_reply(body: ReplyCreate, user: CurrentUser = Depends(get_current_user)):
    sb = get_supabase()

    if body.parent_reply_id and _depth(sb, body.parent_reply_id) >= MAX_DEPTH:
        raise HTTPException(400, f"Replies can nest at most {MAX_DEPTH} levels deep")

    # Resolve @mentions to user ids by display_name
    mentioned_names = MENTION_RE.findall(body.body)
    mention_ids: list[str] = []
    for name in mentioned_names:
        match = sb.table("profiles").select("id").eq("display_name", name).maybe_single().execute()
        if match.data:
            mention_ids.append(match.data["id"])

    decision = moderate(body.body)
    if decision == "reject":
        raise HTTPException(422, "Your reply contains inappropriate language and was not posted.")

    status = "approved" if decision == "approve" else "pending"
    auto_flagged = (decision == "review")

    res = (
        sb.table("replies")
        .insert({
            "answer_id": body.answer_id,
            "parent_reply_id": body.parent_reply_id,
            "user_id": user.id,
            "body": body.body,
            "mentions": mention_ids,
            "status": status,
            "auto_flagged": auto_flagged,
        })
        .execute()
    )
    return res.data[0]


@router.post("/{reply_id}/vote")
async def vote_reply(reply_id: str, value: int, user: CurrentUser = Depends(get_current_user)):
    if value not in (1, -1):
        raise HTTPException(400, "value must be 1 or -1")
    sb = get_supabase()
    sb.table("votes").upsert(
        {"user_id": user.id, "target_type": "reply", "target_id": reply_id, "value": value},
        on_conflict="user_id,target_type,target_id",
    ).execute()
    return {"ok": True}
