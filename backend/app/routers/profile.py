from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, constr
from ..auth import get_current_user, CurrentUser
from ..db import get_sb

router = APIRouter(prefix="/api/profile", tags=["profile"])


class ProfileUpdate(BaseModel):
    display_name: constr(min_length=1, max_length=80, strip_whitespace=True)


@router.patch("")
def update_profile(body: ProfileUpdate, user: CurrentUser = Depends(get_current_user)):
    sb = get_sb()
    res = (
        sb.table("profiles")
        .update({"display_name": body.display_name})
        .eq("id", user.id)
        .select()
        .maybe_single()
        .execute()
    )
    if not res.data:
        raise HTTPException(status_code=404, detail="Profile not found")
    return res.data
