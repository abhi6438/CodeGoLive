"""
Project: SAP AI Core Python Examples
Topic:   11_semantic_search
Goal:    In-memory semantic search over 5 SAP knowledge-base articles using embeddings.
Requirements: AICORE_EMB_DEPLOYMENT_ID
"""

import requests, math
from config import HEADERS, EMB_URL, KB_ARTICLES

def embed(texts):
    r = requests.post(EMB_URL, headers=HEADERS,
                      json={"input": texts, "model": "text-embedding-ada-002"}, timeout=30)
    r.raise_for_status()
    return [d["embedding"] for d in r.json()["data"]]

def cosine(a, b):
    dot = sum(x * y for x, y in zip(a, b))
    na  = math.sqrt(sum(x * x for x in a))
    nb  = math.sqrt(sum(x * x for x in b))
    return dot / (na * nb) if na and nb else 0.0

def search(query, index, top_k=2):
    q_vec = embed([query])[0]
    scored = sorted([(cosine(q_vec, v), a) for v, a in index], reverse=True)
    return scored[:top_k]

if __name__ == "__main__":
    print("Building in-memory index...")
    texts   = [a["text"] for a in KB_ARTICLES]
    vectors = embed(texts)
    index   = list(zip(vectors, KB_ARTICLES))

    queries = [
        "I forgot my password and cannot log in",
        "How do I connect to a remote SAP system?",
        "Steps to record incoming goods from a supplier",
    ]
    for q in queries:
        print(f"\nQuery: {q}")
        for score, art in search(q, index):
            print(f"  [{art['id']}] {art['title']}  (score={score:.4f})")
