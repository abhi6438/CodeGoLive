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

DOC_CHUNKS = [
    {"id": "c1", "text": "SAP S/4HANA Finance simplifies the universal journal by merging FI and CO into a single source of truth. The ACDOCA table replaces multiple summary tables, enabling real-time financial reporting.", "source": "S4HANA_Finance_Guide.pdf", "page": 12},
    {"id": "c2", "text": "The SAP Fiori UX strategy uses role-based apps. Each app is designed for one task on any device. Fiori launchpad is the entry point and can be customized with tiles and groups.", "source": "Fiori_Design_Guide.pdf", "page": 5},
    {"id": "c3", "text": "SAP Integration Suite (formerly CPI) connects cloud and on-premise systems. iFlows define integration logic using adapters for SOAP, REST, OData, SFTP, and more.", "source": "Integration_Suite_Handbook.pdf", "page": 23},
    {"id": "c4", "text": "SAP BTP offers Cloud Foundry, Kyma (Kubernetes), and ABAP environments. Choose Cloud Foundry for Node.js/Java microservices, Kyma for containers, ABAP for S/4HANA extensions.", "source": "BTP_Developer_Guide.pdf", "page": 8},
    {"id": "c5", "text": "SAP AI Core runs AI workloads on Kubernetes. Deployments expose model APIs, pipelines handle training. Resource groups isolate tenants. Authentication uses XSUAA tokens.", "source": "AI_Core_Operations.pdf", "page": 34},
    {"id": "c6", "text": "Material ledger in SAP MM enables multi-currency and multi-valuation inventory. Actual costing closes the period and recalculates material prices based on actual costs.", "source": "MM_Controlling_Guide.pdf", "page": 67},
]
