from fastapi import APIRouter, Depends, HTTPException
from ..supabase_client import get_supabase
from ..auth import get_current_user, CurrentUser

router = APIRouter(prefix="/api/certificates", tags=["certificates"])


@router.get("/me")
async def my_certificate(user: CurrentUser = Depends(get_current_user)):
    """Return the current user's certificate, or 404 if not yet earned."""
    sb = get_supabase()
    res = (
        sb.table("certificates")
        .select("*, profiles(display_name)")
        .eq("user_id", user.id)
        .maybe_single()
        .execute()
    )
    if not res.data:
        raise HTTPException(404, "Certificate not yet earned")
    # Enrich with progress stats
    progress_res = (
        sb.table("user_progress")
        .select("topic_id")
        .eq("user_id", user.id)
        .eq("status", "completed")
        .execute()
    )
    total_res = sb.table("topics").select("id", count="exact").execute()
    return {
        **res.data,
        "completed_topics": len(progress_res.data),
        "total_topics": total_res.count,
    }


@router.get("/{user_id}/public")
async def public_certificate(user_id: str):
    """Public endpoint to verify a certificate by user_id (for sharing)."""
    sb = get_supabase()
    res = (
        sb.table("certificates")
        .select("*, profiles(display_name)")
        .eq("user_id", user_id)
        .maybe_single()
        .execute()
    )
    if not res.data:
        raise HTTPException(404, "No certificate found for this user")
    return res.data
