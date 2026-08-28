from fastapi import Header, HTTPException, status
from pydantic import BaseModel
from .supabase_client import get_supabase


class CurrentUser(BaseModel):
    id: str
    role: str  # learner | moderator | admin
    display_name: str | None = None


async def get_current_user(authorization: str | None = Header(default=None)) -> CurrentUser:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Missing bearer token")

    token = authorization.removeprefix("Bearer ").strip()
    sb = get_supabase()

    # Verify token via Supabase — works with HS256 and RS256
    try:
        user_resp = sb.auth.get_user(token)
    except Exception as exc:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, f"Invalid token: {exc}")

    if not user_resp or not user_resp.user:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Token verification failed")

    user_id = user_resp.user.id

    # Fetch profile for role / display_name
    res = sb.table("profiles").select("id, role, display_name").eq("id", user_id).single().execute()
    if not res.data:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Profile not found")

    return CurrentUser(
        id=res.data["id"],
        role=res.data["role"],
        display_name=res.data.get("display_name"),
    )


async def get_optional_user(authorization: str | None = Header(default=None)) -> CurrentUser | None:
    if not authorization:
        return None
    try:
        return await get_current_user(authorization)
    except HTTPException:
        return None


def assert_role(user: CurrentUser, *allowed_roles: str) -> None:
    if user.role not in allowed_roles:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Insufficient permissions")
