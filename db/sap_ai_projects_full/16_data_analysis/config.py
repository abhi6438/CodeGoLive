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

SALES_CSV = """Region,Product,Q1_Revenue,Q2_Revenue,Q3_Revenue,Q4_Revenue,Target
EMEA,SAP S/4HANA Licenses,2450000,2780000,3100000,3420000,3000000
EMEA,SAP BTP Services,890000,1020000,1180000,1340000,1200000
EMEA,Professional Services,1560000,1490000,1720000,1850000,1600000
Americas,SAP S/4HANA Licenses,3200000,2900000,3500000,4100000,3800000
Americas,SAP BTP Services,1100000,1280000,1450000,1620000,1500000
Americas,Professional Services,2100000,2300000,2150000,2400000,2200000
APJ,SAP S/4HANA Licenses,1800000,1950000,2200000,2600000,2400000
APJ,SAP BTP Services,560000,680000,790000,920000,850000
APJ,Professional Services,980000,1120000,1050000,1230000,1100000"""

PROMPT = f"""Analyze this SAP sales performance data and provide an executive summary with:
1. Top 3 key findings (growth trends, over/underperformance vs target)
2. Which region and product combination performed best overall
3. A specific recommendation for Q1 next year
4. One risk to watch

Sales Data:
{SALES_CSV}"""
