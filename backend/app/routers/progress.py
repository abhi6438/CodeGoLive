from fastapi import APIRouter, Depends
from ..supabase_client import get_supabase
from ..auth import get_current_user, CurrentUser
from datetime import datetime, timezone, timedelta

router = APIRouter(prefix="/api/progress", tags=["progress"])


@router.get("/summary")
async def get_progress_summary(user: CurrentUser = Depends(get_current_user)):
    sb = get_supabase()

    # All published topics grouped by course → module
    courses_res = sb.table("courses").select(
        "id, title, modules(id, title, order_index, topics(id, status))"
    ).order("order_index").execute()

    # User's progress rows
    prog_res = sb.table("user_progress").select(
        "topic_id, status, completed_at"
    ).eq("user_id", user.id).execute()

    progress_map = {}  # topic_id → {status, completed_at}
    all_completed_dts = []
    completed_date_set = set()

    for p in (prog_res.data or []):
        progress_map[p["topic_id"]] = p
        if p.get("status") == "completed" and p.get("completed_at"):
            try:
                dt = datetime.fromisoformat(p["completed_at"].replace("Z", "+00:00"))
                all_completed_dts.append(dt)
                completed_date_set.add(dt.date().isoformat())
            except Exception:
                pass

    result = []
    for c in (courses_res.data or []):
        modules_raw = c.get("modules") or []
        course_total = 0
        course_completed = 0
        course_in_progress = 0
        module_rows = []

        for m in sorted(modules_raw, key=lambda x: x.get("order_index", 0)):
            published = [t for t in (m.get("topics") or []) if t.get("status") == "published"]
            total = len(published)
            comp = sum(1 for t in published if progress_map.get(t["id"], {}).get("status") == "completed")
            inprog = sum(1 for t in published if progress_map.get(t["id"], {}).get("status") == "in_progress")

            if total > 0:
                module_rows.append({
                    "module_id": m["id"],
                    "title": m["title"],
                    "order_index": m.get("order_index", 0),
                    "total": total,
                    "completed": comp,
                    "in_progress": inprog,
                    "pct": round(comp / total * 100),
                })
                course_total += total
                course_completed += comp
                course_in_progress += inprog

        result.append({
            "course_id": c["id"],
            "title": c["title"],
            "total_topics": course_total,
            "completed": course_completed,
            "in_progress": course_in_progress,
            "completion_pct": round(course_completed / course_total * 100) if course_total > 0 else 0,
            "modules": module_rows,
        })

    # Streak: consecutive days with at least one completion (from today or yesterday backwards)
    today = datetime.now(timezone.utc).date()
    streak = 0
    check = today
    while check.isoformat() in completed_date_set:
        streak += 1
        check -= timedelta(days=1)
    if streak == 0:
        check = today - timedelta(days=1)
        while check.isoformat() in completed_date_set:
            streak += 1
            check -= timedelta(days=1)

    total_completed = sum(c["completed"] for c in result)
    last_completed_at = max(all_completed_dts).isoformat() if all_completed_dts else None

    return {
        "courses": result,
        "streak": streak,
        "total_completed": total_completed,
        "last_completed_at": last_completed_at,
    }
