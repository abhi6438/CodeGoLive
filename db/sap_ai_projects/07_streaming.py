"""
Project: SAP AI Core Python Examples
Topic:   07_streaming
Goal:    Stream analysis of an SAP system log snippet using SSE (stream=True), print tokens live.
"""
import requests, os, json

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

def stream_analysis(log):
    payload = {
        "model": "gpt-4o",
        "stream": True,
        "messages": [
            {"role": "system", "content": "You are an SAP Basis expert. Analyze system logs concisely."},
            {"role": "user", "content": f"Analyze this SAP system log and identify root causes:\n{log}"},
        ],
        "max_tokens": 300,
    }
    with requests.post(URL, headers=HEADERS, json=payload, stream=True, timeout=60) as resp:
        resp.raise_for_status()
        for line in resp.iter_lines():
            if not line:
                continue
            text = line.decode("utf-8")
            if text.startswith("data: "):
                data = text[6:]
                if data == "[DONE]":
                    break
                try:
                    chunk = json.loads(data)
                    delta = chunk["choices"][0]["delta"].get("content", "")
                    if delta:
                        print(delta, end="", flush=True)
                except json.JSONDecodeError:
                    pass
    print()

if __name__ == "__main__":
    print("SAP System Log Analysis (streaming)\n" + "=" * 40)
    stream_analysis(LOG_SNIPPET)
