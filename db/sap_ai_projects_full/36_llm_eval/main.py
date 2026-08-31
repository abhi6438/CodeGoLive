"""
Project: SAP GenAI Hub Integration Series
Topic:   36_llm_eval
Goal:    LLM evaluation: RAGAS-style faithfulness, LLM-as-judge, regression test runner
Requirements: pip install requests
"""

from config import HEADERS, URL, SAP_QA_PAIRS

def llm_call(system: str, user: str, max_tokens: int = 200) -> str:
    payload = {"model": "gpt-4o", "messages": [
        {"role": "system", "content": system},
        {"role": "user", "content": user},
    ], "max_tokens": max_tokens}
    r = requests.post(URL, headers=HEADERS, json=payload, timeout=30)
    r.raise_for_status()
    return r.json()["choices"][0]["message"]["content"]


def check_faithfulness(answer: str, context: str) -> dict:
    prompt = f"""Given the context: "{context}"
And the answer: "{answer}"
Does the answer contain ONLY information that can be derived from the context?
Reply with JSON: {{"faithful": true/false, "reason": "..."}}"""
    raw = llm_call("You are a faithfulness evaluator. Respond with valid JSON only.", prompt)
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return {"faithful": "APPROVE" in raw.upper(), "reason": raw[:80]}


def llm_as_judge(question: str, answer: str) -> dict:
    prompt = f"""Question: {question}
Answer: {answer}
Rate the answer quality from 1 (poor) to 5 (excellent) for: accuracy, completeness, clarity.
Reply JSON: {{"score": <1-5>, "feedback": "..."}}"""
    raw = llm_call("You are a strict SAP expert evaluating answer quality. Respond with valid JSON only.", prompt)
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        score = 3
        for c in raw:
            if c.isdigit() and c in "12345":
                score = int(c)
                break
        return {"score": score, "feedback": raw[:80]}


def generate_answer(question: str, context: str) -> str:
    return llm_call(
        "You are an SAP expert. Answer using only the provided context.",
        f"Context: {context}\nQuestion: {question}",
    )


def run_regression_tests():
    print("=== SAP LLM Regression Test Suite ===\n")
    results = []
    total_score = 0

    for i, qa in enumerate(SAP_QA_PAIRS, 1):
        print(f"[Test {i}/5] {qa['question'][:50]}...")
        answer = generate_answer(qa["question"], qa["context"])
        faithfulness = check_faithfulness(answer, qa["context"])
        judgment = llm_as_judge(qa["question"], answer)

        score = judgment.get("score", 0)
        total_score += score
        faithful = faithfulness.get("faithful", False)

        results.append({
            "test": i,
            "question": qa["question"],
            "score": score,
            "faithful": faithful,
            "feedback": judgment.get("feedback", "")[:60],
        })
        status = "PASS" if score >= 3 and faithful else "FAIL"
        print(f"  Score: {score}/5 | Faithful: {faithful} | [{status}]")

    avg_score = total_score / len(SAP_QA_PAIRS)
    passed = sum(1 for r in results if r["score"] >= 3 and r["faithful"])
    print(f"\n=== Results: {passed}/{len(SAP_QA_PAIRS)} passed | Avg score: {avg_score:.1f}/5 ===")
    return results


if __name__ == "__main__":
    run_regression_tests()
