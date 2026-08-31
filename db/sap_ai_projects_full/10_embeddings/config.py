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

MODULES = [
    ("FI", "SAP Financial Accounting: manages general ledger, accounts payable, accounts receivable, and asset accounting."),
    ("MM", "SAP Materials Management: covers procurement, inventory management, and invoice verification for supply chain."),
    ("SD", "SAP Sales and Distribution: handles order management, shipping, billing, and customer master data."),
    ("HR", "SAP Human Resources: manages payroll, time management, personnel administration, and talent development."),
    ("PP", "SAP Production Planning: controls manufacturing orders, capacity planning, MRP, and shop floor operations."),
]
