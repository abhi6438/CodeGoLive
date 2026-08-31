import os
from dotenv import load_dotenv

load_dotenv()  # reads .env file

# ── Env vars ──────────────────────────────────────────────────────────────────
ENVIRONMENT  = os.environ.get("ENVIRONMENT", "production")
OLLAMA_MODEL = os.environ.get("OLLAMA_MODEL", "llama3")
BASE_URL     = os.environ.get("AICORE_BASE_URL", "")
TOKEN        = os.environ.get("AICORE_TOKEN", "")
DEPLOY_ID    = os.environ.get("AICORE_DEPLOYMENT_ID", "")
RG           = os.environ.get("AICORE_RG", "default")

QUESTIONS = [
    "What is SAP S/4HANA Cloud?",
    "How does SAP Integration Suite help connect systems?",
    "What is SAP Build used for?",
]

# ── Ollama client ─────────────────────────────────────────────────────────────
