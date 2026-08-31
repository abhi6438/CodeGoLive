"""
Project: SAP AI Core Python Examples
Topic:   07_streaming
Goal:    Stream analysis of an SAP system log snippet using SSE (stream=True), print tokens live.
"""

import requests, json
from config import HEADERS, URL, LOG_SNIPPET

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
