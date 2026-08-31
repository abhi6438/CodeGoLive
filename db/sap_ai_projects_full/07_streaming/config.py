import os
from dotenv import load_dotenv

load_dotenv()  # reads .env file

BASE    = os.environ["AICORE_BASE_URL"]
TOKEN   = os.environ["AICORE_TOKEN"]
DEPID   = os.environ["AICORE_DEPLOYMENT_ID"]
RG      = os.environ.get("AICORE_RG", "default")
HEADERS = {
    "Authorization": f"Bearer {TOKEN}",
    "Content-Type": "application/json",
    "AI-Resource-Group": RG,
}
URL = f"{BASE}/inference/deployments/{DEPID}/chat/completions"

LOG_SNIPPET = """
[2024-03-15 09:12:01] INFO  Work process WP02 started (DIA)
[2024-03-15 09:12:45] ERROR DBIF_RSQL_SQL_ERROR: SQL error -10108 in cursor operation "SELECT MANDT,VBELN FROM VBAK"
[2024-03-15 09:12:45] ERROR Short dump DBIF_RSQL_SQL_ERROR in program SAPMV45A
[2024-03-15 09:13:01] WARN  Memory consumption 87% - threshold 80% exceeded (heap: 4.3 GB / 5 GB)
[2024-03-15 09:15:22] ERROR Dialog process WP04 restart after dump (restart #3 in last 5 min)
[2024-03-15 09:16:00] INFO  Emergency session opened by user BASIS_ADMIN from 10.0.1.5
"""
