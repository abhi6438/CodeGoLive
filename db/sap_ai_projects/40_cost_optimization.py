"""
Project: SAP GenAI Hub Integration Series
Topic:   40_cost_optimization
Goal:    Cost optimization: smart routing, prompt caching, batching, savings comparison
Requirements: pip install requests
"""

import os, hashlib, time, requests
from dataclasses import dataclass

BASE    = os.environ["AICORE_BASE_URL"]
TOKEN   = os.environ["AICORE_TOKEN"]
DEPID   = os.environ["AICORE_DEPLOYMENT_ID"]
RG      = os.environ.get("AICORE_RG", "default")
HEADERS = {"Authorization": f"Bearer {TOKEN}", "Content-Type": "application/json", "AI-Resource-Group": RG}
URL     = f"{BASE}/inference/deployments/{DEPID}/chat/completions"

MODEL_COSTS = {
    "gpt-4o":      {"input": 0.0025, "output": 0.010},
    "gpt-4o-mini": {"input": 0.00015, "output": 0.0006},
}

COMPLEX_KEYWORDS = ["analyze", "compare", "explain", "design", "architect", "optimize", "evaluate",
                    "pros and cons", "deep dive", "comprehensive", "strategy"]

_prompt_cache: dict[str, str] = {}


@dataclass
class LLMCall:
    question: str
    model: str
    input_tokens: int
    output_tokens: int

    @property
    def cost(self) -> float:
        rates = MODEL_COSTS[self.model]
        return (self.input_tokens / 1000 * rates["input"]) + (self.output_tokens / 1000 * rates["output"])


def route_model(question: str) -> str:
    q_lower = question.lower()
    is_complex = len(question) > 100 or any(kw in q_lower for kw in COMPLEX_KEYWORDS)
    model = "gpt-4o" if is_complex else "gpt-4o-mini"
    print(f"  Routing '{question[:40]}...' -> {model} ({'complex' if is_complex else 'simple'})")
    return model


def get_cached_or_call(system_prompt: str, user_msg: str, model: str) -> tuple[str, bool]:
    cache_key = hashlib.sha256(f"{system_prompt}::{user_msg}".encode()).hexdigest()
    if cache_key in _prompt_cache:
        return _prompt_cache[cache_key], True

    payload = {"model": model, "messages": [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": user_msg},
    ], "max_tokens": 150}
    r = requests.post(URL, headers=HEADERS, json=payload, timeout=30)
    r.raise_for_status()
    answer = r.json()["choices"][0]["message"]["content"]
    _prompt_cache[cache_key] = answer
    return answer, False


def estimate_tokens(text: str) -> int:
    return max(1, len(text) // 4)


def process_batch(questions: list[str], system_prompt: str) -> list[LLMCall]:
    results = []
    for q in questions:
        model = route_model(q)
        answer, cached = get_cached_or_call(system_prompt, q, model)
        in_tok = estimate_tokens(system_prompt + q)
        out_tok = estimate_tokens(answer)
        call = LLMCall(question=q, model=model, input_tokens=in_tok, output_tokens=out_tok)
        results.append(call)
        if cached:
            print(f"  [CACHED] Saved ${call.cost:.4f}")
    return results


def calculate_savings(actual_calls: list[LLMCall]) -> dict:
    actual_cost = sum(c.cost for c in actual_calls)
    naive_calls = [LLMCall(q=c.question, model="gpt-4o", input_tokens=c.input_tokens,
                           output_tokens=c.output_tokens) for c in actual_calls]
    for nc in naive_calls:
        nc.model = "gpt-4o"
    naive_cost = sum((t / 1000 * MODEL_COSTS["gpt-4o"]["input"]) + (t / 1000 * MODEL_COSTS["gpt-4o"]["output"])
                     for c in actual_calls for t in [c.input_tokens, c.output_tokens])
    naive_cost = sum(
        c.input_tokens / 1000 * MODEL_COSTS["gpt-4o"]["input"] +
        c.output_tokens / 1000 * MODEL_COSTS["gpt-4o"]["output"]
        for c in actual_calls)
    savings = naive_cost - actual_cost
    return {"naive_cost": naive_cost, "optimized_cost": actual_cost,
            "savings": savings, "savings_pct": (savings / naive_cost * 100) if naive_cost > 0 else 0}


SYSTEM_PROMPT = "You are an SAP support assistant. Answer concisely."

QUESTIONS = [
    "What is SAP?",
    "What does MM60 do?",
    "Analyze the pros and cons of migrating from SAP ECC to S/4HANA comprehensively",
    "What is a cost center?",
    "Design a comprehensive SAP procurement strategy for a manufacturing company with 5000 employees",
    "How to run MIRO?",
    "What is SAP?",
    "Evaluate and compare all SAP financial reporting tools in detail",
    "What is a plant?",
    "What is SAP?",
]


if __name__ == "__main__":
    print("=== SAP LLM Cost Optimization Demo ===\n")
    print("[Strategy 1 & 2] Smart Routing + Prompt Caching")
    calls = process_batch(QUESTIONS, SYSTEM_PROMPT)

    cache_hits = sum(1 for q in QUESTIONS if
                     hashlib.sha256(f"{SYSTEM_PROMPT}::{q}".encode()).hexdigest() in _prompt_cache
                     and QUESTIONS.index(q) != QUESTIONS.index(q))

    print(f"\n[Strategy 3] Batch Results ({len(calls)} calls processed)")
    model_counts = {}
    for c in calls:
        model_counts[c.model] = model_counts.get(c.model, 0) + 1
    for model, count in model_counts.items():
        print(f"  {model}: {count} calls")

    print("\n[Strategy 4] Cost Comparison")
    savings = calculate_savings(calls)
    print(f"  Without optimization (all gpt-4o):  ${savings['naive_cost']:.4f}")
    print(f"  With optimization (routing+cache):  ${savings['optimized_cost']:.4f}")
    print(f"  Savings: ${savings['savings']:.4f} ({savings['savings_pct']:.1f}%)")
