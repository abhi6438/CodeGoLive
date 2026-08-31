import os
from dotenv import load_dotenv

load_dotenv()  # reads .env file

BASE    = os.environ["AICORE_BASE_URL"]
TOKEN   = os.environ["AICORE_TOKEN"]
DEPID   = os.environ["AICORE_DEPLOYMENT_ID"]
RG      = os.environ.get("AICORE_RG", "default")
HEADERS = {
    "Authorization": f"Bearer {TOKEN}",
    "Content-Type": "application/json",
    "AI-Resource-Group": RG,
}
URL = f"{BASE}/inference/deployments/{DEPID}/chat/completions"

INJECTION_PATTERNS = [
    r"ignore\s+(all\s+)?(previous|above)\s+instructions",
    r"system\s*prompt",
    r"jailbreak",
    r"act\s+as\s+(if\s+you\s+are|a)\s+\w+\s+(without|ignoring)",
    r"DAN\s+mode",
    r"<\s*script\s*>",
    r"EXECUTE\s+IMMEDIATE",
    r"DROP\s+TABLE",
]

PII_PATTERNS = {
    "email":   r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b",
    "phone":   r"\b(\+?\d{1,3}[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}\b",
    "iban":    r"\b[A-Z]{2}\d{2}[A-Z0-9]{4}\d{7,}\b",
    "sap_user": r"\bS\d{10}\b",
}
