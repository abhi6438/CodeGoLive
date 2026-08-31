"""
Project: SAP AI Core Python Examples
Topic:   01_genai_hub
Goal:    Send a simple chat prompt to GPT-4o via GenAI Hub using raw HTTP requests (no SDK).
"""

import requests
from config import HEADERS, URL

def ask(prompt: str) -> str:
    payload = {
        "model": "gpt-4o",
        "messages": [{"role": "user", "content": prompt}],
        "max_tokens": 256,
    }
    r = requests.post(URL, headers=HEADERS, json=payload, timeout=30)
    r.raise_for_status()
    return r.json()["choices"][0]["message"]["content"]

if __name__ == "__main__":
    question = (
        "You are an SAP expert. In two sentences, explain what SAP BTP is "
        "and who should use it."
    )
    print("Question:", question)
    print()
    answer = ask(question)
    print("Answer:", answer)
