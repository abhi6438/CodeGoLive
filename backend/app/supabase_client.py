from functools import lru_cache
from supabase import create_client, Client
from .config import get_settings


@lru_cache
def get_supabase() -> Client:
    """
    Server-side Supabase client using the service_role key.
    This BYPASSES row-level security — only use it for operations the
    backend has already authorized (e.g. moderation actions, admin CRUD).
    Never expose this client or its key to the frontend.
    """
    settings = get_settings()
    if not settings.SUPABASE_URL or not settings.SUPABASE_SERVICE_ROLE_KEY:
        raise RuntimeError(
            "SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY are not set. "
            "Add them to backend/.env before running."
        )
    return create_client(settings.SUPABASE_URL, settings.SUPABASE_SERVICE_ROLE_KEY)
