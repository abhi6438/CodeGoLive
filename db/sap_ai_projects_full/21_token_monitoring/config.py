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

COST_PER_1K_PROMPT     = 0.005
COST_PER_1K_COMPLETION = 0.015

USER_REQUESTS = [
    ("alice@acme.com", "Summarize the key features of SAP S/4HANA in 3 bullet points."),
    ("bob@acme.com",   "Explain what an SAP iDoc is and when to use it."),
    ("alice@acme.com", "What are the main differences between BTP Cloud Foundry and Kyma?"),
    ("carol@acme.com", "List 5 common SAP Basis transactions with their purpose."),
    ("bob@acme.com",   "How does the SAP transport system work? Explain DEV -> QAS -> PRD."),
]
