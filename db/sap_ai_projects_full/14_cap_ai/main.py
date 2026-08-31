"""
Project: SAP AI Core Python Examples
Topic:   14_cap_ai
Goal:    Expense categorization – classify 5 corporate expenses with AI and print results table.
"""

import requests
from config import HEADERS, URL, EXPENSES, SYSTEM

def classify(description):
    r = requests.post(URL, headers=HEADERS, json={
        "model": "gpt-4o",
        "messages": [
            {"role": "system", "content": SYSTEM},
            {"role": "user", "content": description},
        ],
        "max_tokens": 20,
    }, timeout=30)
    r.raise_for_status()
    raw = r.json()["choices"][0]["message"]["content"].strip()
    parts = raw.split("|")
    category   = parts[0].strip() if len(parts) > 0 else "UNKNOWN"
    confidence = parts[1].strip() if len(parts) > 1 else "?"
    return category, confidence

if __name__ == "__main__":
    print(f"{'ID':<6}  {'Amount':>8}  {'Conf':<6}  {'Category':<20}  Description")
    print("-" * 90)
    for exp in EXPENSES:
        cat, conf = classify(exp["description"])
        print(f"{exp['id']:<6}  {exp['amount']:>8.2f}  {conf:<6}  {cat:<20}  {exp['description'][:45]}")
