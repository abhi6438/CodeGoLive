from fastapi import APIRouter, Request
from pydantic import BaseModel
from typing import Optional
import httpx
from ..supabase_client import get_supabase

router = APIRouter(prefix="/api/analytics", tags=["analytics"])


class PageViewIn(BaseModel):
    path: str
    referrer: Optional[str] = None


class PageViewUpdate(BaseModel):
    duration_seconds: Optional[int] = None


async def _get_geo(ip: str) -> dict:
    """Free geo lookup via ip-api.com — no key needed, 1000 req/min."""
    if not ip or ip in ("127.0.0.1", "::1", "testclient"):
        return {"country": None, "city": None}
    try:
        async with httpx.AsyncClient(timeout=2.0) as client:
            r = await client.get(f"http://ip-api.com/json/{ip}?fields=country,city,status")
            data = r.json()
            if data.get("status") == "success":
                return {"country": data.get("country"), "city": data.get("city")}
    except Exception:
        pass
    return {"country": None, "city": None}


@router.post("")
async def record_pageview(body: PageViewIn, request: Request):
    """Record a page view. Called silently from the frontend on every route change."""
    # Get client IP (Vercel sets X-Forwarded-For)
    forwarded = request.headers.get("x-forwarded-for", "")
    ip = forwarded.split(",")[0].strip() if forwarded else (request.client.host if request.client else "")

    geo = await _get_geo(ip)

    sb = get_supabase()
    row = {
        "path": body.path,
        "referrer": body.referrer or None,
        "country": geo["country"],
        "city": geo["city"],
    }

    # Attach user_id if authenticated (best-effort — ignore auth errors)
    try:
        auth_header = request.headers.get("authorization", "")
        if auth_header.startswith("Bearer "):
            from ..auth import get_current_user
            from fastapi.security import HTTPAuthorizationCredentials
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
    """Update the time-spent (duration) for an already-recorded page view."""
    if body.duration_seconds is None or body.duration_seconds < 0:
        return {"ok": False}
    sb = get_supabase()
    sb.table("page_views").update({"duration_seconds": body.duration_seconds}).eq("id", view_id).execute()
    return {"ok": True}
