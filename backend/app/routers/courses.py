from fastapi import APIRouter
from ..supabase_client import get_supabase

router = APIRouter(prefix="/api/courses", tags=["courses"])


@router.get("")
async def list_courses():
    """Public endpoint — returns all courses with module/topic counts."""
    sb = get_supabase()
    res = sb.table("courses").select("*, modules(id, number, title, subtitle, order_index, topics(id))").order("order_index").execute()
    enriched = []
    for c in res.data:
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
async def get_course(course_id: str):
    """Public endpoint — single course with counts."""
    sb = get_supabase()
    res = sb.table("courses").select("*, modules(id, topics(id))").eq("id", course_id).maybe_single().execute()
    if not res.data:
        from fastapi import HTTPException
        raise HTTPException(404, "Course not found")
    c = res.data
    mods = c.pop("modules", []) or []
    topic_count = sum(len(m.get("topics") or []) for m in mods)
    return {**c, "module_count": len(mods), "topic_count": topic_count}
