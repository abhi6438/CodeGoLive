"""
Project: SAP AI Core Python Examples
Topic:   04_system_prompts
Goal:    Demonstrate role-switching: same question answered by CFO, CTO, and End-User personas.
"""

import requests
from config import HEADERS, URL, PERSONAS, QUESTION

def ask_persona(persona_name, system_prompt):
    r = requests.post(URL, headers=HEADERS, json={
        "model": "gpt-4o",
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": QUESTION},
        ],
        "max_tokens": 180,
    }, timeout=30)
    r.raise_for_status()
    return r.json()["choices"][0]["message"]["content"].strip()

if __name__ == "__main__":
    print(f"Question: {QUESTION}\n{'=' * 60}")
    for persona, prompt in PERSONAS.items():
        answer = ask_persona(persona, prompt)
        print(f"\n[{persona}]\n{answer}")
    print()
