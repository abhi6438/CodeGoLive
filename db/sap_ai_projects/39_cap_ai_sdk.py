"""
Project: SAP GenAI Hub Integration Series
Topic:   39_cap_ai_sdk
Goal:    Python equivalent of @sap-ai-sdk/foundation-models with typed client, error handling
Requirements: pip install requests
"""

import os, json, requests
from dataclasses import dataclass, field
from typing import Optional, Iterator


class SAPAIAuthError(Exception):
    pass


class SAPAIRateLimitError(Exception):
    def __init__(self, retry_after: int = 60):
        self.retry_after = retry_after
        super().__init__(f"Rate limited. Retry after {retry_after}s")


class SAPAIModelError(Exception):
    def __init__(self, status_code: int, message: str):
        self.status_code = status_code
        super().__init__(f"Model error {status_code}: {message}")


@dataclass
class ChatMessage:
    role: str
    content: str


@dataclass
class ChatResponse:
    content: str
    model: str
    usage: dict
    finish_reason: str


@dataclass
class EmbeddingResponse:
    embedding: list[float]
    model: str
    token_count: int


@dataclass
class SAPAIClient:
    base_url: str = field(default_factory=lambda: os.environ["AICORE_BASE_URL"])
    token: str = field(default_factory=lambda: os.environ["AICORE_TOKEN"])
    deployment_id: str = field(default_factory=lambda: os.environ["AICORE_DEPLOYMENT_ID"])
    resource_group: str = field(default_factory=lambda: os.environ.get("AICORE_RG", "default"))
    emb_deployment_id: Optional[str] = field(default_factory=lambda: os.environ.get("AICORE_EMB_DEPLOYMENT_ID"))
    _session: Optional[requests.Session] = field(default=None, init=False, repr=False)

    def auth(self) -> bool:
        self._session = requests.Session()
        self._session.headers.update({
            "Authorization": f"Bearer {self.token}",
            "Content-Type": "application/json",
            "AI-Resource-Group": self.resource_group,
        })
        try:
            url = f"{self.base_url}/inference/deployments/{self.deployment_id}"
            r = self._session.get(url, timeout=10)
            if r.status_code == 401:
                raise SAPAIAuthError("Invalid token or unauthorized access")
            print(f"Authenticated. Deployment status: {r.json().get('status', 'unknown')}")
            return True
        except SAPAIAuthError:
            raise
        except Exception as e:
            print(f"Auth check warning: {e}. Session initialized.")
            return True

    def _get_session(self) -> requests.Session:
        if self._session is None:
            self.auth()
        return self._session

    def chat(self, messages: list[ChatMessage], model: str = "gpt-4o",
             temperature: float = 0.7, max_tokens: int = 1000) -> ChatResponse:
        url = f"{self.base_url}/inference/deployments/{self.deployment_id}/chat/completions"
        payload = {
            "model": model, "temperature": temperature, "max_tokens": max_tokens,
            "messages": [{"role": m.role, "content": m.content} for m in messages],
        }
        r = self._get_session().post(url, json=payload, timeout=60)
        if r.status_code == 429:
            raise SAPAIRateLimitError(int(r.headers.get("Retry-After", 60)))
        if r.status_code >= 400:
            raise SAPAIModelError(r.status_code, r.text[:200])
        data = r.json()
        choice = data["choices"][0]
        return ChatResponse(content=choice["message"]["content"], model=data.get("model", model),
                            usage=data.get("usage", {}), finish_reason=choice.get("finish_reason", "stop"))

    def stream(self, messages: list[ChatMessage], model: str = "gpt-4o") -> Iterator[str]:
        url = f"{self.base_url}/inference/deployments/{self.deployment_id}/chat/completions"
        payload = {"model": model, "stream": True,
                   "messages": [{"role": m.role, "content": m.content} for m in messages]}
        with self._get_session().post(url, json=payload, stream=True, timeout=60) as r:
            if r.status_code >= 400:
                raise SAPAIModelError(r.status_code, r.text[:200])
            for line in r.iter_lines():
                if line and line.startswith(b"data: "):
                    data = line[6:]
                    if data == b"[DONE]":
                        break
                    chunk = json.loads(data)
                    delta = chunk["choices"][0].get("delta", {})
                    if "content" in delta:
                        yield delta["content"]

    def embed(self, text: str, model: str = "text-embedding-ada-002") -> EmbeddingResponse:
        if not self.emb_deployment_id:
            raise ValueError("AICORE_EMB_DEPLOYMENT_ID not set")
        url = f"{self.base_url}/inference/deployments/{self.emb_deployment_id}/embeddings"
        payload = {"model": model, "input": text}
        r = self._get_session().post(url, json=payload, timeout=30)
        if r.status_code >= 400:
            raise SAPAIModelError(r.status_code, r.text[:200])
        data = r.json()
        return EmbeddingResponse(embedding=data["data"][0]["embedding"], model=data.get("model", model),
                                 token_count=data.get("usage", {}).get("total_tokens", 0))


if __name__ == "__main__":
    client = SAPAIClient()
    client.auth()

    response = client.chat([
        ChatMessage(role="system", content="You are an SAP expert."),
        ChatMessage(role="user", content="In one sentence, what is SAP S/4HANA?"),
    ])
    print(f"Chat: {response.content}")
    print(f"Tokens used: {response.usage}")

    print("\nStreaming: ", end="", flush=True)
    for chunk in client.stream([ChatMessage(role="user", content="List 3 SAP modules briefly.")]):
        print(chunk, end="", flush=True)
    print()

    if os.environ.get("AICORE_EMB_DEPLOYMENT_ID"):
        emb = client.embed("SAP Materials Management procurement")
        print(f"\nEmbedding dims: {len(emb.embedding)}, tokens: {emb.token_count}")
