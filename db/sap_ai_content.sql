-- SAP AI Core content seed
-- Format: $md$ dollar-quoting

UPDATE public.topics SET content_md = $md$
# Episode 1 — SAP AI Core Intro

## What you'll build
A Python script that authenticates with SAP AI Core, lists all resource groups, and confirms your service binding is correct.

---

## Why this matters
SAP AI Core is the runtime that hosts, deploys, and scales every AI model on BTP. Before you can call GPT-4o or any LLM through the Generative AI Hub, every request passes through AI Core. Getting auth right here unblocks every lesson that follows.

---

## Step 1 — Understand the architecture

> **SAP AI Core** sits between your application and the model. It manages deployments, quotas, and access via OAuth2 + REST.

Key concepts:
- **Resource Group** — tenant namespace; isolates workloads (dev / test / prod)
- **Deployment** — a running model endpoint with a unique URL
- **Configuration** — binds an executable to a specific model + parameters

---

## Step 2 — Install and configure

```bash
pip install ai-core-sdk
```

Create `~/.aicore/config.json` — copy values from BTP Cockpit > AI Core > Service Keys:

```json
{
  "AUTH_URL":       "https://<subaccount>.authentication.eu10.hana.ondemand.com",
  "CLIENT_ID":      "sb-<your-id>",
  "CLIENT_SECRET":  "<secret>",
  "RESOURCE_GROUP": "default",
  "AI_API_URL":     "https://api.ai.prod.eu-central-1.aws.ml.hana.ondemand.com"
}
```

**What each key line does:**
- `AUTH_URL` — OAuth2 token endpoint; scoped to your BTP subaccount
- `CLIENT_ID` / `CLIENT_SECRET` — from the service-key JSON in BTP Cockpit; include the full `sb-...` string
- `RESOURCE_GROUP` — scope for all API calls; create more for prod/dev isolation
- `AI_API_URL` — region-specific base URL found in your service key under `serviceurls`

---

## Step 3 — Verify the connection

```python
from ai_core_sdk.ai_core_v2_client import AICoreV2Client

# Reads ~/.aicore/config.json and fetches an OAuth2 token automatically
client = AICoreV2Client.from_env()

# List resource groups — proves auth is working
rgs = client.resource_groups.query()
for rg in rgs.resources:
    print(f"Resource group: {rg.resource_group_id}")

# List deployments
deps = client.deployment.query(resource_group="default").resources
print(f"Found {len(deps)} deployment(s)")
for d in deps:
    print(f"  {d.id}  status={d.status}")
```

**What each key line does:**
- `AICoreV2Client.from_env()` — reads config, fetches bearer token; no manual OAuth needed
- `client.resource_groups.query()` — lightweight call that validates credentials before any inference
- `.resources` — unwraps the paginated list into a plain Python list
- `client.deployment.query(...)` — returns all deployments; empty list is normal on a fresh setup

---

## Common mistakes

**Mistake:** Using the BTP Cockpit dashboard URL instead of the service-key API URL.
**Fix:** In the service key JSON use `serviceurls.AI_API_URL` verbatim — not the cockpit URL.

**Mistake:** `401 Unauthorized` even with correct-looking credentials.
**Fix:** CLIENT_ID must include the full `sb-` prefix and `!b<n>` suffix. Truncating it breaks the OAuth signature silently.

---

## ✅ Checkpoint

- [ ] `pip install ai-core-sdk` succeeds
- [ ] `config.json` has all five fields from your service key
- [ ] `client.resource_groups.query()` returns at least one group without errors
- [ ] You can print a list of deployments
- [ ] You can explain the difference between a deployment and a configuration

$md$ WHERE slug = 'ai-00-core-intro';

UPDATE public.topics SET content_md = $md$
# Episode 2 — SAP Generative AI Hub

## What you'll build
A Python script that calls the SAP Generative AI Hub to get a GPT-4o chat completion using the OpenAI-compatible endpoint exposed by AI Core.

---

## Why this matters
The Generative AI Hub is SAP's managed gateway to foundation models — GPT-4o, Claude, Gemini, and open-source LLMs — accessed through one consistent API. You write standard OpenAI code and SAP handles routing, rate limiting, and compliance logging.

---

## Step 1 — Find your deployment URL

In AI Launchpad > Generative AI Hub > Deployments, note the Deployment ID. The inference URL follows this pattern:

> `{AI_API_URL}/v2/inference/deployments/{DEPLOYMENT_ID}/v1/chat/completions`

---

## Step 2 — Install dependencies

```bash
pip install openai ai-core-sdk
```

---

## Step 3 — Send your first completion

```python
import os
from ai_core_sdk.ai_core_v2_client import AICoreV2Client
from openai import OpenAI

# Get a fresh bearer token from AI Core
ai_client = AICoreV2Client.from_env()
token = ai_client._token_handler.get_token()

AI_API_URL    = os.environ["AI_API_URL"]
DEPLOYMENT_ID = "d<your-deployment-id>"
RESOURCE_GROUP = "default"

# Point the OpenAI SDK at the GenAI Hub endpoint
client = OpenAI(
    base_url=f"{AI_API_URL}/v2/inference/deployments/{DEPLOYMENT_ID}/v1",
    api_key=token,
    default_headers={"AI-Resource-Group": RESOURCE_GROUP},
)

response = client.chat.completions.create(
    model="gpt-4o",
    messages=[
        {"role": "system", "content": "You are an SAP BTP expert. Be concise."},
        {"role": "user",   "content": "What is the Generative AI Hub in two sentences?"},
    ],
    max_tokens=150,
)

print(response.choices[0].message.content)
```

**What each key line does:**
- `ai_client._token_handler.get_token()` — fetches a valid bearer token; tokens expire in ~12 h so call this once per run
- `base_url=f".../{DEPLOYMENT_ID}/v1"` — all requests route through your specific AI Core deployment
- `default_headers={"AI-Resource-Group": ...}` — required on every request; missing it returns a 404
- `api_key=token` — OpenAI SDK sends this as `Authorization: Bearer <token>`

---

## Common mistakes

**Mistake:** Re-using a cached token after it expires.
**Fix:** Call `get_token()` at the start of each script run, not once at import time.

**Mistake:** Wrong model name in the request body.
**Fix:** The model field is largely ignored by AI Core — the deployment ID pins the model. Check AI Launchpad > Deployments to see what is actually running.

---

## ✅ Checkpoint

- [ ] Bearer token retrieved without errors
- [ ] OpenAI client has correct base_url including Deployment ID
- [ ] `AI-Resource-Group` header is present
- [ ] Chat completion returns a coherent response
- [ ] You can change the system prompt and observe different output

$md$ WHERE slug = 'ai-01-genai-hub';

UPDATE public.topics SET content_md = $md$
# Episode 3 — Prompt Engineering

## What you'll build
A Python script that compares zero-shot, few-shot, and chain-of-thought prompting side by side on the same question.

---

## Why this matters
The model is fixed — your prompt is the only lever you control. These three patterns cover 90% of real-world prompt engineering needs.

---

## Step 1 — The three patterns

> **Zero-shot** — ask directly. Fast; good for simple tasks.
> **Few-shot** — show 2-4 examples before the question. Guides format and tone.
> **Chain-of-thought** — ask the model to reason step by step. Improves accuracy on multi-step problems.

---

## Step 2 — Reusable helper

```python
def chat(system: str, user: str, client) -> str:
    resp = client.chat.completions.create(
        model="gpt-4o",
        messages=[
            {"role": "system", "content": system},
            {"role": "user",   "content": user},
        ],
        temperature=0.2,
        max_tokens=400,
    )
    return resp.choices[0].message.content.strip()
```

**What each key line does:**
- `temperature=0.2` — low randomness for factual tasks; use 0.7-1.0 for creative tasks
- `.strip()` — removes leading/trailing whitespace models sometimes add

---

## Step 3 — Compare all three on the same question

```python
question = "A customer's BTP trial expires in 3 days. What should they do?"

# Zero-shot
print("=== ZERO-SHOT ===")
print(chat("You are an SAP BTP support agent.", question, client))

# Few-shot: examples in the system prompt define the expected format
few_shot = (
    "You are an SAP BTP support agent.\n\n"
    "Examples:\n"
    "User: My CF quota is full.\n"
    "Agent: Delete unused service instances or request a quota increase in BTP Cockpit > Entitlements.\n\n"
    "User: I cannot deploy to Cloud Foundry.\n"
    "Agent: Check the space developer role assignment and run cf login to verify CLI access."
)
print("\n=== FEW-SHOT ===")
print(chat(few_shot, question, client))

# Chain-of-thought: explicit reasoning before the answer
cot = (
    "You are an SAP BTP support agent.\n"
    "Think step by step before answering.\n"
    "Format: REASONING: <thinking>\nANSWER: <recommendation>"
)
print("\n=== CHAIN-OF-THOUGHT ===")
print(chat(cot, question, client))
```

**What each key line does:**
- Few-shot examples belong in `system`, not `user` — they define the task, not ask a question
- `"Think step by step"` — canonical CoT trigger; empirically proven to improve multi-step accuracy
- `REASONING: ... ANSWER:` — structured format lets you parse the final answer with `split("ANSWER:")[-1]`

---

## Common mistakes

**Mistake:** Putting few-shot examples in the `user` message.
**Fix:** Examples that define the task format belong in `system`. The `user` message should be only the current question.

**Mistake:** High temperature for classification or extraction.
**Fix:** `temperature=0` for structured tasks. High temperature is for brainstorming only.

---

## ✅ Checkpoint

- [ ] All three patterns return noticeably different output from the same question
- [ ] CoT response contains both REASONING and ANSWER sections
- [ ] You can parse the ANSWER section programmatically
- [ ] You know when to use each pattern

$md$ WHERE slug = 'ai-02-prompt-engineering';

UPDATE public.topics SET content_md = $md$
# Episode 4 — Chat Completions API

## What you'll build
A multi-turn streaming conversation loop — the core of every chatbot and copilot.

---

## Why this matters
The Chat Completions API is the primitive behind every conversational AI feature in SAP Build, CAP plugins, and custom assistants. Understanding history and streaming is the foundation.

---

## Step 1 — The stateless history pattern

> The API has no memory between calls. You maintain context by sending the full `messages` array on every request.

- `system` — instructions and persona (sent once, first)
- `user` — the human's current message
- `assistant` — the model's previous reply (you append this after each response)

---

## Step 2 — Streaming multi-turn loop

```python
def run_chat(client, system_prompt: str):
    messages = [{"role": "system", "content": system_prompt}]
    print("Type 'quit' to exit.\n")

    while True:
        user_input = input("You: ").strip()
        if user_input.lower() == "quit":
            break

        messages.append({"role": "user", "content": user_input})

        stream = client.chat.completions.create(
            model="gpt-4o",
            messages=messages,
            stream=True,
            max_tokens=500,
        )

        print("AI: ", end="", flush=True)
        full_reply = ""
        for chunk in stream:
            token = chunk.choices[0].delta.content or ""
            print(token, end="", flush=True)
            full_reply += token
        print()

        messages.append({"role": "assistant", "content": full_reply})

run_chat(client, "You are a helpful SAP BTP expert. Be concise.")
```

**What each key line does:**
- `messages.append({"role": "user", ...})` — added **before** the API call so the current message is in context
- `stream=True` — returns a generator; first token appears in ~200 ms
- `chunk.choices[0].delta.content or ""` — `delta.content` is None on the final chunk; `or ""` prevents TypeError
- Last `messages.append(...)` — stores the reply so the next turn has full context

---

## Step 3 — Rolling window to prevent context overflow

```python
def trim_history(messages, max_turns=10):
    system = messages[:1]                       # always keep the system prompt
    recent = messages[1:][-(max_turns * 2):]    # keep last N turns (2 messages each)
    return system + recent
```

Call `messages = trim_history(messages)` before each API call once the conversation exceeds ~20 turns.

---

## Common mistakes

**Mistake:** Not appending the assistant reply after each turn.
**Fix:** Always `messages.append({"role": "assistant", "content": full_reply})` after the stream loop.

**Mistake:** Trimming removes the system prompt.
**Fix:** Slice as `messages[:1]` + trimmed tail, never slice the whole list.

---

## ✅ Checkpoint

- [ ] Multi-turn loop works for 5+ turns without errors
- [ ] Responses stream token-by-token to the terminal
- [ ] Model references earlier messages correctly
- [ ] `trim_history()` keeps system prompt and trims old turns

$md$ WHERE slug = 'ai-03-chat-completions';

UPDATE public.topics SET content_md = $md$
# Episode 5 — System Prompts & Personas

## What you'll build
Three distinct AI personas — a formal SAP consultant, a friendly onboarding bot, and a strict JSON extractor — driven by system prompts alone, no fine-tuning needed.

---

## Why this matters
The system prompt is your most powerful tool. It sets persona, constraints, output format, and domain knowledge. A well-crafted system prompt turns a general model into a domain-specific assistant instantly.

---

## Step 1 — The four-part structure

Every strong system prompt follows this order:

> **Role** → **Context** → **Rules** → **Output format**

- **Role**: who the model is ("You are a senior SAP BTP architect")
- **Context**: what situation it's in ("internal support tool for Transformco employees")
- **Rules**: hard constraints ("never speculate — say I don't know when uncertain")
- **Output format**: exact structure ("include Recommendation and Rationale sections")

---

## Step 2 — Three personas in code

```python
PERSONAS = {
    "consultant": (
        "You are a senior SAP BTP solutions architect at a Big-4 firm. "
        "Context: advising enterprise clients on cloud migration. "
        "Rules: use formal language; never speculate — say you don't know when uncertain. "
        "Output: always include a Recommendation section and a Rationale section."
    ),
    "onboarding": (
        "You are Aria, a friendly SAP BTP onboarding assistant. "
        "Context: helping developers who have never used SAP before. "
        "Rules: explain all acronyms on first use; keep responses under 120 words; "
        "add an encouraging note at the end of every message. "
        "Output: conversational paragraphs, no bullet points."
    ),
    "extractor": (
        "You are a JSON extraction engine. "
        "Rules: output ONLY raw valid JSON — no markdown fences, no prose. "
        "If a field is missing, use null. Never add fields not in the schema. "
        'Schema: {"service": string, "region": string, "tier": string, "cost_usd": number|null}'
    ),
}

def ask(key: str, question: str, client) -> str:
    resp = client.chat.completions.create(
        model="gpt-4o",
        messages=[
            {"role": "system", "content": PERSONAS[key]},
            {"role": "user",   "content": question},
        ],
        temperature=0.1,
    )
    return resp.choices[0].message.content

q = "Tell me about SAP HANA Cloud pricing in eu10"
for key in PERSONAS:
    print(f"\n=== {key.upper()} ===")
    print(ask(key, q, client))
```

**What each key line does:**
- `PERSONAS` dict — makes swapping personas at runtime trivial; great for A/B testing prompt versions
- `"output ONLY raw valid JSON"` — all-caps on ONLY reliably suppresses markdown fences in output
- `temperature=0.1` — near-deterministic; essential for the extractor persona
- Rules use imperative language — "never", "always", "only" — not suggestions like "try to"

---

## Step 3 — Validate the extractor

```python
import json

raw = ask("extractor", "HANA Cloud in eu10 professional tier at USD 1200 per month", client)
try:
    data = json.loads(raw)
    print(data)
except json.JSONDecodeError as e:
    print(f"Parse failed: {e}. Raw: {raw}")
```

---

## Common mistakes

**Mistake:** Rules as suggestions ("try to be concise") instead of hard limits ("respond in under 120 words, hard limit").
**Fix:** Imperative constraints. Models treat vague guidance as optional.

**Mistake:** Extractor still wraps output in code fences.
**Fix:** Add a separate sentence: "Do not use markdown code fences. Output raw JSON only." Repetition helps.

---

## ✅ Checkpoint

- [ ] All three personas produce clearly different styles from the same question
- [ ] Extractor passes `json.loads()` without errors
- [ ] You can add a fourth persona without changing the `ask()` function
- [ ] You can explain Role > Context > Rules > Output format

$md$ WHERE slug = 'ai-04-system-prompts';

UPDATE public.topics SET content_md = $md$
# Episode 6 — Few-Shot Learning

## What you'll build
A ticket classifier that routes SAP support tickets into five categories using only examples in the prompt — no training, no fine-tuning.

---

## Why this matters
Few-shot prompting lets you specialise a model for your domain in minutes. For ticket routing, document classification, and extraction it often matches fine-tuned accuracy at near-zero cost.

---

## Step 1 — Rules for good examples

> Diverse, representative, and unambiguous. Overlapping categories produce inconsistent output.

1. Cover edge cases, not just easy ones
2. Use the exact output format expected in production
3. Aim for 2-4 examples per class

---

## Step 2 — Build the classifier

```python
SYSTEM = (
    "You are an SAP support ticket classifier.\n"
    "Classify each ticket into exactly one of: BILLING | TECHNICAL | ACCESS | PERFORMANCE | GENERAL\n\n"
    "Examples:\n"
    "Ticket: I was charged twice for my BTP subscription\nCategory: BILLING\n\n"
    "Ticket: Cloud Foundry deployment fails with exit code 1\nCategory: TECHNICAL\n\n"
    "Ticket: Cannot log in to BTP Cockpit — 403 error\nCategory: ACCESS\n\n"
    "Ticket: Fiori app takes 45 seconds to load\nCategory: PERFORMANCE\n\n"
    "Ticket: How do I get started with Integration Suite?\nCategory: GENERAL\n\n"
    "Ticket: AI Core deployment stuck in PENDING for 2 hours\nCategory: TECHNICAL\n\n"
    "Rules:\n"
    "- Output ONLY the category name, nothing else\n"
    "- If multiple apply, choose the most specific one"
)

VALID = {"BILLING", "TECHNICAL", "ACCESS", "PERFORMANCE", "GENERAL"}

def classify(ticket: str, client) -> str:
    resp = client.chat.completions.create(
        model="gpt-4o",
        messages=[
            {"role": "system", "content": SYSTEM},
            {"role": "user",   "content": f"Ticket: {ticket}\nCategory:"},
        ],
        temperature=0,
        max_tokens=10,
    )
    result = resp.choices[0].message.content.strip().upper().split()[0]
    return result if result in VALID else "GENERAL"

tickets = [
    "I need a refund for last month's overage charges",
    "My CAP application crashes with a null pointer error",
    "New team member cannot access our subaccount",
    "Report generation times out after 30 seconds",
    "What is the difference between CF and Kyma?",
]
for t in tickets:
    print(f"{classify(t, client):15}  {t}")
```

**What each key line does:**
- `f"Ticket: {ticket}\nCategory:"` — dangling `Category:` primes the model to output the label next, not a sentence
- `temperature=0` — classification must be reproducible; the same ticket must always give the same answer
- `max_tokens=10` — category is one word; capping tokens cuts latency and cost per call
- `.split()[0]` — handles cases where the model adds punctuation or extra words
- `if result in VALID else "GENERAL"` — safe fallback for unexpected model output

---

## Common mistakes

**Mistake:** One example per class — model fails on edge cases.
**Fix:** Minimum 2 examples per class; 3-4 for ambiguous pairs like TECHNICAL vs PERFORMANCE.

**Mistake:** Not validating output — model occasionally outputs "TECHNICAL." with a period.
**Fix:** Always `.split()[0]` and check against your valid set before using the result.

---

## ✅ Checkpoint

- [ ] Correct category returned for all five test tickets
- [ ] `temperature=0` gives identical results across multiple runs
- [ ] New category can be added with examples only — no code change needed
- [ ] Invalid output falls back to GENERAL gracefully

$md$ WHERE slug = 'ai-05-few-shot';

UPDATE public.topics SET content_md = $md$
# Episode 7 — Multi-Turn Conversations

## What you'll build
A `ConversationManager` class with history management, context trimming, and JSON serialisation — ready to plug into a FastAPI or CAP endpoint.

---

## Why this matters
A bare while-loop works in a terminal but breaks in real apps. You need a class that manages history, trims context, and serialises state so you can persist conversations in Supabase and restore them after a page refresh.

---

## Step 1 — Design the class

Responsibilities:
- Store message history with timestamps
- Enforce a max-turn budget via trimming
- Serialise to / deserialise from plain dicts (database-friendly)
- `chat()` method that handles the API call

---

## Step 2 — Implement

```python
import time
from openai import OpenAI

class ConversationManager:
    def __init__(self, client: OpenAI, system_prompt: str, max_turns: int = 20):
        self.client = client
        self.max_turns = max_turns
        self.messages = [{"role": "system", "content": system_prompt}]
        self.created_at = time.time()

    def chat(self, user_message: str, model: str = "gpt-4o") -> str:
        self.messages.append({"role": "user", "content": user_message})
        self._trim()
        resp = self.client.chat.completions.create(
            model=model, messages=self.messages, max_tokens=500,
        )
        reply = resp.choices[0].message.content
        self.messages.append({"role": "assistant", "content": reply})
        return reply

    def _trim(self):
        if len(self.messages) > 1 + self.max_turns * 2:
            self.messages = (
                self.messages[:1] + self.messages[-(self.max_turns * 2):]
            )

    def reset(self):
        self.messages = [self.messages[0]]   # keep system prompt only

    def to_dict(self) -> dict:
        return {"messages": self.messages, "created_at": self.created_at}

    @classmethod
    def from_dict(cls, data: dict, client: OpenAI):
        obj = cls(client, system_prompt="")
        obj.messages = data["messages"]
        obj.created_at = data.get("created_at", time.time())
        return obj
```

**What each key line does:**
- `self.messages[:1]` — always preserves the system prompt; trimming must never remove it
- `-(self.max_turns * 2)` — each turn = user + assistant = 2 messages; multiply accordingly
- `to_dict()` / `from_dict()` — plain dict round-trip for Supabase JSON column storage
- `reset()` — clears history but keeps the system prompt; useful for "new topic" buttons in UI

---

## Step 3 — Use in a web endpoint

```python
sessions = {}  # use Redis or Supabase in production

def handle_message(session_id: str, user_msg: str, client) -> str:
    if session_id not in sessions:
        sessions[session_id] = ConversationManager(
            client, "You are an SAP BTP expert assistant."
        )
    return sessions[session_id].chat(user_msg)

# Test three-turn conversation
for msg in ["What is AI Core?", "And the GenAI Hub?", "How are they related?"]:
    print(handle_message("user-42", msg, client))
```

---

## Common mistakes

**Mistake:** Storing sessions in a Python dict in production — lost on restart.
**Fix:** Serialise with `to_dict()`, store in Supabase, restore with `from_dict()` on each request.

**Mistake:** Trimming removes the system prompt.
**Fix:** Always `messages[:1] + trimmed_tail`, never slice the whole list.

---

## ✅ Checkpoint

- [ ] Three-turn conversation works correctly
- [ ] `_trim()` keeps system prompt and the last 20 turns
- [ ] `to_dict()` / `from_dict()` round-trip without data loss
- [ ] `reset()` clears history but preserves the system prompt

$md$ WHERE slug = 'ai-06-multi-turn';

UPDATE public.topics SET content_md = $md$
# Episode 8 — Streaming Responses

## What you'll build
A FastAPI endpoint that streams AI responses to a browser using Server-Sent Events (SSE) — the same technique used by ChatGPT and SAP Joule.

---

## Why this matters
Streaming makes AI apps feel instant. Without it: spinner for 5-10 seconds, then full response appears. With SSE: first word in ~200ms, text flows as it is generated.

---

## Step 1 — How SSE works

> The server sends `data: <chunk>\n\n` messages over a long-lived HTTP connection. The browser reads each chunk immediately.

SSE advantages over WebSockets for AI output:
- Works over plain HTTP/1.1 — no upgrade handshake
- Firewall-friendly
- One-directional (server to client) — perfect for AI token streaming

---

## Step 2 — FastAPI SSE endpoint

```python
from fastapi import FastAPI
from fastapi.responses import StreamingResponse
import json

app = FastAPI()
# Assume `client` is your initialised OpenAI/GenAI Hub client

def token_stream(prompt: str):
    stream = client.chat.completions.create(
        model="gpt-4o",
        messages=[
            {"role": "system", "content": "You are an SAP BTP expert."},
            {"role": "user",   "content": prompt},
        ],
        stream=True,
        max_tokens=600,
    )
    for chunk in stream:
        token = chunk.choices[0].delta.content
        if token:
            yield f"data: {json.dumps({'token': token})}\n\n"
    yield "data: [DONE]\n\n"

@app.get("/stream")
async def stream_response(prompt: str):
    return StreamingResponse(
        token_stream(prompt),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "X-Accel-Buffering": "no",
        },
    )
```

**What each key line does:**
- `yield f"data: {json.dumps(...)}\n\n"` — SSE requires `data:` prefix and double newline `\n\n` to delimit events
- `if token:` — skips None delta chunks at stream boundaries
- `"Cache-Control": "no-cache"` — prevents proxies from buffering the stream
- `"X-Accel-Buffering": "no"` — critical behind Nginx; without it the whole response is buffered and sent at once

---

## Step 3 — Browser client

```javascript
const es = new EventSource("/stream?prompt=Explain+SAP+AI+Core");
const output = document.getElementById("output");

es.onmessage = (e) => {
    if (e.data === "[DONE]") { es.close(); return; }
    const { token } = JSON.parse(e.data);
    output.textContent += token;
};
```

**What each key line does:**
- `new EventSource(url)` — browser-native SSE client; reconnects automatically on drop
- `es.close()` on `[DONE]` — must close; otherwise the browser reconnects infinitely
- `output.textContent += token` — appends each token as it arrives

---

## Common mistakes

**Mistake:** Nginx buffers the entire response before sending.
**Fix:** Add `X-Accel-Buffering: no` response header and `proxy_buffering off` in the Nginx location block.

**Mistake:** `[DONE]` never sent — browser keeps the connection open forever.
**Fix:** Always `yield "data: [DONE]\n\n"` after the stream loop, in a `finally` block if needed.

---

## ✅ Checkpoint

- [ ] FastAPI `/stream` endpoint starts responding within 500ms
- [ ] Browser appends tokens one by one
- [ ] `[DONE]` closes the EventSource cleanly
- [ ] Response headers prevent proxy buffering

$md$ WHERE slug = 'ai-07-streaming';

UPDATE public.topics SET content_md = $md$
# Episode 9 — Structured Output & JSON Mode

## What you'll build
A pipeline that extracts structured data from unstructured SAP support emails and validates the result against a Pydantic schema.

---

## Why this matters
AI is most useful in enterprise systems when it returns structured data you can write to a database or pass to an API. JSON mode plus Pydantic gives you that reliability.

---

## Step 1 — Two approaches

> **JSON mode** — `response_format={"type": "json_object"}` — guarantees valid JSON but not your schema.
> **Tool/function calling** — define a strict schema; model fills it. More reliable for complex structures.

Start with JSON mode. Upgrade to tool calling when schema compliance becomes critical.

---

## Step 2 — JSON mode with Pydantic validation

```python
import json
from pydantic import BaseModel, ValidationError
from typing import Optional

class SupportTicket(BaseModel):
    customer_id:    str
    issue_category: str      # BILLING | TECHNICAL | ACCESS | PERFORMANCE
    severity:       int      # 1 (low) to 5 (critical)
    summary:        str
    suggested_team: str
    requires_escalation: bool
    resolution_hours: Optional[int]

SYSTEM = (
    "Extract support ticket data from the email below.\n"
    "Return ONLY a JSON object with these fields:\n"
    "customer_id, issue_category, severity (1-5), summary, "
    "suggested_team, requires_escalation (boolean), resolution_hours (integer or null)"
)

def extract_ticket(email_text: str, client) -> SupportTicket:
    resp = client.chat.completions.create(
        model="gpt-4o",
        messages=[
            {"role": "system", "content": SYSTEM},
            {"role": "user",   "content": email_text},
        ],
        response_format={"type": "json_object"},
        temperature=0,
    )
    data = json.loads(resp.choices[0].message.content)
    return SupportTicket(**data)

# Test
sample_email = (
    "From: user@acme.com\n"
    "Subject: Production down\n\n"
    "Our BTP subaccount has been inaccessible since 14:30 UTC.\n"
    "Customer ID ACME-PROD. All services returning 503.\n"
    "200 users blocked. Revenue impact."
)

try:
    ticket = extract_ticket(sample_email, client)
    print(ticket.model_dump_json(indent=2))
except ValidationError as e:
    print(f"Schema validation failed: {e}")
```

**What each key line does:**
- `response_format={"type": "json_object"}` — GPT-4o guarantees valid JSON; without this the model may add prose around the JSON
- `SupportTicket(**data)` — Pydantic validates every field type and raises `ValidationError` if a required field is missing
- `temperature=0` — extraction must be deterministic; the same email should always produce the same output
- `Optional[int]` — makes `resolution_hours` nullable; maps to `null` in JSON

---

## Common mistakes

**Mistake:** Setting `response_format` but system prompt doesn't mention JSON — model still outputs prose.
**Fix:** The system prompt MUST say "Return ONLY a JSON object". The response_format enforces syntax, not intent.

**Mistake:** Not catching `ValidationError` — crashes the app when a field is missing.
**Fix:** Wrap extraction in try/except and log the raw output so you can improve the prompt.

---

## ✅ Checkpoint

- [ ] Extracted ticket passes Pydantic validation
- [ ] `severity` is an integer between 1 and 5
- [ ] `requires_escalation` is a boolean, not a string
- [ ] ValidationError is caught and the raw output is logged

$md$ WHERE slug = 'ai-08-structured-output';

UPDATE public.topics SET content_md = $md$
# Episode 10 — Function Calling & Tool Use

## What you'll build
An AI assistant that queries live BTP service status and a Supabase table by calling Python functions you define — the model orchestrates, your code executes.

---

## Why this matters
Function calling turns the LLM into an orchestrator. Instead of hallucinating data, it decides which function to call and with what arguments. Your code runs the function and feeds the result back.

---

## Step 1 — How it works

> The model does NOT execute functions. It returns `{"name": "get_status", "arguments": {"service": "AI Core"}}`. Your code runs the function and feeds the result back in a `tool` message.

---

## Step 2 — Define tools and implement the loop

```python
import json

def get_service_status(service: str) -> dict:
    # In production: call SAP Trust Centre API
    mock = {
        "AI Core":    {"status": "operational", "latency_ms": 120},
        "HANA Cloud": {"status": "degraded",    "latency_ms": 4500},
    }
    return mock.get(service, {"status": "unknown"})

def list_open_tickets(customer_id: str) -> list:
    # In production: query Supabase
    return [
        {"id": "TKT-001", "category": "PERFORMANCE", "created": "2026-08-27"},
        {"id": "TKT-002", "category": "BILLING",     "created": "2026-08-25"},
    ]

TOOLS = [
    {"type": "function", "function": {
        "name": "get_service_status",
        "description": "Returns the current operational status of a BTP service",
        "parameters": {
            "type": "object",
            "properties": {"service": {"type": "string"}},
            "required": ["service"],
        },
    }},
    {"type": "function", "function": {
        "name": "list_open_tickets",
        "description": "Lists open support tickets for a given customer ID",
        "parameters": {
            "type": "object",
            "properties": {"customer_id": {"type": "string"}},
            "required": ["customer_id"],
        },
    }},
]

FUNCTION_MAP = {"get_service_status": get_service_status, "list_open_tickets": list_open_tickets}

def agent_loop(user_query: str, client) -> str:
    messages = [
        {"role": "system", "content": "You are an SAP BTP support assistant. Use tools to get real data before answering."},
        {"role": "user",   "content": user_query},
    ]
    while True:
        resp = client.chat.completions.create(
            model="gpt-4o", messages=messages, tools=TOOLS, tool_choice="auto",
        )
        msg = resp.choices[0].message
        if not msg.tool_calls:
            return msg.content           # model has the final answer

        messages.append(msg)             # append assistant message with tool_calls
        for tc in msg.tool_calls:
            fn = FUNCTION_MAP[tc.function.name]
            result = fn(**json.loads(tc.function.arguments))
            messages.append({
                "role": "tool", "tool_call_id": tc.id, "content": json.dumps(result),
            })

print(agent_loop("Is HANA Cloud having issues? Also list tickets for customer ACME-42", client))
```

**What each key line does:**
- `tool_choice="auto"` — model decides when to call tools; use `"required"` to force a call
- `messages.append(msg)` — the assistant message with `tool_calls` must be added before tool results
- `"role": "tool"` — tool results use this specific role; `"user"` role silently breaks the loop
- `"tool_call_id": tc.id` — each result references its call ID so the model matches them

---

## Common mistakes

**Mistake:** Not appending the assistant message before adding tool results.
**Fix:** Always `messages.append(msg)` immediately after the API call, before any tool result messages.

**Mistake:** Using `"role": "user"` for tool results.
**Fix:** Tool results must use `"role": "tool"` with a matching `tool_call_id`.

---

## ✅ Checkpoint

- [ ] Model calls `get_service_status` when asked about service health
- [ ] Tool results feed back into the next model call
- [ ] Agent returns a natural-language answer referencing real data
- [ ] Multiple tool calls in one response are all handled

$md$ WHERE slug = 'ai-09-function-calling';

UPDATE public.topics SET content_md = $md$
# Episode 11 — Embeddings

## What you'll build
A Python script that converts text into vector embeddings using the GenAI Hub embedding model, and measures semantic similarity between sentences.

---

## Why this matters
Embeddings are the foundation of semantic search, RAG pipelines, and recommendation systems. Every vector database on SAP BTP starts here.

---

## Step 1 — What is an embedding?

> An **embedding** is a list of numbers (a vector) that represents the meaning of text. Sentences with similar meanings produce vectors that are close together in space. This is what makes semantic search possible — you search by meaning, not by keyword.

A typical embedding model outputs 1536 numbers per input (text-embedding-3-large from OpenAI).

---

## Step 2 — Get embeddings from GenAI Hub

```python
import numpy as np
from openai import OpenAI

# client = your initialised GenAI Hub client with embedding deployment

def embed(text: str, client) -> list:
    resp = client.embeddings.create(
        model="text-embedding-3-large",   # must match your deployment's model
        input=text,
    )
    return resp.data[0].embedding          # list of 1536 floats

def cosine_similarity(a: list, b: list) -> float:
    a, b = np.array(a), np.array(b)
    return float(np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b)))

# Test semantic similarity
sentences = [
    "How do I deploy to Cloud Foundry on BTP?",
    "What is the process for deploying apps to SAP BTP Cloud Foundry?",   # semantically same
    "What is the capital of France?",                                      # unrelated
]

base = embed(sentences[0], client)
for s in sentences[1:]:
    sim = cosine_similarity(base, embed(s, client))
    print(f"Similarity: {sim:.3f}  |  {s[:60]}")
```

**What each key line does:**
- `client.embeddings.create(...)` — OpenAI-compatible call; works against the GenAI Hub embedding deployment
- `resp.data[0].embedding` — the vector is nested under `.data[0].embedding`; index 0 for single-input requests
- `np.dot(a, b) / (norm_a * norm_b)` — cosine similarity; ranges from -1 (opposite) to +1 (identical); ~0.9+ means semantically equivalent

---

## Step 3 — Batch embedding (cost and latency efficient)

```python
def embed_batch(texts: list, client) -> list:
    resp = client.embeddings.create(
        model="text-embedding-3-large",
        input=texts,           # pass a list — much more efficient than one call per text
    )
    # Results are returned in the same order as input
    return [item.embedding for item in sorted(resp.data, key=lambda x: x.index)]
```

**What each key line does:**
- `input=texts` — one API call for up to 2048 texts; roughly 2048x cheaper than calling one at a time
- `sorted(..., key=lambda x: x.index)` — API does not guarantee order; sort by `.index` to match input order

---

## Common mistakes

**Mistake:** Calling the embedding API once per document instead of batching.
**Fix:** Always use `input=list_of_texts` and process up to 2048 texts per call.

**Mistake:** Comparing embeddings from different models (e.g. mixing ada-002 and text-embedding-3-large).
**Fix:** All embeddings in the same search system must come from the same model. Store the model name alongside the vectors.

---

## ✅ Checkpoint

- [ ] Embedding API returns a list of 1536 floats
- [ ] Semantically similar sentences score above 0.85
- [ ] Unrelated sentence scores below 0.3
- [ ] Batch embedding works and returns results in correct order

$md$ WHERE slug = 'ai-10-embeddings';

UPDATE public.topics SET content_md = $md$
# Episode 12 — Semantic Search

## What you'll build
An in-memory semantic search engine over a small SAP knowledge base, using embeddings and cosine similarity to retrieve the most relevant documents for any query.

---

## Why this matters
Keyword search fails when users phrase questions differently from the documentation. Semantic search finds the right answer even when no words overlap — which is the core capability that makes RAG pipelines work.

---

## Step 1 — Build the knowledge base

```python
import numpy as np
from typing import List, Dict

# Your document corpus
DOCS = [
    {"id": "d1", "text": "SAP AI Core manages the lifecycle of AI models on BTP, including deployment, scaling, and monitoring."},
    {"id": "d2", "text": "The Generative AI Hub provides access to large language models like GPT-4o through a unified REST API."},
    {"id": "d3", "text": "To deploy a model in AI Core, you create a configuration that links an executable to a resource group."},
    {"id": "d4", "text": "SAP HANA Cloud's vector engine stores embeddings and supports approximate nearest-neighbour search at scale."},
    {"id": "d5", "text": "Prompt engineering is the practice of designing inputs to language models to get reliable, high-quality outputs."},
]
```

---

## Step 2 — Index and search

```python
def build_index(docs: List[Dict], client) -> List[Dict]:
    texts = [d["text"] for d in docs]
    resp = client.embeddings.create(model="text-embedding-3-large", input=texts)
    vecs = [item.embedding for item in sorted(resp.data, key=lambda x: x.index)]
    for doc, vec in zip(docs, vecs):
        doc["embedding"] = vec
    return docs

def semantic_search(query: str, index: List[Dict], client, top_k: int = 3) -> List[Dict]:
    q_vec = client.embeddings.create(
        model="text-embedding-3-large", input=query
    ).data[0].embedding
    q_arr = np.array(q_vec)

    scored = []
    for doc in index:
        d_arr = np.array(doc["embedding"])
        score = float(np.dot(q_arr, d_arr) / (np.linalg.norm(q_arr) * np.linalg.norm(d_arr)))
        scored.append({"score": score, **{k: v for k, v in doc.items() if k != "embedding"}})

    return sorted(scored, key=lambda x: x["score"], reverse=True)[:top_k]

# Index and search
index = build_index(DOCS, client)
results = semantic_search("How do I run an LLM on SAP BTP?", index, client)
for r in results:
    print(f"Score: {r['score']:.3f}  {r['text'][:80]}")
```

**What each key line does:**
- `build_index()` embeds all documents in one batch call — efficient and consistent
- `sorted(..., key=lambda x: x.index)` — preserves input order in results
- `np.dot / (norm_a * norm_b)` — cosine similarity; normalised dot product gives values in [-1, 1]
- `sorted(..., reverse=True)[:top_k]` — returns the K most similar documents

---

## Step 3 — Persist the index

```python
import json

def save_index(index: List[Dict], path: str):
    with open(path, "w") as f:
        json.dump(index, f)

def load_index(path: str) -> List[Dict]:
    with open(path) as f:
        return json.load(f)
```

Save after building so you only embed documents once. Re-embed only when documents change.

---

## Common mistakes

**Mistake:** Re-embedding the entire corpus on every search query.
**Fix:** Build the index once (`build_index`), save it to disk or Supabase, and load it for each search.

**Mistake:** Returning raw scores to users.
**Fix:** Scores are only meaningful relative to each other. Filter on `score > 0.75` and explain results by excerpt, not by score.

---

## ✅ Checkpoint

- [ ] `build_index()` embeds all five documents in one API call
- [ ] Search returns the correct top-3 documents for a relevant query
- [ ] Unrelated query returns lower scores
- [ ] Index saves to and loads from JSON correctly

$md$ WHERE slug = 'ai-11-semantic-search';

UPDATE public.topics SET content_md = $md$
# Episode 13 — RAG — Indexing Pipeline

## What you'll build
A document indexing pipeline that splits SAP documentation into chunks, embeds each chunk, and stores the vectors in a Supabase JSON column — ready for retrieval.

---

## Why this matters
The indexing pipeline is the "write" side of RAG. Quality at this stage — chunk size, overlap, metadata — directly determines retrieval quality. Poor chunking produces irrelevant search results no matter how good the model is.

---

## Step 1 — Why chunk documents?

> Embedding models have a token limit (~8k for text-embedding-3-large). Long documents must be split. But chunks that are too short lose context; chunks that are too long dilute relevance.

Rule of thumb: 300-500 tokens per chunk, with 50-token overlap between chunks to avoid cutting sentences mid-thought.

---

## Step 2 — The chunking and indexing pipeline

```python
import json
import math

def chunk_text(text: str, chunk_size: int = 400, overlap: int = 50) -> list:
    words = text.split()
    chunks = []
    step = chunk_size - overlap
    for i in range(0, len(words), step):
        chunk = " ".join(words[i : i + chunk_size])
        if chunk:
            chunks.append(chunk)
    return chunks

def index_document(doc_id: str, title: str, content: str, client, supabase) -> int:
    chunks = chunk_text(content)
    texts  = [f"{title}: {chunk}" for chunk in chunks]   # prepend title for context

    # Embed in batches of 100
    all_embeddings = []
    for i in range(0, len(texts), 100):
        batch = texts[i : i + 100]
        resp = client.embeddings.create(model="text-embedding-3-large", input=batch)
        all_embeddings.extend([item.embedding for item in sorted(resp.data, key=lambda x: x.index)])

    # Store in Supabase
    rows = [
        {
            "doc_id":    doc_id,
            "chunk_idx": idx,
            "title":     title,
            "text":      chunk,
            "embedding": json.dumps(emb),   # Supabase JSON column
        }
        for idx, (chunk, emb) in enumerate(zip(chunks, all_embeddings))
    ]
    supabase.table("doc_chunks").upsert(rows).execute()
    return len(rows)

# Usage
count = index_document(
    doc_id="sap-ai-core-guide",
    title="SAP AI Core Administration Guide",
    content=open("ai_core_guide.txt").read(),
    client=client,
    supabase=supabase,
)
print(f"Indexed {count} chunks")
```

**What each key line does:**
- `f"{title}: {chunk}"` — prepending the title gives the model context when a chunk is retrieved without surrounding text
- Batch size of 100 — stays well under the 2048-text limit; avoids rate limits on large documents
- `json.dumps(emb)` — Supabase requires JSON serialisation for array storage in a standard column
- `upsert` — safe to re-run; updates existing chunks instead of creating duplicates

---

## Step 3 — Supabase schema

```sql
CREATE TABLE doc_chunks (
    id         BIGSERIAL PRIMARY KEY,
    doc_id     TEXT NOT NULL,
    chunk_idx  INT  NOT NULL,
    title      TEXT,
    text       TEXT NOT NULL,
    embedding  JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(doc_id, chunk_idx)
);
```

---

## Common mistakes

**Mistake:** Chunks with zero overlap — sentences at the boundary are split mid-thought.
**Fix:** Use 10-20% overlap (50 words for 400-word chunks) to ensure context continuity.

**Mistake:** Embedding each chunk in a separate API call.
**Fix:** Batch 100 chunks per call. Single-item calls cost 100x more per document.

---

## ✅ Checkpoint

- [ ] `chunk_text()` produces overlapping chunks of roughly 400 words
- [ ] Title is prepended to each chunk before embedding
- [ ] Embeddings batch correctly at 100 per API call
- [ ] Rows insert into Supabase without errors
- [ ] Re-running on the same doc_id upserts without duplicates

$md$ WHERE slug = 'ai-12-rag-indexing';

UPDATE public.topics SET content_md = $md$
# Episode 14 — RAG — Full Pipeline

## What you'll build
A complete Retrieval-Augmented Generation pipeline: retrieve the most relevant chunks from Supabase, inject them into a prompt, and generate a grounded answer.

---

## Why this matters
RAG is the standard enterprise pattern for making LLMs answer questions about your private data. Instead of fine-tuning, you retrieve relevant context at query time and give it to the model — grounding answers in real documents and eliminating hallucination.

---

## Step 1 — The RAG loop

> 1. **Embed the query** — same model as the index
> 2. **Retrieve** top-K chunks from the vector store
> 3. **Augment** the prompt with retrieved context
> 4. **Generate** using the LLM

---

## Step 2 — Retrieval from Supabase

```python
import json
import numpy as np

def retrieve(query: str, client, supabase, top_k: int = 5) -> list:
    # 1. Embed the query
    q_vec = client.embeddings.create(
        model="text-embedding-3-large", input=query
    ).data[0].embedding

    # 2. Fetch all chunks (use pgvector in production for ANN search)
    rows = supabase.table("doc_chunks").select("text, embedding").execute().data

    # 3. Score by cosine similarity
    q = np.array(q_vec)
    scored = []
    for row in rows:
        d = np.array(json.loads(row["embedding"]))
        score = float(np.dot(q, d) / (np.linalg.norm(q) * np.linalg.norm(d)))
        scored.append({"score": score, "text": row["text"]})

    return sorted(scored, key=lambda x: x["score"], reverse=True)[:top_k]
```

---

## Step 3 — Generate with context

```python
def rag_answer(query: str, client, supabase) -> str:
    # Retrieve relevant chunks
    chunks = retrieve(query, client, supabase, top_k=5)
    context = "\n\n".join([f"[{i+1}] {c['text']}" for i, c in enumerate(chunks)])

    # Augmented prompt
    system = (
        "You are an SAP BTP expert assistant. "
        "Answer the user's question using ONLY the context provided below. "
        "If the answer is not in the context, say 'I don't have information on that.' "
        "Cite the source number [1], [2], etc. when referencing context.\n\n"
        f"Context:\n{context}"
    )

    resp = client.chat.completions.create(
        model="gpt-4o",
        messages=[
            {"role": "system", "content": system},
            {"role": "user",   "content": query},
        ],
        max_tokens=500,
        temperature=0.1,
    )
    return resp.choices[0].message.content

# Test
print(rag_answer("What resource group should I use for production workloads?", client, supabase))
```

**What each key line does:**
- `f"[{i+1}] {c['text']}"` — numbered context blocks let the model cite sources in its answer
- `"Answer using ONLY the context"` — critical grounding instruction; prevents the model from using training knowledge
- `"If not in context, say 'I don't have information'"` — explicit fallback prevents hallucination on out-of-scope questions
- `temperature=0.1` — near-deterministic; factual Q&A should not vary between runs

---

## Common mistakes

**Mistake:** Fetching all chunks for every query — slow and expensive at scale.
**Fix:** Use SAP HANA Cloud Vector Engine or pgvector for approximate nearest-neighbour search; eliminates full table scan.

**Mistake:** Not instructing the model to use only the provided context.
**Fix:** Without "ONLY the context provided", the model mixes retrieved facts with training knowledge, making answers hard to trace.

---

## ✅ Checkpoint

- [ ] `retrieve()` returns 5 chunks relevant to the query
- [ ] Context blocks are numbered for citation
- [ ] Answer references context numbers
- [ ] Out-of-scope query returns "I don't have information" instead of hallucinating

$md$ WHERE slug = 'ai-13-rag-pipeline';

UPDATE public.topics SET content_md = $md$
# Episode 15 — CAP with AI

## What you'll build
A CAP (Cloud Application Programming Model) service with a custom action that calls the Generative AI Hub and returns AI-generated responses alongside standard OData entities.

---

## Why this matters
CAP is SAP's standard framework for building business applications. Adding AI to a CAP service means your AI features get enterprise authentication, OData exposure, and SAP Fiori front-end support automatically.

---

## Step 1 — Add AI to your CAP project

```bash
# In your existing CAP project
npm install @sap-ai-sdk/core @sap-ai-sdk/ai-api @sap-ai-sdk/foundation-models
```

Configure the AI Core destination in `package.json`:

```json
{
  "cds": {
    "requires": {
      "AICORE_SERVICE": {
        "kind": "rest",
        "credentials": {
          "destination": "AICORE_DESTINATION"
        }
      }
    }
  }
}
```

---

## Step 2 — Define the action in CDS

```cds
// srv/ai-service.cds
service AIService {
    action generateSummary(text: String) returns String;
    action classifyTicket(description: String) returns String;
}
```

---

## Step 3 — Implement the action handler

```javascript
// srv/ai-service.js
const cds = require('@sap/cds');
const { OpenAiChatClient } = require('@sap-ai-sdk/foundation-models');

module.exports = class AIService extends cds.ApplicationService {
    async init() {
        // Register action handler for generateSummary
        this.on('generateSummary', async (req) => {
            const { text } = req.data;

            const aiClient = new OpenAiChatClient('gpt-4o');
            const response = await aiClient.run({
                messages: [
                    { role: 'system', content: 'Summarise the following text in one sentence.' },
                    { role: 'user',   content: text },
                ],
                max_tokens: 100,
            });

            return response.getContent();
        });

        // Register action handler for classifyTicket
        this.on('classifyTicket', async (req) => {
            const { description } = req.data;
            const aiClient = new OpenAiChatClient('gpt-4o');
            const response = await aiClient.run({
                messages: [
                    { role: 'system', content: 'Classify into: BILLING|TECHNICAL|ACCESS|PERFORMANCE|GENERAL. Output only the category.' },
                    { role: 'user',   content: description },
                ],
                max_tokens: 10,
                temperature: 0,
            });
            return response.getContent().trim().toUpperCase();
        });

        return super.init();
    }
};
```

**What each key line does:**
- `new OpenAiChatClient('gpt-4o')` — SAP AI SDK client; reads AI Core credentials from the bound destination automatically
- `this.on('generateSummary', ...)` — registers the CAP action handler; matches the CDS action name exactly
- `response.getContent()` — helper that extracts the text from the chat completion response object
- `return super.init()` — required; calls the parent class initialisation after registering handlers

---

## Common mistakes

**Mistake:** Forgetting `return super.init()` at the end of `init()`.
**Fix:** Without it, the parent service initialisation is skipped and CAP cannot register routes.

**Mistake:** Using the raw `fetch` API instead of the AI SDK in CAP.
**Fix:** The AI SDK reads BTP destination credentials automatically. Raw fetch requires manual credential management, which breaks in Cloud Foundry.

---

## ✅ Checkpoint

- [ ] `cds watch` starts without errors
- [ ] POST to `/ai/generateSummary` with a text body returns a one-sentence summary
- [ ] POST to `/ai/classifyTicket` returns a valid category name
- [ ] Authentication is handled by CAP automatically

$md$ WHERE slug = 'ai-14-cap-ai';

UPDATE public.topics SET content_md = $md$
# Episode 16 — SAPUI5 AI Chat Interface

## What you'll build
A SAPUI5 Fiori application with a chat panel that streams AI responses from your CAP backend in real time.

---

## Why this matters
Most SAP users work in Fiori apps. Adding a chat panel to an existing Fiori app — rather than building a standalone tool — means AI assistance is available exactly where users are working.

---

## Step 1 — The architecture

> Frontend: SAPUI5 View + Controller calls the CAP service action.
> Backend: CAP action calls GenAI Hub and returns the response.
> Transport: standard OData action POST from UI5.

---

## Step 2 — The SAPUI5 View (XML)

```xml
<!-- webapp/view/Chat.view.xml -->
<mvc:View controllerName="myapp.controller.Chat"
          xmlns="sap.m" xmlns:mvc="sap.ui.core.mvc">
  <Page title="AI Assistant">
    <content>
      <VBox class="sapUiSmallMargin" height="500px">
        <!-- Message list -->
        <List id="messageList" growing="true">
          <StandardListItem
            title="{model>role}"
            description="{model>content}"
            wrapping="true"/>
        </List>
        <!-- Input area -->
        <HBox>
          <Input id="userInput" placeholder="Ask a question..." width="80%"
                 submit=".onSend"/>
          <Button text="Send" press=".onSend" type="Emphasized"/>
        </HBox>
      </VBox>
    </content>
  </Page>
</mvc:View>
```

---

## Step 3 — The controller

```javascript
// webapp/controller/Chat.controller.js
sap.ui.define(['sap/ui/core/mvc/Controller', 'sap/ui/model/json/JSONModel'], (Controller, JSONModel) => {
    return Controller.extend('myapp.controller.Chat', {
        onInit() {
            this.getView().setModel(new JSONModel({ messages: [] }), 'model');
        },

        async onSend() {
            const input   = this.byId('userInput');
            const userMsg = input.getValue().trim();
            if (!userMsg) return;

            this._addMessage('User', userMsg);
            input.setValue('');

            try {
                // Call the CAP action
                const result = await this.getOwnerComponent()
                    .getModel()
                    .callFunction('/generateSummary', {
                        method: 'POST',
                        urlParameters: { text: userMsg },
                    });

                this._addMessage('AI', result.generateSummary);
            } catch (err) {
                this._addMessage('AI', 'Sorry, an error occurred. Please try again.');
            }
        },

        _addMessage(role, content) {
            const model    = this.getView().getModel('model');
            const messages = model.getProperty('/messages');
            messages.push({ role, content });
            model.setProperty('/messages', messages);
        },
    });
});
```

**What each key line does:**
- `new JSONModel({ messages: [] })` — local model for the chat history; updates trigger automatic UI re-render
- `callFunction('/generateSummary', {...})` — OData function import call to the CAP backend
- `this._addMessage('User', userMsg)` — appends user message to the local model before the API call so UI feels responsive
- The `try/catch` — shows a graceful error message instead of crashing the Fiori app on API failure

---

## Common mistakes

**Mistake:** Using `model.refresh()` after updating the messages array.
**Fix:** Use `model.setProperty('/messages', updatedArray)` — this triggers binding updates correctly for JSON models.

**Mistake:** Not clearing the input field after send.
**Fix:** `input.setValue('')` immediately after reading the value, before the async API call.

---

## ✅ Checkpoint

- [ ] Fiori app displays a chat panel with input field and message list
- [ ] User messages appear immediately without waiting for AI response
- [ ] AI response appends after the API call completes
- [ ] Error message displayed (not a crash) when the backend call fails

$md$ WHERE slug = 'ai-15-ui5-ai-chat';

UPDATE public.topics SET content_md = $md$
# Episode 17 — AI-Powered Data Analysis

## What you'll build
A Python script that uses the AI to analyse a Pandas DataFrame — generating natural-language summaries, detecting anomalies, and answering questions about the data.

---

## Why this matters
Business users cannot write SQL or Python. AI + Pandas lets them ask questions in plain English and get instant insights from any structured dataset — a pattern used in SAP Analytics Cloud and SAP Datasphere.

---

## Step 1 — The pattern

> Load data into Pandas, describe it to the LLM, let users ask questions in natural language. The model either answers directly from the description, or generates Python code you execute in a sandbox.

---

## Step 2 — Natural language data Q&A

```python
import pandas as pd
import json

# Sample BTP usage data
df = pd.DataFrame({
    "service":  ["AI Core", "HANA Cloud", "Integration Suite", "AI Core", "HANA Cloud"],
    "month":    ["2026-06", "2026-06", "2026-06", "2026-07", "2026-07"],
    "cost_usd": [1200, 3500, 850, 1450, 3200],
    "api_calls": [45000, 12000, 8500, 52000, 11500],
})

def analyse(question: str, df: pd.DataFrame, client) -> str:
    # Build a compact description of the data
    description = {
        "shape":    f"{df.shape[0]} rows x {df.shape[1]} columns",
        "columns":  {col: str(df[col].dtype) for col in df.columns},
        "sample":   df.head(3).to_dict(orient="records"),
        "stats":    json.loads(df.describe().to_json()),
    }

    system = (
        "You are a data analyst. Answer questions about a dataset based on its description. "
        "Be specific with numbers. If you cannot answer from the description, say so.\n\n"
        f"Dataset description:\n{json.dumps(description, indent=2)}"
    )

    resp = client.chat.completions.create(
        model="gpt-4o",
        messages=[
            {"role": "system", "content": system},
            {"role": "user",   "content": question},
        ],
        max_tokens=300,
        temperature=0.1,
    )
    return resp.choices[0].message.content

# Test questions
questions = [
    "Which service had the highest total cost across both months?",
    "Is AI Core usage growing month-over-month?",
    "What is the average cost per API call for each service?",
]
for q in questions:
    print(f"Q: {q}")
    print(f"A: {analyse(q, df, client)}\n")
```

**What each key line does:**
- `df.describe().to_json()` — passes descriptive statistics (mean, std, min, max) to the model without exposing raw data
- `df.head(3).to_dict(orient="records")` — gives the model a concrete sample to understand data format
- `temperature=0.1` — data analysis answers should be consistent and factual
- `json.dumps(description, indent=2)` — structured JSON is easier for the model to parse than free-form text

---

## Step 3 — Anomaly detection

```python
def detect_anomalies(df: pd.DataFrame, column: str, client) -> str:
    stats = df[column].describe().to_dict()
    values = df[["service", "month", column]].to_dict(orient="records")

    prompt = (
        f"Analyse these {column} values for anomalies. "
        f"Stats: {json.dumps(stats)}. "
        f"Values: {json.dumps(values)}. "
        "List any values that appear unusual and explain why."
    )
    resp = client.chat.completions.create(
        model="gpt-4o",
        messages=[{"role": "user", "content": prompt}],
        max_tokens=200, temperature=0.1,
    )
    return resp.choices[0].message.content

print(detect_anomalies(df, "cost_usd", client))
```

---

## Common mistakes

**Mistake:** Sending the full raw DataFrame to the model — token-expensive and leaks sensitive data.
**Fix:** Send only `describe()` stats and a 3-row sample. For sensitive data, anonymise before sending.

**Mistake:** Trusting the model's arithmetic on complex calculations.
**Fix:** For precise numeric answers (totals, percentages), compute them in Pandas first and include the result in the prompt.

---

## ✅ Checkpoint

- [ ] Model correctly identifies the highest-cost service from the description
- [ ] Month-over-month growth question answered with specific percentages
- [ ] Anomaly detection flags the HANA Cloud June cost as the highest single value
- [ ] Sensitive data is never sent to the model in raw form

$md$ WHERE slug = 'ai-16-data-analysis';

UPDATE public.topics SET content_md = $md$
# Episode 18 — Multi-Modal AI (Vision)

## What you'll build
A Python script that sends images to GPT-4o Vision via the GenAI Hub and extracts structured information — including SAP UI screenshots, invoice images, and diagrams.

---

## Why this matters
Multi-modal AI unlocks document intelligence, screenshot analysis, and visual QA — use cases that appear constantly in enterprise automation: invoice processing, form extraction, UI testing, and architecture review.

---

## Step 1 — How vision inputs work

> GPT-4o accepts images either as Base64-encoded data or as a public URL. The image is embedded in the `user` message under a `content` array with items of type `image_url`.

---

## Step 2 — Analyse an image from a file

```python
import base64

def encode_image(path: str) -> str:
    with open(path, "rb") as f:
        return base64.b64encode(f.read()).decode("utf-8")

def analyse_image(image_path: str, question: str, client) -> str:
    b64 = encode_image(image_path)
    resp = client.chat.completions.create(
        model="gpt-4o",
        messages=[{
            "role": "user",
            "content": [
                {"type": "text",  "text": question},
                {"type": "image_url", "image_url": {
                    "url": f"data:image/png;base64,{b64}",
                    "detail": "high",   # "low" = faster, "high" = more accurate
                }},
            ],
        }],
        max_tokens=500,
    )
    return resp.choices[0].message.content

# Analyse a Fiori screenshot
result = analyse_image(
    "fiori_screenshot.png",
    "Describe all UI elements visible in this SAP Fiori screenshot and identify any error messages.",
    client,
)
print(result)
```

**What each key line does:**
- `f"data:image/png;base64,{b64}"` — inline Base64 format; no need to host the image publicly
- `"detail": "high"` — uses more tokens but captures fine details like small text in screenshots; use "low" for thumbnails
- `"content": [...]` — array format for multi-modal; text and image items are interleaved

---

## Step 3 — Structured extraction from invoice images

```python
from pydantic import BaseModel
from typing import Optional
import json

class InvoiceData(BaseModel):
    vendor:      str
    invoice_no:  str
    date:        str
    total_usd:   float
    line_items:  list

def extract_invoice(image_path: str, client) -> InvoiceData:
    b64 = encode_image(image_path)
    system = (
        "Extract invoice data. "
        "Return ONLY raw JSON with fields: vendor, invoice_no, date, total_usd, line_items. "
        "line_items is a list of {description, qty, unit_price, total}."
    )
    resp = client.chat.completions.create(
        model="gpt-4o",
        messages=[
            {"role": "system", "content": system},
            {"role": "user", "content": [
                {"type": "text", "text": "Extract invoice data from this image."},
                {"type": "image_url", "image_url": {"url": f"data:image/png;base64,{b64}", "detail": "high"}},
            ]},
        ],
        response_format={"type": "json_object"},
        temperature=0,
        max_tokens=800,
    )
    return InvoiceData(**json.loads(resp.choices[0].message.content))
```

---

## Common mistakes

**Mistake:** Using `"detail": "high"` for all images — 4-8x more tokens than "low".
**Fix:** Use "low" for simple images (icons, thumbnails), "high" only for detailed screenshots and documents with small text.

**Mistake:** Sending very large images (>5MB) — slow and expensive.
**Fix:** Resize to max 1024px on the longest side before encoding. Quality for text extraction is maintained at this resolution.

---

## ✅ Checkpoint

- [ ] Image successfully sent and response received
- [ ] Screenshot analysis lists all visible UI elements
- [ ] Invoice extraction returns parseable JSON
- [ ] `InvoiceData` Pydantic validation passes

$md$ WHERE slug = 'ai-17-multi-modal';

UPDATE public.topics SET content_md = $md$
# Episode 19 — AI Agents & Agentic Loops

## What you'll build
An autonomous AI agent that plans and executes a multi-step SAP BTP task — checking service health, analysing recent tickets, and generating a status report — without step-by-step human instruction.

---

## Why this matters
Single-turn LLM calls are powerful but limited. Agents can decompose complex tasks, retry on failure, gather information across multiple steps, and produce outcomes that no single prompt could achieve. This is the foundation of SAP Joule's autonomous features.

---

## Step 1 — The ReAct pattern

> **ReAct** (Reason + Act) is the standard agent pattern:
> 1. Model **thinks** about what to do next (Thought)
> 2. Model **decides** on a tool call (Action)
> 3. Tool **executes** and returns a result (Observation)
> 4. Repeat until the task is complete

---

## Step 2 — Agent with planning and tools

```python
import json

TOOLS = [
    {"type": "function", "function": {
        "name": "check_service_health",
        "description": "Get current health status of a BTP service",
        "parameters": {"type": "object", "properties": {
            "service_name": {"type": "string"}
        }, "required": ["service_name"]},
    }},
    {"type": "function", "function": {
        "name": "get_recent_tickets",
        "description": "Get support tickets from the last N days",
        "parameters": {"type": "object", "properties": {
            "days": {"type": "integer", "default": 7}
        }, "required": []},
    }},
    {"type": "function", "function": {
        "name": "write_report",
        "description": "Write a status report to a file",
        "parameters": {"type": "object", "properties": {
            "content": {"type": "string"}, "filename": {"type": "string"}
        }, "required": ["content", "filename"]},
    }},
]

def check_service_health(service_name: str) -> dict:
    return {"service": service_name, "status": "operational", "uptime_pct": 99.8}

def get_recent_tickets(days: int = 7) -> list:
    return [
        {"id": "T-101", "severity": 3, "category": "PERFORMANCE", "resolved": True},
        {"id": "T-102", "severity": 5, "category": "ACCESS",      "resolved": False},
    ]

def write_report(content: str, filename: str) -> dict:
    with open(filename, "w") as f:
        f.write(content)
    return {"status": "written", "filename": filename}

FUNCTION_MAP = {
    "check_service_health": check_service_health,
    "get_recent_tickets":   get_recent_tickets,
    "write_report":         write_report,
}

def run_agent(goal: str, client, max_steps: int = 10) -> str:
    messages = [
        {"role": "system", "content": (
            "You are an autonomous SAP BTP operations agent. "
            "Use tools to gather information and complete the goal. "
            "Be thorough — check all relevant services and data before writing the report."
        )},
        {"role": "user", "content": goal},
    ]

    for step in range(max_steps):
        resp = client.chat.completions.create(
            model="gpt-4o", messages=messages,
            tools=TOOLS, tool_choice="auto", max_tokens=1000,
        )
        msg = resp.choices[0].message

        if not msg.tool_calls:
            return msg.content   # agent decided it's done

        print(f"Step {step+1}: calling {[tc.function.name for tc in msg.tool_calls]}")
        messages.append(msg)

        for tc in msg.tool_calls:
            fn     = FUNCTION_MAP[tc.function.name]
            result = fn(**json.loads(tc.function.arguments))
            messages.append({"role": "tool", "tool_call_id": tc.id, "content": json.dumps(result)})

    return "Max steps reached — task incomplete"

# Run
output = run_agent(
    "Check the health of AI Core and HANA Cloud, review recent tickets, and write a concise status report to btp_status.md",
    client,
)
print(output)
```

**What each key line does:**
- `max_steps=10` — safety limit; prevents infinite loops if the model keeps calling tools
- `for tc in msg.tool_calls` — handles parallel tool calls (model may request multiple tools in one response)
- `if not msg.tool_calls: return msg.content` — agent terminates when the model stops requesting tools
- Each tool result fed back as `"role": "tool"` — model sees the results and decides the next action

---

## Common mistakes

**Mistake:** No `max_steps` limit — agent loops forever on ambiguous goals.
**Fix:** Always set a step limit and return an "incomplete" message when hit.

**Mistake:** Agent never stops calling tools.
**Fix:** Set clear completion criteria in the system prompt: "When you have enough information to write the report, write it immediately."

---

## ✅ Checkpoint

- [ ] Agent calls `check_service_health` and `get_recent_tickets` before writing the report
- [ ] Report file is created on disk
- [ ] Agent terminates cleanly after completing the goal
- [ ] Step limit prevents infinite loops

$md$ WHERE slug = 'ai-18-ai-agents';

UPDATE public.topics SET content_md = $md$
# Episode 20 — Prompt Templates

## What you'll build
A versioned prompt template system with variable substitution, stored in Supabase — the same pattern used by SAP Generative AI Hub's built-in template feature.

---

## Why this matters
Hard-coded prompts in source code become a maintenance problem as applications grow. A template system lets business users edit prompts without deploying code, enables A/B testing, and provides full version history for compliance.

---

## Step 1 — The template format

Use Jinja2-style `{{variable}}` placeholders — familiar to SAP developers from CAP CQL and Fiori templates.

---

## Step 2 — Template engine

```python
import re
import json

def render_template(template: str, variables: dict) -> str:
    def replacer(match):
        key = match.group(1).strip()
        if key not in variables:
            raise ValueError(f"Template variable '{key}' not provided")
        return str(variables[key])
    return re.sub(r'\{\{(.*?)\}\}', replacer, template)

# Example templates
TEMPLATES = {
    "ticket_summary": {
        "version": "1.2",
        "system": "You are an SAP support expert. Summarise the ticket in {{max_words}} words or fewer.",
        "user":   "Customer: {{customer_name}}\nIssue: {{issue_description}}\nPriority: {{priority}}",
    },
    "product_description": {
        "version": "1.0",
        "system": "You are a technical writer for SAP BTP. Write a {{tone}} description.",
        "user":   "Product: {{product_name}}\nTarget audience: {{audience}}\nKey features: {{features}}",
    },
}

def run_template(template_key: str, variables: dict, client) -> str:
    tmpl = TEMPLATES[template_key]
    system = render_template(tmpl["system"], variables)
    user   = render_template(tmpl["user"],   variables)

    resp = client.chat.completions.create(
        model="gpt-4o",
        messages=[
            {"role": "system", "content": system},
            {"role": "user",   "content": user},
        ],
        max_tokens=300,
    )
    return resp.choices[0].message.content

# Usage
result = run_template("ticket_summary", {
    "max_words":          "50",
    "customer_name":      "Acme Corp",
    "issue_description":  "Cannot access BTP cockpit after password reset",
    "priority":           "High",
}, client)
print(result)
```

**What each key line does:**
- `re.sub(r'\{\{(.*?)\}\}', replacer, template)` — finds all `{{variable}}` placeholders and replaces them
- `raise ValueError(f"Template variable '{key}' not provided")` — explicit error when a variable is missing; prevents silent empty substitution
- Templates stored as dicts with a `version` field — makes A/B testing and rollback straightforward

---

## Step 3 — Store templates in Supabase

```python
def save_template(key: str, tmpl: dict, supabase):
    supabase.table("prompt_templates").upsert({
        "key":     key,
        "version": tmpl["version"],
        "system":  tmpl["system"],
        "user":    tmpl["user"],
    }).execute()

def load_template(key: str, supabase) -> dict:
    rows = supabase.table("prompt_templates").select("*").eq("key", key).execute().data
    if not rows:
        raise KeyError(f"Template '{key}' not found")
    return rows[0]
```

---

## Common mistakes

**Mistake:** Using f-strings for prompt templates — they evaluate at definition time, not at call time.
**Fix:** Use `{{variable}}` placeholders and `re.sub` so variables are substituted at call time from a dict.

**Mistake:** No version field — impossible to roll back a bad prompt update.
**Fix:** Always include a `version` string and use `upsert` with version in the key for history.

---

## ✅ Checkpoint

- [ ] `render_template()` substitutes all variables correctly
- [ ] Missing variable raises a `ValueError` with the variable name
- [ ] `ticket_summary` template returns a coherent summary under 50 words
- [ ] Template saves to and loads from Supabase without errors

$md$ WHERE slug = 'ai-19-prompt-templates';

UPDATE public.topics SET content_md = $md$
# Episode 21 — AI Safety & Content Filtering

## What you'll build
A two-layer content moderation system that pre-screens user inputs and post-screens AI outputs — using the OpenAI moderation API and custom rule-based filters.

---

## Why this matters
Enterprise AI deployments must comply with SAP's Responsible AI guidelines. A safety layer prevents harmful inputs reaching the model and harmful outputs reaching users — required for any production deployment.

---

## Step 1 — Two-layer architecture

> **Input filter** — screen user messages before they reach the model.
> **Output filter** — screen model responses before they reach the user.
> Both layers are needed: malicious inputs can produce harmful outputs even with a well-prompted model.

---

## Step 2 — OpenAI moderation API

```python
def is_safe(text: str, client) -> tuple:
    resp   = client.moderations.create(input=text)
    result = resp.results[0]
    if result.flagged:
        violated = [cat for cat, v in result.categories.__dict__.items() if v]
        return False, f"Flagged for: {', '.join(violated)}"
    return True, "OK"

safe, reason = is_safe("How do I configure SAP AI Core?", client)
print(f"{'SAFE' if safe else 'BLOCKED'}: {reason}")
```

**What each key line does:**
- `client.moderations.create(input=text)` — moderation endpoint; no tokens charged for this call
- `result.flagged` — True if any category score exceeds the threshold
- `result.categories.__dict__.items()` — iterates hate, violence, self-harm, and all other categories

---

## Step 3 — Custom keyword and pattern filter

```python
import re

BLOCKED_PATTERNS = [
    r"\b(DROP TABLE|DELETE FROM|TRUNCATE)\b",
    r"ignore (all |your )?(previous |prior )?instructions",
    r"act as (an? )?(DAN|jailbreak|unrestricted)",
]

def custom_filter(text: str) -> tuple:
    for pattern in BLOCKED_PATTERNS:
        if re.search(pattern, text, re.IGNORECASE):
            return False, f"Blocked by pattern match"
    return True, "OK"

def safe_chat(user_message: str, client) -> str:
    for check in [custom_filter(user_message), is_safe(user_message, client)]:
        safe, reason = check
        if not safe:
            return "I cannot process that request."

    resp = client.chat.completions.create(
        model="gpt-4o",
        messages=[
            {"role": "system", "content": "You are an SAP BTP assistant."},
            {"role": "user",   "content": user_message},
        ],
        max_tokens=400,
    )
    return resp.choices[0].message.content
```

**What each key line does:**
- `re.IGNORECASE` — catches capitalisation variations used to evade keyword filters
- Custom patterns run first — blocks known attacks cheaply without an API call
- Generic error message — does not reveal filter details to the user

---

## Common mistakes

**Mistake:** Relying on only one layer — moderation API misses domain-specific SQL injection patterns.
**Fix:** Combine both layers. Custom patterns for known risks, moderation API for broad safety categories.

**Mistake:** Returning filter details to the user — reveals how to evade the system.
**Fix:** Log details internally; always return a generic message externally.

---

## ✅ Checkpoint

- [ ] Moderation API correctly flags inappropriate content
- [ ] SQL injection patterns caught by custom filter before the API call
- [ ] Prompt injection attempt blocked
- [ ] Safe SAP questions pass both layers

$md$ WHERE slug = 'ai-20-ai-safety';

UPDATE public.topics SET content_md = $md$
# Episode 22 — Token Usage & Cost Monitoring

## What you'll build
A cost-tracking wrapper that logs every AI API call to Supabase and generates a daily usage report broken down by feature.

---

## Why this matters
GPT-4o costs $2.50-$10 per million tokens. An enterprise app making thousands of calls per day can accumulate significant costs invisibly. Monitoring is essential for budgeting and optimisation.

---

## Step 1 — Approximate pricing

| Model              | Input $/M | Output $/M |
|--------------------|-----------|------------|
| gpt-4o             | $2.50     | $10.00     |
| gpt-4o-mini        | $0.15     | $0.60      |
| text-embedding-3-large | $0.13 | —          |

---

## Step 2 — Cost-tracking wrapper

```python
import time
from datetime import datetime

PRICING = {
    "gpt-4o":       {"input": 2.50, "output": 10.00},
    "gpt-4o-mini":  {"input": 0.15, "output": 0.60},
}

def tracked_chat(messages: list, model: str, client, supabase=None, context: str = "") -> str:
    start = time.time()
    resp  = client.chat.completions.create(model=model, messages=messages, max_tokens=500)
    elapsed = time.time() - start

    usage  = resp.usage
    prices = PRICING.get(model, {"input": 0, "output": 0})
    cost   = (usage.prompt_tokens * prices["input"] +
              usage.completion_tokens * prices["output"]) / 1_000_000

    log = {
        "timestamp":         datetime.utcnow().isoformat(),
        "model":             model,
        "context":           context,
        "prompt_tokens":     usage.prompt_tokens,
        "completion_tokens": usage.completion_tokens,
        "total_tokens":      usage.total_tokens,
        "cost_usd":          round(cost, 6),
        "latency_ms":        round(elapsed * 1000),
    }

    if supabase:
        supabase.table("ai_usage_logs").insert(log).execute()
    else:
        print(f"Tokens: {log['total_tokens']} | Cost: ${log['cost_usd']:.4f} | {log['latency_ms']}ms")

    return resp.choices[0].message.content

response = tracked_chat(
    messages=[{"role": "user", "content": "What is SAP BTP?"}],
    model="gpt-4o", client=client, context="faq_page",
)
```

**What each key line does:**
- `resp.usage.prompt_tokens` / `completion_tokens` — exact counts from the API; never estimate
- `/ 1_000_000` — pricing is per million tokens
- `context="faq_page"` — tag each call by feature so you can analyse cost per feature
- `round(cost, 6)` — six decimal places for sub-cent precision

---

## Step 3 — Daily report

```python
def daily_report(supabase) -> dict:
    today = datetime.utcnow().date().isoformat()
    rows  = (supabase.table("ai_usage_logs")
             .select("context, cost_usd").gte("timestamp", today).execute().data)

    total = sum(r["cost_usd"] for r in rows)
    by_ctx = {}
    for r in rows:
        by_ctx[r["context"]] = by_ctx.get(r["context"], 0) + r["cost_usd"]

    print(f"Today's cost: ${total:.4f}")
    for ctx, cost in sorted(by_ctx.items(), key=lambda x: -x[1]):
        print(f"  {ctx:30} ${cost:.4f}")
    return {"total": total, "by_context": by_ctx}
```

---

## Common mistakes

**Mistake:** Not logging from day one — impossible to diagnose cost spikes retroactively.
**Fix:** Wrap every AI call in `tracked_chat()` from the first line of code.

**Mistake:** Ignoring `prompt_tokens` — long system prompts are often 50-80% of total token cost.
**Fix:** Log `prompt_tokens` and `completion_tokens` separately to find where cost comes from.

---

## ✅ Checkpoint

- [ ] `tracked_chat()` logs token counts and cost to Supabase
- [ ] Cost calculation is correct for a known token count
- [ ] Daily report groups cost by context feature
- [ ] Most expensive feature identified from the report

$md$ WHERE slug = 'ai-21-token-monitoring';

UPDATE public.topics SET content_md = $md$
# Episode 23 — Batch AI Processing

## What you'll build
An async batch pipeline that classifies hundreds of SAP support tickets concurrently — 10x faster than sequential processing — using asyncio and a semaphore for rate limiting.

---

## Why this matters
Many enterprise AI tasks are not real-time: nightly classification, weekly summarisation, bulk enrichment. Async processing with rate limiting handles thousands of items efficiently without hitting API quotas.

---

## Step 1 — Async vs sequential

> Sequential: 100 tickets x 1s each = 100 seconds.
> Async (10 concurrent): 100 tickets / 10 = ~10 seconds.
> A semaphore limits concurrency to avoid rate-limit errors.

---

## Step 2 — Async batch classifier

```python
import asyncio
from openai import AsyncOpenAI

async def classify_one(ticket: dict, client: AsyncOpenAI, sem: asyncio.Semaphore) -> dict:
    async with sem:
        resp = await client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": "Classify: BILLING|TECHNICAL|ACCESS|PERFORMANCE|GENERAL. One word only."},
                {"role": "user",   "content": ticket["description"]},
            ],
            temperature=0, max_tokens=10,
        )
        return {**ticket, "category": resp.choices[0].message.content.strip().upper()}

async def batch_classify(tickets: list, max_concurrent: int = 10) -> list:
    async_client = AsyncOpenAI(
        base_url="<your-genai-hub-url>",
        api_key="<bearer-token>",
        default_headers={"AI-Resource-Group": "default"},
    )
    sem     = asyncio.Semaphore(max_concurrent)
    tasks   = [classify_one(t, async_client, sem) for t in tickets]
    results = await asyncio.gather(*tasks, return_exceptions=True)

    ok     = [r for r in results if isinstance(r, dict)]
    failed = [r for r in results if isinstance(r, Exception)]
    print(f"Done: {len(ok)} ok, {len(failed)} failed")
    return ok

tickets = [{"id": f"T-{i:03d}", "description": f"Issue description number {i}"} for i in range(50)]
results = asyncio.run(batch_classify(tickets, max_concurrent=10))
```

**What each key line does:**
- `AsyncOpenAI` — async variant of the client; enables `await` on API calls
- `asyncio.Semaphore(max_concurrent)` — allows at most 10 concurrent API calls
- `async with sem` — blocks if 10 calls are already in flight; acquires a slot automatically
- `asyncio.gather(*tasks, return_exceptions=True)` — runs all tasks concurrently; one failure does not cancel others
- `gpt-4o-mini` — 16x cheaper than gpt-4o for simple classification tasks

---

## Step 3 — Retry failures

```python
async def batch_with_retry(tickets: list, retries: int = 3) -> list:
    remaining = tickets
    all_ok = []
    for attempt in range(retries):
        results = await batch_classify(remaining)
        all_ok.extend(results)
        done_ids  = {r["id"] for r in results}
        remaining = [t for t in remaining if t["id"] not in done_ids]
        if not remaining:
            break
    return all_ok
```

---

## Common mistakes

**Mistake:** No concurrency limit — sending all requests at once hits rate limit and all fail.
**Fix:** Always use a Semaphore. Start at `max_concurrent=5`, increase if rate limits allow.

**Mistake:** `gpt-4o` for batch classification — 16x more expensive than `gpt-4o-mini`.
**Fix:** Use `gpt-4o-mini` for classification; reserve `gpt-4o` for complex reasoning.

---

## ✅ Checkpoint

- [ ] 50 tickets processed concurrently with semaphore of 10
- [ ] One failure does not stop the batch
- [ ] Processing time less than 20% of sequential time
- [ ] Each result has `id`, `description`, and `category`

$md$ WHERE slug = 'ai-22-batch-processing';

UPDATE public.topics SET content_md = $md$
# Episode 24 — Multilingual AI & Translation

## What you'll build
A multilingual support pipeline that detects the language of incoming tickets, translates to English for processing, and returns responses in the customer's original language.

---

## Why this matters
SAP serves customers in 180 countries. AI translation that preserves SAP technical terms — "AI Core", "Kyma", "HANA Cloud" — is what separates a useful enterprise tool from a toy.

---

## Step 1 — Language detection

```python
def detect_language(text: str, client) -> str:
    resp = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content":
            f"Detect the language. Output only the ISO 639-1 code (en, de, fr, ja, etc). Text: {text[:200]}"}],
        temperature=0, max_tokens=5,
    )
    return resp.choices[0].message.content.strip().lower()

samples = [
    "My SAP AI Core deployment is stuck in PENDING status",
    "Mein SAP AI Core Deployment ist im PENDING-Status steckengeblieben",
    "SAP AI CoreのデプロイメントがPENDINGになっています",
]
for s in samples:
    print(f"{detect_language(s, client):5}  {s[:60]}")
```

---

## Step 2 — Translate preserving SAP terms

```python
SAP_TERMS = ["SAP AI Core", "HANA Cloud", "BTP", "Kyma", "Cloud Foundry", "Generative AI Hub"]

def translate(text: str, target_lang: str, client) -> str:
    terms_str = ", ".join(SAP_TERMS)
    resp = client.chat.completions.create(
        model="gpt-4o",
        messages=[{"role": "user", "content":
            f"Translate to {target_lang}. Keep these terms unchanged: {terms_str}. "
            f"Output only the translation.\n\n{text}"}],
        temperature=0.1, max_tokens=500,
    )
    return resp.choices[0].message.content.strip()

def multilingual_support(ticket: str, client) -> str:
    lang = detect_language(ticket, client)
    english = translate(ticket, "English", client) if lang != "en" else ticket

    resp = client.chat.completions.create(
        model="gpt-4o",
        messages=[
            {"role": "system", "content": "You are an SAP BTP expert. Be concise."},
            {"role": "user",   "content": english},
        ],
        max_tokens=300,
    )
    answer_en = resp.choices[0].message.content

    return translate(answer_en, lang, client) if lang != "en" else answer_en

german_ticket = "Ich kann mich nicht in das BTP Cockpit einloggen. Ich bekomme einen 403-Fehler."
print(multilingual_support(german_ticket, client))
```

**What each key line does:**
- `text[:200]` — language detection needs very few characters; truncate to save tokens
- `"Keep these terms unchanged: ..."` — prevents "HANA Cloud" becoming "HANA-Cloud" in German
- Process in English, translate back — consistent quality; avoids chain-of-translation errors
- `temperature=0.1` — slight warmth helps natural phrasing; zero is too stilted for translation

---

## Common mistakes

**Mistake:** Translating the system prompt and instructions to the user's language.
**Fix:** Always process in English. Only translate user input (to English) and the final response (to their language).

**Mistake:** Not listing SAP product names in `preserve_terms`.
**Fix:** Always include your product names. "AI Core" becomes "AI-Kern" in German without this instruction.

---

## ✅ Checkpoint

- [ ] Language detection correctly identifies English, German, and Japanese
- [ ] German ticket translated to English retains SAP product names
- [ ] Final response correctly translated back to German
- [ ] Full pipeline returns a response in the original language

$md$ WHERE slug = 'ai-23-translation';

UPDATE public.topics SET content_md = $md$
# Episode 25 — Production Patterns

## What you'll build
A production-ready AI service wrapper combining retry with exponential backoff, response caching, and a circuit breaker — the patterns required for enterprise deployment.

---

## Why this matters
LLM APIs have higher latency and failure rates than traditional REST APIs. Without retry, caching, and circuit breaking, a temporary API outage can cascade into application downtime.

---

## Step 1 — Retry with exponential backoff

```python
import time, random

def with_retry(fn, max_retries: int = 3, base_delay: float = 1.0):
    for attempt in range(max_retries + 1):
        try:
            return fn()
        except Exception as e:
            if attempt == max_retries:
                raise
            delay = base_delay * (2 ** attempt) + random.uniform(0, 1)
            print(f"Attempt {attempt+1} failed: {e}. Retry in {delay:.1f}s")
            time.sleep(delay)

# Usage
result = with_retry(lambda: client.chat.completions.create(
    model="gpt-4o",
    messages=[{"role": "user", "content": "What is SAP BTP?"}],
    max_tokens=100,
))
```

**What each key line does:**
- `2 ** attempt` — doubles wait time on each retry (1s, 2s, 4s)
- `random.uniform(0, 1)` — jitter prevents multiple clients retrying simultaneously (thundering herd)
- `if attempt == max_retries: raise` — re-raises after the final attempt so caller sees the error

---

## Step 2 — Response caching

```python
import hashlib

_cache: dict = {}

def cached_chat(system: str, user: str, client, ttl: int = 3600) -> str:
    key = hashlib.sha256(f"{system}|{user}".encode()).hexdigest()

    if key in _cache:
        entry = _cache[key]
        if time.time() - entry["ts"] < ttl:
            return entry["response"]

    resp = client.chat.completions.create(
        model="gpt-4o",
        messages=[{"role": "system", "content": system}, {"role": "user", "content": user}],
        temperature=0, max_tokens=300,
    )
    response = resp.choices[0].message.content
    _cache[key] = {"response": response, "ts": time.time()}
    return response
```

**What each key line does:**
- `hashlib.sha256(...)` — deterministic key; same prompt always hits same cache entry
- `temperature=0` — only cache deterministic responses; do not cache variable-temperature outputs
- TTL check — stale entries not served; use Redis with native TTL in production

---

## Step 3 — Circuit breaker

```python
class CircuitBreaker:
    def __init__(self, threshold=5, timeout=60.0):
        self.threshold = threshold
        self.timeout   = timeout
        self.failures  = 0
        self.opened_at = None

    def call(self, fn):
        if self.opened_at and time.time() - self.opened_at < self.timeout:
            raise RuntimeError("Circuit open — AI service unavailable")
        try:
            result = fn()
            self.failures  = 0
            self.opened_at = None
            return result
        except Exception as e:
            self.failures += 1
            if self.failures >= self.threshold:
                self.opened_at = time.time()
                print(f"Circuit opened after {self.failures} failures")
            raise

breaker = CircuitBreaker(threshold=5, timeout=60)
```

**What each key line does:**
- `opened_at` — tracks when circuit opened; after `timeout` seconds one probe call is allowed
- `self.failures = 0` on success — resets counter; handles partial recovery correctly
- `threshold=5` — 5 consecutive failures open the circuit; tune for your SLA

---

## Common mistakes

**Mistake:** Retrying on 400 Bad Request — that is your bug, not the API's.
**Fix:** Only retry on 429 (rate limit) and 5xx errors. Check `e.status_code` before retrying.

**Mistake:** No TTL on cache — stale AI responses served indefinitely.
**Fix:** Always set a TTL. For factual Q&A, 1 hour is safe. For real-time data, skip the cache.

---

## ✅ Checkpoint

- [ ] `with_retry()` waits longer on each retry attempt
- [ ] `cached_chat()` returns cached response on the second identical call
- [ ] Circuit breaker opens after 5 failures
- [ ] Circuit resets to closed after a successful call

$md$ WHERE slug = 'ai-24-production-patterns';

UPDATE public.topics SET content_md = $md$
# Episode 26 — Mini Project — AI Help Desk

## What you'll build
A deployable AI help desk: FastAPI backend with RAG, Supabase knowledge base, and streaming responses — bringing together everything from episodes 1-24.

---

## Why this matters
This mini project is your first production-grade AI application. It integrates auth, embeddings, RAG, streaming, and cost tracking into one deployable service on SAP BTP Cloud Foundry.

---

## Step 1 — Architecture

```
Browser (HTML/JS)
    |
    | POST /ask/stream  (SSE)
    v
FastAPI (main.py)
    |
    +--> Embed question  --> GenAI Hub (text-embedding-3-large)
    +--> Retrieve chunks --> Supabase  (doc_chunks table)
    +--> Generate answer --> GenAI Hub (gpt-4o, stream=True)
```

---

## Step 2 — FastAPI backend (key endpoints)

```python
from fastapi import FastAPI
from fastapi.responses import StreamingResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import json, numpy as np

app = FastAPI()
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

# ai_core, client, supabase initialised here (see episode 1 and 2)

class Question(BaseModel):
    text: str

def retrieve(question: str, top_k: int = 5) -> str:
    q_vec = client.embeddings.create(
        model="text-embedding-3-large", input=question
    ).data[0].embedding
    rows  = supabase.table("doc_chunks").select("text, embedding").execute().data
    q     = np.array(q_vec)
    scored = sorted(
        [{"score": float(np.dot(q, np.array(json.loads(r["embedding"]))) /
                        (np.linalg.norm(q) * np.linalg.norm(np.array(json.loads(r["embedding"]))))),
          "text": r["text"]} for r in rows],
        key=lambda x: x["score"], reverse=True,
    )[:top_k]
    return "\n\n".join(f"[{i+1}] {c['text']}" for i, c in enumerate(scored))

@app.post("/ask/stream")
async def ask_stream(q: Question):
    context = retrieve(q.text)
    system  = (
        "You are an SAP BTP expert. Answer using ONLY the context. "
        "Cite [1], [2] etc. If not in context, say you don't have that information.\n\n"
        f"Context:\n{context}"
    )
    def stream():
        s = client.chat.completions.create(
            model="gpt-4o", stream=True, max_tokens=500,
            messages=[{"role": "system", "content": system}, {"role": "user", "content": q.text}],
        )
        for chunk in s:
            t = chunk.choices[0].delta.content
            if t:
                yield f"data: {json.dumps({'token': t})}\n\n"
        yield "data: [DONE]\n\n"

    return StreamingResponse(stream(), media_type="text/event-stream",
                             headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"})

@app.get("/health")
async def health():
    return {"status": "ok"}
```

**What each key line does:**
- `CORSMiddleware(allow_origins=["*"])` — allows the frontend to call the API from any origin in dev
- `retrieve()` fetches and scores in Python — replace with pgvector in production
- `get_client()` called per request — refreshes the bearer token before it expires
- `"ONLY the context"` in system — grounding instruction prevents hallucination on out-of-scope questions

---

## Step 3 — Deploy to Cloud Foundry

```bash
# Procfile
web: uvicorn main:app --host 0.0.0.0 --port $PORT

# manifest.yml
applications:
  - name: sap-ai-helpdesk
    memory: 512M
    buildpacks: [python_buildpack]
    env:
      AI_API_URL: <your-ai-api-url>
      SUPABASE_URL: <your-supabase-url>

cf push
```

---

## Common mistakes

**Mistake:** Hard-coded bearer token — expires after 12 hours.
**Fix:** Call `get_token()` inside request handlers, not once at startup.

**Mistake:** No CORS headers — browser blocks all fetch calls.
**Fix:** Add `CORSMiddleware` from day one; restrict `allow_origins` to your domain in production.

---

## ✅ Checkpoint

- [ ] `/health` returns `{"status": "ok"}`
- [ ] `/ask/stream` streams tokens for a relevant question
- [ ] Retrieved context cited with [1], [2] in the response
- [ ] App deploys to Cloud Foundry with `cf push`

$md$ WHERE slug = 'ai-25-mp-help-desk';

UPDATE public.topics SET content_md = $md$
# Episode 27 — Mini Project — AI Code Reviewer

## What you'll build
An automated code review tool that analyses Python and JavaScript code for bugs, security issues, and SAP best-practice violations — deployable as a GitHub Actions step.

---

## Why this matters
AI code review catches common issues instantly — SQL injection, hard-coded credentials, missing error handling — freeing human reviewers for architecture-level feedback.

---

## Step 1 — Schema for review findings

```python
from pydantic import BaseModel
from typing import List
import json

class Issue(BaseModel):
    severity:    str    # CRITICAL | HIGH | MEDIUM | LOW
    category:    str    # SECURITY | BUG | PERFORMANCE | SAP_BEST_PRACTICE
    line:        int
    description: str
    suggestion:  str

class ReviewResult(BaseModel):
    issues:   List[Issue]
    summary:  str
    score:    int   # 0-100
```

---

## Step 2 — Review function

```python
REVIEW_SYSTEM = (
    "You are a senior SAP BTP code reviewer. "
    "Find bugs, security vulnerabilities, and SAP-specific issues. "
    "Focus on: hard-coded credentials, missing error handling, SQL injection, "
    "and violations of SAP CAP or AI Core best practices. "
    "Return ONLY a JSON object: "
    '{"issues": [{"severity": ..., "category": ..., "line": ..., "description": ..., "suggestion": ...}], '
    '"summary": ..., "score": 0-100}'
)

def review_code(code: str, language: str, client) -> ReviewResult:
    prompt = f"Language: {language}\n\nCode:\n```{language}\n{code}\n```"
    resp = client.chat.completions.create(
        model="gpt-4o",
        messages=[
            {"role": "system", "content": REVIEW_SYSTEM},
            {"role": "user",   "content": prompt},
        ],
        response_format={"type": "json_object"},
        temperature=0, max_tokens=1500,
    )
    return ReviewResult(**json.loads(resp.choices[0].message.content))

# Test code with intentional issues
bad_code = "\n".join([
    "def run_query(user_input):",
    "    password = 'admin123'",
    "    query = 'SELECT * FROM users WHERE name = ' + user_input",
    "    return db.execute(query)",
])

result = review_code(bad_code, "python", client)
print(f"Score: {result.score}/100")
for issue in sorted(result.issues, key=lambda x: ["CRITICAL","HIGH","MEDIUM","LOW"].index(x.severity)):
    print(f"  [{issue.severity}] Line {issue.line}: {issue.description}")
```

**What each key line does:**
- `response_format={"type": "json_object"}` — guarantees parseable JSON so Pydantic validation succeeds
- `temperature=0` — the same bug must always be flagged; reproducibility is essential
- `.join([...])` to build the test code — avoids triple-quote nesting issues when embedding code in strings
- `sorted(..., key=lambda x: ["CRITICAL",...].index(x.severity))` — displays critical issues first

---

## Step 3 — GitHub Actions integration

```yaml
name: AI Code Review
on: [pull_request]
jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0
      - name: Run AI review
        env:
          AI_API_URL:    ${{ secrets.AI_API_URL }}
          CLIENT_ID:     ${{ secrets.AI_CLIENT_ID }}
          CLIENT_SECRET: ${{ secrets.AI_CLIENT_SECRET }}
        run: |
          pip install openai ai-core-sdk pydantic
          git diff origin/main...HEAD --unified=5 > diff.txt
          python review_runner.py diff.txt
```

---

## Common mistakes

**Mistake:** Sending entire large files — exceeds context window and wastes tokens.
**Fix:** Review only the diff (`git diff`), not the full file. Focus on changed lines + 5 lines of context.

**Mistake:** Not validating output — `ReviewResult(**data)` fails if the model omits a field.
**Fix:** Wrap in try/except and log the raw output when Pydantic validation fails.

---

## ✅ Checkpoint

- [ ] Hard-coded password flagged as CRITICAL
- [ ] SQL injection flagged as CRITICAL with a specific fix suggestion
- [ ] `ReviewResult` Pydantic validation passes without errors
- [ ] Issues displayed in severity order (CRITICAL first)

$md$ WHERE slug = 'ai-26-mp-code-reviewer';

UPDATE public.topics SET content_md = $md$
# Episode 28 — Mini Project — AI Usage Dashboard

## What you'll build
A live AI usage and cost dashboard: Supabase data store, FastAPI aggregation API, and a real-time HTML frontend — showing token consumption, cost by feature, latency, and model distribution.

---

## Why this matters
This capstone brings together logging (episode 22), Supabase, data aggregation, and a production frontend. It gives your organisation the visibility needed for budget approval and cost optimisation of AI workloads.

---

## Step 1 — Supabase schema

```sql
CREATE TABLE ai_usage_logs (
    id                BIGSERIAL PRIMARY KEY,
    timestamp         TIMESTAMPTZ DEFAULT NOW(),
    model             TEXT NOT NULL,
    context           TEXT,
    prompt_tokens     INT,
    completion_tokens INT,
    total_tokens      INT,
    cost_usd          NUMERIC(10, 6),
    latency_ms        INT,
    success           BOOLEAN DEFAULT TRUE
);

CREATE INDEX ON ai_usage_logs (timestamp DESC);
CREATE INDEX ON ai_usage_logs (context);
```

---

## Step 2 — FastAPI aggregation endpoint

```python
from fastapi import FastAPI
from datetime import datetime, timedelta
from supabase import create_client

app = FastAPI()
supabase = create_client("<SUPABASE_URL>", "<SUPABASE_KEY>")

@app.get("/dashboard/summary")
async def summary(days: int = 7):
    since = (datetime.utcnow() - timedelta(days=days)).isoformat()
    rows  = (supabase.table("ai_usage_logs")
             .select("model, context, total_tokens, cost_usd, latency_ms, success")
             .gte("timestamp", since)
             .execute().data)

    n            = max(len(rows), 1)
    total_cost   = sum(r["cost_usd"] or 0 for r in rows)
    total_tokens = sum(r["total_tokens"] or 0 for r in rows)
    avg_latency  = sum(r["latency_ms"] or 0 for r in rows) / n
    success_rate = sum(1 for r in rows if r["success"]) / n * 100

    by_model = {}
    for r in rows:
        m = r["model"]
        if m not in by_model:
            by_model[m] = {"calls": 0, "cost": 0}
        by_model[m]["calls"] += 1
        by_model[m]["cost"]  += r["cost_usd"] or 0

    by_context = {}
    for r in rows:
        c = r["context"] or "unknown"
        by_context[c] = by_context.get(c, 0) + (r["cost_usd"] or 0)

    return {
        "total_calls":      len(rows),
        "total_cost_usd":   round(total_cost, 4),
        "total_tokens":     total_tokens,
        "avg_latency_ms":   round(avg_latency),
        "success_rate_pct": round(success_rate, 1),
        "by_model":         by_model,
        "by_context":       by_context,
    }
```

**What each key line does:**
- `.gte("timestamp", since)` — filters to the time window; avoids full table scan
- `max(len(rows), 1)` — prevents division by zero when no data exists for the period
- `by_model` / `by_context` — aggregated in Python for flexibility; use Supabase RPC for large datasets

---

## Step 3 — HTML frontend (key JavaScript)

```javascript
async function load() {
    const data = await fetch('/dashboard/summary?days=7').then(r => r.json());

    document.getElementById('cost').textContent    = '$' + data.total_cost_usd.toFixed(4);
    document.getElementById('calls').textContent   = data.total_calls.toLocaleString();
    document.getElementById('latency').textContent = data.avg_latency_ms + 'ms';
    document.getElementById('success').textContent = data.success_rate_pct + '%';

    // Cost by feature bar chart (use Chart.js)
    const labels = Object.keys(data.by_context);
    const values = Object.values(data.by_context).map(v => parseFloat(v.toFixed(4)));
    renderBarChart('context-chart', labels, values);
}
load();
setInterval(load, 30000);   // auto-refresh every 30 seconds
```

**What each key line does:**
- `setInterval(load, 30000)` — auto-refresh every 30 seconds; no WebSocket needed for a dashboard
- `toLocaleString()` — formats large numbers with commas (e.g. 12,345)
- `.toFixed(4)` — consistent decimal formatting for cost values

---

## Common mistakes

**Mistake:** No time-range filter — querying the full table on every load gets slow at scale.
**Fix:** Always filter with `.gte("timestamp", since)` and add the timestamp index.

**Mistake:** No auto-refresh — dashboard shows stale data.
**Fix:** `setInterval(load, 30000)` for 30-second refresh, or use Supabase Realtime for sub-second updates.

---

## ✅ Checkpoint

- [ ] Supabase schema created with timestamp and context indexes
- [ ] `/dashboard/summary` returns all six metric fields
- [ ] `by_model` and `by_context` breakdowns are accurate
- [ ] Dashboard auto-refreshes every 30 seconds
- [ ] Zero-call period handled without dividing by zero

$md$ WHERE slug = 'ai-27-mp-ai-dashboard';

