"""
Project: SAP AI Core Python Examples
Topic:   25_mp_help_desk
Goal:    Complete CLI help desk chatbot with ticket management.
         Commands: 'ticket: <issue>' creates a ticket, 'status' lists tickets, 'quit' exits.
"""

import requests
from datetime import datetime
from config import HEADERS, URL, SYSTEM

def chat(history):
    r = requests.post(URL, headers=HEADERS, json={
        "model": "gpt-4o",
        "messages": history,
        "max_tokens": 200,
    }, timeout=30)
    r.raise_for_status()
    return r.json()["choices"][0]["message"]["content"].strip()

def create_ticket(issue: str) -> str:
    tid = f"INC{len(tickets)+1:04d}"
    tickets.append({
        "id": tid,
        "issue": issue,
        "created": datetime.now().strftime("%Y-%m-%d %H:%M"),
        "status": "OPEN",
    })
    return tid

def show_status():
    if not tickets:
        return "No tickets created in this session."
    lines = [f"{'ID':<10} {'Status':<8} {'Created':<18} Issue"]
    lines.append("-" * 70)
    for t in tickets:
        lines.append(f"{t['id']:<10} {t['status']:<8} {t['created']:<18} {t['issue'][:35]}")
    return "\n".join(lines)

def main():
    history = [{"role": "system", "content": SYSTEM}]
    print("SAP Help Desk (type 'ticket: <issue>', 'status', or 'quit')")
    print("=" * 55)
    while True:
        try:
            user_input = input("\nYou: ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\nGoodbye!")
            break
        if not user_input:
            continue
        if user_input.lower() == "quit":
            print("Goodbye! Your session has ended.")
            break
        if user_input.lower() == "status":
            print(show_status())
            continue
        if user_input.lower().startswith("ticket:"):
            issue = user_input[7:].strip()
            tid   = create_ticket(issue)
            print(f"Bot: Ticket {tid} created for: '{issue}'. Our team will respond within 4 hours.")
            continue
        history.append({"role": "user", "content": user_input})
        reply = chat(history)
        history.append({"role": "assistant", "content": reply})
        print(f"Bot: {reply}")

if __name__ == "__main__":
    main()
