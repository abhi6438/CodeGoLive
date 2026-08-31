"""
Advanced RAG Pipeline: HyPE + BM25 + RRF + Cross-Encoder Reranking
pip install rank-bm25 sentence-transformers requests
"""

import json
import math
import requests
from rank_bm25 import BM25Okapi
from sentence_transformers import CrossEncoder
from config import BASE_URL, DEPLOY_ID, EMB_DEPLOY, HEADERS, CORPUS, QUESTIONS

def embed(texts: list[str]) -> list[list[float]]:
    url = f"{BASE_URL}/inference/deployments/{EMB_DEPLOY}/embeddings"
    resp = requests.post(url, headers=HEADERS, json={"input": texts}, timeout=30)
    resp.raise_for_status()
    data = resp.json()["data"]
    data.sort(key=lambda x: x["index"])
    return [d["embedding"] for d in data]

def cosine(a, b):
    dot = sum(x * y for x, y in zip(a, b))
    na  = math.sqrt(sum(x * x for x in a))
    nb  = math.sqrt(sum(y * y for y in b))
    return dot / (na * nb + 1e-9)

# ── LLM call ─────────────────────────────────────────────────────────────────
def chat(messages: list[dict]) -> str:
    url = f"{BASE_URL}/inference/deployments/{DEPLOY_ID}/chat/completions"
    resp = requests.post(url, headers=HEADERS,
                         json={"messages": messages, "max_tokens": 300}, timeout=30)
    resp.raise_for_status()
    return resp.json()["choices"][0]["message"]["content"].strip()

# ── HyPE: Hypothetical Prompt Embeddings ─────────────────────────────────────
def hype_query(question: str) -> list[float]:
    """Generate a hypothetical answer and embed it instead of the raw query."""
    hyp = chat([
        {"role": "system", "content": "Answer in 1-2 sentences as if you are a SAP expert."},
        {"role": "user",   "content": question},
    ])
    print(f"  [HyPE] Hypothetical answer: {hyp[:80]}...")
    return embed([hyp])[0]

# ── BM25 retrieval ────────────────────────────────────────────────────────────
def bm25_retrieve(query: str, corpus: list[str], k: int = 5) -> list[tuple[int, float]]:
    tokenized = [doc.lower().split() for doc in corpus]
    bm25 = BM25Okapi(tokenized)
    scores = bm25.get_scores(query.lower().split())
    ranked = sorted(enumerate(scores), key=lambda x: x[1], reverse=True)
    return ranked[:k]

# ── Vector retrieval ──────────────────────────────────────────────────────────
def vector_retrieve(query_vec: list[float], corpus_vecs: list[list[float]],
                    k: int = 5) -> list[tuple[int, float]]:
    scored = [(i, cosine(query_vec, cv)) for i, cv in enumerate(corpus_vecs)]
    return sorted(scored, key=lambda x: x[1], reverse=True)[:k]

# ── Reciprocal Rank Fusion ────────────────────────────────────────────────────
def rrf(rankings: list[list[tuple[int, float]]], k: int = 60) -> list[int]:
    scores: dict[int, float] = {}
    for ranking in rankings:
        for rank, (doc_id, _) in enumerate(ranking):
            scores[doc_id] = scores.get(doc_id, 0.0) + 1.0 / (k + rank + 1)
    return [doc_id for doc_id, _ in sorted(scores.items(), key=lambda x: x[1], reverse=True)]

# ── Cross-encoder reranking ───────────────────────────────────────────────────
reranker = CrossEncoder("cross-encoder/ms-marco-MiniLM-L-6-v2")

def rerank(query: str, docs: list[str], top_n: int = 3) -> list[str]:
    pairs = [(query, doc) for doc in docs]
    scores = reranker.predict(pairs)
    ranked = sorted(zip(docs, scores), key=lambda x: x[1], reverse=True)
    return [doc for doc, _ in ranked[:top_n]]

# ── Naive RAG (baseline) ──────────────────────────────────────────────────────
def naive_rag(question: str, corpus: list[str], corpus_vecs: list[list[float]]) -> str:
    q_vec = embed([question])[0]
    top = vector_retrieve(q_vec, corpus_vecs, k=3)
    context = "\n".join(corpus[i] for i, _ in top)
    return chat([
        {"role": "system", "content": f"Answer using context:\n{context}"},
        {"role": "user",   "content": question},
    ])

# ── Advanced RAG ──────────────────────────────────────────────────────────────
def advanced_rag(question: str, corpus: list[str], corpus_vecs: list[list[float]]) -> str:
    # 1. HyPE embedding
    hype_vec = hype_query(question)
    # 2. BM25
    bm25_results = bm25_retrieve(question, corpus, k=5)
    # 3. Vector with HyPE embedding
    vec_results = vector_retrieve(hype_vec, corpus_vecs, k=5)
    # 4. RRF fusion
    fused_ids = rrf([bm25_results, vec_results])[:5]
    candidates = [corpus[i] for i in fused_ids]
    # 5. Cross-encoder reranking
    top_docs = rerank(question, candidates, top_n=3)
    context = "\n".join(top_docs)
    return chat([
        {"role": "system", "content": f"Answer using context:\n{context}"},
        {"role": "user",   "content": question},
    ])

# ── Main ──────────────────────────────────────────────────────────────────────
def main():
    print("Embedding corpus...")
    corpus_vecs = embed(CORPUS)

    for q in QUESTIONS:
        print(f"\n{'='*60}")
        print(f"Question: {q}")
        print(f"{'='*60}")

        print("\n[Naive RAG]")
        naive_ans = naive_rag(q, CORPUS, corpus_vecs)
        print(f"  {naive_ans}")

        print("\n[Advanced RAG: HyPE + BM25 + RRF + Cross-Encoder]")
        adv_ans = advanced_rag(q, CORPUS, corpus_vecs)
        print(f"  {adv_ans}")

if __name__ == "__main__":
    main()
