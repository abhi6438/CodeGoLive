"""
Project: SAP GenAI Hub Integration Series
Topic:   35_joule_extensions
Goal:    Simulate a Joule skill extension: manifest, handler, BTP registration pattern
Requirements: pip install requests
"""

import os, json, requests

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


def joule_skill_handler(input_data: dict) -> dict:
    company_code = input_data["company_code"]
    fiscal_year = input_data["fiscal_year"]
    analysis_type = input_data["analysis_type"]

    mock_po_data = {
        "company_code": company_code,
        "fiscal_year": fiscal_year,
        "total_spend": 4250000,
        "po_count": 342,
        "top_vendors": ["SAP SE", "Microsoft", "AWS", "Dell Technologies"],
        "categories": {"IT": 62, "Services": 28, "Office": 10},
    }

    system_prompt = "You are Joule, SAP's AI assistant. Provide concise, actionable SAP insights."
    user_prompt = f"Analyze PO data for {company_code}/{fiscal_year}: {json.dumps(mock_po_data)}. Type: {analysis_type}"

    payload = {"model": "gpt-4o", "messages": [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": user_prompt},
    ], "max_tokens": 300}
    r = requests.post(URL, headers=HEADERS, json=payload, timeout=30)
    r.raise_for_status()
    analysis_text = r.json()["choices"][0]["message"]["content"]

    joule_response = {
        "text": analysis_text,
        "actions": [
            {"type": "navigate", "label": "Open PO Report in SAP", "transaction": "ME2N",
             "params": {"BUKRS": company_code, "GJAHR": fiscal_year}},
            {"type": "create_task", "label": "Schedule vendor review", "assignee": "procurement.manager"},
        ],
        "data": mock_po_data,
        "metadata": {"skill": "sap-po-analysis-skill", "version": "1.0.0", "confidence": 0.92},
    }
    return joule_response


def show_btp_registration():
    print("=== BTP Service Binding Registration Pattern ===")
    print("1. Create AI Core service instance on BTP:")
    print("   cf create-service aicore extended genai-hub-instance")
    print("2. Create service key:")
    print("   cf create-service-key genai-hub-instance genai-hub-binding")
    print("3. Register skill via Joule API (using binding credentials):")
    print("   POST /joule/v1/skills with manifest JSON")
    print("4. Skill appears in SAP Build Joule skill catalog")


if __name__ == "__main__":
    print("=== Joule Skill Manifest ===")
    print(json.dumps(SKILL_MANIFEST, indent=2))

    print("\n=== Invoking Skill Handler ===")
    result = joule_skill_handler({
        "company_code": "1000",
        "fiscal_year": "2024",
        "analysis_type": "spend_summary",
    })
    print(f"Response text: {result['text'][:200]}...")
    print(f"Actions: {[a['label'] for a in result['actions']]}")

    print()
    show_btp_registration()
