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
        "*, profiles(display_name, avatar_url), question_tags(tags(name)), answers(id)"
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

    ins = (
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
    )
    if not ins or not ins.data:
        raise HTTPException(500, "Question could not be saved. Please try again.")
    q = ins.data[0]

    for tag_name in body.tags:
        tag_name = tag_name.strip().lower().lstrip("#")
        if not tag_name:
            continue
        try:
            existing = sb.table("tags").select("id, usage_count").eq("name", tag_name).maybe_single().execute()
            if existing and existing.data:
                tag_id = existing.data["id"]
                current_count = existing.data.get("usage_count") or 0
                sb.table("tags").update({"usage_count": current_count + 1}).eq("id", tag_id).execute()
            else:
                tag_ins = sb.table("tags").insert({"name": tag_name, "usage_count": 1}).execute()
                if not tag_ins or not tag_ins.data:
                    continue
                tag_id = tag_ins.data[0]["id"]
            sb.table("question_tags").insert({"question_id": q["id"], "tag_id": tag_id}).execute()
        except Exception:
            pass  # tag failure is non-fatal; question is already saved

    return q


@router.get("/community-stats")
async def community_stats():
    """Public endpoint — returns aggregate stats for the community page sidebar."""
    sb = get_supabase()
    try:
        q_count = sb.table("questions").select("id", count="exact").eq("deleted", False).execute().count or 0
        a_count = sb.table("answers").select("id", count="exact").execute().count or 0
        u_count = sb.table("profiles").select("id", count="exact").execute().count or 0
        tags = sb.table("tags").select("id, name, usage_count").gt("usage_count", 0).order("usage_count", desc=True).limit(12).execute().data or []
        return {"question_count": q_count, "answer_count": a_count, "member_count": u_count, "top_tags": tags}
    except Exception:
        return {"question_count": 0, "answer_count": 0, "member_count": 0, "top_tags": []}

@router.get("/{question_id}")
async def get_question(question_id: str):
    sb = get_supabase()
    q = sb.table("questions").select(
        "*, profiles(display_name, avatar_url), question_tags(tags(name)), answers(id)"
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

@router.delete("/{question_id}")
async def delete_question(question_id: str, user: CurrentUser = Depends(get_current_user)):
    sb = get_supabase()
    # Fetch question to verify ownership
    res = sb.table("questions").select("id, user_id").eq("id", question_id).single().execute()
    if not res or not res.data:
        raise HTTPException(404, "Question not found")
    q = res.data
    # Only author or admin may delete
    profile = sb.table("profiles").select("role").eq("id", user.id).single().execute()
    role = profile.data.get("role", "learner") if profile and profile.data else "learner"
    if q["user_id"] != user.id and role != "admin":
        raise HTTPException(403, "Not allowed")
    # Decrement usage_count for each tag on this question before soft-deleting
    try:
        qt_res = sb.table("question_tags").select("tag_id").eq("question_id", question_id).execute()
        if qt_res and qt_res.data:
            for qt in qt_res.data:
                tag_res = sb.table("tags").select("id, usage_count").eq("id", qt["tag_id"]).limit(1).execute()
                if tag_res and tag_res.data:
                    current = tag_res.data[0].get("usage_count") or 0
                    new_count = max(0, current - 1)
                    sb.table("tags").update({"usage_count": new_count}).eq("id", qt["tag_id"]).execute()
    except Exception:
        pass  # tag decrement is non-fatal
    sb.table("questions").update({"deleted": True}).eq("id", question_id).execute()
    return {"ok": True}
