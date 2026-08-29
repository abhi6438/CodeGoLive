"""
Project: SAP GenAI Hub Integration Series
Topic:   29_mcp_client
Goal:    Connect to MCP server, discover tools, run agentic loop with GenAI Hub
Requirements: pip install mcp requests
"""

import asyncio, json, os, subprocess, requests
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client

BASE    = os.environ["AICORE_BASE_URL"]
TOKEN   = os.environ["AICORE_TOKEN"]
DEPID   = os.environ["AICORE_DEPLOYMENT_ID"]
RG      = os.environ.get("AICORE_RG", "default")
HEADERS = {"Authorization": f"Bearer {TOKEN}", "Content-Type": "application/json", "AI-Resource-Group": RG}
URL     = f"{BASE}/inference/deployments/{DEPID}/chat/completions"


def mcp_tool_to_openai(tool) -> dict:
    return {
        "type": "function",
        "function": {
            "name": tool.name,
            "description": tool.description,
            "parameters": tool.inputSchema,
        },
    }


def call_llm(messages: list, tools: list) -> dict:
    payload = {"model": "gpt-4o", "messages": messages, "tools": tools, "tool_choice": "auto"}
    r = requests.post(URL, headers=HEADERS, json=payload, timeout=60)
    r.raise_for_status()
    return r.json()["choices"][0]["message"]


async def run_agent(user_query: str):
    server_params = StdioServerParameters(command="python3", args=["28_mcp_server.py"])

    async with stdio_client(server_params) as (read, write):
        async with ClientSession(read, write) as session:
            await session.initialize()

            tools_list = await session.list_tools()
            openai_tools = [mcp_tool_to_openai(t) for t in tools_list.tools]
            print(f"Discovered {len(openai_tools)} tools: {[t['function']['name'] for t in openai_tools]}")

            messages = [
                {"role": "system", "content": "You are an SAP assistant. Use the provided tools to answer queries."},
                {"role": "user", "content": user_query},
            ]

            for iteration in range(5):
                response = call_llm(messages, openai_tools)
                messages.append(response)

                if response.get("tool_calls"):
                    for tc in response["tool_calls"]:
                        fn_name = tc["function"]["name"]
                        fn_args = json.loads(tc["function"]["arguments"])
                        print(f"  Calling tool: {fn_name}({fn_args})")

                        result = await session.call_tool(fn_name, fn_args)
                        tool_result = result.content[0].text if result.content else "{}"

                        messages.append({
                            "role": "tool",
                            "tool_call_id": tc["id"],
                            "content": tool_result,
                        })
                else:
                    print(f"\nFinal answer:\n{response['content']}")
                    break


if __name__ == "__main__":
    query = "What is the stock for material MAT-001 at plant 1000? Also get open POs for company code 1000."
    asyncio.run(run_agent(query))
