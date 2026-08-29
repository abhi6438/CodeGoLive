"""
Project: SAP AI Core Python Examples
Topic:   15_ui5_ai_chat
Goal:    FastAPI backend for SAP UI5 chat widget. POST /api/chat endpoint.
Requirements: pip install fastapi uvicorn requests
Run with: uvicorn 15_ui5_ai_chat:app --reload --port 8000
"""
import requests, os
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List

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

app = FastAPI(title="SAP UI5 AI Chat Backend", version="1.0.0")

class Message(BaseModel):
    role: str
    content: str

class ChatRequest(BaseModel):
    messages: List[Message]
    max_tokens: int = 300

class ChatResponse(BaseModel):
    reply: str
    model: str
    usage: dict

SYSTEM_MSG = {
    "role": "system",
    "content": (
        "You are a helpful SAP assistant embedded in the SAP Fiori launchpad. "
        "Help users with SAP transactions, error messages, and business processes. "
        "Be concise and always suggest the relevant SAP transaction code when applicable."
    ),
}

@app.post("/api/chat", response_model=ChatResponse)
def chat(req: ChatRequest):
    messages = [SYSTEM_MSG] + [m.dict() for m in req.messages]
    try:
        r = requests.post(URL, headers=HEADERS, json={
            "model": "gpt-4o",
            "messages": messages,
            "max_tokens": req.max_tokens,
        }, timeout=30)
        r.raise_for_status()
    except requests.HTTPError as e:
        raise HTTPException(status_code=502, detail=str(e))
    data = r.json()
    return ChatResponse(
        reply = data["choices"][0]["message"]["content"].strip(),
        model = data.get("model", "gpt-4o"),
        usage = data.get("usage", {}),
    )

@app.get("/health")
def health():
    return {"status": "ok", "service": "sap-ui5-ai-chat"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
