"""
RAG Pipeline with Langfuse Observability Tracing
pip install langfuse requests
"""

import math
import time
import requests
from langfuse import Langfuse
from config import BASE_URL, DEPLOY_ID, EMB_DEPLOY, LF_PUBLIC, LF_SECRET, LF_HOST, AI_HEADERS, QUESTIONS, CORPUS

def cosine(a, b):
    dot = sum(x * y for x, y in zip(a, b))
    return dot / (math.sqrt(sum(x*x for x in a)) * math.sqrt(sum(y*y for y in b)) + 1e-9)

def embed_texts(texts: list[str]) -> list[list[float]]:
    url = f"{BASE_URL}/inference/deployments/{EMB_DEPLOY}/embeddings"
    resp = requests.post(url, headers=AI_HEADERS, json={"input": texts}, timeout=30)
    resp.raise_for_status()
    data = resp.json()["data"]
    data.sort(key=lambda x: x["index"])
    return [d["embedding"] for d in data]

def vector_search(query_vec, corpus_vecs, corpus, k=3):
    scored = [(corpus[i], cosine(query_vec, cv)) for i, cv in enumerate(corpus_vecs)]
    return sorted(scored, key=lambda x: x[1], reverse=True)[:k]

# ── Traced RAG pipeline ───────────────────────────────────────────────────────
def traced_rag(question: str, corpus_vecs: list[list[float]], langfuse: Langfuse):
    # 1. Create top-level trace
    trace = langfuse.trace(
        name="sap-rag-query",
        input={"question": question},
        metadata={"corpus_size": len(CORPUS)},
    )

    # 2. Retrieval span
    retrieval_span = trace.span(name="retrieval", input={"query": question})
    t0 = time.time()
    q_vec = embed_texts([question])[0]
    top_docs = vector_search(q_vec, corpus_vecs, CORPUS)
    retrieval_ms = int((time.time() - t0) * 1000)
    context_docs = [doc for doc, _ in top_docs]
    retrieval_span.end(
        output={"retrieved_docs": context_docs},
        metadata={"latency_ms": retrieval_ms, "top_scores": [round(s, 4) for _, s in top_docs]},
    )

    # 3. Build messages
    context = "\n".join(context_docs)
    messages = [
        {"role": "system", "content": f"You are an SAP expert. Use the context:\n{context}"},
        {"role": "user",   "content": question},
    ]

    # 4. Generation span
    generation_span = trace.generation(
        name="answer",
        model="gpt-4o",
        input=messages,
    )
    t1 = time.time()
    url = f"{BASE_URL}/inference/deployments/{DEPLOY_ID}/chat/completions"
    resp = requests.post(url, headers=AI_HEADERS,
                         json={"messages": messages, "max_tokens": 300}, timeout=30)
    resp.raise_for_status()
    result = resp.json()
    answer = result["choices"][0]["message"]["content"].strip()
    usage  = result.get("usage", {})
    gen_ms = int((time.time() - t1) * 1000)

    generation_span.end(
        output=answer,
        usage={
            "input":  usage.get("prompt_tokens", 0),
            "output": usage.get("completion_tokens", 0),
            "total":  usage.get("total_tokens", 0),
        },
        metadata={"latency_ms": gen_ms},
    )

    # 5. Update trace with final output
    trace.update(output=answer)

    return answer, trace.id

# ── Main ──────────────────────────────────────────────────────────────────────
def main():
    langfuse = Langfuse(
        public_key=LF_PUBLIC,
        secret_key=LF_SECRET,
        host=LF_HOST,
    )
    print(f"Langfuse connected: {LF_HOST}")

    print("Pre-computing corpus embeddings...")
    corpus_vecs = embed_texts(CORPUS)

    for q in QUESTIONS:
        print(f"\n{'='*60}")
        print(f"Q: {q}")
        answer, trace_id = traced_rag(q, corpus_vecs, langfuse)
        print(f"A: {answer}")
        print(f"   [Trace ID: {trace_id}]")
        print(f"   [View at: {LF_HOST}/trace/{trace_id}]")

    # Flush all pending events to Langfuse
    langfuse.flush()
    print("\nAll traces flushed to Langfuse.")

if __name__ == "__main__":
    main()
