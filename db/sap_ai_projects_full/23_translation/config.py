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

UI_STRINGS = [
    "Create Purchase Order",
    "Goods Receipt Posted Successfully",
    "Authorization Check Failed",
    "Select Company Code",
    "Post General Ledger Entry",
]
LANGUAGES = ["German", "French", "Spanish", "Japanese", "Portuguese"]

INCOMING_MESSAGES = [
    "Hallo, ich kann mich nicht in das SAP-System anmelden.",
    "Je ne trouve pas la transaction pour créer une commande d'achat.",
    "システムにログインできません。パスワードが正しくありません。",
]
