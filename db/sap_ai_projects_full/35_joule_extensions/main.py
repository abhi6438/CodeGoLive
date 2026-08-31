"""
Project: SAP GenAI Hub Integration Series
Topic:   35_joule_extensions
Goal:    Simulate a Joule skill extension: manifest, handler, BTP registration pattern
Requirements: pip install requests
"""

from config import HEADERS, URL, SKILL_MANIFEST

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
