import os
from dotenv import load_dotenv

load_dotenv()  # reads .env file

HANA_HOST = os.environ["HANA_HOST"]
HANA_PORT = int(os.environ.get("HANA_PORT", "443"))
HANA_USER = os.environ["HANA_USER"]
HANA_PASS = os.environ["HANA_PASSWORD"]

BASE     = os.environ["AICORE_BASE_URL"]
TOKEN    = os.environ["AICORE_TOKEN"]
EMB_DEPID = os.environ["AICORE_EMB_DEPLOYMENT_ID"]
RG       = os.environ.get("AICORE_RG", "default")
EMB_URL  = f"{BASE}/inference/deployments/{EMB_DEPID}/embeddings"
HEADERS  = {"Authorization": f"Bearer {TOKEN}", "Content-Type": "application/json", "AI-Resource-Group": RG}

SAP_DOCS = [
    ("DOC001", "MM60", "Transaction MM60 displays inventory turnover analysis by material and plant."),
    ("DOC002", "FB70", "Transaction FB70 is used to post customer invoices in SAP Financial Accounting."),
    ("DOC003", "ME21N", "Transaction ME21N creates purchase orders in SAP Materials Management."),
    ("DOC004", "VA01", "Transaction VA01 creates sales orders in SAP Sales and Distribution."),
    ("DOC005", "SE38", "Transaction SE38 is the ABAP editor for writing and editing SAP programs."),
]
