"""
Project: SAP AI Core Python Examples
Topic:   19_prompt_templates
Goal:    Jinja2 templates for SAP change request documentation. Two CR examples.
Requirements: pip install jinja2 requests
"""
import requests, os
from jinja2 import Template

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

CR_TEMPLATE = Template("""
You are an SAP change management expert. Generate a formal change request document.

Change Request: {{ cr_id }}
System: {{ system }} ({{ environment }})
Requestor: {{ requestor }} | Team: {{ team }}
Priority: {{ priority }} | Type: {{ change_type }}
Planned Date: {{ planned_date }}

Description:
{{ description }}

Affected Components: {{ components | join(', ') }}
Rollback Plan: {{ rollback }}

Please generate:
1. Risk assessment (HIGH/MEDIUM/LOW with justification)
2. Impact analysis (3 bullet points)
3. Pre-implementation checklist (4 items)
4. Formal approval recommendation
""".strip())

CHANGE_REQUESTS = [
    {
        "cr_id": "CR-2024-0892",
        "system": "SAP S/4HANA",
        "environment": "Production PRD",
        "requestor": "Maria Weber",
        "team": "Basis",
        "priority": "HIGH",
        "change_type": "Infrastructure",
        "planned_date": "2024-03-30 22:00 CET",
        "description": "Apply SAP kernel patch 7.91 PL12 to fix security vulnerability CVE-2024-12345. Current kernel 7.91 PL08 is affected.",
        "components": ["SAP Kernel", "Work Processes", "ICM"],
        "rollback": "Revert to kernel PL08 via backup; downtime estimated 45 minutes.",
    },
    {
        "cr_id": "CR-2024-0901",
        "system": "SAP BTP Integration Suite",
        "environment": "Production CF EU10",
        "requestor": "Klaus Müller",
        "team": "Integration",
        "priority": "MEDIUM",
        "change_type": "Configuration",
        "planned_date": "2024-04-05 18:00 CET",
        "description": "Deploy new iFlow 'Vendor Invoice Processing v3.2' to automate 3-way match between PO, GR and vendor invoice via EDI 810.",
        "components": ["Integration Suite", "iFlow", "SFTP Adapter", "OData Connector"],
        "rollback": "Deactivate new iFlow and reactivate v3.1; no data loss expected.",
    },
]

def generate_cr_doc(cr_data):
    prompt = CR_TEMPLATE.render(**cr_data)
    r = requests.post(URL, headers=HEADERS, json={
        "model": "gpt-4o",
        "messages": [{"role": "user", "content": prompt}],
        "max_tokens": 400,
    }, timeout=30)
    r.raise_for_status()
    return r.json()["choices"][0]["message"]["content"].strip()

if __name__ == "__main__":
    for cr in CHANGE_REQUESTS:
        print(f"\n{'=' * 60}\nChange Request: {cr['cr_id']}\n{'=' * 60}")
        doc = generate_cr_doc(cr)
        print(doc)
