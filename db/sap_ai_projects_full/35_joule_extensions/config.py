import os
from dotenv import load_dotenv

load_dotenv()  # reads .env file

BASE    = os.environ["AICORE_BASE_URL"]
TOKEN   = os.environ["AICORE_TOKEN"]
DEPID   = os.environ["AICORE_DEPLOYMENT_ID"]
RG      = os.environ.get("AICORE_RG", "default")
HEADERS = {"Authorization": f"Bearer {TOKEN}", "Content-Type": "application/json", "AI-Resource-Group": RG}
URL     = f"{BASE}/inference/deployments/{DEPID}/chat/completions"

SKILL_MANIFEST = {
    "apiVersion": "joule.sap.com/v1alpha1",
    "kind": "Skill",
    "metadata": {"name": "sap-po-analysis-skill", "namespace": "default"},
    "spec": {
        "displayName": "Purchase Order Analysis",
        "description": "Analyzes SAP purchase orders and provides spend insights and vendor recommendations",
        "version": "1.0.0",
        "inputSchema": {
            "type": "object",
            "properties": {
                "company_code": {"type": "string", "description": "SAP company code (e.g. '1000')"},
                "fiscal_year": {"type": "string", "description": "Fiscal year (e.g. '2024')"},
                "analysis_type": {
                    "type": "string",
                    "enum": ["spend_summary", "vendor_ranking", "anomaly_detection"],
                    "description": "Type of analysis to perform",
                },
            },
            "required": ["company_code", "fiscal_year", "analysis_type"],
        },
        "outputSchema": {
            "type": "object",
            "properties": {
                "text": {"type": "string"},
                "actions": {"type": "array", "items": {"type": "object"}},
                "data": {"type": "object"},
            },
        },
        "btpServiceBinding": {
            "serviceInstance": "genai-hub-instance",
            "secretName": "genai-hub-binding",
            "resourceGroup": "joule-skills",
        },
    },
}
