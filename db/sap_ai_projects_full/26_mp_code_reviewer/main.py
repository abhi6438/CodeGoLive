"""
Project: SAP AI Core Python Examples
Topic:   26_mp_code_reviewer
Goal:    Review 2 ABAP code snippets for security/performance issues.
         Returns JSON with issues list, score (0-10), and summary.
"""

import requests, json
from config import HEADERS, URL, ABAP_SNIPPETS, REVIEW_SYSTEM

def review_abap(name, code):
    r = requests.post(URL, headers=HEADERS, json={
        "model": "gpt-4o",
        "messages": [
            {"role": "system", "content": REVIEW_SYSTEM},
            {"role": "user", "content": f"Review this ABAP code:\n```abap{code}```"},
        ],
        "response_format": {"type": "json_object"},
        "max_tokens": 500,
    }, timeout=30)
    r.raise_for_status()
    return json.loads(r.json()["choices"][0]["message"]["content"])

if __name__ == "__main__":
    for name, code in ABAP_SNIPPETS.items():
        print(f"\n{'=' * 60}\nReviewing: {name}\n{'=' * 60}")
        result = review_abap(name, code)
        print(f"Score: {result['score']}/10")
        print(f"Summary: {result['summary']}")
        print(f"\nIssues ({len(result['issues'])}):")
        for issue in result["issues"]:
            print(f"  [{issue['severity']:8}] [{issue['type']:15}] {issue['description']}")
            print(f"           Fix: {issue['fix']}")
