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

EXPENSES = [
    {"id": "E001", "description": "Flight MUC-SFO + hotel for SAP TechEd conference", "amount": 2340.00},
    {"id": "E002", "description": "AWS EC2 instances for BTP development sandbox", "amount": 187.50},
    {"id": "E003", "description": "Team lunch at Zum Franziskaner restaurant, Munich", "amount": 312.80},
    {"id": "E004", "description": "SAP Learning Hub subscription – 12 months", "amount": 1200.00},
    {"id": "E005", "description": "Taxi from Frankfurt airport to customer site", "amount": 65.00},
]

CATEGORIES = ["TRAVEL", "IT_INFRASTRUCTURE", "MEALS_ENTERTAINMENT", "TRAINING", "LOCAL_TRANSPORT"]

SYSTEM = (
    f"Classify the expense into exactly one category: {', '.join(CATEGORIES)}. "
    "Reply with only the category name and a confidence (HIGH/MEDIUM/LOW) separated by '|'."
)
