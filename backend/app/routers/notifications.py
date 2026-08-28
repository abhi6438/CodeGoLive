from fastapi import APIRouter, Depends
from ..supabase_client import get_supabase
from ..auth import get_current_user, CurrentUser

router = APIRouter(prefix="/api/notifications", tags=["notifications"])


@router.get("")
async def list_notifications(user: CurrentUser = Depends(get_current_user)):
    sb = get_supabase()
    res = (
        sb.table("notifications")
        .select("*")
        .eq("user_id", user.id)
        .order("created_at", desc=True)
        .limit(50)
        .execute()
    )
    return res.data


@router.post("/{notification_id}/read")
async def mark_read(notification_id: str, user: CurrentUser = Depends(get_current_user)):
    sb = get_supabase()
    sb.table("notifications").update({"read": True}).eq("id", notification_id).eq(
        "user_id", user.id
    ).execute()
    return {"ok": True}
