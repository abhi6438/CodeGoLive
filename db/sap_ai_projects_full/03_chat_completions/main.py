"""
Project: SAP AI Core Python Examples
Topic:   03_chat_completions
Goal:    SAP FAQ bot – loop through 3 questions maintaining conversation history.
"""

import requests
from config import HEADERS, URL, QUESTIONS

def chat(history):
    r = requests.post(URL, headers=HEADERS,
                      json={"model": "gpt-4o", "messages": history, "max_tokens": 200},
                      timeout=30)
    r.raise_for_status()
    return r.json()["choices"][0]["message"]["content"].strip()

if __name__ == "__main__":
    history = [
        {"role": "system", "content": (
            "You are an SAP FAQ bot. Answer concisely in 2-3 sentences. "
            "Refer back to previous answers when relevant."
        )}
    ]
    for i, question in enumerate(QUESTIONS, 1):
        history.append({"role": "user", "content": question})
        answer = chat(history)
        history.append({"role": "assistant", "content": answer})
        print(f"Q{i}: {question}")
        print(f"A{i}: {answer}")
        print("-" * 60)
