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

TURNS = [
    "I need to build a BTP application for our procurement team of 50 users.",
    "We need SAP Integration Suite to connect with 3 external supplier APIs daily.",
    "Add an AI service for invoice anomaly detection, processing 10,000 invoices/month.",
    "What is the estimated monthly cost for everything we discussed? Give a rough range in USD.",
]
