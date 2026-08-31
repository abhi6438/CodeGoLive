import os
from dotenv import load_dotenv

load_dotenv()  # reads .env file

BASE    = os.environ["AICORE_BASE_URL"]
TOKEN   = os.environ["AICORE_TOKEN"]
EMB_ID  = os.environ["AICORE_EMB_DEPLOYMENT_ID"]
RG      = os.environ.get("AICORE_RG", "default")
HEADERS = {
    "Authorization": f"Bearer {TOKEN}",
    "Content-Type": "application/json",
    "AI-Resource-Group": RG,
}
EMB_URL = f"{BASE}/inference/deployments/{EMB_ID}/embeddings"

KB_ARTICLES = [
    {"id": "KB001", "title": "How to reset SAP user password",
     "text": "Administrators can reset passwords in SU01. Navigate to SU01, enter user ID, click Change, set new password in Logon Data tab."},
    {"id": "KB002", "title": "Goods receipt posting in MIGO",
     "text": "To post a goods receipt: open MIGO, select Goods Receipt and Purchase Order, enter PO number, verify quantities, post with movement type 101."},
    {"id": "KB003", "title": "Running payroll in SAP HR",
     "text": "Execute payroll via PC00_M99_CALC. Ensure master data is locked, run simulation first, review log, then post to FI with PC00_M99_CIPE."},
    {"id": "KB004", "title": "Creating a vendor in SAP MM",
     "text": "Create vendors in XK01 for all company codes or MK01 for purchasing only. Required fields: name, country, reconciliation account, payment terms."},
    {"id": "KB005", "title": "Troubleshooting RFC connection errors",
     "text": "Check RFC destination in SM59. Test connection using Remote Logon. Common issues: wrong hostname, firewall blocking port 3300, invalid credentials."},
]
