"""
Local vs Cloud LLM Pattern: Ollama (dev) / GenAI Hub (prod)
pip install requests
"""

import json
import requests
from config import ENVIRONMENT, OLLAMA_MODEL, BASE_URL, TOKEN, DEPLOY_ID, RG, QUESTIONS

class OllamaClient:
    """Talks to a locally running Ollama server."""

    BASE = "http://localhost:11434"

    def __init__(self, model: str = OLLAMA_MODEL):
        self.model = model

    def chat(self, messages: list[dict]) -> str:
        resp = requests.post(
            f"{self.BASE}/api/chat",
            json={"model": self.model, "messages": messages, "stream": False},
            timeout=120,
        )
        resp.raise_for_status()
        return resp.json()["message"]["content"].strip()

    @staticmethod
    def list_models() -> list[str]:
        """GET /api/tags — list locally available models."""
        resp = requests.get("http://localhost:11434/api/tags", timeout=10)
        resp.raise_for_status()
        return [m["name"] for m in resp.json().get("models", [])]

    @staticmethod
    def pull_model(model: str) -> None:
        """POST /api/pull — download a model (streams progress)."""
        print(f"Pulling model '{model}' from Ollama registry...")
        resp = requests.post(
            "http://localhost:11434/api/pull",
            json={"name": model},
            stream=True,
            timeout=300,
        )
        resp.raise_for_status()
        for line in resp.iter_lines():
            if line:
                data = json.loads(line)
                status = data.get("status", "")
                total  = data.get("total", 0)
                done   = data.get("completed", 0)
                if total:
                    pct = int(done / total * 100)
                    print(f"  {status}: {pct}%", end="\r")
                else:
                    print(f"  {status}")
        print(f"\nModel '{model}' ready.")

# ── GenAI Hub client ──────────────────────────────────────────────────────────
class GenAIHubClient:
    """Talks to SAP AI Core GenAI Hub."""

    def __init__(self):
        self.url = f"{BASE_URL}/inference/deployments/{DEPLOY_ID}/chat/completions"
        self.headers = {
            "Authorization": f"Bearer {TOKEN}",
            "Content-Type":  "application/json",
            "AI-Resource-Group": RG,
        }

    def chat(self, messages: list[dict]) -> str:
        resp = requests.post(
            self.url,
            headers=self.headers,
            json={"messages": messages, "max_tokens": 300},
            timeout=30,
        )
        resp.raise_for_status()
        return resp.json()["choices"][0]["message"]["content"].strip()

# ── Factory ───────────────────────────────────────────────────────────────────
def get_client():
    """Return OllamaClient in development, GenAIHubClient in production."""
    if ENVIRONMENT == "development":
        print(f"[Backend: Ollama local — model={OLLAMA_MODEL}]")
        return OllamaClient(model=OLLAMA_MODEL)
    print(f"[Backend: SAP GenAI Hub — deployment={DEPLOY_ID}]")
    return GenAIHubClient()

# ── Main ──────────────────────────────────────────────────────────────────────
def main():
    print(f"ENVIRONMENT={ENVIRONMENT}")
    client = get_client()

    # Optionally list available Ollama models (dev only)
    if ENVIRONMENT == "development":
        try:
            models = OllamaClient.list_models()
            print(f"Available Ollama models: {models}")
        except Exception as e:
            print(f"Could not list Ollama models: {e}")

    for q in QUESTIONS:
        print(f"\n{'='*60}")
        print(f"Q: {q}")
        messages = [
            {"role": "system", "content": "You are a concise SAP expert."},
            {"role": "user",   "content": q},
        ]
        answer = client.chat(messages)
        print(f"A: {answer}")

    # Show how to pull a model (commented out — would actually download)
    # OllamaClient.pull_model("mistral")

if __name__ == "__main__":
    main()
