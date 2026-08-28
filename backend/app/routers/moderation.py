from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from ..supabase_client import get_supabase
from ..auth import get_current_user, CurrentUser, assert_role

router = APIRouter(prefix="/api/moderation", tags=["moderation"])


@router.get("/queue")
async def get_queue(user: CurrentUser = Depends(get_current_user)):
    assert_role(user, "moderator", "admin")
    sb = get_supabase()

    pending_answers = (
        sb.table("answers")
        .select("*, profiles(display_name), questions(title)")
        .eq("status", "pending")
        .order("auto_flagged", desc=True)
        .order("created_at")
        .execute()
        .data
    )
    pending_replies = (
        sb.table("replies")
        .select("*, profiles(display_name)")
        .eq("status", "pending")
        .order("auto_flagged", desc=True)
        .order("created_at")
        .execute()
        .data
    )
    return {"answers": pending_answers, "replies": pending_replies}


class ModerationDecision(BaseModel):
    approve: bool
    note: str | None = None


@router.post("/answers/{answer_id}")
async def moderate_answer(
    answer_id: str, decision: ModerationDecision, user: CurrentUser = Depends(get_current_user)
):
    assert_role(user, "moderator", "admin")
    sb = get_supabase()
    new_status = "approved" if decision.approve else "rejected"
    sb.table("answers").update({"status": new_status, "moderator_note": decision.note}).eq(
        "id", answer_id
    ).execute()

    if decision.approve:
        answer = sb.table("answers").select("user_id, question_id").eq("id", answer_id).single().execute().data
        sb.table("notifications").insert({
            "user_id": answer["user_id"],
            "type": "answered",
            "source_id": answer_id,
        }).execute()

    return {"ok": True}


@router.post("/replies/{reply_id}")
async def moderate_reply(
    reply_id: str, decision: ModerationDecision, user: CurrentUser = Depends(get_current_user)
):
    assert_role(user, "moderator", "admin")
    sb = get_supabase()
    new_status = "approved" if decision.approve else "rejected"
    sb.table("replies").update({"status": new_status, "moderator_note": decision.note}).eq(
        "id", reply_id
    ).execute()

    if decision.approve:
        reply = sb.table("replies").select("mentions").eq("id", reply_id).single().execute().data
        for mentioned_id in reply.get("mentions", []):
            sb.table("notifications").insert({
                "user_id": mentioned_id,
                "type": "mentioned",
                "source_id": reply_id,
            }).execute()

    return {"ok": True}
