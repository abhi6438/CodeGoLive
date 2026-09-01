from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from ..supabase_client import get_supabase
from ..auth import get_current_user, CurrentUser, assert_role

router = APIRouter(prefix="/api/admin", tags=["admin"])


# ─── Stats ────────────────────────────────────────────────────────────────────

@router.get("/stats")
async def get_stats(user: CurrentUser = Depends(get_current_user)):
    assert_role(user, "admin")
    sb = get_supabase()

    courses = sb.table("courses").select("id, status").execute().data
    modules = sb.table("modules").select("id").execute().data
    topics = sb.table("topics").select("id, status").execute().data
    users = sb.table("profiles").select("id, role").execute().data

    published = sum(1 for t in topics if t.get("status") == "published")
    draft = sum(1 for t in topics if t.get("status") != "published")
    active_courses = sum(1 for c in courses if c.get("status") == "available")

    return {
        "courses": len(courses),
        "active_courses": active_courses,
        "modules": len(modules),
        "topics": len(topics),
        "published_topics": published,
        "draft_topics": draft,
        "users": len(users),
        "admins": sum(1 for u in users if u.get("role") == "admin"),
        "moderators": sum(1 for u in users if u.get("role") == "moderator"),
        "learners": sum(1 for u in users if u.get("role") == "learner"),
    }


# ─── Courses ──────────────────────────────────────────────────────────────────

class CourseCreate(BaseModel):
    id: str           # slug like "sap-btp"
    title: str
    description: str | None = None
    status: str = "coming_soon"   # available | coming_soon | archived
    icon: str | None = None
    color: str | None = None
    order_index: int = 0


class CourseUpdate(BaseModel):
    title: str | None = None
    subtitle: str | None = None
    description: str | None = None
    status: str | None = None
    icon: str | None = None
    color: str | None = None
    order_index: int | None = None


@router.get("/courses")
async def list_courses(user: CurrentUser = Depends(get_current_user)):
    assert_role(user, "admin")
    sb = get_supabase()
    res = sb.table("courses").select("*, modules(id)").order("order_index").execute()
    # Enrich with module count
    enriched = []
    for c in res.data:
        mods = c.pop("modules", []) or []
        enriched.append({**c, "module_count": len(mods)})
    return enriched


@router.post("/courses")
async def create_course(body: CourseCreate, user: CurrentUser = Depends(get_current_user)):
    assert_role(user, "admin")
    sb = get_supabase()
    res = sb.table("courses").insert(body.model_dump()).execute()
    if not res.data:
        raise HTTPException(400, "Failed to create course")
    return res.data[0]


@router.patch("/courses/{course_id}")
async def update_course(course_id: str, body: CourseUpdate, user: CurrentUser = Depends(get_current_user)):
    assert_role(user, "admin")
    sb = get_supabase()
    payload = {k: v for k, v in body.model_dump().items() if v is not None}
    if not payload:
        raise HTTPException(400, "No fields to update")
    sb.table("courses").update(payload).eq("id", course_id).execute()
    res = sb.table("courses").select("*").eq("id", course_id).maybe_single().execute()
    if not res.data:
        raise HTTPException(404, "Course not found")
    return res.data


@router.delete("/courses/{course_id}")
async def delete_course(course_id: str, user: CurrentUser = Depends(get_current_user)):
    assert_role(user, "admin")
    sb = get_supabase()
    # Check for modules — block delete if any exist
    modules = sb.table("modules").select("id").eq("course_id", course_id).execute().data
    if modules:
        raise HTTPException(409, f"Cannot delete course with {len(modules)} module(s). Remove modules first.")
    sb.table("courses").delete().eq("id", course_id).execute()
    return {"ok": True}


# ─── Modules ──────────────────────────────────────────────────────────────────

class ModuleCreate(BaseModel):
    course_id: str
    number: str
    title: str
    description: str | None = None
    order_index: int = 0


class ModuleUpdate(BaseModel):
    course_id: str | None = None
    number: str | None = None
    title: str | None = None
    description: str | None = None
    order_index: int | None = None


@router.get("/modules")
async def list_modules(course_id: str | None = None, user: CurrentUser = Depends(get_current_user)):
    assert_role(user, "admin")
    sb = get_supabase()
    q = sb.table("modules").select("*, topics(id), courses(title)").order("order_index")
    if course_id:
        q = q.eq("course_id", course_id)
    res = q.execute()
    enriched = []
    for m in res.data:
        topics = m.pop("topics", []) or []
        course = m.pop("courses", None) or {}
        enriched.append({**m, "topic_count": len(topics), "course_title": course.get("title", "")})
    return enriched


@router.post("/modules")
async def create_module(body: ModuleCreate, user: CurrentUser = Depends(get_current_user)):
    assert_role(user, "admin")
    sb = get_supabase()
    res = sb.table("modules").insert(body.model_dump()).execute()
    if not res.data:
        raise HTTPException(400, "Failed to create module")
    return res.data[0]


@router.patch("/modules/{module_id}")
async def update_module(module_id: str, body: ModuleUpdate, user: CurrentUser = Depends(get_current_user)):
    assert_role(user, "admin")
    sb = get_supabase()
    payload = {k: v for k, v in body.model_dump().items() if v is not None}
    if not payload:
        raise HTTPException(400, "No fields to update")
    sb.table("modules").update(payload).eq("id", module_id).execute()
    res = sb.table("modules").select("*").eq("id", module_id).maybe_single().execute()
    if not res.data:
        raise HTTPException(404, "Module not found")
    return res.data


@router.delete("/modules/{module_id}")
async def delete_module(module_id: str, user: CurrentUser = Depends(get_current_user)):
    assert_role(user, "admin")
    sb = get_supabase()
    topics = sb.table("topics").select("id").eq("module_id", module_id).execute().data
    if topics:
        raise HTTPException(409, f"Cannot delete module with {len(topics)} topic(s). Remove topics first.")
    sb.table("modules").delete().eq("id", module_id).execute()
    return {"ok": True}


# ─── Topics ───────────────────────────────────────────────────────────────────

class TopicUpdate(BaseModel):
    title: str | None = None
    focus: str | None = None
    description: str | None = None
    video_url: str | None = None
    github_url: str | None = None
    deliverable_note: str | None = None
    content_md: str | None = None
    order_index: int | None = None
    status: str | None = None   # published | draft


@router.patch("/topics/{topic_id}")
async def update_topic(topic_id: str, body: TopicUpdate, user: CurrentUser = Depends(get_current_user)):
    assert_role(user, "admin")
    sb = get_supabase()
    payload = {k: v for k, v in body.model_dump().items() if v is not None}
    if not payload:
        raise HTTPException(400, "No fields to update")
    sb.table("topics").update(payload).eq("id", topic_id).execute()
    res = sb.table("topics").select("*").eq("id", topic_id).maybe_single().execute()
    if not res.data:
        raise HTTPException(404, "Topic not found")
    return res.data


class TopicCreate(BaseModel):
    module_id: str
    number: str
    slug: str
    title: str
    focus: str | None = None
    description: str | None = None
    video_url: str | None = None
    github_url: str | None = None
    order_index: int = 0
    status: str = "draft"


@router.post("/topics")
async def create_topic(body: TopicCreate, user: CurrentUser = Depends(get_current_user)):
    assert_role(user, "admin")
    sb = get_supabase()
    res = sb.table("topics").insert(body.model_dump()).execute()
    if not res.data:
        raise HTTPException(400, "Failed to create topic")
    return res.data[0]


@router.delete("/topics/{topic_id}")
async def delete_topic(topic_id: str, user: CurrentUser = Depends(get_current_user)):
    assert_role(user, "admin")
    sb = get_supabase()
    sb.table("topics").delete().eq("id", topic_id).execute()
    return {"ok": True}


@router.get("/topics")
async def list_topics_admin(module_id: str | None = None, user: CurrentUser = Depends(get_current_user)):
    assert_role(user, "admin")
    sb = get_supabase()
    q = sb.table("topics").select("*, modules(title, course_id, courses(title))").order("order_index")
    if module_id:
        q = q.eq("module_id", module_id)
    res = q.execute()
    enriched = []
    for t in res.data:
        mod = t.pop("modules", None) or {}
        course = mod.pop("courses", None) or {}
        enriched.append({
            **t,
            "module_title": mod.get("title", ""),
            "course_title": course.get("title", ""),
        })
    return enriched


# ─── Users ────────────────────────────────────────────────────────────────────

@router.get("/users")
async def list_users(user: CurrentUser = Depends(get_current_user)):
    assert_role(user, "admin")
    sb = get_supabase()
    res = sb.table("profiles").select("*").order("created_at", desc=True).execute()
    return res.data


class RoleUpdate(BaseModel):
    role: str  # learner | moderator | admin


@router.patch("/users/{user_id}/role")
async def update_user_role(user_id: str, body: RoleUpdate, user: CurrentUser = Depends(get_current_user)):
    assert_role(user, "admin")
    if body.role not in ("learner", "moderator", "admin"):
        raise HTTPException(400, "Invalid role")
    sb = get_supabase()
    sb.table("profiles").update({"role": body.role}).eq("id", user_id).execute()
    return {"ok": True}


# ─── Tags ─────────────────────────────────────────────────────────────────────

@router.post("/tags/merge")
async def merge_tags(source_tag_id: str, target_tag_id: str, user: CurrentUser = Depends(get_current_user)):
    assert_role(user, "admin")
    sb = get_supabase()
    links = sb.table("question_tags").select("question_id").eq("tag_id", source_tag_id).execute().data
    for link in links:
        sb.table("question_tags").upsert(
            {"question_id": link["question_id"], "tag_id": target_tag_id}
        ).execute()
    sb.table("question_tags").delete().eq("tag_id", source_tag_id).execute()
    sb.table("tags").delete().eq("id", source_tag_id).execute()
    return {"ok": True}


@router.get("/tags")
async def list_tags(user: CurrentUser = Depends(get_current_user)):
    assert_role(user, "admin")
    sb = get_supabase()
    res = sb.table("tags").select("*").order("usage_count", desc=True).execute()
    return res.data


# ── GitHub Repos per topic ──────────────────────────────────────────────────

class RepoCreate(BaseModel):
    topic_id: str
    url: str
    label: str | None = None
    language: str | None = None
    order_index: int = 0

class RepoUpdate(BaseModel):
    url: str | None = None
    label: str | None = None
    language: str | None = None
    order_index: int | None = None

@router.get("/topics/{topic_id}/repos")
async def list_repos(topic_id: str, user: CurrentUser = Depends(get_current_user)):
    assert_role(user, "admin")
    sb = get_supabase()
    return sb.table("topic_github_repos").select("*").eq("topic_id", topic_id).order("order_index").execute().data

@router.post("/topics/{topic_id}/repos")
async def create_repo(topic_id: str, body: RepoCreate, user: CurrentUser = Depends(get_current_user)):
    assert_role(user, "admin")
    sb = get_supabase()
    payload = {**body.model_dump(), "topic_id": topic_id}
    res = sb.table("topic_github_repos").insert(payload).execute()
    return res.data[0]

@router.patch("/repos/{repo_id}")
async def update_repo(repo_id: str, body: RepoUpdate, user: CurrentUser = Depends(get_current_user)):
    assert_role(user, "admin")
    sb = get_supabase()
    payload = {k: v for k, v in body.model_dump().items() if v is not None}
    sb.table("topic_github_repos").update(payload).eq("id", repo_id).execute()
    return sb.table("topic_github_repos").select("*").eq("id", repo_id).maybe_single().execute().data

@router.delete("/repos/{repo_id}")
async def delete_repo(repo_id: str, user: CurrentUser = Depends(get_current_user)):
    assert_role(user, "admin")
    sb = get_supabase()
    sb.table("topic_github_repos").delete().eq("id", repo_id).execute()
    return {"ok": True}


# ── Videos per topic ────────────────────────────────────────────────────────

class VideoCreate(BaseModel):
    topic_id: str
    url: str
    title: str | None = None
    duration_minutes: int | None = None
    order_index: int = 0

class VideoUpdate(BaseModel):
    url: str | None = None
    title: str | None = None
    duration_minutes: int | None = None
    order_index: int | None = None

@router.get("/topics/{topic_id}/videos")
async def list_videos(topic_id: str, user: CurrentUser = Depends(get_current_user)):
    assert_role(user, "admin")
    sb = get_supabase()
    return sb.table("topic_videos").select("*").eq("topic_id", topic_id).order("order_index").execute().data

@router.post("/topics/{topic_id}/videos")
async def create_video(topic_id: str, body: VideoCreate, user: CurrentUser = Depends(get_current_user)):
    assert_role(user, "admin")
    sb = get_supabase()
    payload = {**body.model_dump(), "topic_id": topic_id}
    res = sb.table("topic_videos").insert(payload).execute()
    return res.data[0]

@router.patch("/videos/{video_id}")
async def update_video(video_id: str, body: VideoUpdate, user: CurrentUser = Depends(get_current_user)):
    assert_role(user, "admin")
    sb = get_supabase()
    payload = {k: v for k, v in body.model_dump().items() if v is not None}
    sb.table("topic_videos").update(payload).eq("id", video_id).execute()
    return sb.table("topic_videos").select("*").eq("id", video_id).maybe_single().execute().data

@router.delete("/videos/{video_id}")
async def delete_video(video_id: str, user: CurrentUser = Depends(get_current_user)):
    assert_role(user, "admin")
    sb = get_supabase()
    sb.table("topic_videos").delete().eq("id", video_id).execute()
    return {"ok": True}


@router.get("/analytics")
async def get_analytics(user: CurrentUser = Depends(get_current_user)):
    assert_role(user, "admin")
    """Return aggregated analytics for the admin dashboard."""
    sb = get_supabase()
    from datetime import datetime, timedelta, timezone
    now = datetime.now(timezone.utc)
    today_start = now.replace(hour=0, minute=0, second=0, microsecond=0).isoformat()
    week_start  = (now - timedelta(days=7)).isoformat()
    month_start = (now - timedelta(days=30)).isoformat()

    def count_since(since: str) -> int:
        r = sb.table("page_views").select("id", count="exact").gte("created_at", since).execute()
        return r.count or 0

    views_today = count_since(today_start)
    views_7d    = count_since(week_start)
    views_30d   = count_since(month_start)

    # Average session duration (last 30d, only rows with duration recorded)
    dur_rows = (
        sb.table("page_views")
        .select("duration_seconds")
        .gte("created_at", month_start)
        .not_.is_("duration_seconds", "null")
        .execute()
        .data or []
    )
    durations = [r["duration_seconds"] for r in dur_rows if r["duration_seconds"]]
    avg_duration = round(sum(durations) / len(durations)) if durations else 0

    # Top 10 pages (last 30d)
    all_views = (
        sb.table("page_views")
        .select("path")
        .gte("created_at", month_start)
        .execute()
        .data or []
    )
    from collections import Counter
    top_pages = [
        {"path": p, "count": c}
        for p, c in Counter(r["path"] for r in all_views).most_common(10)
    ]

    # Top 10 countries (last 30d)
    country_rows = (
        sb.table("page_views")
        .select("country")
        .gte("created_at", month_start)
        .not_.is_("country", "null")
        .execute()
        .data or []
    )
    top_countries = [
        {"country": co, "count": c}
        for co, c in Counter(r["country"] for r in country_rows if r["country"]).most_common(10)
    ]

    # Logged-in vs anonymous (last 30d)
    logged_in = (
        sb.table("page_views")
        .select("id", count="exact")
        .gte("created_at", month_start)
        .not_.is_("user_id", "null")
        .execute()
        .count or 0
    )

    # Recent 50 visits
    recent = (
        sb.table("page_views")
        .select("id, path, country, city, user_id, duration_seconds, created_at")
        .order("created_at", desc=True)
        .limit(50)
        .execute()
        .data or []
    )

    return {
        "views_today": views_today,
        "views_7d": views_7d,
        "views_30d": views_30d,
        "avg_duration_seconds": avg_duration,
        "top_pages": top_pages,
        "top_countries": top_countries,
        "logged_in_count": logged_in,
        "anonymous_count": views_30d - logged_in,
        "recent": recent,
    }



# ─── Assessment Settings ──────────────────────────────────────────────────────

class AssessmentSettingUpdate(BaseModel):
    enabled: bool


@router.get("/assessment-settings")
async def list_assessment_settings(user: CurrentUser = Depends(get_current_user)):
    assert_role(user, "admin")
    sb = get_supabase()
    courses = sb.table("courses").select("id, title, status").order("order_index").execute().data or []
    settings_res = sb.table("course_assessment_settings").select("course_id, enabled").execute().data or []
    settings_map = {s["course_id"]: s["enabled"] for s in settings_res}
    return [
        {
            "course_id": c["id"],
            "title": c["title"],
            "status": c["status"],
            "assessment_enabled": settings_map.get(c["id"], False),
        }
        for c in courses
    ]


@router.patch("/assessment-settings/{course_id}")
async def update_assessment_setting(
    course_id: str,
    body: AssessmentSettingUpdate,
    user: CurrentUser = Depends(get_current_user),
):
    assert_role(user, "admin")
    sb = get_supabase()
    sb.table("course_assessment_settings").upsert(
        {"course_id": course_id, "enabled": body.enabled},
        on_conflict="course_id",
    ).execute()
    return {"course_id": course_id, "assessment_enabled": body.enabled}
