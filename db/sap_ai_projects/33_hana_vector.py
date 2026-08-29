"""
Project: SAP GenAI Hub Integration Series
Topic:   33_hana_vector
Goal:    Store and query document embeddings in SAP HANA Cloud using VECTOR(1536)
Requirements: pip install hdbcli requests
Env vars: HANA_HOST, HANA_PORT, HANA_USER, HANA_PASSWORD
          AICORE_BASE_URL, AICORE_TOKEN, AICORE_EMB_DEPLOYMENT_ID, AICORE_RG
"""

import os, json, requests
import hdbcli.dbapi as dbapi

HANA_HOST = os.environ["HANA_HOST"]
HANA_PORT = int(os.environ.get("HANA_PORT", "443"))
HANA_USER = os.environ["HANA_USER"]
HANA_PASS = os.environ["HANA_PASSWORD"]

BASE     = os.environ["AICORE_BASE_URL"]
TOKEN    = os.environ["AICORE_TOKEN"]
EMB_DEPID = os.environ["AICORE_EMB_DEPLOYMENT_ID"]
RG       = os.environ.get("AICORE_RG", "default")
EMB_URL  = f"{BASE}/inference/deployments/{EMB_DEPID}/embeddings"
HEADERS  = {"Authorization": f"Bearer {TOKEN}", "Content-Type": "application/json", "AI-Resource-Group": RG}

SAP_DOCS = [
    ("DOC001", "MM60", "Transaction MM60 displays inventory turnover analysis by material and plant."),
    ("DOC002", "FB70", "Transaction FB70 is used to post customer invoices in SAP Financial Accounting."),
    ("DOC003", "ME21N", "Transaction ME21N creates purchase orders in SAP Materials Management."),
    ("DOC004", "VA01", "Transaction VA01 creates sales orders in SAP Sales and Distribution."),
    ("DOC005", "SE38", "Transaction SE38 is the ABAP editor for writing and editing SAP programs."),
]


def get_embedding(text: str) -> list[float]:
    payload = {"model": "text-embedding-ada-002", "input": text}
    r = requests.post(EMB_URL, headers=HEADERS, json=payload, timeout=30)
    r.raise_for_status()
    return r.json()["data"][0]["embedding"]


def setup_table(cursor):
    cursor.execute("DROP TABLE IF EXISTS SAP_DOC_EMBEDDINGS")
    cursor.execute("""
        CREATE TABLE SAP_DOC_EMBEDDINGS (
            DOC_ID      NVARCHAR(20) PRIMARY KEY,
            TCODE       NVARCHAR(10),
            DESCRIPTION NCLOB,
            EMBEDDING   REAL_VECTOR(1536)
        )
    """)
    print("Table SAP_DOC_EMBEDDINGS created.")


def insert_documents(cursor):
    for doc_id, tcode, description in SAP_DOCS:
        print(f"  Embedding {doc_id} ({tcode})...")
        embedding = get_embedding(description)
        vec_str = "[" + ",".join(str(v) for v in embedding) + "]"
        cursor.execute(
            "INSERT INTO SAP_DOC_EMBEDDINGS VALUES (?, ?, ?, TO_REAL_VECTOR(?))",
            (doc_id, tcode, description, vec_str),
        )
    print(f"Inserted {len(SAP_DOCS)} documents.")


def semantic_search(cursor, query: str, top_k: int = 3):
    print(f"\nSearching for: '{query}'")
    query_vec = get_embedding(query)
    vec_str = "[" + ",".join(str(v) for v in query_vec) + "]"

    cursor.execute("""
        SELECT TOP ? DOC_ID, TCODE, DESCRIPTION,
               COSINE_SIMILARITY(EMBEDDING, TO_REAL_VECTOR(?)) AS SIMILARITY
        FROM SAP_DOC_EMBEDDINGS
        ORDER BY SIMILARITY DESC
    """, (top_k, vec_str))

    rows = cursor.fetchall()
    for row in rows:
        print(f"  [{row[0]}] {row[1]}: {row[2][:60]}... (score={row[3]:.4f})")
    return rows


if __name__ == "__main__":
    conn = dbapi.connect(address=HANA_HOST, port=HANA_PORT, user=HANA_USER,
                         password=HANA_PASS, encrypt=True, sslValidateCertificate=False)
    cursor = conn.cursor()

    setup_table(cursor)
    insert_documents(cursor)
    conn.commit()

    semantic_search(cursor, "How do I create a purchase order?")
    semantic_search(cursor, "Financial accounting and invoicing transactions")

    cursor.close()
    conn.close()
    print("\nDone.")
