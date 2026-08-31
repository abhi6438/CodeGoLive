"""
Project: SAP AI Core Python Examples
Topic:   06_multi_turn
Goal:    Multi-turn BTP cost estimator – simulate 4 user turns building up requirements.
"""

import requests
from config import HEADERS, URL, TURNS

def chat(history):
    r = requests.post(URL, headers=HEADERS, json={
        "model": "gpt-4o",
        "messages": history,
        "max_tokens": 220,
    }, timeout=30)
    r.raise_for_status()
    return r.json()["choices"][0]["message"]["content"].strip()

if __name__ == "__main__":
    history = [{"role": "system", "content": (
        "You are an SAP BTP cost estimation assistant. "
        "Track requirements as the user adds them and refine the estimate each turn. "
        "Be concise but mention key BTP services involved."
    )}]
    for i, user_msg in enumerate(TURNS, 1):
        history.append({"role": "user", "content": user_msg})
        print(f"Turn {i} - User: {user_msg}")
        reply = chat(history)
        history.append({"role": "assistant", "content": reply})
        print(f"Turn {i} - Bot:  {reply}")
        print()
