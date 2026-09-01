from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, field_validator
from ..supabase_client import get_supabase
from ..auth import get_current_user, CurrentUser

router = APIRouter(prefix="/api/profile", tags=["profile"])


class ProfileUpdate(BaseModel):
    display_name: str

    @field_validator("display_name")
    @classmethod
    def validate_name(cls, v):
        v = v.strip()
        if not v:
            raise ValueError("Display name cannot be empty")
        if len(v) > 80:
            raise ValueError("Display name must be 80 characters or fewer")
        return v


@router.patch("")
def update_profile(body: ProfileUpdate, user: CurrentUser = Depends(get_current_user)):
    sb = get_supabase()
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
