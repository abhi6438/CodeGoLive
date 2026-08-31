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

SCREENSHOT_DESCRIPTION = """
[SAP Fiori Screenshot Description]
The screen shows the SAP S/4HANA Fiori launchpad with the following layout:
- Top navigation bar: SAP logo on left, search icon, bell icon (3 notifications), user avatar 'JS' on right
- Main area shows 4 tile groups:
  Group 1 'Finance': 'Post Journal Entry', 'Display GL Account', 'Manage Bank Accounts' tiles
  Group 2 'Procurement': 'Create Purchase Order' tile with a red badge showing '12 pending approvals'
  Group 3 'Reports': 'Cash Flow Analysis' tile showing sparkline chart trending down 8% this month
  Group 4 'Administration': 'User Management', 'System Status' tiles
- System Status tile shows WARNING icon with text 'Background jobs: 2 failed'
- Footer shows current user: John Smith | Company: ACME Corp | System: S4H PRD
"""
