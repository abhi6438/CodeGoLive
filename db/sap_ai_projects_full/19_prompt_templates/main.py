"""
Project: SAP AI Core Python Examples
Topic:   19_prompt_templates
Goal:    Jinja2 templates for SAP change request documentation. Two CR examples.
Requirements: pip install jinja2 requests
"""

import requests
from jinja2 import Template
from config import HEADERS, URL, CR_TEMPLATE, CHANGE_REQUESTS

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
