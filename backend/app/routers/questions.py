from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from ..supabase_client import get_supabase
from ..auth import get_current_user, CurrentUser
from ..moderation_filter import moderate

router = APIRouter(prefix="/api/questions", tags=["questions"])


class QuestionCreate(BaseModel):
    title: str
    body: str
    topic_id: str | None = None  # None = general "Ask Anything" question
    tags: list[str] = []


@router.get("")
async def list_questions(topic_id: str | None = None, general_only: bool = False):
    sb = get_supabase()
    query = sb.table("questions").select(
        "*, profiles(display_name, avatar_url), question_tags(tags(name))"
    ).eq("deleted", False)

    if general_only:
        query = query.is_("topic_id", "null")
    elif topic_id:
        query = query.eq("topic_id", topic_id)

    res = query.order("created_at", desc=True).execute()
    return res.data


@router.post("")
async def create_question(body: QuestionCreate, user: CurrentUser = Depends(get_current_user)):
    sb = get_supabase()

    decision = moderate(f"{body.title} {body.body}")
    if decision == "reject":
        raise HTTPException(422, "Your question contains inappropriate language and was not posted.")

    status = "approved" if decision == "approve" else "pending"
    auto_flagged = (decision == "review")

    q = (
        sb.table("questions")
        .insert({
            "title": body.title,
            "body": body.body,
            "topic_id": body.topic_id,
            "user_id": user.id,
            "status": status,
            "auto_flagged": auto_flagged,
        })
        .execute()
        .data[0]
    )

    for tag_name in body.tags:
        tag_name = tag_name.strip().lower().lstrip("#")
        if not tag_name:
            continue
        existing = sb.table("tags").select("id").eq("name", tag_name).maybe_single().execute()
        if existing.data:
            tag_id = existing.data["id"]
            sb.table("tags").update({"usage_count": existing.data.get("usage_count", 0) + 1}).eq(
                "id", tag_id
            ).execute()
        else:
            tag_id = sb.table("tags").insert({"name": tag_name, "usage_count": 1}).execute().data[0]["id"]
        sb.table("question_tags").insert({"question_id": q["id"], "tag_id": tag_id}).execute()

    return q


@router.get("/{question_id}")
async def get_question(question_id: str):
    sb = get_supabase()
    q = sb.table("questions").select(
        "*, profiles(display_name, avatar_url), question_tags(tags(name))"
    ).eq("id", question_id).single().execute()
    if not q.data:
        raise HTTPException(404, "Question not found")

    # Approved, top-level answers with nested (approved) replies
    answers = (
        sb.table("answers")
        .select("*, profiles(display_name, avatar_url)")
        .eq("question_id", question_id)
        .eq("status", "approved")
        .eq("deleted", False)
        .order("accepted", desc=True)
        .order("created_at")
        .execute()
        .data
    )

    for a in answers:
        replies = (
            sb.table("replies")
            .select("*, profiles(display_name, avatar_url)")
            .eq("answer_id", a["id"])
            .eq("status", "approved")
            .eq("deleted", False)
            .order("created_at")
            .execute()
            .data
        )
        a["replies"] = replies

    return {**q.data, "answers": answers}
