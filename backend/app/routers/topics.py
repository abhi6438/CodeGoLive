from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from ..supabase_client import get_supabase
from ..auth import get_current_user, get_optional_user, CurrentUser

router = APIRouter(prefix="/api/topics", tags=["topics"])


@router.get("/search")
async def search_topics(q: str):
    sb = get_supabase()
    q = q.strip()
    if not q:
        return []

    results = []
    seen_slugs = set()

    # ── 1. Full-text search on search_vector (best quality matches) ────────────
    try:
        fts = sb.table("topics").select(
            "slug, title, description, focus, content_md, modules(id, title, course_id)"
        ).text_search("search_vector", q).execute()
        for row in (fts.data or []):
            if row["slug"] not in seen_slugs:
                seen_slugs.add(row["slug"])
                results.append(_enrich(row, q))
    except Exception:
        pass

    # ── 2. ILIKE fallback — partial word match on title, description, focus ────
    try:
        like_q = f"%{q}%"
        ilike = sb.table("topics").select(
            "slug, title, description, focus, content_md, modules(id, title, course_id)"
        ).ilike("title", like_q).execute()
        for row in (ilike.data or []):
            if row["slug"] not in seen_slugs:
                seen_slugs.add(row["slug"])
                results.append(_enrich(row, q))
    except Exception:
        pass

    try:
        like_q = f"%{q}%"
        ilike2 = sb.table("topics").select(
            "slug, title, description, focus, content_md, modules(id, title, course_id)"
        ).ilike("description", like_q).execute()
        for row in (ilike2.data or []):
            if row["slug"] not in seen_slugs:
                seen_slugs.add(row["slug"])
                results.append(_enrich(row, q))
    except Exception:
        pass

    # ── 3. content_md search — search inside the full lesson text ──────────────
    try:
        like_q = f"%{q}%"
        content_res = sb.table("topics").select(
            "slug, title, description, focus, content_md, modules(id, title, course_id)"
        ).ilike("content_md", like_q).execute()
        for row in (content_res.data or []):
            if row["slug"] not in seen_slugs:
                seen_slugs.add(row["slug"])
                results.append(_enrich(row, q))
    except Exception:
        pass

    # Strip content_md from final response (only snippet is returned)
    for r in results:
        r.pop("content_md", None)

    return results


def _enrich(row: dict, q: str) -> dict:
    """Add a short snippet showing context around the search term."""
    snippet = ""
    q_lower = q.lower()

    # Try to find context in content_md
    content = row.get("content_md") or ""
    idx = content.lower().find(q_lower)
    if idx != -1:
        start = max(0, idx - 80)
        end = min(len(content), idx + len(q) + 120)
        raw = content[start:end].replace("\n", " ").replace("#", "").strip()
        if start > 0:
            raw = "…" + raw
        if end < len(content):
            raw = raw + "…"
        snippet = raw
    elif row.get("description"):
        snippet = row["description"]

    row["snippet"] = snippet
    # Flatten module info for frontend
    mod = row.pop("modules", None)
    if isinstance(mod, dict):
        row["course_id"] = mod.get("course_id")
        row["module_title"] = mod.get("title")
    elif isinstance(mod, list) and mod:
        row["course_id"] = mod[0].get("course_id")
        row["module_title"] = mod[0].get("title")
    else:
        row.setdefault("course_id", None)
        row.setdefault("module_title", None)
    return row

@router.get("/{slug}")
async def get_topic(slug: str, user: CurrentUser | None = Depends(get_optional_user)):
    sb = get_supabase()
    topic_res = sb.table("topics").select("*").eq("slug", slug).maybe_single().execute()
    if not topic_res.data:
        raise HTTPException(404, "Topic not found")
    topic = topic_res.data

    try:
        images = (
            sb.table("content_images")
            .select("*")
            .eq("topic_id", topic["id"])
            .execute()
            .data
        ) or []
    except Exception:
        images = []

    try:
        prereqs_res = (
            sb.table("topic_prerequisites")
            .select("requires_topic_id")
            .eq("topic_id", topic["id"])
            .execute()
        )
        prereq_ids = [r["requires_topic_id"] for r in (prereqs_res.data or [])]
        if prereq_ids:
            prereq_topics = (
                sb.table("topics")
                .select("id, slug, title")
                .in_("id", prereq_ids)
                .execute()
                .data
            ) or []
        else:
            prereq_topics = []
        prereqs = [{"requires_topic_id": p["id"], "topics": {"slug": p["slug"], "title": p["title"]}} for p in prereq_topics]
    except Exception:
        prereqs = []

    progress_status = "not_started"
    if user:
        try:
            prog = (
                sb.table("user_progress")
                .select("status")
                .eq("user_id", user.id)
                .eq("topic_id", topic["id"])
                .maybe_single()
                .execute()
            )
            if prog.data:
                progress_status = prog.data["status"]
        except Exception:
            pass

    # fetch github repos
    try:
        repos = (
            sb.table("topic_github_repos")
            .select("*")
            .eq("topic_id", topic["id"])
            .order("order_index")
            .execute()
            .data
        ) or []
    except Exception:
        repos = []

    # fetch videos
    try:
        videos = (
            sb.table("topic_videos")
            .select("*")
            .eq("topic_id", topic["id"])
            .order("order_index")
            .execute()
            .data
        ) or []
    except Exception:
        videos = []

    return {
        **topic,
        "images": images,
        "prerequisites": prereqs,
        "progress_status": progress_status,
        "github_repos": repos,
        "videos": videos,
    }


class ProgressUpdate(BaseModel):
    status: str  # in_progress | completed


@router.post("/{slug}/progress")
async def update_progress(
    slug: str, body: ProgressUpdate, user: CurrentUser = Depends(get_current_user)
):
    if body.status not in ("in_progress", "completed"):
        raise HTTPException(400, "Invalid status")

    sb = get_supabase()
    topic_res = sb.table("topics").select("id").eq("slug", slug).maybe_single().execute()
    if not topic_res.data:
        raise HTTPException(404, "Topic not found")
    topic_id = topic_res.data["id"]

    payload = {"user_id": user.id, "topic_id": topic_id, "status": body.status}
    if body.status == "completed":
        payload["completed_at"] = "now()"

    sb.table("user_progress").upsert(payload, on_conflict="user_id,topic_id").execute()
    return {"ok": True}


@router.post("/{slug}/complete")
async def complete_topic(slug: str, user: CurrentUser = Depends(get_current_user)):
    """Mark a topic complete, then check if the whole course is done → auto-issue certificate."""
    sb = get_supabase()

    topic_res = sb.table("topics").select("id, module_id").eq("slug", slug).maybe_single().execute()
    if not topic_res.data:
        raise HTTPException(404, "Topic not found")
    topic = topic_res.data

    # Upsert progress as completed
    sb.table("user_progress").upsert(
        {"user_id": user.id, "topic_id": topic["id"], "status": "completed", "completed_at": "now()"},
        on_conflict="user_id,topic_id",
    ).execute()

    # Look up which course this topic belongs to
    mod_res = sb.table("modules").select("course_id").eq("id", topic["module_id"]).maybe_single().execute()
    if not mod_res.data:
        return {"ok": True, "course_completed": False}
    course_id = mod_res.data["course_id"]

    # All published topic IDs in this course
    mod_ids_res = sb.table("modules").select("id").eq("course_id", course_id).execute()
    mod_ids = [m["id"] for m in (mod_ids_res.data or [])]
    if not mod_ids:
        return {"ok": True, "course_completed": False}

    pub_res = sb.table("topics").select("id").in_("module_id", mod_ids).eq("status", "published").execute()
    pub_ids = [t["id"] for t in (pub_res.data or [])]
    if not pub_ids:
        return {"ok": True, "course_completed": False}

    # How many has the user completed?
    comp_res = sb.table("user_progress").select("topic_id")         .eq("user_id", user.id).eq("status", "completed")         .in_("topic_id", pub_ids).execute()
    completed_count = len(comp_res.data or [])
    course_completed = completed_count >= len(pub_ids)

    if course_completed:
        # Try per-course cert first, fall back to legacy single-cert schema
        try:
            sb.table("certificates").upsert(
                {"user_id": user.id, "course_id": course_id, "issued_at": "now()"},
                on_conflict="user_id,course_id",
            ).execute()
        except Exception:
            sb.table("certificates").upsert(
                {"user_id": user.id, "issued_at": "now()"},
                on_conflict="user_id",
            ).execute()

    return {"ok": True, "course_completed": course_completed, "course_id": course_id}
