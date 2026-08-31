"""
Project: SAP AI Core Python Examples
Topic:   21_token_monitoring
Goal:    Track tokens per user across 5 requests. Print cost dashboard with per-user breakdown.
"""

import requests
from collections import defaultdict
from config import HEADERS, URL, COST_PER_1K_PROMPT, COST_PER_1K_COMPLETION, USER_REQUESTS

def chat_with_tracking(user, message):
    r = requests.post(URL, headers=HEADERS, json={
        "model": "gpt-4o",
        "messages": [{"role": "user", "content": message}],
        "max_tokens": 200,
    }, timeout=30)
    r.raise_for_status()
    usage = r.json().get("usage", {})
    return usage.get("prompt_tokens", 0), usage.get("completion_tokens", 0)

if __name__ == "__main__":
    user_stats = defaultdict(lambda: {"prompt": 0, "completion": 0, "requests": 0})

    for user, msg in USER_REQUESTS:
        pt, ct = chat_with_tracking(user, msg)
        user_stats[user]["prompt"]     += pt
        user_stats[user]["completion"] += ct
        user_stats[user]["requests"]   += 1
        print(f"  {user:<25} +{pt:>4}p +{ct:>3}c tokens")

    print("\n" + "=" * 65)
    print(f"{'User':<25} {'Reqs':>5} {'Prompt':>8} {'Compl':>7} {'Cost (USD)':>12}")
    print("-" * 65)
    total_cost = 0
    for user, s in sorted(user_stats.items()):
        cost = (s["prompt"] / 1000 * COST_PER_1K_PROMPT
                + s["completion"] / 1000 * COST_PER_1K_COMPLETION)
        total_cost += cost
        print(f"{user:<25} {s['requests']:>5} {s['prompt']:>8} {s['completion']:>7} ${cost:>11.4f}")
    print("-" * 65)
    total_p = sum(s["prompt"]     for s in user_stats.values())
    total_c = sum(s["completion"] for s in user_stats.values())
    print(f"{'TOTAL':<25} {len(USER_REQUESTS):>5} {total_p:>8} {total_c:>7} ${total_cost:>11.4f}")
