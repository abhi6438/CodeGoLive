"""
Project: SAP AI Core Python Examples
Topic:   27_mp_ai_dashboard
Goal:    Simulate 7 days of AI usage logs, compute metrics, print table, generate AI executive insight.
"""

import requests, random
from datetime import date, timedelta
from config import HEADERS, URL, COST_PER_1K_PROMPT, COST_PER_1K_COMPLETION

def simulate_day(day_offset):
    d = date.today() - timedelta(days=6 - day_offset)
    is_weekend = d.weekday() >= 5
    base_requests = random.randint(20, 40) if not is_weekend else random.randint(3, 8)
    errors        = random.randint(0, 3)
    avg_latency   = round(random.uniform(0.8, 3.2), 2)
    prompt_tokens  = base_requests * random.randint(150, 400)
    compl_tokens   = base_requests * random.randint(80, 200)
    cost = (prompt_tokens / 1000 * COST_PER_1K_PROMPT
            + compl_tokens / 1000 * COST_PER_1K_COMPLETION)
    return {
        "date": d.isoformat(),
        "requests": base_requests,
        "errors": errors,
        "error_rate": round(errors / max(base_requests, 1) * 100, 1),
        "avg_latency_s": avg_latency,
        "prompt_tokens": prompt_tokens,
        "completion_tokens": compl_tokens,
        "cost_usd": round(cost, 4),
    }

def generate_insight(metrics_summary):
    r = requests.post(URL, headers=HEADERS, json={
        "model": "gpt-4o",
        "messages": [
            {"role": "system", "content": "You are an AI operations analyst. Be concise (3-4 sentences)."},
            {"role": "user", "content": (
                f"Provide an executive insight for this AI usage dashboard (7-day view):\n\n"
                f"{metrics_summary}\n\n"
                "Focus on: usage trends, cost efficiency, and any operational concerns."
            )},
        ],
        "max_tokens": 200,
    }, timeout=30)
    r.raise_for_status()
    return r.json()["choices"][0]["message"]["content"].strip()

if __name__ == "__main__":
    daily = [simulate_day(i) for i in range(7)]

    print("SAP AI Core Usage Dashboard – Last 7 Days")
    print("=" * 85)
    print(f"{'Date':<12} {'Reqs':>6} {'Errors':>7} {'Err%':>6} {'Latency':>9} {'P-Tok':>8} {'C-Tok':>8} {'Cost':>9}")
    print("-" * 85)
    for d in daily:
        print(f"{d['date']:<12} {d['requests']:>6} {d['errors']:>7} {d['error_rate']:>5.1f}% "
              f"{d['avg_latency_s']:>7.2f}s {d['prompt_tokens']:>8} {d['completion_tokens']:>8} "
              f"${d['cost_usd']:>8.4f}")
    print("-" * 85)

    totals = {
        "total_requests": sum(d["requests"] for d in daily),
        "total_errors":   sum(d["errors"]   for d in daily),
        "avg_latency":    round(sum(d["avg_latency_s"] for d in daily) / 7, 2),
        "total_cost":     round(sum(d["cost_usd"] for d in daily), 4),
        "peak_day":       max(daily, key=lambda x: x["requests"])["date"],
    }
    totals["overall_error_rate"] = round(totals["total_errors"] / totals["total_requests"] * 100, 1)
    print(f"\nTotals: {totals['total_requests']} requests | {totals['overall_error_rate']}% errors | "
          f"avg {totals['avg_latency']}s latency | total cost ${totals['total_cost']}")
    print(f"Peak day: {totals['peak_day']}")

    summary_str = str(totals)
    print("\n--- AI Executive Insight ---")
    print(generate_insight(summary_str))
