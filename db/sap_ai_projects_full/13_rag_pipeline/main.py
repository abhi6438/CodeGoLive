"""
Project: SAP AI Core Python Examples
Topic:   13_rag_pipeline
Goal:    RAG pipeline – retrieve relevant chunks then generate a grounded answer.
         Requires the ChromaDB store built by 12_rag_indexing.py.
Requirements: pip install chromadb requests
"""

import requests
import chromadb
from config import HEADERS, CHAT_URL, EMB_URL

def embed(text):
    r = requests.post(EMB_URL, headers=HEADERS,
                      json={"input": [text], "model": "text-embedding-ada-002"}, timeout=30)
    r.raise_for_status()
    return r.json()["data"][0]["embedding"]

def retrieve(query, collection, top_k=3):
    q_vec   = embed(query)
    results = collection.query(query_embeddings=[q_vec], n_results=top_k)
    docs     = results["documents"][0]
    metas    = results["metadatas"][0]
    return list(zip(docs, metas))

def generate(query, context_chunks):
    context = "\n\n".join(
        f"[Source: {m['source']} p.{m['page']}]\n{doc}"
        for doc, m in context_chunks
    )
    messages = [
        {"role": "system", "content": (
            "You are an SAP documentation assistant. "
            "Answer ONLY using the provided context. "
            "Always cite the source document and page number."
        )},
        {"role": "user", "content": f"Context:\n{context}\n\nQuestion: {query}"},
    ]
    r = requests.post(CHAT_URL, headers=HEADERS,
                      json={"model": "gpt-4o", "messages": messages, "max_tokens": 300},
                      timeout=30)
    r.raise_for_status()
    return r.json()["choices"][0]["message"]["content"].strip()

if __name__ == "__main__":
    client     = chromadb.PersistentClient(path="./sap_chroma_db")
    collection = client.get_collection("sap_docs")

    questions = [
        "What runtime environments does SAP BTP offer for developers?",
        "How does SAP S/4HANA simplify financial accounting?",
    ]
    for q in questions:
        chunks = retrieve(q, collection)
        answer = generate(q, chunks)
        print(f"Q: {q}\nA: {answer}\n{'=' * 60}\n")
