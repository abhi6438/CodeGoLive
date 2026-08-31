"""
Project: SAP AI Core Python Examples
Topic:   12_rag_indexing
Goal:    Build a ChromaDB vector store from SAP document chunks.
Requirements: pip install chromadb requests
"""

import requests
import chromadb
from config import HEADERS, EMB_URL, DOC_CHUNKS

def embed(texts):
    r = requests.post(EMB_URL, headers=HEADERS,
                      json={"input": texts, "model": "text-embedding-ada-002"}, timeout=30)
    r.raise_for_status()
    return [d["embedding"] for d in r.json()["data"]]

if __name__ == "__main__":
    client     = chromadb.PersistentClient(path="./sap_chroma_db")
    collection = client.get_or_create_collection("sap_docs")

    existing = set(collection.get()["ids"])
    new_chunks = [c for c in DOC_CHUNKS if c["id"] not in existing]

    if new_chunks:
        texts    = [c["text"] for c in new_chunks]
        vectors  = embed(texts)
        collection.add(
            ids        = [c["id"] for c in new_chunks],
            embeddings = vectors,
            documents  = texts,
            metadatas  = [{"source": c["source"], "page": c["page"]} for c in new_chunks],
        )
        print(f"Indexed {len(new_chunks)} new chunks.")
    else:
        print("All chunks already indexed.")

    print(f"Collection size: {collection.count()} documents")
    print("ChromaDB stored at ./sap_chroma_db")
