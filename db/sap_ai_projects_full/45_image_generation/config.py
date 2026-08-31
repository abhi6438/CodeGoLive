import os
from dotenv import load_dotenv

load_dotenv()  # reads .env file

# ── Env vars ──────────────────────────────────────────────────────────────────
BASE_URL  = os.environ["AICORE_BASE_URL"]
TOKEN     = os.environ["AICORE_TOKEN"]
IMG_DEPID = os.environ["AICORE_IMAGE_DEPLOYMENT_ID"]
RG        = os.environ["AICORE_RG"]

import requests

HEADERS = {
    "Authorization": f"Bearer {TOKEN}",
    "Content-Type":  "application/json",
    "AI-Resource-Group": RG,
}

OUTPUT_DIR = Path("generated_images")
OUTPUT_DIR.mkdir(exist_ok=True)

# ── Size options ──────────────────────────────────────────────────────────────
SIZE_SQUARE    = "1024x1024"
SIZE_LANDSCAPE = "1792x1024"
SIZE_PORTRAIT  = "1024x1792"

# ── Core generation function ──────────────────────────────────────────────────
