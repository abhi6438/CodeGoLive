"""
Project: SAP AI Core Python Examples
Topic:   16_data_analysis
Goal:    Pass an inline CSV sales report to AI for executive summary analysis.
"""

import requests
from config import HEADERS, URL, PROMPT

if __name__ == "__main__":
    r = requests.post(URL, headers=HEADERS, json={
        "model": "gpt-4o",
        "messages": [
            {"role": "system", "content": "You are a senior SAP business analyst. Be direct and data-driven."},
            {"role": "user", "content": PROMPT},
        ],
        "max_tokens": 400,
    }, timeout=30)
    r.raise_for_status()
    summary = r.json()["choices"][0]["message"]["content"].strip()
    print("SAP Sales Executive Summary\n" + "=" * 40)
    print(summary)
    tokens = r.json().get("usage", {})
    print(f"\n[Tokens: prompt={tokens.get('prompt_tokens',0)}, completion={tokens.get('completion_tokens',0)}]")
