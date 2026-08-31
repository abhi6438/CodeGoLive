from fastapi import APIRouter, Request
from pydantic import BaseModel
from typing import Optional
import urllib.request, json
from ..supabase_client import get_supabase

router = APIRouter(prefix="/api/analytics", tags=["analytics"])


class PageViewIn(BaseModel):
    path: str
    referrer: Optional[str] = None


class PageViewUpdate(BaseModel):
    duration_seconds: Optional[int] = None


def _get_geo(ip: str) -> dict:
    """Free geo lookup via ip-api.com — no key, 1000 req/min, stdlib only."""
    if not ip or ip in ("127.0.0.1", "::1", "testclient", ""):
        return {"country": None, "city": None}
    try:
        url = f"http://ip-api.com/json/{ip}?fields=country,city,status"
        with urllib.request.urlopen(url, timeout=2) as resp:
            data = json.loads(resp.read())
            if data.get("status") == "success":
                return {"country": data.get("country"), "city": data.get("city")}
    except Exception:
        pass
    return {"country": None, "city": None}


@router.post("")
async def record_pageview(body: PageViewIn, request: Request):
    """Record a page view silently on every route change."""
    forwarded = request.headers.get("x-forwarded-for", "")
    ip = forwarded.split(",")[0].strip() if forwarded else (request.client.host if request.client else "")

    geo = _get_geo(ip)

    sb = get_supabase()
    row = {
        "path": body.path,
        "referrer": body.referrer or None,
        "country": geo["country"],
        "city": geo["city"],
    }

    # Attach user_id if authenticated (best-effort)
    try:
        auth_header = request.headers.get("authorization", "")
        if auth_header.startswith("Bearer "):
            token = auth_header[7:]
            user_data = sb.auth.get_user(token)
            if user_data and user_data.user:
                row["user_id"] = user_data.user.id
    except Exception:
        pass

    result = sb.table("page_views").insert(row).execute()
    if result.data:
        return {"id": result.data[0]["id"]}
    return {"id": None}


@router.patch("/{view_id}")
async def update_duration(view_id: int, body: PageViewUpdate):
    """Update time-spent for an already-recorded page view."""
    if body.duration_seconds is None or body.duration_seconds < 0:
        return {"ok": False}
    sb = get_supabase()
    sb.table("page_views").update({"duration_seconds": body.duration_seconds}).eq("id", view_id).execute()
    return {"ok": True}
