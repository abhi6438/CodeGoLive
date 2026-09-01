import random
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import List
from ..supabase_client import get_supabase
from ..auth import get_current_user, CurrentUser

router = APIRouter(prefix="/api/assessment", tags=["assessment"])

PASS_PERCENTAGE = 70        # % correct to pass
QUESTIONS_PER_ATTEMPT = 30  # random subset shown per attempt
COURSE_ID = "sap-btp"


# ─────────────────────────────────────────────
# GET /api/assessment/status
# ─────────────────────────────────────────────
@router.get("/status")
def assessment_status(
    user: CurrentUser = Depends(get_current_user),
    course_id: str = COURSE_ID,
):
    """Has the user passed the assessment for the given course?"""
    sb = get_supabase()
    res = (
        sb.table("assessment_attempts")
        .select("id, score, total, passed, attempted_at")
        .eq("user_id", user.id)
        .eq("course_id", course_id)
        .order("attempted_at", desc=True)
        .limit(1)
        .execute()
    )
    best = (
        sb.table("assessment_attempts")
        .select("score, total")
        .eq("user_id", user.id)
        .eq("course_id", course_id)
        .eq("passed", True)
        .limit(1)
        .execute()
    )
    # Count all attempts
    count_res = (
        sb.table("assessment_attempts")
        .select("id", count="exact")
        .eq("user_id", user.id)
        .eq("course_id", course_id)
        .execute()
    )
    return {
        "passed": bool(best.data),
        "last_attempt": res.data[0] if res.data else None,
        "total_attempts": count_res.count or 0,
    }


# ─────────────────────────────────────────────
# GET /api/assessment/questions
# ─────────────────────────────────────────────
@router.get("/questions")
def get_questions(
    user: CurrentUser = Depends(get_current_user),
    course_id: str = COURSE_ID,
):
    """Return a randomised subset of questions (without revealing correct answers)."""
    sb = get_supabase()
    res = (
        sb.table("assessment_questions")
        .select("id, question, options, topic_slug, order_num")
        .eq("course_id", course_id)
        .execute()
    )
    if not res.data:
        raise HTTPException(404, "No questions found for this course")

    pool = res.data
    random.shuffle(pool)
    subset = pool[:QUESTIONS_PER_ATTEMPT]
    # Re-number for display
    for i, q in enumerate(subset):
        q["number"] = i + 1
    return {"questions": subset, "total": len(subset), "pass_percentage": PASS_PERCENTAGE}


# ─────────────────────────────────────────────
# POST /api/assessment/submit
# ─────────────────────────────────────────────
class AnswerItem(BaseModel):
    question_id: str
    selected_option: int  # 0-3


class SubmitBody(BaseModel):
    course_id: str = COURSE_ID
    answers: List[AnswerItem]


@router.post("/submit")
def submit_assessment(body: SubmitBody, user: CurrentUser = Depends(get_current_user)):
    """Grade the submitted answers; record attempt; issue cert if all topics done + passed."""
    if not body.answers:
        raise HTTPException(400, "No answers submitted")

    sb = get_supabase()

    # Fetch the submitted questions with their correct answers
    question_ids = [a.question_id for a in body.answers]
    res = (
        sb.table("assessment_questions")
        .select("id, question, options, correct_option, explanation, topic_slug")
        .in_("id", question_ids)
        .execute()
    )
    if not res.data:
        raise HTTPException(404, "Questions not found")

    questions_map = {q["id"]: q for q in res.data}

    # Build answer map
    answer_map = {a.question_id: a.selected_option for a in body.answers}

    # Grade
    results = []
    correct_count = 0
    for q in res.data:
        qid = q["id"]
        selected = answer_map.get(qid, -1)
        is_correct = selected == q["correct_option"]
        if is_correct:
            correct_count += 1
        results.append({
            "question_id": qid,
            "question": q["question"],
            "options": q["options"],
            "selected_option": selected,
            "correct_option": q["correct_option"],
            "is_correct": is_correct,
            "explanation": q["explanation"],
            "topic_slug": q["topic_slug"],
        })

    total = len(results)
    score_pct = round((correct_count / total) * 100) if total else 0
    passed = score_pct >= PASS_PERCENTAGE

    # Record attempt
    sb.table("assessment_attempts").insert({
        "user_id": user.id,
        "course_id": body.course_id,
        "score": correct_count,
        "total": total,
        "passed": passed,
    }).execute()

    # If passed, try to issue certificate (check all topics complete too)
    cert_issued = False
    if passed:
        total_topics_res = sb.table("topics").select("id", count="exact").execute()
        completed_res = (
            sb.table("user_progress")
            .select("topic_id")
            .eq("user_id", user.id)
            .eq("status", "completed")
            .execute()
        )
        all_done = len(completed_res.data) >= (total_topics_res.count or 0)
        if all_done:
            sb.table("certificates").upsert(
                {"user_id": user.id},
                on_conflict="user_id"
            ).execute()
            cert_issued = True

    return {
        "correct": correct_count,
        "total": total,
        "score_percentage": score_pct,
        "passed": passed,
        "cert_issued": cert_issued,
        "pass_percentage": PASS_PERCENTAGE,
        "results": results,
    }
