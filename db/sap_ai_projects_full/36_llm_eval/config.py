import os
from dotenv import load_dotenv

load_dotenv()  # reads .env file

BASE    = os.environ["AICORE_BASE_URL"]
TOKEN   = os.environ["AICORE_TOKEN"]
DEPID   = os.environ["AICORE_DEPLOYMENT_ID"]
RG      = os.environ.get("AICORE_RG", "default")
HEADERS = {"Authorization": f"Bearer {TOKEN}", "Content-Type": "application/json", "AI-Resource-Group": RG}
URL     = f"{BASE}/inference/deployments/{DEPID}/chat/completions"

SAP_QA_PAIRS = [
    {"question": "What is transaction MM60?", "expected_topic": "inventory turnover",
     "context": "MM60 displays inventory analysis including stock turnover by material and plant."},
    {"question": "How to post a vendor invoice?", "expected_topic": "invoice posting",
     "context": "Use transaction MIRO for logistics invoice verification or FB60 for direct FI posting."},
    {"question": "What is a cost center in SAP?", "expected_topic": "cost center controlling",
     "context": "A cost center is an organizational unit in SAP CO that tracks costs for a department."},
    {"question": "Explain SAP Material Ledger", "expected_topic": "material valuation",
     "context": "Material Ledger in SAP enables actual costing and records all goods movements at actual cost."},
    {"question": "What is the purpose of profit center?", "expected_topic": "profit center accounting",
     "context": "Profit centers represent units of responsibility in SAP and allow internal P&L reporting."},
]
