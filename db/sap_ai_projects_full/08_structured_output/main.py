"""
Project: SAP AI Core Python Examples
Topic:   08_structured_output
Goal:    Extract a structured JSON support ticket from a support email using response_format json_schema.
"""

import requests, json
from config import HEADERS, URL, SUPPORT_EMAIL, SCHEMA

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
