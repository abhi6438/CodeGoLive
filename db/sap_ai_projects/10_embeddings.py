"""
Project: SAP AI Core Python Examples
Topic:   10_embeddings
Goal:    Embed 5 SAP module descriptions, find most similar to a query using cosine similarity.
         Pure math only – no external library required.
Requirements: AICORE_EMB_DEPLOYMENT_ID for the embedding model deployment.
"""
import requests, os, math

BASE    = os.environ["AICORE_BASE_URL"]
TOKEN   = os.environ["AICORE_TOKEN"]
EMB_ID  = os.environ["AICORE_EMB_DEPLOYMENT_ID"]
RG      = os.environ.get("AICORE_RG", "default")
HEADERS = {
    "Authorization": f"Bearer {TOKEN}",
    "Content-Type": "application/json",
    "AI-Resource-Group": RG,
}
EMB_URL = f"{BASE}/inference/deployments/{EMB_ID}/embeddings"

MODULES = [
    ("FI", "SAP Financial Accounting: manages general ledger, accounts payable, accounts receivable, and asset accounting."),
    ("MM", "SAP Materials Management: covers procurement, inventory management, and invoice verification for supply chain."),
    ("SD", "SAP Sales and Distribution: handles order management, shipping, billing, and customer master data."),
    ("HR", "SAP Human Resources: manages payroll, time management, personnel administration, and talent development."),
    ("PP", "SAP Production Planning: controls manufacturing orders, capacity planning, MRP, and shop floor operations."),
]

def embed(texts):
    r = requests.post(EMB_URL, headers=HEADERS,
                      json={"input": texts, "model": "text-embedding-ada-002"}, timeout=30)
    r.raise_for_status()
    return [d["embedding"] for d in r.json()["data"]]

def cosine(a, b):
    dot  = sum(x * y for x, y in zip(a, b))
    na   = math.sqrt(sum(x * x for x in a))
    nb   = math.sqrt(sum(x * x for x in b))
    return dot / (na * nb) if na and nb else 0.0

if __name__ == "__main__":
    query = "Which module should I use for managing vendor invoices and payments?"
    names, descs = zip(*MODULES)
    print("Embedding module descriptions...")
    all_vecs = embed(list(descs) + [query])
    module_vecs, query_vec = all_vecs[:-1], all_vecs[-1]

    scores = [(cosine(query_vec, v), n) for v, n in zip(module_vecs, names)]
    scores.sort(reverse=True)

    print(f"\nQuery: {query}\n")
    print(f"{'Module':<6}  {'Similarity':>10}")
    print("-" * 20)
    for score, name in scores:
        print(f"{name:<6}  {score:>10.4f}")
    print(f"\nBest match: {scores[0][1]}")
