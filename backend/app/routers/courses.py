from fastapi import APIRouter, Depends
from ..supabase_client import get_supabase
from ..auth import get_optional_user, CurrentUser

router = APIRouter(prefix="/api/courses", tags=["courses"])


@router.get("")
async def list_courses(user: CurrentUser | None = Depends(get_optional_user)):
    """Public endpoint — returns all courses the caller can access.
    Restricted courses are hidden unless the user has an explicit grant."""
    sb = get_supabase()
    res = sb.table("courses").select("*, modules(id, number, title, subtitle, order_index, topics(id))").order("order_index").execute()

    # Collect course IDs the user has been granted access to
    accessible: set = set()
    if user:
        try:
            access_res = sb.table("user_course_access").select("course_id").eq("user_id", user.id).execute()
            accessible = {r["course_id"] for r in (access_res.data or [])}
        except Exception:
            pass  # table not yet created — treat as no grants

    enriched = []
    for c in res.data:
        # Skip restricted courses the user has no grant for
        if c.get("access_type", "public") == "restricted" and c["id"] not in accessible:
            # Admins always see everything
            if not user or user.role not in ("admin", "moderator"):
                continue
        mods = sorted(c.pop("modules", []) or [], key=lambda m: m.get("order_index", 0))
        topic_count = sum(len(m.get("topics") or []) for m in mods)
        enriched.append({
            **c,
            "module_count": len(mods),
            "topic_count": topic_count,
            "modules": [
                {"title": m["title"], "subtitle": m.get("subtitle"), "number": m.get("number")}
                for m in mods
            ],
        })
    return enriched


@router.get("/{course_id}")
async def get_course(course_id: str, user: CurrentUser | None = Depends(get_optional_user)):
    """Public endpoint — single course with counts. Returns 404 for restricted courses the caller cannot access."""
    sb = get_supabase()
    res = sb.table("courses").select("*, modules(id, topics(id))").eq("id", course_id).maybe_single().execute()
    if not res.data:
        from fastapi import HTTPException
        raise HTTPException(404, "Course not found")
    c = res.data
    # Enforce access control for restricted courses
    if c.get("access_type", "public") == "restricted":
        allowed = False
        if user:
            if user.role in ("admin", "moderator"):
                allowed = True
            else:
                try:
                    access = sb.table("user_course_access").select("id")                                .eq("user_id", user.id).eq("course_id", course_id)                                .maybe_single().execute()
                    allowed = bool(access.data)
                except Exception:
                    allowed = False  # table not yet created
        if not allowed:
            from fastapi import HTTPException
            raise HTTPException(404, "Course not found")
    mods = c.pop("modules", []) or []
    topic_count = sum(len(m.get("topics") or []) for m in mods)
    return {**c, "module_count": len(mods), "topic_count": topic_count}
