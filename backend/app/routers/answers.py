from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from ..supabase_client import get_supabase
from ..auth import get_current_user, CurrentUser
from ..moderation_filter import moderate

router = APIRouter(prefix="/api/answers", tags=["answers"])


class AnswerCreate(BaseModel):
    question_id: str
    body: str


@router.post("")
async def create_answer(body: AnswerCreate, user: CurrentUser = Depends(get_current_user)):
    sb = get_supabase()

    decision = moderate(body.body)
    if decision == "reject":
        raise HTTPException(422, "Your answer contains inappropriate language and was not posted.")

    status = "approved" if decision == "approve" else "pending"
    auto_flagged = (decision == "review")

    res = (
        sb.table("answers")
        .insert({
            "question_id": body.question_id,
            "user_id": user.id,
            "body": body.body,
            "status": status,
            "auto_flagged": auto_flagged,
        })
        .execute()
    )
    return res.data[0]


@router.post("/{answer_id}/accept")
async def accept_answer(answer_id: str, user: CurrentUser = Depends(get_current_user)):
    """Only the original asker of the parent question may accept an answer."""
    sb = get_supabase()
    ans = sb.table("answers").select("question_id").eq("id", answer_id).single().execute()
    if not ans.data:
        raise HTTPException(404, "Answer not found")

    question = sb.table("questions").select("user_id").eq("id", ans.data["question_id"]).single().execute()
    if not question.data or question.data["user_id"] != user.id:
        raise HTTPException(403, "Only the asker can accept an answer")

    # unset any previous accepted answer on this question, then set this one
    sb.table("answers").update({"accepted": False}).eq("question_id", ans.data["question_id"]).execute()
    sb.table("answers").update({"accepted": True}).eq("id", answer_id).execute()

    sb.table("notifications").insert({
        "user_id": sb.table("answers").select("user_id").eq("id", answer_id).single().execute().data["user_id"],
        "type": "accepted",
        "source_id": answer_id,
    }).execute()

    return {"ok": True}


@router.post("/{answer_id}/vote")
async def vote_answer(answer_id: str, value: int, user: CurrentUser = Depends(get_current_user)):
    if value not in (1, -1):
        raise HTTPException(400, "value must be 1 or -1")
    sb = get_supabase()
    sb.table("votes").upsert(
        {"user_id": user.id, "target_type": "answer", "target_id": answer_id, "value": value},
        on_conflict="user_id,target_type,target_id",
    ).execute()
    return {"ok": True}
