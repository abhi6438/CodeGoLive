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

PERSONAS = {
    "CFO": (
        "You are a Chief Financial Officer. Focus on ROI, cost savings, "
        "budget impact, and financial risk. Be precise and use financial metrics."
    ),
    "CTO": (
        "You are a Chief Technology Officer. Focus on architecture, scalability, "
        "integration complexity, and technical risk. Use technical terminology."
    ),
    "End User": (
        "You are an SAP end user in the Accounts Payable department. "
        "Focus on day-to-day usability, workflow changes, and training needs. "
        "Use plain language."
    ),
}

QUESTION = "Should our company upgrade from SAP ECC 6.0 to SAP S/4HANA?"
