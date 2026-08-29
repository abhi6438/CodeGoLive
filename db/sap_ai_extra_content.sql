UPDATE public.topics SET content_md = $md$
# 41 · Advanced RAG

## What you'll build
An advanced RAG pipeline that combines HyPE, BM25 hybrid search, reciprocal rank fusion, and cross-encoder reranking to dramatically outperform naive retrieval on SAP knowledge questions.

---

## Why this matters
Enterprise SAP documentation is dense with domain jargon — naive vector search misses exact terms like "BAPI_SALESORDER_CREATEFROMDAT2" that BM25 handles well. Combining both retrieval strategies with reranking lifts answer accuracy by 30–50% on SAP-specific queries, which is the difference between a trustworthy enterprise AI assistant and one that hallucinates ABAP syntax.

---

## Step 1 — Understand the four techniques
> **HyPE** (Hypothetical Prompt Embeddings) generates a fake answer to the user's question and uses *that* as the query vector — because real answers are semantically closer to stored chunks than the question itself is.

Key terms:
- **BM25** — keyword-frequency ranking (Okapi BM25); great for exact SAP terms and transaction codes
- **Reciprocal Rank Fusion (RRF)** — combines ranked lists from multiple retrievers without needing score calibration
- **Cross-encoder reranker** — a second, slower model that scores every (query, chunk) pair together for high precision

---

## Step 2 — Install dependencies
```bash
pip install rank-bm25 sentence-transformers langchain-community chromadb openai
```
**What each package does:**
- `rank-bm25` — pure-Python BM25 implementation, no Java required
- `sentence-transformers` — provides cross-encoder reranker models
- `chromadb` — local vector store for the embedding side
- `langchain-community` — utility loaders for SAP documents

---

## Step 3 — Build the hybrid pipeline
```python
import os
from openai import OpenAI
from rank_bm25 import BM25Okapi
from sentence_transformers import CrossEncoder
import chromadb

client = OpenAI(
    base_url=os.environ['GENAI_HUB_URL'],
    api_key=os.environ['GENAI_HUB_KEY'],
)

reranker = CrossEncoder('cross-encoder/ms-marco-MiniLM-L-6-v2')
chroma = chromadb.Client()
collection = chroma.get_or_create_collection('sap_docs')

def hype_query(question):
    resp = client.chat.completions.create(
        model='gpt-4o',
        messages=[
            {'role': 'system', 'content': 'Answer in one sentence as if you are SAP documentation.'},
            {'role': 'user', 'content': question},
        ],
        max_tokens=80,
    )
    return resp.choices[0].message.content

def bm25_search(corpus_tokens, query, docs, k=10):
    bm25 = BM25Okapi(corpus_tokens)
    scores = bm25.get_scores(query.lower().split())
    ranked = sorted(enumerate(scores), key=lambda x: x[1], reverse=True)
    return [docs[i] for i, _ in ranked[:k]]

def rrf(lists, k=60):
    scores = {}
    for ranked in lists:
        for rank, doc in enumerate(ranked):
            scores[doc] = scores.get(doc, 0) + 1 / (k + rank + 1)
    return sorted(scores, key=scores.get, reverse=True)

def advanced_rag(question):
    hyp = hype_query(question)
    vec_results = collection.query(query_texts=[hyp], n_results=10)['documents'][0]
    all_docs = [d['text'] for d in collection.get()['metadatas']]
    corpus_tokens = [d.lower().split() for d in all_docs]
    bm_results = bm25_search(corpus_tokens, question, all_docs)
    fused = rrf([vec_results, bm_results])[:20]
    pairs = [(question, doc) for doc in fused]
    rerank_scores = reranker.predict(pairs)
    top5 = [fused[i] for i in sorted(range(len(rerank_scores)), key=lambda i: rerank_scores[i], reverse=True)[:5]]
    context = '\n\n'.join(top5)
    final = client.chat.completions.create(
        model='gpt-4o',
        messages=[
            {'role': 'system', 'content': f'Answer using this SAP context:\n{context}'},
            {'role': 'user', 'content': question},
        ],
    )
    return final.choices[0].message.content
```
**What each key section does:**
- `hype_query` — generates a hypothetical answer to improve vector similarity
- `bm25_search` — keyword ranking for exact SAP terms and transaction codes
- `rrf` — merges two ranked lists without needing score normalization
- `reranker.predict` — scores every candidate against the question for precision

---

## Step 4 — Run and verify
```bash
python advanced_rag.py
```
Ask a question like "How do I create a sales order using BAPI?" — you should see 5 reranked chunks from SAP documentation followed by a precise answer that correctly names `BAPI_SALESORDER_CREATEFROMDAT2`.

---

## Common mistakes
**Mistake:** Running BM25 on the same chunked embeddings corpus causes index mismatches.
**Fix:** Keep a separate plain-text list of chunks in the same order as your vector store; pass that list to BM25.

**Mistake:** Reranking all 20 fused results is slow and the cross-encoder hits API limits.
**Fix:** Fuse to 20, rerank to get top 5, then pass only those 5 to the final LLM call.

**Mistake:** HyPE hallucinations introduce noise when the LLM makes up SAP transaction codes.
**Fix:** Set `max_tokens=80` and add `temperature=0` to keep the hypothetical answer tightly scoped.

---

## ✅ Checkpoint
- [ ] BM25 and vector retrieval both return results for the same query
- [ ] RRF merges the two ranked lists without score errors
- [ ] Cross-encoder reranker returns a score for every (question, chunk) pair
- [ ] Final answer cites correct SAP transaction codes from the top-5 context
- [ ] Pipeline runs end-to-end in under 8 seconds on a 1,000-chunk corpus
- [ ] HyPE query is visibly different from the original question in logs
$md$ WHERE slug = 'ai-41-advanced-rag';

UPDATE public.topics SET content_md = $md$
# 42 · AI Observability

## What you'll build
A fully traced RAG pipeline that logs every prompt, retrieval step, token count, and latency to Langfuse, giving you production-grade dashboards to debug and optimize your SAP AI application.

---

## Why this matters
In enterprise SAP projects, AI pipelines fail silently — a retrieval step returns stale pricing data, the LLM hallucinates a BAPI parameter, and no one knows why until a month-end report is wrong. Distributed tracing gives you a complete audit trail of every inference, which SAP customers increasingly require for compliance in FI, HR, and procurement workflows.

---

## Step 1 — Understand Langfuse tracing concepts
> A **trace** represents one user request end-to-end. Each trace contains **spans** — named timed segments like "retrieve", "rerank", and "generate". Langfuse stores every prompt, completion, token count, and model name, making each span independently queryable.

Key terms:
- **Generation** — a span wrapping a single LLM call with prompt and completion logged
- **Score** — a human or automated quality rating attached to a trace (e.g. user thumbs-up)
- **Session** — groups traces from the same user conversation for context

---

## Step 2 — Install and configure Langfuse
```bash
pip install langfuse openai
```
Set environment variables:
```bash
export LANGFUSE_PUBLIC_KEY=pk-lf-...
export LANGFUSE_SECRET_KEY=sk-lf-...
export LANGFUSE_HOST=https://cloud.langfuse.com
export GENAI_HUB_URL=https://api.ai.your-btp-region.aws.ml.hana.ondemand.com/v2
export GENAI_HUB_KEY=your-key-here
```
**What each variable does:**
- `LANGFUSE_PUBLIC_KEY` / `LANGFUSE_SECRET_KEY` — authenticate your project; never commit these
- `LANGFUSE_HOST` — use your self-hosted URL here for air-gapped SAP environments
- `GENAI_HUB_URL` — your BTP AI Core inference endpoint

---

## Step 3 — Instrument the pipeline
```python
import os, time
from openai import OpenAI
from langfuse import Langfuse
from langfuse.decorators import observe, langfuse_context

lf = Langfuse()
ai = OpenAI(base_url=os.environ['GENAI_HUB_URL'], api_key=os.environ['GENAI_HUB_KEY'])

DOCS = [
    'BAPI_SALESORDER_CREATEFROMDAT2 creates a sales order from external data.',
    'Use FM CONVERSION_EXIT_MATN1_INPUT to convert material numbers.',
    'Transaction VA01 creates sales orders in the UI; use ME21N for purchase orders.',
]

@observe(name='retrieve')
def retrieve(query):
    langfuse_context.update_current_span(input={'query': query})
    results = [d for d in DOCS if any(w in d.lower() for w in query.lower().split())]
    langfuse_context.update_current_span(output={'chunks': len(results)})
    return results or DOCS[:2]

@observe(name='generate')
def generate(question, context_chunks):
    context = '\n'.join(context_chunks)
    t0 = time.time()
    resp = ai.chat.completions.create(
        model='gpt-4o',
        messages=[
            {'role': 'system', 'content': f'Answer using SAP context:\n{context}'},
            {'role': 'user', 'content': question},
        ],
    )
    latency = round(time.time() - t0, 2)
    langfuse_context.update_current_generation(
        model='gpt-4o',
        usage={'input': resp.usage.prompt_tokens, 'output': resp.usage.completion_tokens},
        metadata={'latency_s': latency},
    )
    return resp.choices[0].message.content

@observe(name='sap-rag-pipeline')
def sap_rag(question):
    chunks = retrieve(question)
    answer = generate(question, chunks)
    lf.score(trace_id=langfuse_context.get_current_trace_id(), name='auto-quality',
             value=1 if 'BAPI' in answer or 'transaction' in answer.lower() else 0)
    return answer

if __name__ == '__main__':
    result = sap_rag('How do I create a sales order programmatically?')
    print(result)
    lf.flush()
```
**What each key section does:**
- `@observe` decorator — automatically starts and ends a span, capturing timing
- `langfuse_context.update_current_span` — attaches input/output metadata to the span
- `lf.score` — adds a programmatic quality signal that appears on the Langfuse dashboard
- `lf.flush()` — ensures all events are sent before the process exits

---

## Step 4 — Run and view traces
```bash
python traced_rag.py
```
Open `https://cloud.langfuse.com` → your project → Traces. You will see one trace named "sap-rag-pipeline" containing two child spans — "retrieve" and "generate" — with latency, token counts, and the auto-quality score visible on the detail panel.

---

## Common mistakes
**Mistake:** Forgetting `lf.flush()` at the end of a script means traces are lost.
**Fix:** Always call `lf.flush()` before process exit, or use the context manager `with Langfuse() as lf:`.

**Mistake:** Logging raw SAP PII (employee IDs, salary data) into Langfuse violates GDPR.
**Fix:** Mask sensitive fields before passing them to `update_current_span`; use a `redact()` helper.

**Mistake:** Using the same `LANGFUSE_PUBLIC_KEY` for dev and prod mixes traces in dashboards.
**Fix:** Create separate Langfuse projects for each environment and inject keys via BTP environment variables.

---

## ✅ Checkpoint
- [ ] Langfuse credentials are set as environment variables, not hardcoded
- [ ] Trace appears in the Langfuse UI within 5 seconds of running the script
- [ ] "retrieve" and "generate" show as child spans with individual latencies
- [ ] Token counts for prompt and completion are visible on the generate span
- [ ] Auto-quality score appears on the trace detail panel
- [ ] `lf.flush()` is called before the script exits
$md$ WHERE slug = 'ai-42-ai-observability';

UPDATE public.topics SET content_md = $md$
# 43 · JavaScript + GenAI Hub

## What you'll build
A Node.js `SAPAIClient` class with `chat()` and `stream()` methods that call the SAP GenAI Hub using only built-in Node.js APIs — no npm packages, no bundler, no runtime dependencies.

---

## Why this matters
Many SAP BTP applications run on Node.js — CAP services, Fiori extensions, and BTP Kyma workloads. Avoiding npm packages for AI calls eliminates supply-chain risk, reduces container image size, and passes SAP security scans that flag third-party HTTP clients. Native `fetch` has been stable in Node.js since v18 and is the standard going forward.

---

## Step 1 — Understand the GenAI Hub API shape
> The SAP GenAI Hub exposes an OpenAI-compatible REST API. Every request POSTs JSON to `/chat/completions` with a bearer token. Streaming responses use Server-Sent Events (SSE) — each line is prefixed with `data: ` and ends with `data: [DONE]`.

Key terms:
- **Bearer token** — the `GENAI_HUB_KEY` sent as `Authorization: Bearer ...` on every request
- **SSE (Server-Sent Events)** — a chunked HTTP response where each chunk is one JSON delta
- **delta.content** — the incremental text fragment in each SSE chunk during streaming

---

## Step 2 — Confirm Node.js version
```bash
node --version   # must be v18.0.0 or higher
```
No installation needed — `fetch` and `ReadableStream` are built in from v18. If your BTP Kyma workload uses Node 16, pin the base image to `node:18-alpine` in your Dockerfile.

---

## Step 3 — Build SAPAIClient
```javascript
// sap-ai-client.mjs
const BASE_URL = process.env.GENAI_HUB_URL;
const API_KEY  = process.env.GENAI_HUB_KEY;
const MODEL    = process.env.GENAI_MODEL ?? 'gpt-4o';

class SAPAIClient {
  #headers() {
    return {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${API_KEY}`,
    };
  }

  async chat(messages, opts = {}) {
    const res = await fetch(`${BASE_URL}/chat/completions`, {
      method: 'POST',
      headers: this.#headers(),
      body: JSON.stringify({ model: MODEL, messages, ...opts }),
    });
    if (!res.ok) throw new Error(`GenAI Hub error ${res.status}: ${await res.text()}`);
    const data = await res.json();
    return data.choices[0].message.content;
  }

  async stream(messages, onChunk) {
    const res = await fetch(`${BASE_URL}/chat/completions`, {
      method: 'POST',
      headers: this.#headers(),
      body: JSON.stringify({ model: MODEL, messages, stream: true }),
    });
    if (!res.ok) throw new Error(`GenAI Hub stream error ${res.status}`);
    const reader = res.body.getReader();
    const decoder = new TextDecoder();
    let buffer = '';
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      buffer += decoder.decode(value, { stream: true });
      const lines = buffer.split('\n');
      buffer = lines.pop();
      for (const line of lines) {
        if (!line.startsWith('data: ') || line === 'data: [DONE]') continue;
        const delta = JSON.parse(line.slice(6)).choices[0].delta.content ?? '';
        if (delta) onChunk(delta);
      }
    }
  }
}

const ai = new SAPAIClient();

const answer = await ai.chat([
  { role: 'system', content: 'You are an SAP expert.' },
  { role: 'user',   content: 'What does transaction SE38 do?' },
]);
console.log('Chat answer:', answer);

process.stdout.write('Stream answer: ');
await ai.stream(
  [{ role: 'user', content: 'List 3 core SAP modules in one sentence each.' }],
  chunk => process.stdout.write(chunk),
);
console.log();
```
**What each key section does:**
- `#headers()` — private method (ES2022 class field) keeps auth logic in one place
- `chat()` — standard request/response, returns the full string content
- `stream()` — reads SSE line-by-line, fires `onChunk` for each text delta
- `buffer` — accumulates partial lines across `read()` chunks so no delta is split

---

## Step 4 — Run and verify
```bash
node sap-ai-client.mjs
```
You should see a complete chat answer followed by the streamed response printing character-by-character. Total cold-start time should be under 200ms with no module loading overhead.

---

## Common mistakes
**Mistake:** Using `require()` with `.mjs` files throws `ERR_REQUIRE_ESM`.
**Fix:** Use `node sap-ai-client.mjs` (ESM) or rename to `.cjs` and replace `await` at top level with an async IIFE.

**Mistake:** Forgetting `stream: true` in the body means the response is not chunked and the SSE reader hangs.
**Fix:** Always set `stream: true` in the request body when calling the `stream()` method.

**Mistake:** Not draining the SSE buffer when chunks contain partial JSON lines causes `JSON.parse` to throw.
**Fix:** The `buffer += ... lines.pop()` pattern retains incomplete lines across reads — never parse a line before it ends with `\n`.

---

## ✅ Checkpoint
- [ ] `node --version` reports v18 or higher
- [ ] `GENAI_HUB_URL` and `GENAI_HUB_KEY` are set as environment variables
- [ ] `chat()` returns a complete string without any `await` issues
- [ ] `stream()` prints tokens incrementally — not all at once at the end
- [ ] Error handling throws a descriptive message when the API key is wrong
- [ ] No `node_modules` folder exists — zero npm dependencies
$md$ WHERE slug = 'ai-43-js-genai-hub';

UPDATE public.topics SET content_md = $md$
# 44 · Local Dev with Ollama

## What you'll build
A dual-mode `AIClient` that runs Llama 3 locally via Ollama during development and automatically switches to the SAP GenAI Hub in production — with zero code changes between environments.

---

## Why this matters
SAP development teams often work in restricted corporate networks where every API call is logged or proxied. Running a local LLM with Ollama eliminates API costs during iteration, works fully offline on flights or in air-gapped dev environments, and removes the risk of accidentally sending sensitive SAP data to a cloud endpoint during early prototyping.

---

## Step 1 — Understand the mode-switching strategy
> Both Ollama and the SAP GenAI Hub expose OpenAI-compatible APIs. The client reads a single environment variable — `AI_ENV` — and points to `http://localhost:11434/v1` locally or your BTP endpoint in production. The model name changes (`llama3` vs `gpt-4o`) but every method call is identical.

Key terms:
- **Ollama** — a local LLM runtime that serves models via a REST API compatible with the OpenAI SDK
- **`AI_ENV`** — the single toggle: `local` (default) or `production`
- **Model aliasing** — mapping a logical name like `default` to the right model per environment

---

## Step 2 — Install Ollama and pull Llama 3
```bash
# macOS / Linux
curl -fsSL https://ollama.com/install.sh | sh
ollama pull llama3
ollama serve   # starts the local API on port 11434
```
**What each command does:**
- `ollama pull llama3` — downloads the 4.7GB Llama 3 8B quantized model
- `ollama serve` — exposes `http://localhost:11434/v1` with OpenAI-compatible endpoints
- Install `pip install openai` once; the same SDK works for both Ollama and GenAI Hub

---

## Step 3 — Build the dual-mode client
```python
import os
from openai import OpenAI

AI_ENV = os.environ.get('AI_ENV', 'local')

LOCAL_CONFIG = {
    'base_url': 'http://localhost:11434/v1',
    'api_key': 'ollama',
    'model': 'llama3',
}

PROD_CONFIG = {
    'base_url': os.environ.get('GENAI_HUB_URL', ''),
    'api_key': os.environ.get('GENAI_HUB_KEY', ''),
    'model': 'gpt-4o',
}

CONFIG = LOCAL_CONFIG if AI_ENV == 'local' else PROD_CONFIG

client = OpenAI(base_url=CONFIG['base_url'], api_key=CONFIG['api_key'])

def chat(messages, **kwargs):
    resp = client.chat.completions.create(
        model=CONFIG['model'],
        messages=messages,
        **kwargs,
    )
    return resp.choices[0].message.content

def sap_explain(topic):
    return chat([
        {'role': 'system', 'content': 'You are an SAP expert. Be concise and accurate.'},
        {'role': 'user', 'content': f'Explain {topic} in SAP in 2-3 sentences.'},
    ])

def sap_generate_abap_comment(code_snippet):
    return chat([
        {'role': 'system', 'content': 'Generate a one-line ABAP comment for this code. Output only the comment.'},
        {'role': 'user', 'content': code_snippet},
    ])

if __name__ == '__main__':
    env_label = 'LOCAL (Ollama/Llama3)' if AI_ENV == 'local' else 'PRODUCTION (GenAI Hub)'
    print(f'Running in {env_label} mode\n')

    print('--- Explain IDoc ---')
    print(sap_explain('IDoc (Intermediate Document)'))

    print('\n--- ABAP Comment ---')
    snippet = 'LOOP AT lt_orders INTO ls_order WHERE status = "OPEN".'
    print(sap_generate_abap_comment(snippet))
```
**What each key section does:**
- `CONFIG = LOCAL_CONFIG if AI_ENV == 'local'` — single branch selects the entire config dict
- `api_key='ollama'` — Ollama ignores the key but the OpenAI SDK requires a non-empty string
- `**kwargs` in `chat()` — passes through `temperature`, `max_tokens`, etc. unchanged
- `sap_generate_abap_comment` — shows a real SAP dev use case for local AI tooling

---

## Step 4 — Run in both modes
```bash
# Local mode (default)
python dual_mode_client.py

# Production mode
AI_ENV=production python dual_mode_client.py
```
Local mode should respond in 2–5 seconds with Llama 3. Production mode should respond in under 2 seconds with GPT-4o. Both return valid SAP explanations — verify the outputs are semantically equivalent even if worded differently.

---

## Common mistakes
**Mistake:** Ollama is not running when the script executes, causing a `ConnectionRefusedError`.
**Fix:** Run `ollama serve` in a separate terminal first, or add `ollama serve &` to your dev startup script.

**Mistake:** Setting `api_key=None` for Ollama causes the OpenAI SDK to raise a validation error before the request is sent.
**Fix:** Always pass `api_key='ollama'` (or any non-empty string) — Ollama ignores its value.

**Mistake:** Using `model='gpt-4o'` with Ollama fails with model-not-found; using `model='llama3'` with GenAI Hub also fails.
**Fix:** Always read the model name from `CONFIG['model']` — never hardcode it in the call site.

---

## ✅ Checkpoint
- [ ] `ollama serve` is running and responds at `http://localhost:11434/v1/models`
- [ ] `AI_ENV=local` produces a valid SAP explanation from Llama 3
- [ ] `AI_ENV=production` produces a valid SAP explanation from GenAI Hub
- [ ] Both modes use identical Python call sites — no `if AI_ENV` branches in business logic
- [ ] Switching modes requires only the environment variable change, not a code edit
- [ ] Local mode works fully offline with no network requests
$md$ WHERE slug = 'ai-44-ollama-local';

UPDATE public.topics SET content_md = $md$
# 45 · Image Generation

## What you'll build
An image generator that creates SAP architecture diagrams, workflow visuals, and UI mockups from natural language prompts using DALL-E 3 through the SAP GenAI Hub images endpoint.

---

## Why this matters
SAP consultants spend hours in PowerPoint drawing system landscape diagrams, integration flows, and process flowcharts for client presentations. An AI image generator that understands SAP conventions — system colors, integration middleware icons, and BTP service names — produces presentation-ready visuals in seconds, dramatically accelerating solution documentation.

---

## Step 1 — Understand the images endpoint
> The GenAI Hub images endpoint mirrors OpenAI's `/images/generations` API. You POST a prompt string and receive a URL or base64-encoded PNG. DALL-E 3 accepts detailed natural language and honors style instructions like "clean white background, technical diagram style, no gradients."

Key terms:
- **`response_format`** — `url` gives a temporary CDN link; `b64_json` gives a base64 PNG safe to save locally
- **`size`** — `1024x1024` (square), `1792x1024` (landscape), or `1024x1792` (portrait)
- **`quality`** — `standard` (faster, cheaper) or `hd` (sharper text and details, recommended for diagrams)

---

## Step 2 — Install dependencies
```bash
pip install openai pillow requests
```
**What each package does:**
- `openai` — SDK handles auth and the images endpoint
- `pillow` — opens and saves the returned PNG for local viewing or annotation
- `requests` — downloads the image from the temporary CDN URL when using `response_format=url`

---

## Step 3 — Build the SAP image generator
```python
import os, base64, requests
from pathlib import Path
from openai import OpenAI
from PIL import Image
import io

client = OpenAI(
    base_url=os.environ['GENAI_HUB_URL'],
    api_key=os.environ['GENAI_HUB_KEY'],
)

SAP_STYLE = (
    'Clean technical diagram on a white background. '
    'SAP blue (#0070F2) for primary components. '
    'Grey arrows for data flow. No gradients. No shadows. '
    'Label every box and arrow clearly in bold sans-serif font.'
)

def generate_sap_image(description, filename='output.png', size='1792x1024', quality='hd'):
    prompt = f'{description}\n\nStyle: {SAP_STYLE}'
    resp = client.images.generate(
        model='dall-e-3',
        prompt=prompt,
        n=1,
        size=size,
        quality=quality,
        response_format='b64_json',
    )
    image_data = base64.b64decode(resp.data[0].b64_json)
    img = Image.open(io.BytesIO(image_data))
    out_path = Path(filename)
    img.save(out_path, 'PNG')
    print(f'Saved {out_path} ({img.size[0]}x{img.size[1]}px)')
    return out_path

DIAGRAMS = [
    (
        'SAP BTP architecture diagram showing: '
        'S/4HANA on-premise connected via SAP Integration Suite to BTP. '
        'BTP contains AI Core (GenAI Hub), HANA Cloud, and CAP application. '
        'External users access via Fiori launchpad.',
        'btp_architecture.png',
    ),
    (
        'SAP Order-to-Cash process flow: '
        'Customer Order -> VA01 Sales Order -> Delivery VL01N -> '
        'Goods Issue -> VF01 Billing -> FI Posting. '
        'Show each step as a rounded rectangle with transaction code below.',
        'order_to_cash.png',
    ),
    (
        'SAP Integration Suite middleware diagram: '
        'ERP (left) sending IDocs to Integration Suite (center) '
        'which transforms and routes to three targets on the right: '
        'Salesforce CRM, Ariba Procurement, and a REST API consumer.',
        'integration_flow.png',
    ),
]

if __name__ == '__main__':
    for description, filename in DIAGRAMS:
        print(f'Generating {filename}...')
        generate_sap_image(description, filename)
```
**What each key section does:**
- `SAP_STYLE` — a reusable style suffix that keeps all generated images visually consistent
- `response_format='b64_json'` — returns the image inline, avoiding CDN URL expiry issues
- `Image.open(io.BytesIO(...))` — decodes base64 to a Pillow image for saving or manipulation
- `DIAGRAMS` list — lets you batch-generate multiple SAP diagrams in one run

---

## Step 4 — Run and view results
```bash
python sap_image_gen.py
```
Three PNG files appear in the current directory. Open `btp_architecture.png` — it should show a clean landscape diagram with labeled boxes for S/4HANA, Integration Suite, AI Core, HANA Cloud, and a Fiori frontend. Generation takes 15–30 seconds per image at `hd` quality.

---

## Common mistakes
**Mistake:** DALL-E 3 ignores hex color codes in prompts and uses random colors.
**Fix:** Describe colors in natural language — "SAP corporate blue" or "light grey background" — rather than hex values.

**Mistake:** Using `n=4` to generate multiple variants returns an API error; DALL-E 3 only supports `n=1`.
**Fix:** Call `generate_sap_image` in a loop with different prompt variations instead of setting `n > 1`.

**Mistake:** Saving with `response_format='url'` and opening the URL later fails because the CDN link expires in 60 minutes.
**Fix:** Always use `response_format='b64_json'` and save to disk immediately after generation.

---

## ✅ Checkpoint
- [ ] `btp_architecture.png` is generated and shows distinct labeled components
- [ ] `order_to_cash.png` displays the full O2C flow with transaction codes
- [ ] `integration_flow.png` shows bidirectional arrows with named systems
- [ ] All images use consistent styling from the `SAP_STYLE` suffix
- [ ] Files are saved as PNG using Pillow and open correctly in any image viewer
- [ ] Generation completes without API errors for all three diagrams
$md$ WHERE slug = 'ai-45-image-generation';
