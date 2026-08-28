import os
from functools import lru_cache

from dotenv import load_dotenv

load_dotenv()


class Settings:
    SUPABASE_URL: str = os.environ.get("SUPABASE_URL", "")
    SUPABASE_SERVICE_ROLE_KEY: str = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "")
    SUPABASE_JWT_SECRET: str = os.environ.get("SUPABASE_JWT_SECRET", "")
    ALLOWED_ORIGINS: list[str] = os.environ.get(
        "ALLOWED_ORIGINS", "http://localhost:5173"
    ).split(",")


@lru_cache
def get_settings() -> Settings:
    return Settings()
