"""
Project: SAP AI Core Python Examples
Topic:   08_structured_output
Goal:    Extract a structured JSON support ticket from a support email using response_format json_schema.
"""
import requests, os, json

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

SUPPORT_EMAIL = """
From: m.schneider@acme-corp.de
Subject: Urgent - Cannot post goods receipt in MM

Hello Support team,

Since this morning our warehouse staff cannot post goods receipts against
purchase order 4500123456 in transaction MIGO. They get error message
M7 053 "Plant 1000 not allowed for movement type 101".

This is blocking 12 users in Munich warehouse. We need this resolved ASAP
as we have a critical delivery from vendor Bosch (LIF# 100045) arriving today.

Please help urgently.
Regards, Monika Schneider, Warehouse Manager
"""

SCHEMA = {
    "name": "support_ticket",
    "strict": True,
    "schema": {
        "type": "object",
        "properties": {
            "title":       {"type": "string"},
            "priority":    {"type": "string", "enum": ["LOW", "MEDIUM", "HIGH", "CRITICAL"]},
            "module":      {"type": "string"},
            "transaction": {"type": "string"},
            "error_code":  {"type": "string"},
            "affected_users": {"type": "integer"},
            "reporter":    {"type": "string"},
            "summary":     {"type": "string"},
        },
        "required": ["title","priority","module","transaction","error_code","affected_users","reporter","summary"],
        "additionalProperties": False,
    },
}

if __name__ == "__main__":
    r = requests.post(URL, headers=HEADERS, json={
        "model": "gpt-4o",
        "messages": [
            {"role": "system", "content": "Extract a support ticket from the email. Fill all fields."},
            {"role": "user", "content": SUPPORT_EMAIL},
        ],
        "response_format": {"type": "json_schema", "json_schema": SCHEMA},
        "max_tokens": 300,
    }, timeout=30)
    r.raise_for_status()
    ticket = json.loads(r.json()["choices"][0]["message"]["content"])
    print("Extracted Support Ticket:")
    print(json.dumps(ticket, indent=2))
