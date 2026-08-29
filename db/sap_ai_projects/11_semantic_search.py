"""
Project: SAP AI Core Python Examples
Topic:   11_semantic_search
Goal:    In-memory semantic search over 5 SAP knowledge-base articles using embeddings.
Requirements: AICORE_EMB_DEPLOYMENT_ID
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

KB_ARTICLES = [
    {"id": "KB001", "title": "How to reset SAP user password",
     "text": "Administrators can reset passwords in SU01. Navigate to SU01, enter user ID, click Change, set new password in Logon Data tab."},
    {"id": "KB002", "title": "Goods receipt posting in MIGO",
     "text": "To post a goods receipt: open MIGO, select Goods Receipt and Purchase Order, enter PO number, verify quantities, post with movement type 101."},
    {"id": "KB003", "title": "Running payroll in SAP HR",
     "text": "Execute payroll via PC00_M99_CALC. Ensure master data is locked, run simulation first, review log, then post to FI with PC00_M99_CIPE."},
    {"id": "KB004", "title": "Creating a vendor in SAP MM",
     "text": "Create vendors in XK01 for all company codes or MK01 for purchasing only. Required fields: name, country, reconciliation account, payment terms."},
    {"id": "KB005", "title": "Troubleshooting RFC connection errors",
     "text": "Check RFC destination in SM59. Test connection using Remote Logon. Common issues: wrong hostname, firewall blocking port 3300, invalid credentials."},
]

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
