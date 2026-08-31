"""
Project: SAP AI Core Python Examples
Topic:   05_few_shot
Goal:    Classify SAP error messages into AUTH/DATA/NETWORK/CONFIG using few-shot prompting.
"""

import requests
from config import HEADERS, URL, SYSTEM, TEST_ERRORS

def classify(error_msg):
    r = requests.post(URL, headers=HEADERS, json={
        "model": "gpt-4o",
        "messages": [
            {"role": "system", "content": SYSTEM},
            {"role": "user", "content": error_msg},
        ],
        "max_tokens": 10,
    }, timeout=30)
    r.raise_for_status()
    return r.json()["choices"][0]["message"]["content"].strip()

if __name__ == "__main__":
    print(f"{'Category':<10}  Error Message")
    print("-" * 80)
    for error in TEST_ERRORS:
        category = classify(error)
        print(f"{category:<10}  {error[:70]}")
