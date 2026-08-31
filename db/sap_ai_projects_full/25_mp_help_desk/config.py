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

SYSTEM = """You are an SAP Help Desk assistant for ACME Corp.
Help users with SAP issues, error messages, and how-to questions.
Be concise (max 3 sentences). Always suggest the SAP transaction code when relevant.
If the issue needs a ticket, say 'I recommend creating a ticket for this.'"""

tickets = []
