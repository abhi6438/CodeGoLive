"""
Project: SAP AI Core Python Examples
Topic:   02_prompt_engineering
Goal:    Compare zero-shot vs few-shot sentiment classification of an SAP error message.
"""

import requests
from config import HEADERS, URL, TEST_MESSAGE

def chat(messages):
    r = requests.post(URL, headers=HEADERS,
                      json={"model": "gpt-4o", "messages": messages, "max_tokens": 80},
                      timeout=30)
    r.raise_for_status()
    return r.json()["choices"][0]["message"]["content"].strip()

def zero_shot(msg):
    return chat([
        {"role": "user", "content": f"Classify the sentiment of this SAP error message as POSITIVE, NEUTRAL, or NEGATIVE.\n\nMessage: {msg}"}
    ])

def few_shot(msg):
    return chat([
        {"role": "system", "content": (
            "Classify SAP error messages as POSITIVE, NEUTRAL, or NEGATIVE.\n\n"
            "Examples:\n"
            "Message: 'Document 4500001234 posted successfully.' -> POSITIVE\n"
            "Message: 'RFC destination SM59_TEST is not configured.' -> NEGATIVE\n"
            "Message: 'Background job RPRAPA00 completed with 0 errors.' -> POSITIVE\n"
            "Message: 'Warning: Tolerance limit exceeded by 0.01 EUR.' -> NEUTRAL\n"
        )},
        {"role": "user", "content": f"Message: {msg}"},
    ])

if __name__ == "__main__":
    print("Test message:", TEST_MESSAGE)
    print()
    print("Zero-shot result :", zero_shot(TEST_MESSAGE))
    print("Few-shot  result :", few_shot(TEST_MESSAGE))
