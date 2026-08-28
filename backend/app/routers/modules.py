from fastapi import APIRouter
from ..supabase_client import get_supabase

router = APIRouter(prefix="/api/modules", tags=["modules"])


@router.get("")
async def list_modules():
    sb = get_supabase()
    res = sb.table("modules").select("*").order("order_index").execute()
    return res.data


@router.get("/{module_id}/topics")
async def list_topics_for_module(module_id: str):
    sb = get_supabase()
    res = (
        sb.table("topics")
        .select("*")
        .eq("module_id", module_id)
        .order("order_index")
        .execute()
    )
    return res.data
