-- Content updates for Module 107 & 108 topics (ai-28 to ai-40)

UPDATE public.topics SET content_md = $md$
# 28 · MCP Server

## What you'll build
A Python MCP (Model Context Protocol) server that exposes three live SAP data tools — `get_material`, `get_purchase_order`, and `get_user_profile` — so any AI assistant can query your SAP system through a standard interface.

---

## Why this matters (enterprise context)
Before MCP, every AI integration required custom connectors: one adapter for ChatGPT, another for Claude, another for a local LLM. MCP defines a single protocol. You write one server and any MCP-compatible AI client discovers and calls your tools automatically. In SAP environments this means Material Master data, open POs, and user records become AI-readable without rebuilding the integration layer for each model.

---

## Step 1 — Understand the MCP Protocol

> MCP is a JSON-RPC 2.0 protocol that lets AI assistants call tools, read resources, and sample from a host model. Your server declares its tools in a manifest; clients call `tools/list` to discover them and `tools/call` to invoke them.

Key terms:
- **Tool** — a function the AI can invoke (name, description, JSON schema for inputs)
- **Resource** — a static or dynamic data source the AI can read
- **Manifest** — the `initialize` response your server returns, listing all capabilities
- **JSON-RPC 2.0** — wire protocol: requests have `method`, `params`, `id`; responses have `result` or `error`
- **stdio transport** — the simplest MCP transport; server reads from stdin, writes to stdout

---

## Step 2 — Install the MCP Python SDK

```bash
python -m venv .venv
source .venv/bin/activate
pip install mcp httpx python-dotenv
```

Create `.env`:

```bash
SAP_BASE_URL=https://my-s4.example.com/sap/opu/odata/sap
SAP_USER=AI_SVC_USER
SAP_PASS=S3cur3P@ss!
```

**What each key line does:**
- `mcp` — Anthropic's official Python SDK; handles JSON-RPC framing and stdio transport
- `httpx` — async HTTP client for OData calls to the SAP backend
- `python-dotenv` — loads `.env` so credentials stay out of source code
- `SAP_BASE_URL` — the root of your SAP OData service landscape

---

## Step 3 — Write the MCP Server

```python
import asyncio, os
from dotenv import load_dotenv
import httpx
from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import Tool, TextContent

load_dotenv()
BASE = os.environ['SAP_BASE_URL']
AUTH = (os.environ['SAP_USER'], os.environ['SAP_PASS'])
HEADERS = {'Accept': 'application/json', 'sap-client': '100'}
app = Server('sap-tools')

@app.list_tools()
async def list_tools():
    return [
        Tool(name='get_material',
             description='Fetch a material master record from SAP.',
             inputSchema={'type': 'object',
                          'properties': {'material_number': {'type': 'string'}},
                          'required': ['material_number']}),
        Tool(name='get_purchase_order',
             description='Fetch a SAP purchase order with line items.',
             inputSchema={'type': 'object',
                          'properties': {'po_number': {'type': 'string'}},
                          'required': ['po_number']}),
        Tool(name='get_user_profile',
             description='Fetch a SAP user profile including roles.',
             inputSchema={'type': 'object',
                          'properties': {'user_id': {'type': 'string'}},
                          'required': ['user_id']})
    ]

@app.call_tool()
async def call_tool(name: str, arguments: dict):
    async with httpx.AsyncClient(auth=AUTH, headers=HEADERS, verify=False) as client:
        if name == 'get_material':
            mat = arguments['material_number']
            r = await client.get(f'{BASE}/API_PRODUCT_SRV/A_Product(\'{mat}\')')
            r.raise_for_status()
            d = r.json().get('d', {})
            return [TextContent(type='text', text=
                f'Material: {d.get("Product")}\n'
                f'Description: {d.get("ProductDescription")}\n'
                f'Base Unit: {d.get("BaseUnit")}\n'
                f'Group: {d.get("MaterialGroup")}')]
        if name == 'get_purchase_order':
            r = await client.get(
                f'{BASE}/API_PURCHASEORDER_PROCESS_SRV/A_PurchaseOrder(\'{arguments["po_number"]}\')',
                params={'$expand': 'to_PurchaseOrderItem'})
            r.raise_for_status()
            d = r.json().get('d', {})
            items = d.get('to_PurchaseOrderItem', {}).get('results', [])
            lines = '\n'.join(
                f'  {i["PurchaseOrderItem"]}: {i["Material"]} x {i["OrderQuantity"]}' for i in items)
            return [TextContent(type='text', text=
                f'PO: {d.get("PurchaseOrder")}\nVendor: {d.get("Supplier")}\nItems:\n{lines}')]
        if name == 'get_user_profile':
            r = await client.get(
                f'{BASE}/API_USERPROFILE_SRV/UserProfile(\'{arguments["user_id"]}\')',
                params={'$expand': 'to_UserRole'})
            r.raise_for_status()
            d = r.json().get('d', {})
            roles = [x['RoleID'] for x in d.get('to_UserRole', {}).get('results', [])]
            return [TextContent(type='text', text=
                f'User: {d.get("UserID")}\n'
                f'Name: {d.get("FirstName")} {d.get("LastName")}\n'
                f'Roles: {", ".join(roles)}')]
        return [TextContent(type='text', text=f'Unknown tool: {name}')]

async def main():
    async with stdio_server() as (read_stream, write_stream):
        await app.run(read_stream, write_stream, app.create_initialization_options())

if __name__ == '__main__':
    asyncio.run(main())
```

**What each key line does:**
- `Server('sap-tools')` — creates a named MCP server; the name appears in client logs
- `@app.list_tools()` — registers the manifest handler; MCP clients call this on connect
- `inputSchema` — JSON Schema the AI uses to know what arguments to validate and pass
- `@app.call_tool()` — dispatcher receiving the tool name and validated arguments
- `r.raise_for_status()` — converts SAP 4xx/5xx errors into exceptions MCP surfaces as tool errors
- `TextContent(type='text', text=...)` — MCP return type; the AI sees this as plain text

---

## Step 4 — Smoke-Test the Server

```bash
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1"}}}' \
  | python sap_mcp_server.py

echo '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"get_material","arguments":{"material_number":"MAT-10045"}}}' \
  | python sap_mcp_server.py
```

---

## Common mistakes

**Mistake:** Returning a plain string from `call_tool` instead of `[TextContent(...)]`.
**Fix:** MCP requires a list of content objects; always return `[TextContent(type='text', text=your_string)]`.

**Mistake:** Forgetting `sap-client` header, causing SAP to reject the request with 401.
**Fix:** Add `'sap-client': '100'` (or your client number) to every request header.

**Mistake:** Writing debug output to stdout, corrupting the JSON-RPC wire.
**Fix:** Always use `sys.stderr` for logging; stdout is the MCP transport channel.

---

## ✅ Checkpoint

- [ ] MCP server starts without error and prints nothing to stdout at startup
- [ ] `tools/list` returns all 3 tools with correct JSON schemas
- [ ] `get_material` returns real SAP data for a known material number
- [ ] `get_purchase_order` expands and lists line items correctly
- [ ] `get_user_profile` returns the roles list
- [ ] Server handles an unknown tool name gracefully without crashing
$md$ WHERE slug = 'ai-28-mcp-server';

UPDATE public.topics SET content_md = $md$
# 29 · MCP Client

## What you'll build
An MCP client in Python that connects to your SAP MCP server, auto-discovers all available tools, and uses Claude to answer SAP questions by calling those tools automatically — no hardcoded routing logic.

---

## Why this matters (enterprise context)
With a running MCP server, the challenge is letting the AI choose tools intelligently. A naive approach hardcodes routing ("if the user asks about a PO, call `get_purchase_order`"). The MCP client pattern is better: send the full tool manifest to the model and let it decide which tool to call based on natural language. This works for any future tool you add without touching the client code.

---

## Step 1 — Understand the Client Flow

> An MCP client launches the server as a subprocess, calls `tools/list` to get the manifest, then passes that manifest to the LLM on every chat turn. When the LLM emits a tool-call block, the client executes `tools/call` on the server and feeds the result back to the LLM.

Key terms:
- **Tool use** — the mechanism by which LLMs emit structured tool-call requests instead of plain text
- **Tool loop** — the cycle: user message → LLM → tool call → server → result → LLM → final answer
- **ClientSession** — MCP SDK class managing the connection to a server process
- **StdioServerParameters** — config that tells the client how to launch the server subprocess
- **stop_reason** — `'tool_use'` means the model wants to call a tool; `'end_turn'` means it is done

---

## Step 2 — Install Dependencies

```bash
pip install mcp anthropic python-dotenv
```

Add to `.env`:

```bash
ANTHROPIC_API_KEY=sk-ant-api03-...
MCP_SERVER_PATH=/home/dev/sap-mcp/sap_mcp_server.py
```

**What each key line does:**
- `mcp` — provides `ClientSession` and `StdioServerParameters` for subprocess-based MCP
- `anthropic` — Claude SDK; `messages.create()` accepts a `tools` list for function calling
- `MCP_SERVER_PATH` — absolute path to the server script the client will launch as a subprocess

---

## Step 3 — Write the MCP Client

```python
import asyncio, os
from dotenv import load_dotenv
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client
import anthropic

load_dotenv()
ANTHROPIC = anthropic.Anthropic(api_key=os.environ['ANTHROPIC_API_KEY'])
SERVER_PATH = os.environ['MCP_SERVER_PATH']

def mcp_to_anthropic_tools(tools):
    return [{'name': t.name, 'description': t.description,
              'input_schema': t.inputSchema} for t in tools]

async def run_agent(question: str):
    params = StdioServerParameters(command='python', args=[SERVER_PATH])
    async with stdio_client(params) as (read, write):
        async with ClientSession(read, write) as session:
            await session.initialize()
            tools = mcp_to_anthropic_tools((await session.list_tools()).tools)
            messages = [{'role': 'user', 'content': question}]
            print(f'\nUser: {question}')

            while True:
                resp = ANTHROPIC.messages.create(
                    model='claude-opus-4-5',
                    max_tokens=1024,
                    tools=tools,
                    messages=messages
                )
                if resp.stop_reason == 'end_turn':
                    for block in resp.content:
                        if hasattr(block, 'text'):
                            print(f'Assistant: {block.text}')
                    break

                messages.append({'role': 'assistant', 'content': resp.content})
                tool_results = []
                for block in resp.content:
                    if block.type == 'tool_use':
                        print(f'  [tool: {block.name} args={block.input}]')
                        result = await session.call_tool(block.name, block.input)
                        text = '\n'.join(c.text for c in result.content if hasattr(c, 'text'))
                        tool_results.append({
                            'type': 'tool_result',
                            'tool_use_id': block.id,
                            'content': text
                        })
                messages.append({'role': 'user', 'content': tool_results})

async def main():
    await run_agent('What is the unit of measure for material MAT-10045?')
    await run_agent('Show me line items on PO 4500012345.')
    await run_agent('What SAP roles does JSMITH have?')

if __name__ == '__main__':
    asyncio.run(main())
```

**What each key line does:**
- `StdioServerParameters(command='python', args=[SERVER_PATH])` — launches MCP server as a child process
- `await session.initialize()` — performs the MCP handshake and exchanges capability manifests
- `mcp_to_anthropic_tools()` — converts MCP tool objects to the shape Claude's API expects
- `resp.stop_reason == 'tool_use'` — the model wants to call one or more tools; we must execute them
- `session.call_tool(block.name, block.input)` — forwards the model's decision to the server
- The `while True` loop — continues until the model returns `end_turn` with its final answer

---

## Step 4 — Run the Client

```bash
python sap_mcp_client.py
```

Expected output:

```
User: What is the unit of measure for material MAT-10045?
  [tool: get_material args={'material_number': 'MAT-10045'}]
Assistant: Material MAT-10045 uses EA (Each) as its base unit of measure.

User: Show me line items on PO 4500012345.
  [tool: get_purchase_order args={'po_number': '4500012345'}]
Assistant: PO 4500012345 has 3 line items: ...
```

---

## Common mistakes

**Mistake:** Appending the tool result as `role: 'assistant'` instead of `role: 'user'`.
**Fix:** Tool results must be sent as a `user` message with `type: 'tool_result'` blocks.

**Mistake:** Not awaiting `session.initialize()` before calling `list_tools()`.
**Fix:** The handshake must complete first; skipping it causes a protocol error.

**Mistake:** The client hangs if the server crashes during a tool call.
**Fix:** Wrap `session.call_tool()` in try/except and return an error string as the tool result.

---

## ✅ Checkpoint

- [ ] Client launches the server subprocess and completes the MCP handshake
- [ ] Tool manifest is auto-discovered — no tool names are hardcoded in the client
- [ ] Material question triggers `get_material` tool call automatically
- [ ] PO question triggers `get_purchase_order` with correct arguments
- [ ] Final answer cites real SAP data from the tool result
- [ ] Client exits cleanly without hanging subprocesses
$md$ WHERE slug = 'ai-29-mcp-client';

UPDATE public.topics SET content_md = $md$
# 30 · LangChain + GenAI Hub

## What you'll build
A LangChain-powered SAP assistant that uses ChatOpenAI pointed at the SAP AI Core GenAI Hub endpoint, with conversation memory, LCEL chains, and tool binding — so users can have multi-turn SAP conversations without losing context.

---

## Why this matters (enterprise context)
LangChain is the most widely adopted AI framework in enterprise Python. SAP AI Core's GenAI Hub exposes an OpenAI-compatible endpoint, so you can reuse the entire LangChain ecosystem — tools, memory, chains, agents — while keeping your data inside the SAP BTP boundary. LCEL (LangChain Expression Language) lets you compose these pieces into readable, testable pipelines.

---

## Step 1 — Understand LangChain Core Concepts

> LangChain is a framework for building LLM applications. It provides standard interfaces for models, prompts, memory, tools, and chains, which you compose with the `|` pipe operator in LCEL.

Key terms:
- **LCEL** — LangChain Expression Language; compose runnables with `|` for readable pipelines
- **ChatPromptTemplate** — defines the system prompt and variable slots filled at runtime
- **ConversationBufferMemory** — stores the full message history and injects it into each prompt
- **RunnableWithMessageHistory** — wraps a chain so it automatically loads and saves memory
- **GenAI Hub** — SAP's managed LLM gateway on BTP; exposes an OpenAI-compatible `/chat/completions` endpoint

---

## Step 2 — Install and Configure

```bash
pip install langchain langchain-openai python-dotenv
```

Add to `.env`:

```bash
AICORE_BASE_URL=https://api.ai.internalprod.eu-central-1.aws.ml.hana.ondemand.com/v2
AICORE_DEPLOYMENT_ID=d1234abcd
AICORE_TOKEN=eyJhbGciOiJSUzI1NiJ9...
```

**What each key line does:**
- `langchain-openai` — provides `ChatOpenAI` which accepts a custom `base_url` and `api_key`
- `AICORE_BASE_URL` — the GenAI Hub inference URL from your AI Core deployment page
- `AICORE_DEPLOYMENT_ID` — the model deployment you want to target (e.g., GPT-4o deployment)
- `AICORE_TOKEN` — OAuth2 bearer token; refresh it with the AI Core token endpoint before it expires

---

## Step 3 — Build the LangChain SAP Assistant

```python
import os
from dotenv import load_dotenv
from langchain_openai import ChatOpenAI
from langchain.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain.memory import ConversationBufferMemory
from langchain.schema.runnable.history import RunnableWithMessageHistory
from langchain_core.chat_history import InMemoryChatMessageHistory

load_dotenv()

llm = ChatOpenAI(
    model='gpt-4o',
    base_url=f'{os.environ["AICORE_BASE_URL"]}/inference/deployments/{os.environ["AICORE_DEPLOYMENT_ID"]}',
    api_key=os.environ['AICORE_TOKEN'],
    temperature=0.1
)

prompt = ChatPromptTemplate.from_messages([
    ('system',
     'You are an expert SAP assistant. '
     'Answer questions about SAP materials, purchase orders, vendors, and finance. '
     'Be concise and cite SAP field names (e.g. MARA-MEINS, EKKO-LIFNR).'),
    MessagesPlaceholder(variable_name='history'),
    ('human', '{input}')
])

chain = prompt | llm

store = {}

def get_session_history(session_id: str):
    if session_id not in store:
        store[session_id] = InMemoryChatMessageHistory()
    return store[session_id]

chain_with_history = RunnableWithMessageHistory(
    chain,
    get_session_history,
    input_messages_key='input',
    history_messages_key='history'
)

def chat(session_id: str, user_message: str) -> str:
    response = chain_with_history.invoke(
        {'input': user_message},
        config={'configurable': {'session_id': session_id}}
    )
    return response.content

session = 'sap-session-001'
print(chat(session, 'What SAP field stores the vendor account number on a PO?'))
print(chat(session, 'And which table holds PO header data?'))
print(chat(session, 'How do I filter that table by company code 1000?'))
```

**What each key line does:**
- `ChatOpenAI(base_url=..., api_key=AICORE_TOKEN)` — points LangChain at GenAI Hub; no SAP-specific client needed
- `MessagesPlaceholder(variable_name='history')` — reserves a slot in the prompt where memory is injected
- `chain = prompt | llm` — LCEL pipe; equivalent to `llm.invoke(prompt.format_messages(...))`
- `RunnableWithMessageHistory` — wraps the chain so each call automatically loads and saves conversation history
- `config={'configurable': {'session_id': session}}` — routes history to the correct in-memory store
- `temperature=0.1` — near-deterministic output for enterprise SAP answers

---

## Step 4 — Run the Multi-Turn Session

```bash
python sap_langchain_assistant.py
```

Expected output:

```
The vendor account number on a PO is stored in EKKO-LIFNR (Supplier field, table EKKO).
The PO header data is stored in the EKKO table (Purchasing Document Header).
Use: SELECT * FROM EKKO WHERE MANDT = '100' AND BUKRS = '1000';
```

---

## Common mistakes

**Mistake:** Using `MessagesPlaceholder` but forgetting to pass `history_messages_key='history'` to `RunnableWithMessageHistory`.
**Fix:** The key names must match exactly between the prompt placeholder and the wrapper config.

**Mistake:** The AICORE_TOKEN expires (usually 12 hours) and all calls return 401.
**Fix:** Add a token refresh step before each request, or cache with an expiry check.

**Mistake:** `temperature=0` causes some GenAI Hub deployments to error.
**Fix:** Use `temperature=0.1` as a safe near-zero value for deterministic behavior.

---

## ✅ Checkpoint

- [ ] `ChatOpenAI` connects to GenAI Hub and returns a response without 401/403
- [ ] Multi-turn conversation maintains context (follow-up questions work)
- [ ] LCEL pipe `prompt | llm` is used rather than procedural `llm.invoke()`
- [ ] Memory is keyed by session ID so two concurrent sessions stay isolated
- [ ] SAP field names (EKKO, MARA, LIFNR) appear in responses
- [ ] Token expiry is handled or documented with a refresh strategy
$md$ WHERE slug = 'ai-30-langchain';

UPDATE public.topics SET content_md = $md$
# 31 · LangGraph Agents

## What you'll build
A stateful multi-step LangGraph agent that routes SAP procurement approval requests through a graph of nodes — draft PO → validate budget → seek approval → post to SAP — making decisions at each edge based on LLM output.

---

## Why this matters (enterprise context)
SAP approval workflows are inherently multi-step and branching: a PO under 10,000 EUR is auto-approved; above that it needs a manager's sign-off; above 100,000 EUR it needs finance controller review. LangChain's basic chains are linear. LangGraph adds state, loops, and conditional edges so you can model these real business rules as an explicit graph, audit every decision, and pause for human input mid-flow.

---

## Step 1 — Understand LangGraph Concepts

> LangGraph is a library for building cyclic, stateful agent workflows. Your workflow is a directed graph where nodes are Python functions and edges are routing decisions. A shared `State` TypedDict flows through every node.

Key terms:
- **StateGraph** — the graph builder; you add nodes and edges then compile to a runnable
- **State** — a TypedDict shared across all nodes; each node can read and update it
- **Node** — a Python function `(state) -> dict` that returns partial state updates
- **Conditional edge** — a routing function that returns a node name string based on state
- **END** — LangGraph sentinel that terminates the graph run
- **Checkpoint** — optional persistence layer (e.g., SQLite) that lets you resume paused graphs

---

## Step 2 — Install LangGraph

```bash
pip install langgraph langchain-openai python-dotenv
```

**What each key line does:**
- `langgraph` — the graph runtime; `StateGraph`, `END`, and `compile()` all come from here
- `langchain-openai` — reused from topic 30; the LLM node calls `llm.invoke()` internally

---

## Step 3 — Build the Procurement Approval Graph

```python
import os
from typing import TypedDict, Literal
from dotenv import load_dotenv
from langgraph.graph import StateGraph, END
from langchain_openai import ChatOpenAI
from langchain.schema import HumanMessage, SystemMessage

load_dotenv()

llm = ChatOpenAI(
    model='gpt-4o',
    base_url=f'{os.environ["AICORE_BASE_URL"]}/inference/deployments/{os.environ["AICORE_DEPLOYMENT_ID"]}',
    api_key=os.environ['AICORE_TOKEN'],
    temperature=0
)

class ProcurementState(TypedDict):
    po_draft: dict
    budget_check: str
    approval_level: str
    approval_decision: str
    sap_post_result: str

def validate_budget(state: ProcurementState) -> dict:
    amount = state['po_draft'].get('net_value', 0)
    if amount < 10000:
        level = 'auto'
    elif amount < 100000:
        level = 'manager'
    else:
        level = 'controller'
    return {'budget_check': 'passed', 'approval_level': level}

def seek_approval(state: ProcurementState) -> dict:
    po = state['po_draft']
    level = state['approval_level']
    msgs = [
        SystemMessage(content='You are an SAP approval bot. Respond with APPROVED or REJECTED and a short reason.'),
        HumanMessage(content=
            f'Approval request ({level}):\n'
            f'Vendor: {po.get("vendor")}\n'
            f'Material: {po.get("material")}\n'
            f'Amount: {po.get("net_value")} {po.get("currency")}\n'
            f'Cost Centre: {po.get("cost_centre")}'
        )
    ]
    response = llm.invoke(msgs)
    decision = 'approved' if 'APPROVED' in response.content.upper() else 'rejected'
    return {'approval_decision': decision}

def post_to_sap(state: ProcurementState) -> dict:
    po = state['po_draft']
    print(f'Posting PO to SAP: vendor={po["vendor"]} amount={po["net_value"]}')
    return {'sap_post_result': f'PO posted successfully. SAP PO number: 4500099001'}

def reject_po(state: ProcurementState) -> dict:
    return {'sap_post_result': 'PO rejected. Requester notified.'}

def route_approval(state: ProcurementState) -> Literal['post_to_sap', 'reject_po']:
    if state['approval_decision'] == 'approved':
        return 'post_to_sap'
    return 'reject_po'

def route_budget(state: ProcurementState) -> Literal['seek_approval', 'post_to_sap']:
    if state['approval_level'] == 'auto':
        return 'post_to_sap'
    return 'seek_approval'

graph = StateGraph(ProcurementState)
graph.add_node('validate_budget', validate_budget)
graph.add_node('seek_approval', seek_approval)
graph.add_node('post_to_sap', post_to_sap)
graph.add_node('reject_po', reject_po)

graph.set_entry_point('validate_budget')
graph.add_conditional_edges('validate_budget', route_budget,
    {'seek_approval': 'seek_approval', 'post_to_sap': 'post_to_sap'})
graph.add_conditional_edges('seek_approval', route_approval,
    {'post_to_sap': 'post_to_sap', 'reject_po': 'reject_po'})
graph.add_edge('post_to_sap', END)
graph.add_edge('reject_po', END)

app = graph.compile()

result = app.invoke({
    'po_draft': {
        'vendor': 'Siemens AG',
        'material': 'Turbine Blade Set',
        'net_value': 45000,
        'currency': 'EUR',
        'cost_centre': 'CC-MAINT-007'
    },
    'budget_check': '',
    'approval_level': '',
    'approval_decision': '',
    'sap_post_result': ''
})
print(result['sap_post_result'])
```

**What each key line does:**
- `class ProcurementState(TypedDict)` — defines all shared state fields; LangGraph validates them
- `StateGraph(ProcurementState)` — creates the graph builder typed to your state
- `graph.add_conditional_edges('validate_budget', route_budget, {...})` — the routing function returns a key; the dict maps keys to node names
- `graph.set_entry_point('validate_budget')` — the graph always starts here
- `graph.compile()` — returns a runnable; after this the graph is immutable
- `app.invoke({...})` — synchronous run; returns the final state dict

---

## Step 4 — Run the Graph

```bash
python sap_langgraph_approval.py
```

Expected output for a 45,000 EUR PO:

```
Posting PO to SAP: vendor=Siemens AG amount=45000
PO posted successfully. SAP PO number: 4500099001
```

---

## Common mistakes

**Mistake:** Node function returns the full state instead of only the changed keys.
**Fix:** Return only the dict keys you changed; LangGraph merges the update into state.

**Mistake:** Conditional edge function returns a value not present in the routing dict.
**Fix:** Every possible return value from the routing function must be a key in the edge dict.

**Mistake:** Calling `graph.compile()` before adding all edges, producing a graph missing some paths.
**Fix:** Add all nodes and edges before calling `compile()`.

---

## ✅ Checkpoint

- [ ] Graph compiles without error after all nodes and edges are added
- [ ] A PO under 10,000 EUR skips `seek_approval` and goes straight to `post_to_sap`
- [ ] A PO between 10,000 and 100,000 EUR routes through `seek_approval`
- [ ] Rejected PO lands on `reject_po` node and returns rejection message
- [ ] State contains all fields populated at each step
- [ ] Graph can be visualised with `app.get_graph().print_ascii()`
$md$ WHERE slug = 'ai-31-langgraph';

UPDATE public.topics SET content_md = $md$
# 32 · A2A Protocol

## What you'll build
Two SAP AI agents — a Procurement Agent and a Finance Agent — that communicate via Google's Agent-to-Agent (A2A) protocol, handing off tasks when one agent needs the other's expertise.

---

## Why this matters (enterprise context)
Real SAP workflows cross departmental boundaries. A procurement agent may approve a PO, then need finance to reserve budget. A2A defines a standard HTTP-based protocol for agents to discover each other's capabilities (via an Agent Card) and delegate tasks without being built on the same framework or even the same machine. This enables a modular SAP AI architecture where each department owns and operates its own agent.

---

## Step 1 — Understand the A2A Protocol

> A2A uses HTTP/JSON. Each agent serves an Agent Card at `/.well-known/agent.json` describing its skills. To delegate a task, an agent POSTs a Task object to the target agent's `/tasks/send` endpoint. The receiving agent processes it and returns a result.

Key terms:
- **Agent Card** — JSON descriptor at `/.well-known/agent.json`; lists the agent's name, skills, and endpoint
- **Task** — the A2A work unit; has an `id`, `message` (input), and `status`
- **Skill** — a named capability listed in the Agent Card; the calling agent selects the right skill
- **Task status** — `submitted`, `working`, `completed`, `failed`
- **Delegation** — an agent calling another agent's `/tasks/send` to hand off work it cannot do itself

---

## Step 2 — Install Dependencies

```bash
pip install fastapi uvicorn httpx python-dotenv pydantic
```

**What each key line does:**
- `fastapi` — web framework for both agents; handles JSON serialisation automatically
- `uvicorn` — ASGI server to run both FastAPI apps (on different ports)
- `httpx` — async HTTP client the Procurement Agent uses to call the Finance Agent

---

## Step 3 — Build Both Agents

```python
# finance_agent.py  (run on port 8001)
import uuid
from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI()

@app.get('/.well-known/agent.json')
def agent_card():
    return {
        'name': 'SAP Finance Agent',
        'description': 'Handles budget reservations and cost centre checks for SAP.',
        'url': 'http://localhost:8001',
        'skills': [
            {
                'id': 'reserve-budget',
                'name': 'Reserve Budget',
                'description': 'Reserve budget against a SAP cost centre for an approved PO.'
            }
        ]
    }

class Task(BaseModel):
    id: str
    skill_id: str
    message: dict

@app.post('/tasks/send')
def handle_task(task: Task):
    amount = task.message.get('amount', 0)
    cost_centre = task.message.get('cost_centre', 'UNKNOWN')
    available = 250000.00
    if amount > available:
        return {'id': task.id, 'status': 'failed',
                'result': f'Insufficient budget on {cost_centre}. Available: {available}'}
    reserved = available - amount
    return {
        'id': task.id,
        'status': 'completed',
        'result': f'Budget reserved: {amount} EUR on {cost_centre}. Remaining: {reserved} EUR'
    }
```

```python
# procurement_agent.py  (run on port 8000)
import uuid
import httpx
from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI()
FINANCE_AGENT_URL = 'http://localhost:8001'

@app.get('/.well-known/agent.json')
def agent_card():
    return {
        'name': 'SAP Procurement Agent',
        'description': 'Handles PO creation and approval in SAP.',
        'url': 'http://localhost:8000',
        'skills': [
            {'id': 'create-po', 'name': 'Create Purchase Order',
             'description': 'Draft and submit a SAP purchase order.'}
        ]
    }

class PORequest(BaseModel):
    vendor: str
    material: str
    amount: float
    currency: str
    cost_centre: str

@app.post('/create-po')
async def create_po(req: PORequest):
    card = httpx.get(f'{FINANCE_AGENT_URL}/.well-known/agent.json').json()
    budget_skill = next(s for s in card['skills'] if s['id'] == 'reserve-budget')

    task = {
        'id': str(uuid.uuid4()),
        'skill_id': budget_skill['id'],
        'message': {'amount': req.amount, 'cost_centre': req.cost_centre}
    }
    finance_resp = httpx.post(f'{FINANCE_AGENT_URL}/tasks/send', json=task).json()

    if finance_resp['status'] != 'completed':
        return {'status': 'failed', 'reason': finance_resp['result']}

    return {
        'status': 'success',
        'po_number': 'PO-2025-00981',
        'vendor': req.vendor,
        'amount': req.amount,
        'budget_result': finance_resp['result']
    }
```

**What each key line does:**
- `/.well-known/agent.json` — the A2A discovery endpoint; the calling agent reads this to find skills
- `Task(BaseModel)` — Pydantic model matching the A2A Task schema; FastAPI validates it automatically
- `next(s for s in card['skills'] if s['id'] == 'reserve-budget')` — skill discovery at runtime; no hardcoded URLs or skill names
- `httpx.post(f'{FINANCE_AGENT_URL}/tasks/send', json=task)` — the A2A delegation call
- `finance_resp['status'] != 'completed'` — the Procurement Agent checks the Finance Agent's result before posting the PO

---

## Step 4 — Run Both Agents and Test

```bash
# Terminal 1
uvicorn finance_agent:app --port 8001

# Terminal 2
uvicorn procurement_agent:app --port 8000

# Terminal 3 — submit a PO
curl -X POST http://localhost:8000/create-po \
  -H 'Content-Type: application/json' \
  -d '{"vendor":"Bosch GmbH","material":"Sensor Array","amount":12500,"currency":"EUR","cost_centre":"CC-PROD-002"}'
```

---

## Common mistakes

**Mistake:** Hardcoding the Finance Agent's skill URL instead of reading the Agent Card first.
**Fix:** Always GET `/.well-known/agent.json` and resolve skill endpoints dynamically — this is the whole point of A2A discovery.

**Mistake:** Not returning a `status` field in the Task response, causing the caller to crash.
**Fix:** Always return `{'id': task.id, 'status': 'completed'|'failed', 'result': ...}`.

**Mistake:** Running both agents on the same port.
**Fix:** Use `--port 8000` and `--port 8001` for the two uvicorn processes.

---

## ✅ Checkpoint

- [ ] Finance Agent serves its Agent Card at `/.well-known/agent.json`
- [ ] Procurement Agent reads the Agent Card dynamically at runtime
- [ ] A PO request triggers a budget-reservation call to the Finance Agent via A2A
- [ ] Insufficient budget causes the Procurement Agent to return `failed` status
- [ ] Successful budget reservation returns a PO number
- [ ] Agents can run on separate machines by changing `FINANCE_AGENT_URL`
$md$ WHERE slug = 'ai-32-a2a-protocol';

UPDATE public.topics SET content_md = $md$
# 33 · SAP HANA Vector Engine

## What you'll build
A RAG (Retrieval-Augmented Generation) pipeline built entirely inside SAP HANA Cloud, using the native `VECTOR` column type and `COSINE_SIMILARITY` function — no external vector database required.

---

## Why this matters (enterprise context)
Most RAG architectures add a separate vector store (Pinecone, pgvector, Weaviate) alongside the main database. This creates two systems to maintain, two security models, and data duplication. SAP HANA Cloud 2024 adds first-class vector support directly in the SQL engine. Your SAP documents, their embeddings, and your transactional data all live in one database with one backup policy and one set of authorisations.

---

## Step 1 — Understand HANA Vector Columns

> SAP HANA Cloud stores embeddings as `VECTOR(1536)` columns — arrays of 32-bit floats. The built-in `COSINE_SIMILARITY(v1, v2)` function returns a value from -1 to 1. You can query it in SQL like any other function: `ORDER BY COSINE_SIMILARITY(embedding, ?) DESC`.

Key terms:
- **VECTOR(n)** — HANA column type storing a fixed-dimension float array; n=1536 for text-embedding-3-small
- **COSINE_SIMILARITY** — built-in HANA function; higher = more similar
- **TO_REAL_VECTOR** — converts a JSON array string to the VECTOR type for parameter binding
- **Embedding model** — maps text to a float vector; we use OpenAI's `text-embedding-3-small` via GenAI Hub
- **Top-k** — retrieve the k most similar vectors; typically k=3 for RAG context

---

## Step 2 — Create the HANA Vector Table

```sql
-- Run in SAP HANA Database Explorer or hdbsql
CREATE TABLE SAP_DOC_EMBEDDINGS (
    DOC_ID      NVARCHAR(50)   NOT NULL PRIMARY KEY,
    TITLE       NVARCHAR(500),
    CONTENT     NCLOB,
    EMBEDDING   VECTOR(1536),
    CREATED_AT  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**What each key line does:**
- `VECTOR(1536)` — reserves space for 1,536 floats; match this to your embedding model dimension
- `NCLOB` — stores the full document text; HANA can index CLOBs separately from vectors
- `PRIMARY KEY` on `DOC_ID` — prevents duplicate embeddings for the same document

---

## Step 3 — Ingest Documents with Embeddings

```python
import os, json
from dotenv import load_dotenv
import hdbcli.dbapi as hana
from openai import OpenAI

load_dotenv()

conn = hana.connect(
    address=os.environ['HANA_HOST'],
    port=443,
    user=os.environ['HANA_USER'],
    password=os.environ['HANA_PASS'],
    encrypt=True
)

openai = OpenAI(
    base_url=f'{os.environ["AICORE_BASE_URL"]}/inference/deployments/{os.environ["EMBEDDING_DEPLOYMENT_ID"]}',
    api_key=os.environ['AICORE_TOKEN']
)

SAP_DOCS = [
    {'id': 'DOC-001', 'title': 'MM60 Inventory Valuation Guide',
     'content': 'The MM60 report provides inventory valuation at plant level. '
                'Run it with movement type 101 to see GR-based valuations. '
                'The MBEW table holds the current stock value per valuation area.'},
    {'id': 'DOC-002', 'title': 'MIRO Invoice Verification Process',
     'content': 'MIRO is the SAP transaction for Logistics Invoice Verification. '
                'Post vendor invoices against POs. Tolerances are configured in OMR6. '
                'Blocked invoices land in MRBR for manual release.'},
    {'id': 'DOC-003', 'title': 'ME21N Purchase Order Creation',
     'content': 'ME21N is the SAP transaction to create a purchase order. '
                'Enter the vendor, purchasing org, and line items. '
                'The system checks open purchase requisitions automatically.'}
]

cursor = conn.cursor()

for doc in SAP_DOCS:
    emb_resp = openai.embeddings.create(
        model='text-embedding-3-small',
        input=doc['content']
    )
    vector = emb_resp.data[0].embedding
    vector_json = json.dumps(vector)

    cursor.execute(
        'UPSERT SAP_DOC_EMBEDDINGS (DOC_ID, TITLE, CONTENT, EMBEDDING) '
        'VALUES (?, ?, ?, TO_REAL_VECTOR(?)) WITH PRIMARY KEY',
        (doc['id'], doc['title'], doc['content'], vector_json)
    )
    print(f'Inserted {doc["id"]}')

conn.commit()
cursor.close()
```

**What each key line does:**
- `hdbcli.dbapi.connect(encrypt=True)` — HANA Cloud requires TLS; `encrypt=True` enables it
- `openai.embeddings.create(model='text-embedding-3-small', input=doc['content'])` — calls GenAI Hub embedding endpoint
- `json.dumps(vector)` — serialises the float list to a JSON string for HANA binding
- `TO_REAL_VECTOR(?)` — HANA function that parses the JSON array into the internal VECTOR type
- `UPSERT ... WITH PRIMARY KEY` — inserts or updates based on `DOC_ID`; safe to re-run

---

## Step 4 — Query with COSINE_SIMILARITY

```python
def semantic_search(query: str, top_k: int = 3) -> list:
    emb_resp = openai.embeddings.create(
        model='text-embedding-3-small',
        input=query
    )
    query_vector = json.dumps(emb_resp.data[0].embedding)

    cursor = conn.cursor()
    cursor.execute(
        'SELECT TOP ? DOC_ID, TITLE, CONTENT, '
        'COSINE_SIMILARITY(EMBEDDING, TO_REAL_VECTOR(?)) AS SCORE '
        'FROM SAP_DOC_EMBEDDINGS '
        'ORDER BY SCORE DESC',
        (top_k, query_vector)
    )
    rows = cursor.fetchall()
    cursor.close()
    return [{'id': r[0], 'title': r[1], 'content': r[2], 'score': float(r[3])} for r in rows]

results = semantic_search('How do I check the value of my warehouse stock?')
for r in results:
    print(f'{r["score"]:.3f}  {r["title"]}')
```

---

## Common mistakes

**Mistake:** Using `VECTOR` without specifying dimension, then inserting 1536-dim vectors into a 512-dim column.
**Fix:** Always match `VECTOR(n)` to your embedding model: 1536 for text-embedding-3-small, 3072 for text-embedding-3-large.

**Mistake:** Passing the raw Python list to the HANA binding instead of a JSON string.
**Fix:** Always `json.dumps(vector)` before passing to `TO_REAL_VECTOR(?)`.

**Mistake:** `ORDER BY COSINE_SIMILARITY DESC` without `TOP ?` causes a full table scan on large tables.
**Fix:** Use `SELECT TOP 5 ... ORDER BY SCORE DESC` so HANA can optimise the scan.

---

## ✅ Checkpoint

- [ ] `SAP_DOC_EMBEDDINGS` table created with `VECTOR(1536)` column
- [ ] Three documents ingested with real embedding vectors
- [ ] `COSINE_SIMILARITY` query returns results ordered by relevance score
- [ ] Query about stock valuation ranks DOC-001 (MM60) highest
- [ ] `UPSERT ... WITH PRIMARY KEY` re-run is idempotent
- [ ] Scores are between 0 and 1 (cosine similarity of normalised vectors)
$md$ WHERE slug = 'ai-33-hana-vector';

UPDATE public.topics SET content_md = $md$
# 34 · Document Information Extraction

## What you'll build
A Python script that uploads invoice PDFs to the SAP Document Information Extraction (DOX) BTP service and retrieves structured field values — vendor, invoice number, date, line items, and total — automatically.

---

## Why this matters (enterprise context)
SAP DOX is a pre-trained ML service on BTP that understands the layout of invoices, purchase orders, and receipts in dozens of languages. Instead of building and training your own OCR model, you call the REST API and get structured JSON back in seconds. The extracted fields can be fed directly into MIRO (logistics invoice verification) to pre-populate postings, cutting manual data entry by over 80%.

---

## Step 1 — Understand the DOX API Flow

> DOX uses an asynchronous job pattern: you POST a document to start a job, poll `GET /jobs/{id}` until status is `DONE`, then fetch the extracted fields with `GET /jobs/{id}/result`.

Key terms:
- **Job** — the asynchronous extraction unit; created with POST, polled with GET
- **Schema ID** — identifies which field set to extract; `SAP_invoice_schema_en` for English invoices
- **Extraction field** — a key-value pair from the document; e.g., `invoiceNumber`, `grossAmount`, `senderName`
- **Confidence** — a 0–1 score per field; below 0.8 is flagged for human review
- **Client ID** — DOX tenant segmentation; documents uploaded to one client are invisible to others

---

## Step 2 — Get DOX Service Credentials

From BTP cockpit:
1. Navigate to your DOX service instance
2. Create a service key → download the JSON
3. Extract `url`, `uaa.clientid`, `uaa.clientsecret`, `uaa.url`

```bash
DOX_URL=https://aiservices-dox.cfapps.eu10.hana.ondemand.com
DOX_CLIENT_ID=sb-ai-service-dox-...
DOX_CLIENT_SECRET=aBcDeFgH...
DOX_AUTH_URL=https://your-subdomain.authentication.eu10.hana.ondemand.com
DOX_CLIENT_ID_DOX=default
```

**What each key line does:**
- `DOX_URL` — the base URL of your DOX service instance
- `DOX_CLIENT_SECRET` — OAuth2 client credentials for service-to-service auth
- `DOX_AUTH_URL` — token endpoint; append `/oauth/token?grant_type=client_credentials`
- `DOX_CLIENT_ID_DOX` — the DOX client namespace for your documents; use `default` unless you need multi-tenancy

---

## Step 3 — Write the DOX Extraction Client

```python
import os, time, json
import httpx
from dotenv import load_dotenv

load_dotenv()

def get_dox_token() -> str:
    resp = httpx.post(
        f'{os.environ["DOX_AUTH_URL"]}/oauth/token',
        params={'grant_type': 'client_credentials'},
        auth=(os.environ['DOX_CLIENT_ID'], os.environ['DOX_CLIENT_SECRET'])
    )
    resp.raise_for_status()
    return resp.json()['access_token']

def extract_invoice(pdf_path: str) -> dict:
    token = get_dox_token()
    headers = {'Authorization': f'Bearer {token}'}
    base = os.environ['DOX_URL']
    client_id = os.environ['DOX_CLIENT_ID_DOX']

    with open(pdf_path, 'rb') as f:
        files = {'file': (os.path.basename(pdf_path), f, 'application/pdf')}
        data = {
            'options': json.dumps({
                'extraction': {'headerFields': ['invoiceNumber', 'invoiceDate',
                                                'grossAmount', 'currencyCode',
                                                'senderName', 'senderAddress'],
                               'lineItemFields': ['description', 'quantity',
                                                  'unitPrice', 'netAmount']},
                'clientId': client_id,
                'documentType': 'invoice',
                'schemaId': 'SAP_invoice_schema_en'
            })
        }
        post_resp = httpx.post(f'{base}/document/jobs', headers=headers,
                               files=files, data=data)
        post_resp.raise_for_status()
        job_id = post_resp.json()['id']
        print(f'Job created: {job_id}')

    for attempt in range(20):
        time.sleep(3)
        status_resp = httpx.get(f'{base}/document/jobs/{job_id}', headers=headers)
        status = status_resp.json().get('status')
        print(f'  Status: {status}')
        if status == 'DONE':
            break
        if status == 'FAILED':
            raise RuntimeError(f'DOX job failed: {status_resp.json()}')

    result_resp = httpx.get(f'{base}/document/jobs/{job_id}/result', headers=headers)
    result_resp.raise_for_status()
    return result_resp.json()

def format_extraction(result: dict) -> None:
    header = result.get('extraction', {}).get('headerFields', [])
    lines = result.get('extraction', {}).get('lineItems', [])

    print('\n=== Extracted Invoice Fields ===')
    for field in header:
        conf = field.get('confidence', 0)
        flag = ' ⚠ LOW CONFIDENCE' if conf < 0.8 else ''
        print(f'  {field["name"]}: {field["value"]} (confidence: {conf:.2f}){flag}')

    print('\n=== Line Items ===')
    for i, item in enumerate(lines, 1):
        fields = {f['name']: f['value'] for f in item.get('lineItemFields', [])}
        print(f'  {i}. {fields.get("description")} | qty: {fields.get("quantity")} | '
              f'unit: {fields.get("unitPrice")} | net: {fields.get("netAmount")}')

if __name__ == '__main__':
    result = extract_invoice('sample_invoice.pdf')
    format_extraction(result)
    with open('extracted_invoice.json', 'w') as f:
        json.dump(result, f, indent=2)
    print('\nFull result saved to extracted_invoice.json')
```

**What each key line does:**
- `get_dox_token()` — client credentials OAuth2 flow; DOX does not use user tokens
- `'schemaId': 'SAP_invoice_schema_en'` — tells DOX which pre-trained model to use
- `'headerFields': [...]` — the list of fields you want extracted from the header section
- `'lineItemFields': [...]` — per-line fields; DOX segments the table automatically
- `for attempt in range(20): time.sleep(3)` — poll every 3 seconds; most invoices finish in under 15 seconds
- `status == 'DONE'` — only then fetch the result; fetching early returns an empty extraction

---

## Step 4 — Run the Extractor

```bash
python dox_extractor.py
```

Expected output:

```
Job created: 7f3a1b2c-...
  Status: RUNNING
  Status: DONE

=== Extracted Invoice Fields ===
  invoiceNumber: INV-2025-04471 (confidence: 0.97)
  invoiceDate: 2025-03-15 (confidence: 0.95)
  grossAmount: 12350.00 (confidence: 0.99)
  senderName: Acme Supplies GmbH (confidence: 0.93)
```

---

## Common mistakes

**Mistake:** Fetching the result before status is `DONE`, getting an empty extraction.
**Fix:** Always poll until `status == 'DONE'` or `'FAILED'` before calling the result endpoint.

**Mistake:** Using the wrong `schemaId` for the language/document type.
**Fix:** Use `SAP_invoice_schema_en` for English invoices; DOX supports 40+ languages with separate schema IDs.

**Mistake:** Ignoring low-confidence fields and posting wrong values to MIRO.
**Fix:** Flag any field with confidence below 0.8 for human review before automation.

---

## ✅ Checkpoint

- [ ] OAuth2 token obtained from DOX auth endpoint without error
- [ ] Invoice PDF uploaded and job ID returned
- [ ] Polling loop waits for `DONE` status before fetching result
- [ ] At least 5 header fields extracted with confidence scores
- [ ] Line items parsed into a structured list
- [ ] Low-confidence fields are flagged in the output
$md$ WHERE slug = 'ai-34-dox-service';

UPDATE public.topics SET content_md = $md$
# 35 · Extending SAP Joule

## What you'll build
A custom Joule skill — a backend microservice deployed on BTP Cloud Foundry — that surfaces AI-generated procurement summaries and recommendations inside the SAP S/4HANA Joule assistant panel.

---

## Why this matters (enterprise context)
SAP Joule is the built-in AI assistant across the SAP product suite. Rather than asking users to leave S/4HANA to use a separate AI tool, you extend Joule directly. Custom skills let you inject domain-specific intelligence — your company's data, your approval rules, your phrasing — into the Joule panel that end users already know. The skill is invoked by natural language: "Joule, summarise my open purchase orders."

---

## Step 1 — Understand Joule Skill Architecture

> A Joule skill is an HTTP service registered in the SAP Build Work Zone Skill Registry. Joule routes user utterances to skills using intent matching. Your skill receives a payload with the user's message and context, processes it, and returns a structured response Joule renders in its panel.

Key terms:
- **Skill Registry** — SAP BTP service where you register your skill's endpoint and intent examples
- **Intent** — a sample phrase that triggers your skill; e.g., "summarise my open POs"
- **Skill endpoint** — the HTTPS URL Joule POSTs to when your skill is triggered
- **Response card** — the structured JSON your skill returns; Joule renders it as a formatted panel
- **Context** — Joule passes the logged-in user's ID and system context so your skill can personalise

---

## Step 2 — Set Up BTP Cloud Foundry App

```bash
cf login -a https://api.cf.eu10.hana.ondemand.com
cf target -o my-org -s dev
pip install flask gunicorn python-dotenv anthropic
```

`manifest.yml`:

```yaml
applications:
  - name: sap-joule-skill
    memory: 256M
    instances: 1
    buildpacks:
      - python_buildpack
    command: gunicorn -b 0.0.0.0:$PORT app:app
    env:
      AICORE_BASE_URL: https://api.ai.internalprod.eu-central-1.aws.ml.hana.ondemand.com/v2
      AICORE_DEPLOYMENT_ID: d1234abcd
      AICORE_TOKEN: eyJhbGciOiJSUzI1NiJ9...
      SAP_BASE_URL: https://my-s4.example.com/sap/opu/odata/sap
      SAP_USER: AI_SVC_USER
      SAP_PASS: S3cur3P@ss!
```

**What each key line does:**
- `gunicorn -b 0.0.0.0:$PORT` — BTP Cloud Foundry injects `$PORT`; bind to it for routing to work
- `256M` — sufficient for a Flask + Anthropic SDK app; increase to 512M if adding pandas for analytics
- `AICORE_TOKEN` — set this as a CF environment variable so it is not in source code

---

## Step 3 — Write the Joule Skill Service

```python
# app.py
import os, json
import httpx
from flask import Flask, request, jsonify
from anthropic import Anthropic

app = Flask(__name__)
anthropic = Anthropic(api_key=os.environ['AICORE_TOKEN'])

def fetch_open_pos(user_id: str) -> list:
    base = os.environ['SAP_BASE_URL']
    auth = (os.environ['SAP_USER'], os.environ['SAP_PASS'])
    headers = {'Accept': 'application/json', 'sap-client': '100'}
    url = f'{base}/API_PURCHASEORDER_PROCESS_SRV/A_PurchaseOrder'
    params = {
        '$filter': f'CreatedByUser eq \'{user_id}\' and PurchaseOrderStatus eq \'B\'',
        '$top': 10,
        '$select': 'PurchaseOrder,Supplier,NetPaymentAmount,DocumentCurrency,PurchasingOrganization'
    }
    with httpx.Client(auth=auth, headers=headers, verify=False) as client:
        r = client.get(url, params=params)
        r.raise_for_status()
        return r.json().get('d', {}).get('results', [])

def generate_summary(pos: list) -> str:
    if not pos:
        return 'You have no open purchase orders requiring attention.'
    po_list = '\n'.join(
        f'- PO {p["PurchaseOrder"]}: vendor {p["Supplier"]}, '
        f'{p["NetPaymentAmount"]} {p["DocumentCurrency"]}'
        for p in pos
    )
    response = anthropic.messages.create(
        model='claude-opus-4-5',
        max_tokens=400,
        messages=[{
            'role': 'user',
            'content': (
                f'Summarise these open SAP purchase orders in 2-3 sentences '
                f'and give one actionable recommendation:\n{po_list}'
            )
        }]
    )
    return response.content[0].text

@app.route('/skill/po-summary', methods=['POST'])
def po_summary_skill():
    body = request.get_json(force=True)
    user_id = body.get('context', {}).get('userId', 'UNKNOWN')
    pos = fetch_open_pos(user_id)
    summary = generate_summary(pos)
    return jsonify({
        'type': 'text',
        'content': summary,
        'metadata': {
            'skill': 'po-summary',
            'poCount': len(pos)
        }
    })

@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'ok'})

if __name__ == '__main__':
    app.run(port=int(os.environ.get('PORT', 5000)))
```

**What each key line does:**
- `body.get('context', {}).get('userId')` — Joule passes the logged-in SAP user ID so you can fetch their data
- `PurchaseOrderStatus eq 'B'` — OData filter for POs in `BLOCKED` / open status (adapt to your landscape)
- `anthropic.messages.create(...)` — calls Claude via GenAI Hub to generate the natural-language summary
- `jsonify({'type': 'text', 'content': summary})` — Joule expects a `type` field to know how to render
- `/health` endpoint — BTP health checks this URL; the app is considered healthy only when it returns 200

---

## Step 4 — Deploy and Register the Skill

```bash
cf push sap-joule-skill

# Register in Skill Registry (BTP Cockpit > Build Work Zone > Skills)
# Skill Name:     PO Summary
# Endpoint URL:   https://sap-joule-skill.cfapps.eu10.hana.ondemand.com/skill/po-summary
# Intent examples:
#   "summarise my open purchase orders"
#   "what POs are waiting for me"
#   "give me a PO overview"
```

---

## Common mistakes

**Mistake:** The skill endpoint returns 200 but Joule shows nothing because `type` field is missing.
**Fix:** Always include `'type': 'text'` (or `'card'`) in the response JSON.

**Mistake:** Hardcoding `PORT=5000` instead of reading `os.environ.get('PORT')`.
**Fix:** BTP assigns a random port; always bind to `$PORT`.

**Mistake:** The skill times out because the SAP OData call and LLM call run sequentially and take over 10 seconds.
**Fix:** Cache the OData result for 60 seconds or run the LLM call concurrently with `asyncio.gather`.

---

## ✅ Checkpoint

- [ ] `cf push` deploys the app without errors
- [ ] `/health` endpoint returns `{"status": "ok"}`
- [ ] `/skill/po-summary` returns a valid JSON response with `type` and `content` fields
- [ ] PO data is fetched for the correct user from the context payload
- [ ] Claude generates a coherent 2-3 sentence summary
- [ ] Skill is registered in BTP Work Zone Skill Registry with at least 3 intent examples
$md$ WHERE slug = 'ai-35-joule-extensions';

UPDATE public.topics SET content_md = $md$
# 36 · LLM Evaluation & Testing

## What you'll build
An evaluation suite that tests your SAP RAG pipeline using RAGAS metrics, the LLM-as-judge pattern, and a regression test harness — giving you a numeric score for faithfulness, answer relevance, and context precision.

---

## Why this matters (enterprise context)
Deploying an AI assistant in production without evaluation is like shipping SAP code without unit tests. When a prompt change breaks something, you need to know immediately. RAGAS provides four core metrics that measure whether your RAG system is hallucinating, retrieving the wrong context, or answering off-topic. LLM-as-judge lets a second model score open-ended answers that you cannot check with string matching.

---

## Step 1 — Understand Evaluation Metrics

> RAGAS measures RAG pipeline quality along four dimensions. You run these on a test dataset of (question, ground-truth answer, retrieved context, generated answer) tuples.

Key terms:
- **Faithfulness** — is every claim in the answer supported by the retrieved context? (0 to 1; 1 = no hallucinations)
- **Answer Relevance** — does the answer address the question? (1 = perfectly on-topic)
- **Context Precision** — how much of the retrieved context is actually relevant? (1 = no noise)
- **Context Recall** — does the retrieved context contain all information needed for the ground truth? (1 = complete)
- **LLM-as-judge** — a second LLM call that scores a response on a rubric; useful for open-ended quality

---

## Step 2 — Install Evaluation Libraries

```bash
pip install ragas datasets langchain-openai python-dotenv
```

**What each key line does:**
- `ragas` — the RAGAS framework; imports `evaluate`, `faithfulness`, `answer_relevancy`, `context_precision`
- `datasets` — HuggingFace datasets format that RAGAS expects for the test dataset
- `langchain-openai` — RAGAS uses LangChain internally to run the judge LLM calls

---

## Step 3 — Build the Evaluation Suite

```python
import os
from dotenv import load_dotenv
from datasets import Dataset
from ragas import evaluate
from ragas.metrics import faithfulness, answer_relevancy, context_precision, context_recall
from langchain_openai import ChatOpenAI, OpenAIEmbeddings

load_dotenv()

llm = ChatOpenAI(
    model='gpt-4o',
    base_url=f'{os.environ["AICORE_BASE_URL"]}/inference/deployments/{os.environ["AICORE_DEPLOYMENT_ID"]}',
    api_key=os.environ['AICORE_TOKEN'],
    temperature=0
)

embeddings = OpenAIEmbeddings(
    model='text-embedding-3-small',
    base_url=f'{os.environ["AICORE_BASE_URL"]}/inference/deployments/{os.environ["EMBEDDING_DEPLOYMENT_ID"]}',
    api_key=os.environ['AICORE_TOKEN']
)

SAP_TEST_CASES = [
    {
        'question': 'Which SAP table stores purchase order header data?',
        'ground_truth': 'The EKKO table stores SAP purchase order header data.',
        'answer': 'SAP purchase order header data is stored in the EKKO table. '
                  'The key fields are EBELN (PO number), LIFNR (vendor), and BUKRS (company code).',
        'contexts': [
            'EKKO is the SAP table for purchasing document headers. '
            'It contains fields EBELN (purchasing document number), '
            'LIFNR (vendor account number), BUKRS (company code), '
            'BSART (document type), and AEDAT (last change date).',
            'EKPO stores purchasing document item data. '
            'EKKO and EKPO are joined on MANDT and EBELN.'
        ]
    },
    {
        'question': 'How do I release a blocked invoice in SAP?',
        'ground_truth': 'Use transaction MRBR to release blocked invoices in SAP.',
        'answer': 'To release a blocked invoice in SAP, use transaction ME23N to view the PO '
                  'and check tolerance limits.',
        'contexts': [
            'MRBR is the SAP transaction for releasing blocked invoices. '
            'Navigate to MRBR, enter the invoice number, review the blocking reason, '
            'and click Release. Tolerances are set in OMR6.',
            'Invoice blocking in SAP occurs when price variances exceed tolerance limits '
            'configured in purchase order tolerance keys.'
        ]
    },
    {
        'question': 'What field in MARA stores the material base unit of measure?',
        'ground_truth': 'The field MARA-MEINS stores the base unit of measure.',
        'answer': 'The base unit of measure is stored in the MEINS field of the MARA table.',
        'contexts': [
            'MARA is the general material data table in SAP. '
            'Key fields include MATNR (material number), MATKL (material group), '
            'MEINS (base unit of measure), MTART (material type), and MBRSH (industry sector).',
            'MARC stores plant-specific material data. '
            'MARD stores storage location data. MARA holds the base unit in MEINS.'
        ]
    }
]

dataset = Dataset.from_list(SAP_TEST_CASES)

results = evaluate(
    dataset=dataset,
    metrics=[faithfulness, answer_relevancy, context_precision, context_recall],
    llm=llm,
    embeddings=embeddings
)

print('\n=== RAGAS Evaluation Results ===')
print(f'Faithfulness:      {results["faithfulness"]:.3f}')
print(f'Answer Relevancy:  {results["answer_relevancy"]:.3f}')
print(f'Context Precision: {results["context_precision"]:.3f}')
print(f'Context Recall:    {results["context_recall"]:.3f}')
print(f'\nOverall Score:     {sum(results[m] for m in ["faithfulness","answer_relevancy","context_precision","context_recall"])/4:.3f}')

LOW_THRESHOLD = 0.7
print('\n=== Failing Cases ===')
for i, row in enumerate(results.to_pandas().itertuples()):
    if row.faithfulness < LOW_THRESHOLD or row.answer_relevancy < LOW_THRESHOLD:
        print(f'  Case {i+1}: faithfulness={row.faithfulness:.2f}, relevancy={row.answer_relevancy:.2f}')
        print(f'    Q: {SAP_TEST_CASES[i]["question"]}')
```

**What each key line does:**
- `Dataset.from_list(SAP_TEST_CASES)` — converts your test tuples to the HuggingFace Dataset format RAGAS expects
- `evaluate(dataset=..., metrics=[...])` — runs all four metrics; each requires multiple internal LLM calls
- `faithfulness` metric — asks the LLM to check each claim in the answer against the context; detects hallucination
- `answer_relevancy` — generates questions from the answer and checks if they match the original question
- `results.to_pandas()` — converts results to a DataFrame so you can inspect per-case scores
- `LOW_THRESHOLD = 0.7` — flag anything below 0.7 for human review; adjust for your quality bar

---

## Step 4 — Run the Evaluation

```bash
python sap_rag_eval.py
```

Expected output:

```
=== RAGAS Evaluation Results ===
Faithfulness:      0.667
Answer Relevancy:  0.841
Context Precision: 0.833
Context Recall:    0.917

Overall Score:     0.814

=== Failing Cases ===
  Case 2: faithfulness=0.00, relevancy=0.72
    Q: How do I release a blocked invoice in SAP?
```

Case 2 fails faithfulness because the answer mentions ME23N but the context only mentions MRBR — a hallucination caught by RAGAS.

---

## Common mistakes

**Mistake:** Running evaluation on the same LLM that generated the answers, inflating faithfulness scores.
**Fix:** Use a different or stronger model as the judge; Claude as judge on GPT-4o answers works well.

**Mistake:** Providing too few test cases (fewer than 5) and over-interpreting the scores.
**Fix:** Use at least 20 test cases spanning different question types for meaningful metrics.

**Mistake:** `context_recall` is 0 for all cases because `ground_truth` was left empty.
**Fix:** `context_recall` requires a populated `ground_truth` field; it cannot be computed without it.

---

## ✅ Checkpoint

- [ ] RAGAS evaluation runs on the 3 test cases without API errors
- [ ] `faithfulness` score correctly identifies Case 2 as hallucinating (score close to 0)
- [ ] `answer_relevancy` score is above 0.8 for Cases 1 and 3
- [ ] `to_pandas()` returns one row per test case with per-metric columns
- [ ] Failing cases are printed with their question and scores
- [ ] Evaluation completes in under 60 seconds for 3 test cases
$md$ WHERE slug = 'ai-36-llm-eval';

UPDATE public.topics SET content_md = $md$
# 37 · Fine-Tuning on AI Core

## What you'll build
A fine-tuning pipeline that prepares SAP support-ticket JSONL training data, submits a fine-tuning job to SAP AI Core, monitors training progress, and registers the resulting model for inference.

---

## Why this matters (enterprise context)
A base GPT-4o model knows SAP in general terms. A fine-tuned model trained on 500 of your company's resolved support tickets knows your specific transaction codes, your error messages, and your resolution patterns. Fine-tuning on AI Core keeps your training data inside BTP — it never leaves your control plane — while producing a model that answers SAP questions with company-specific precision.

---

## Step 1 — Understand AI Core Fine-Tuning

> SAP AI Core accepts fine-tuning jobs via its `POST /lm/dataset` and `POST /lm/training-jobs` API. You upload a JSONL file to AI Core's artifact store, then submit a job referencing that artifact and a base model. AI Core runs the training on managed GPU infrastructure.

Key terms:
- **JSONL** — JSON Lines format; each line is one training example as `{"messages": [...]}`
- **Artifact** — a registered file in AI Core's artifact store (S3-backed); referenced by UUID in training jobs
- **Training configuration** — JSON specifying the base model, hyperparameters (epochs, LR), and artifact reference
- **Model checkpoint** — the output of fine-tuning; registered as a new AI Core artifact you can deploy
- **Execution** — AI Core's term for a training run; has status `PENDING`, `RUNNING`, `COMPLETED`, `DEAD`

---

## Step 2 — Prepare Training Data

```python
import json, os

SUPPORT_TICKETS = [
    {
        'ticket': 'Error: No matching records found in MARA for material Z-PUMP-001.',
        'resolution': 'Check client 100 vs client 200. Run MM60 in client 100. '
                      'Material Z-PUMP-001 is plant-specific to plant 1010.'
    },
    {
        'ticket': 'Invoice blocked with reason M: price variance exceeds tolerance.',
        'resolution': 'Check PO price in ME23N. Vendor changed price by 8%. '
                      'Tolerance key B1 allows 5%. Either update PO or release via MRBR with reason code 02.'
    },
    {
        'ticket': 'MIRO posting fails with error: account 191100 requires cost centre.',
        'resolution': 'Account 191100 is a GR/IR clearing account requiring a CO object. '
                      'Check OKB9 for default cost centre assignment. '
                      'Add cost centre CC-1010-MAINT to the GR/IR posting rule.'
    }
]

def prepare_jsonl(tickets: list, output_path: str) -> None:
    with open(output_path, 'w') as f:
        for t in tickets:
            example = {
                'messages': [
                    {'role': 'system',
                     'content': 'You are an expert SAP support engineer. '
                                'Diagnose SAP errors and provide step-by-step resolutions '
                                'citing exact transaction codes and table names.'},
                    {'role': 'user', 'content': t['ticket']},
                    {'role': 'assistant', 'content': t['resolution']}
                ]
            }
            f.write(json.dumps(example) + '\n')
    print(f'Wrote {len(tickets)} training examples to {output_path}')

prepare_jsonl(SUPPORT_TICKETS, 'sap_finetune_train.jsonl')
```

**What each key line does:**
- Each line is one `{"messages": [...]}` object — the ChatML format OpenAI and AI Core both accept
- `system` message — sets the persona; every training example shares the same system prompt
- `user` message — the SAP error or question (the input)
- `assistant` message — the ideal resolution (what we want the model to learn to produce)
- Writing one JSON object per line, not a JSON array — JSONL differs from JSON

---

## Step 3 — Submit the Fine-Tuning Job

```python
import httpx, os, time
from dotenv import load_dotenv

load_dotenv()
BASE = os.environ['AICORE_BASE_URL']
TOKEN = os.environ['AICORE_TOKEN']
HEADERS = {'Authorization': f'Bearer {TOKEN}', 'AI-Resource-Group': 'default'}

def upload_dataset(jsonl_path: str) -> str:
    with open(jsonl_path, 'rb') as f:
        resp = httpx.post(
            f'{BASE}/lm/dataset',
            headers=HEADERS,
            files={'file': ('training.jsonl', f, 'application/jsonl')},
            data={'name': 'sap-support-train-v1', 'type': 'text/jsonl'}
        )
        resp.raise_for_status()
        artifact_id = resp.json()['id']
        print(f'Dataset uploaded: artifact_id={artifact_id}')
        return artifact_id

def submit_training_job(artifact_id: str) -> str:
    payload = {
        'name': 'sap-support-finetune-v1',
        'trainingDatasetId': artifact_id,
        'baseModel': 'gpt-4o-mini-2024-07-18',
        'hyperParameters': {
            'n_epochs': 3,
            'learning_rate_multiplier': 0.1,
            'batch_size': 4
        }
    }
    resp = httpx.post(f'{BASE}/lm/training-jobs', headers=HEADERS, json=payload)
    resp.raise_for_status()
    job_id = resp.json()['id']
    print(f'Training job submitted: {job_id}')
    return job_id

def poll_training(job_id: str) -> dict:
    for i in range(60):
        time.sleep(30)
        resp = httpx.get(f'{BASE}/lm/training-jobs/{job_id}', headers=HEADERS)
        status = resp.json().get('status')
        trained_tokens = resp.json().get('trainedTokens', 0)
        print(f'  [{i*30}s] Status: {status}, tokens trained: {trained_tokens}')
        if status in ('COMPLETED', 'DEAD'):
            return resp.json()
    raise TimeoutError('Training did not complete within 30 minutes')

if __name__ == '__main__':
    artifact_id = upload_dataset('sap_finetune_train.jsonl')
    job_id = submit_training_job(artifact_id)
    result = poll_training(job_id)
    if result['status'] == 'COMPLETED':
        print(f'\nFine-tuned model ID: {result["fineTunedModel"]}')
        print('Register this model ID in AI Core deployments to serve it for inference.')
    else:
        print(f'Training failed: {result.get("statusDetails")}')
```

**What each key line does:**
- `'AI-Resource-Group': 'default'` — required header; AI Core multi-tenancy groups resources
- `upload_dataset()` — registers the JSONL as an AI Core artifact; the returned ID is referenced by the job
- `'baseModel': 'gpt-4o-mini-2024-07-18'` — pin the exact base model version for reproducibility
- `n_epochs=3` — number of passes through the training data; 3 is a safe default for small datasets
- `poll_training()` — polls every 30 seconds; real training runs take 5-30 minutes depending on dataset size
- `result['fineTunedModel']` — the model ID you deploy in AI Core to serve inference requests

---

## Step 4 — Run the Pipeline

```bash
python sap_finetune.py
```

---

## Common mistakes

**Mistake:** Training JSONL has fewer than 10 examples; AI Core rejects the job.
**Fix:** Use at least 10 examples; 50-500 is the practical sweet spot for domain adaptation.

**Mistake:** `assistant` messages are too short (one word), teaching the model to be terse.
**Fix:** Include full, detailed resolutions in training data; the model learns the length distribution.

**Mistake:** Using `gpt-4o` as the base model; only smaller models support fine-tuning in most deployments.
**Fix:** Use `gpt-4o-mini-2024-07-18` or `gpt-3.5-turbo`; check your AI Core deployment for available base models.

---

## ✅ Checkpoint

- [ ] JSONL file written with at least 3 valid training examples
- [ ] Dataset uploaded and artifact ID returned
- [ ] Training job submitted and job ID returned
- [ ] Polling loop detects `COMPLETED` status
- [ ] Fine-tuned model ID extracted from the result
- [ ] Model ID noted for use as a deployment base in AI Core
$md$ WHERE slug = 'ai-37-fine-tuning';

UPDATE public.topics SET content_md = $md$
# 38 · Speech & Audio (Whisper)

## What you'll build
A Python pipeline that transcribes SAP meeting recordings using the Whisper API, extracts action items with Claude, and posts them as SAP tasks via the API — turning meeting audio into tracked work automatically.

---

## Why this matters (enterprise context)
SAP project teams have daily standups, weekly steering committee meetings, and vendor calls where action items get lost in notes. Whisper transcribes meeting audio with word-level accuracy in 90+ languages. Claude extracts structured action items from the transcript. The SAP Task Management API creates tracked tasks with owners and due dates — all without human data entry. A 60-minute meeting produces a task list in under 2 minutes.

---

## Step 1 — Understand the Pipeline

> The pipeline has three stages: Audio → Transcript (Whisper), Transcript → Action Items (Claude), Action Items → SAP Tasks (OData API). Each stage produces structured output consumed by the next.

Key terms:
- **Whisper** — OpenAI's speech recognition model; `whisper-1` via API handles files up to 25 MB
- **Segments** — Whisper splits long audio into timestamped segments; useful for speaker attribution
- **Action item** — a structured task with owner, description, and due date extracted by Claude
- **SAP Task Management** — BTP service with an OData API for creating and tracking tasks
- **chunking** — splitting audio files larger than 25 MB into overlapping segments before sending to Whisper

---

## Step 2 — Install Dependencies

```bash
pip install openai anthropic pydub python-dotenv httpx
apt-get install -y ffmpeg   # required by pydub for audio processing
```

Add to `.env`:

```bash
AICORE_BASE_URL=https://api.ai.internalprod.eu-central-1.aws.ml.hana.ondemand.com/v2
WHISPER_DEPLOYMENT_ID=d5678efgh
CLAUDE_DEPLOYMENT_ID=d1234abcd
AICORE_TOKEN=eyJhbGciOiJSUzI1NiJ9...
SAP_TASK_BASE_URL=https://my-s4.example.com/sap/opu/odata/sap/C_TASK_SRV
SAP_USER=AI_SVC_USER
SAP_PASS=S3cur3P@ss!
```

**What each key line does:**
- `pydub` — audio file manipulation; used to split large files and convert formats
- `ffmpeg` — pydub's audio backend; must be installed at OS level
- `WHISPER_DEPLOYMENT_ID` — your Whisper model deployment in AI Core GenAI Hub

---

## Step 3 — Write the Meeting Pipeline

```python
import os, json
from pathlib import Path
from dotenv import load_dotenv
from openai import OpenAI
from anthropic import Anthropic
import httpx

load_dotenv()

whisper_client = OpenAI(
    base_url=f'{os.environ["AICORE_BASE_URL"]}/inference/deployments/{os.environ["WHISPER_DEPLOYMENT_ID"]}',
    api_key=os.environ['AICORE_TOKEN']
)

claude_client = Anthropic(api_key=os.environ['AICORE_TOKEN'])

def transcribe_audio(audio_path: str) -> str:
    path = Path(audio_path)
    print(f'Transcribing {path.name} ({path.stat().st_size / 1024 / 1024:.1f} MB)...')
    with open(audio_path, 'rb') as f:
        transcript = whisper_client.audio.transcriptions.create(
            model='whisper-1',
            file=f,
            response_format='text',
            language='en'
        )
    print(f'Transcript length: {len(transcript)} characters')
    return transcript

def extract_action_items(transcript: str, meeting_date: str) -> list:
    response = claude_client.messages.create(
        model='claude-opus-4-5',
        max_tokens=1024,
        messages=[{
            'role': 'user',
            'content': (
                f'Extract all action items from this SAP project meeting transcript. '
                f'Meeting date: {meeting_date}.\n\n'
                f'Return a JSON array where each element has:\n'
                f'  - "owner": the person responsible (first and last name)\n'
                f'  - "task": a clear one-sentence description of the action\n'
                f'  - "due_date": ISO date string (estimate from context; default to 7 days from meeting)\n'
                f'  - "priority": "HIGH", "MEDIUM", or "LOW"\n\n'
                f'Transcript:\n{transcript}\n\n'
                f'Return only the JSON array, no explanation.'
            )
        }]
    )
    raw = response.content[0].text.strip()
    if raw.startswith('```'):
        raw = raw.split('```')[1]
        if raw.startswith('json'):
            raw = raw[4:]
    return json.loads(raw.strip())

def post_sap_task(item: dict) -> str:
    auth = (os.environ['SAP_USER'], os.environ['SAP_PASS'])
    headers = {'Accept': 'application/json', 'Content-Type': 'application/json',
               'sap-client': '100'}
    payload = {
        'TaskName': item['task'][:50],
        'TaskDescription': item['task'],
        'ProcessorId': item['owner'].replace(' ', '.').upper(),
        'DueDate': f'/Date({_to_epoch_ms(item["due_date"])})/',
        'Priority': {'HIGH': '1', 'MEDIUM': '2', 'LOW': '3'}.get(item['priority'], '2'),
        'Status': 'OPEN'
    }
    with httpx.Client(auth=auth, headers=headers, verify=False) as client:
        r = client.post(f'{os.environ["SAP_TASK_BASE_URL"]}/Task', json=payload)
        r.raise_for_status()
        task_id = r.json().get('d', {}).get('TaskId', 'UNKNOWN')
        return task_id

def _to_epoch_ms(date_str: str) -> int:
    from datetime import datetime
    dt = datetime.strptime(date_str, '%Y-%m-%d')
    return int(dt.timestamp() * 1000)

def process_meeting(audio_path: str, meeting_date: str) -> None:
    transcript = transcribe_audio(audio_path)
    print('\nExtracting action items...')
    items = extract_action_items(transcript, meeting_date)
    print(f'Found {len(items)} action items')

    for item in items:
        print(f'\n  Task: {item["task"]}')
        print(f'  Owner: {item["owner"]} | Due: {item["due_date"]} | Priority: {item["priority"]}')
        task_id = post_sap_task(item)
        print(f'  -> SAP Task created: {task_id}')

if __name__ == '__main__':
    process_meeting('steering_committee_2025_03_15.mp3', '2025-03-15')
```

**What each key line does:**
- `response_format='text'` — returns the transcript as a plain string; use `'verbose_json'` for timestamps
- `language='en'` — skip auto-detection for a small speed gain; remove this for multilingual meetings
- `json.loads(raw.strip())` — Claude returns JSON inside a code fence; the strip logic removes it
- `ProcessorId: owner.replace(' ', '.').upper()` — converts "John Smith" to "JOHN.SMITH" matching SAP user IDs
- `f'/Date({epoch_ms})/'` — SAP OData date format for DateTime fields; milliseconds since Unix epoch

---

## Step 4 — Run the Pipeline

```bash
python sap_meeting_pipeline.py
```

Expected output:

```
Transcribing steering_committee_2025_03_15.mp3 (18.3 MB)...
Transcript length: 8420 characters
Extracting action items...
Found 4 action items

  Task: Update the vendor master for Siemens AG with new payment terms
  Owner: Maria Braun | Due: 2025-03-22 | Priority: HIGH
  -> SAP Task created: TASK-00012345
```

---

## Common mistakes

**Mistake:** Audio file exceeds 25 MB and Whisper API returns a 400 error.
**Fix:** Use pydub to split the file into 20-minute chunks with 30-second overlap before sending.

**Mistake:** Claude returns a JSON array wrapped in a markdown code fence and `json.loads` fails.
**Fix:** Strip the code fence markers before parsing; the strip logic in the code handles this.

**Mistake:** SAP user IDs do not match the "FirstName.LastName" pattern and tasks post with wrong owner.
**Fix:** Build a lookup table mapping speaker names to SAP user IDs; pass it in the Claude prompt.

---

## ✅ Checkpoint

- [ ] Whisper transcribes a test audio file and returns readable text
- [ ] Claude extracts at least 2 action items from the transcript as valid JSON
- [ ] JSON parsing handles the code-fence wrapper correctly
- [ ] SAP task created with correct owner, due date, and priority
- [ ] Pipeline completes end-to-end in under 2 minutes for a 30-minute recording
- [ ] Error logged if Whisper returns empty transcript (silent or non-speech audio)
$md$ WHERE slug = 'ai-38-whisper';

UPDATE public.topics SET content_md = $md$
# 39 · CAP AI SDK (TypeScript)

## What you'll build
A TypeScript CAP (Cloud Application Programming) service that uses the official `@sap-ai-sdk/foundation-models` package to call LLMs with typed clients, built-in GenAI Hub auth, streaming responses, and structured error handling.

---

## Why this matters (enterprise context)
The `@sap-ai-sdk` package is SAP's official TypeScript SDK for AI Core and the GenAI Hub. It handles OAuth2 token refresh, retry logic, streaming, and destination lookup automatically. Compared to raw `fetch` calls against the GenAI Hub API, the SDK reduces boilerplate by 80% and is the approach SAP recommends in production CAP applications. It is maintained by SAP's AI foundation team and is updated with each new model.

---

## Step 1 — Understand CAP + AI SDK Integration

> In a CAP project, AI calls live in service handler files. The `@sap-ai-sdk/foundation-models` package provides a typed `AzureOpenAiChatClient` (and `OpenAiChatClient`) that reads credentials from the bound AI Core service instance automatically.

Key terms:
- **CAP** — SAP Cloud Application Programming Model; Node.js/TypeScript framework for BTP services
- **`@sap-ai-sdk/foundation-models`** — official SAP package; wraps GenAI Hub LLM endpoints
- **`AzureOpenAiChatClient`** — the primary client class; constructor takes the deployment ID
- **Streaming** — `client.stream()` yields response tokens as they arrive; reduces perceived latency
- **Destination** — a BTP named connection; the SDK resolves it automatically from the environment

---

## Step 2 — Scaffold the CAP Project

```bash
npm install -g @sap/cds-dk
cds init sap-ai-cap-service --add typescript
cd sap-ai-cap-service
npm install @sap-ai-sdk/foundation-models @sap-ai-sdk/ai-core
npm install -D typescript ts-node @types/node
```

`package.json` scripts section:

```json
{
  "scripts": {
    "start": "cds-ts serve",
    "build": "cds build && tsc",
    "watch": "cds-ts watch"
  }
}
```

**What each key line does:**
- `cds init --add typescript` — generates tsconfig.json and wires ts-node into the CDS runtime
- `@sap-ai-sdk/foundation-models` — the LLM client package; installs `AzureOpenAiChatClient`
- `@sap-ai-sdk/ai-core` — core utilities including credential resolution from bound service instances
- `cds-ts serve` — starts the CAP server with TypeScript compilation on the fly

---

## Step 3 — Define the Service Schema

`srv/ai-service.cds`:

```cds
service AIService @(path: '/ai') {
  action summarizePO(poNumber: String) returns String;
  action classifyTicket(ticketText: String) returns {
    category: String;
    priority: String;
    suggestedAction: String;
  };
}
```

---

## Step 4 — Write the TypeScript Service Handler

`srv/ai-service.ts`:

```typescript
import cds from '@sap/cds';
import { AzureOpenAiChatClient } from '@sap-ai-sdk/foundation-models';

const DEPLOYMENT_ID = process.env.AICORE_DEPLOYMENT_ID || '';

function getClient(): AzureOpenAiChatClient {
  return new AzureOpenAiChatClient({ deploymentId: DEPLOYMENT_ID });
}

module.exports = cds.service.impl(async function (srv: any) {

  srv.on('summarizePO', async (req: any) => {
    const { poNumber } = req.data;
    const client = getClient();

    const response = await client.run({
      messages: [
        {
          role: 'system',
          content: 'You are an SAP procurement expert. Summarise SAP purchase orders in 2 sentences.'
        },
        {
          role: 'user',
          content: `Summarise purchase order ${poNumber}. ` +
                   'Include vendor, total value, and status. ' +
                   'If you do not have real data, state that this is a demo summary.'
        }
      ],
      max_tokens: 200,
      temperature: 0.1
    });

    const content = response.getContent();
    if (!content) throw new cds.error('AI returned empty response');
    return content;
  });

  srv.on('classifyTicket', async (req: any) => {
    const { ticketText } = req.data;
    const client = getClient();

    const response = await client.run({
      messages: [
        {
          role: 'system',
          content: 'You are an SAP support classifier. ' +
                   'Return a JSON object with keys: category, priority, suggestedAction. ' +
                   'category must be one of: MM, FI, SD, BASIS, ABAP, OTHER. ' +
                   'priority must be: HIGH, MEDIUM, or LOW. ' +
                   'Return only the JSON object, no markdown.'
        },
        { role: 'user', content: ticketText }
      ],
      max_tokens: 150,
      temperature: 0
    });

    const raw = response.getContent() || '{}';
    try {
      return JSON.parse(raw);
    } catch {
      throw new cds.error(`AI returned invalid JSON: ${raw}`);
    }
  });

});
```

**What each key line does:**
- `new AzureOpenAiChatClient({ deploymentId: DEPLOYMENT_ID })` — the SDK reads the bound AI Core service credentials automatically from the environment; no explicit auth code needed
- `client.run({ messages: [...] })` — typed call; TypeScript enforces the message shape at compile time
- `response.getContent()` — helper method on the SDK response; extracts the first choice's message content
- `temperature: 0` for classification — deterministic output is essential for category/priority parsing
- `throw new cds.error(...)` — CDS error type; CAP translates it to the correct HTTP status code automatically
- `JSON.parse(raw)` in a try/catch — LLM output is never fully trusted; always handle parse failures

---

## Step 5 — Run and Test

```bash
cds-ts watch
```

```bash
# Test summarizePO
curl -X POST http://localhost:4004/ai/summarizePO \
  -H 'Content-Type: application/json' \
  -d '{"poNumber": "4500012345"}'

# Test classifyTicket
curl -X POST http://localhost:4004/ai/classifyTicket \
  -H 'Content-Type: application/json' \
  -d '{"ticketText": "MIRO invoice blocked with reason M: price variance 12%"}'
```

Expected response for `classifyTicket`:

```json
{"value": {"category": "MM", "priority": "HIGH", "suggestedAction": "Check PO price in ME23N and verify tolerance key in OMR6."}}
```

---

## Common mistakes

**Mistake:** `AzureOpenAiChatClient` constructor fails because `AICORE_DEPLOYMENT_ID` is undefined.
**Fix:** Set the environment variable in `.env` or `default-env.json`; CDS loads `.env` automatically in development.

**Mistake:** `response.getContent()` returns `null` when the model hits `max_tokens` and stops mid-sentence.
**Fix:** Increase `max_tokens` or check `response.getFinishReason()`; handle `'length'` finish reason explicitly.

**Mistake:** TypeScript compilation fails because `@sap-ai-sdk` types are incompatible with older tsconfig targets.
**Fix:** Set `"target": "ES2022"` and `"module": "CommonJS"` in `tsconfig.json` for CAP compatibility.

---

## ✅ Checkpoint

- [ ] `cds-ts watch` starts without TypeScript errors
- [ ] `summarizePO` returns a non-empty string response from GenAI Hub
- [ ] `classifyTicket` returns valid JSON with all three required keys
- [ ] Invalid JSON from the LLM is caught and returns a CDS error, not a 500 crash
- [ ] No hardcoded credentials appear in source code
- [ ] SDK handles token refresh automatically (test by waiting past token expiry)
$md$ WHERE slug = 'ai-39-cap-ai-sdk';

UPDATE public.topics SET content_md = $md$
# 40 · Cost Optimization

## What you'll build
A cost analysis and optimization toolkit that measures token spend across your SAP AI integrations, implements prompt caching, routes simple tasks to cheaper models, and applies batching — targeting a 60%+ reduction in monthly AI API costs.

---

## Why this matters (enterprise context)
A production SAP AI assistant handling 10,000 queries per day at GPT-4o pricing can cost EUR 15,000 per month or more. Three techniques combined typically cut this by 60-80%: prompt caching (reuse expensive system prompts), model routing (use GPT-4o-mini for simple queries), and request batching (use the Batch API for non-realtime jobs). Understanding token economics is now a required skill for any enterprise AI architect.

---

## Step 1 — Understand Token Cost Drivers

> AI API costs are `(input_tokens * input_price) + (output_tokens * output_price)` per request. The four levers are: model choice, system prompt length, output length, and cache hits.

Key terms:
- **Prompt caching** — Anthropic and OpenAI cache the prefix of repeated system prompts; cache hits cost 10% of full input price
- **Cache read tokens** — tokens served from cache; billed at a steep discount
- **Model routing** — classify the query complexity first, then dispatch to the cheapest capable model
- **Batch API** — OpenAI's `/v1/batches` endpoint; 50% discount, up to 24-hour latency acceptable
- **Token budget** — setting `max_tokens` prevents runaway output costs on open-ended prompts

---

## Step 2 — Measure Current Costs

```python
import os, json
from dataclasses import dataclass, field
from datetime import datetime
from dotenv import load_dotenv
from anthropic import Anthropic

load_dotenv()
client = Anthropic(api_key=os.environ['AICORE_TOKEN'])

PRICING = {
    'claude-opus-4-5':     {'input': 15.00, 'output': 75.00, 'cache_read': 1.50, 'cache_write': 18.75},
    'claude-sonnet-4-5':   {'input':  3.00, 'output': 15.00, 'cache_read': 0.30, 'cache_write':  3.75},
    'claude-haiku-3-5':    {'input':  0.80, 'output':  4.00, 'cache_read': 0.08, 'cache_write':  1.00},
}

@dataclass
class CostTracker:
    model: str
    requests: int = 0
    input_tokens: int = 0
    output_tokens: int = 0
    cache_read_tokens: int = 0
    cache_write_tokens: int = 0
    total_cost_usd: float = 0.0

    def record(self, usage) -> float:
        self.requests += 1
        p = PRICING.get(self.model, PRICING['claude-sonnet-4-5'])
        it = getattr(usage, 'input_tokens', 0)
        ot = getattr(usage, 'output_tokens', 0)
        cr = getattr(usage, 'cache_read_input_tokens', 0)
        cw = getattr(usage, 'cache_creation_input_tokens', 0)
        self.input_tokens += it
        self.output_tokens += ot
        self.cache_read_tokens += cr
        self.cache_write_tokens += cw
        cost = ((it - cr) * p['input'] + ot * p['output'] +
                cr * p['cache_read'] + cw * p['cache_write']) / 1_000_000
        self.total_cost_usd += cost
        return cost

    def report(self) -> str:
        return (
            f'Model: {self.model}\n'
            f'Requests: {self.requests}\n'
            f'Input tokens: {self.input_tokens:,}\n'
            f'Output tokens: {self.output_tokens:,}\n'
            f'Cache read tokens: {self.cache_read_tokens:,}\n'
            f'Total cost: ${self.total_cost_usd:.4f}'
        )

tracker = CostTracker(model='claude-opus-4-5')
```

**What each key line does:**
- `PRICING` dict — stores per-million-token prices for each model; update when Anthropic changes pricing
- `cache_read_input_tokens` — appears in the usage object when prompt caching is active; billed at 10% of input price
- `cache_creation_input_tokens` — tokens written to cache on the first request; billed at 125% of input price once
- `(it - cr)` — subtract cache reads from regular input to avoid double-counting
- `/1_000_000` — prices are per million tokens; divide to get per-request cost

---

## Step 3 — Implement Prompt Caching and Model Routing

```python
SAP_SYSTEM_PROMPT = (
    'You are an expert SAP consultant specialising in MM, FI, SD, and ABAP. '
    'Answer questions citing exact SAP transaction codes, table names, and field names. '
    'For simple lookup questions (single transaction or table) be brief. '
    'For complex questions involving multiple modules, be thorough.\n\n'
    'SAP Module Reference:\n'
    'MM (Materials Management): ME21N, ME23N, MIGO, MIRO, MB51, MM60\n'
    'FI (Finance): FB01, FB60, F110, FS10N, FAGLB03, FBL1N\n'
    'SD (Sales): VA01, VA03, VL01N, VF01, ME2M, XD01\n'
    'BASIS: SM50, SM66, ST05, STMS, SCC4, SE06\n'
)

def classify_complexity(question: str) -> str:
    keywords_simple = ['what is', 'which table', 'which field', 'transaction code for',
                        'tcode for', 'what does', 'definition of']
    q_lower = question.lower()
    if any(k in q_lower for k in keywords_simple) and len(question) < 100:
        return 'simple'
    return 'complex'

def route_model(complexity: str) -> str:
    return 'claude-haiku-3-5' if complexity == 'simple' else 'claude-opus-4-5'

def ask_sap_question(question: str, use_cache: bool = True) -> tuple:
    complexity = classify_complexity(question)
    model = route_model(complexity)
    local_tracker = CostTracker(model=model)

    system_block = {'type': 'text', 'text': SAP_SYSTEM_PROMPT}
    if use_cache:
        system_block['cache_control'] = {'type': 'ephemeral'}

    response = client.messages.create(
        model=model,
        max_tokens=300 if complexity == 'simple' else 800,
        system=[system_block],
        messages=[{'role': 'user', 'content': question}]
    )

    cost = local_tracker.record(response.usage)
    tracker.record(response.usage)
    return response.content[0].text, cost, model

QUESTIONS = [
    'What transaction code creates a purchase order in SAP?',
    'Explain the three-way match process in SAP and which tables are involved.',
    'What field in MARA stores the base unit of measure?',
    'How do I set up automatic payment runs in FI, including the configuration steps for F110?',
    'What is MIRO?',
    'How does goods receipt posting affect stock valuation in MBEW and what movement types are involved?'
]

print('=== SAP AI Cost Optimisation Demo ===\n')
total_without_optimisation = 0.0

for q in QUESTIONS:
    answer, cost, model = ask_sap_question(q, use_cache=True)
    naive_cost = (len(SAP_SYSTEM_PROMPT.split()) * 1.3 + 50) / 1000 * PRICING['claude-opus-4-5']['input'] / 1000
    total_without_optimisation += naive_cost
    complexity = classify_complexity(q)
    print(f'Q: {q[:60]}...')
    print(f'   Model: {model} ({complexity}) | Cost: ${cost:.5f}')
    print(f'   A: {answer[:100]}...\n')

print(tracker.report())
print(f'\nEstimated naive cost (all Opus, no cache): ${total_without_optimisation:.4f}')
print(f'Actual cost with optimisations:           ${tracker.total_cost_usd:.4f}')
savings = (1 - tracker.total_cost_usd / max(total_without_optimisation, 0.0001)) * 100
print(f'Savings: {savings:.1f}%')
```

**What each key line does:**
- `'cache_control': {'type': 'ephemeral'}` — tells Anthropic to cache the system prompt prefix; required for cache hits on repeated calls
- `classify_complexity()` — simple keyword heuristic; replace with a real classifier for production
- `route_model()` — simple questions go to Haiku (10x cheaper than Opus); complex to Opus
- `max_tokens=300 if complexity == 'simple'` — caps output for simple lookups; prevents 800-token answers to "what is MIRO?"
- `tracker.record(response.usage)` — accumulates totals across the session for the final report

---

## Step 4 — Run the Cost Analyzer

```bash
python sap_cost_optimizer.py
```

Expected output on 6 questions:

```
Q: What transaction code creates a purchase order in SAP?...
   Model: claude-haiku-3-5 (simple) | Cost: $0.00008
Q: Explain the three-way match process in SAP...
   Model: claude-opus-4-5 (complex) | Cost: $0.00124

Estimated naive cost (all Opus, no cache): $0.00842
Actual cost with optimisations:            $0.00289
Savings: 65.7%
```

---

## Common mistakes

**Mistake:** Setting `cache_control` but always changing the first part of the system prompt, getting zero cache hits.
**Fix:** The cached prefix must be identical across calls; put dynamic content at the END of the system prompt, after the static instructions.

**Mistake:** Routing all short questions to Haiku, including multi-step ABAP debugging requests.
**Fix:** Test your classifier on 50 real user questions before deploying; add a complexity override for questions containing "how to configure" or "step by step".

**Mistake:** Setting `max_tokens=50` on complex questions, truncating answers mid-sentence.
**Fix:** Use two `max_tokens` tiers (300 and 800) as shown; add a third tier (2000) for code generation requests.

---

## ✅ Checkpoint

- [ ] `CostTracker.record()` correctly calculates cost for a single API call
- [ ] Simple questions route to `claude-haiku-3-5` automatically
- [ ] Complex questions route to `claude-opus-4-5`
- [ ] `cache_creation_input_tokens` appears in usage on the first call (cache write)
- [ ] `cache_read_input_tokens` appears in usage on the second identical call (cache hit)
- [ ] Final savings percentage is at least 50% compared to the naive baseline
$md$ WHERE slug = 'ai-40-cost-optimization';
