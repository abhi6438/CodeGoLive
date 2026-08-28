from fastapi import APIRouter, Query
from typing import Optional
from ..supabase_client import get_supabase

router = APIRouter(prefix="/api/modules", tags=["modules"])


@router.get("")
async def list_modules(course_id: Optional[str] = Query(None)):
    sb = get_supabase()
    q = sb.table("modules").select("*").order("order_index")
    if course_id:
        q = q.eq("course_id", course_id)
    res = q.execute()
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
