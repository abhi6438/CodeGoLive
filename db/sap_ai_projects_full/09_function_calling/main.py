"""
Project: SAP AI Core Python Examples
Topic:   09_function_calling
Goal:    Agentic loop with 2 mock SAP functions (get_open_pos, get_material_stock).
         Run until no more tool calls are requested.
"""

import requests, json
from config import HEADERS, URL, TOOLS

def mock_tool(name, args):
    if name == "get_open_purchase_orders":
        return json.dumps([
            {"po": "4500123456", "material": "PUMP-001", "qty": 10, "plant": "1000"},
            {"po": "4500123457", "material": "VALVE-007", "qty": 5,  "plant": "1000"},
        ])
    if name == "get_material_stock":
        return json.dumps({"material": args["material_id"], "plant": args["plant"], "stock": 3, "unit": "EA"})
    return json.dumps({"error": "unknown tool"})

def run_agent(user_request):
    messages = [
        {"role": "system", "content": "You are an SAP procurement assistant. Use tools to answer accurately."},
        {"role": "user", "content": user_request},
    ]
    for _ in range(6):
        r = requests.post(URL, headers=HEADERS, json={
            "model": "gpt-4o", "messages": messages, "tools": TOOLS, "max_tokens": 400,
        }, timeout=30)
        r.raise_for_status()
        msg = r.json()["choices"][0]["message"]
        messages.append(msg)
        if not msg.get("tool_calls"):
            return msg["content"]
        for tc in msg["tool_calls"]:
            result = mock_tool(tc["function"]["name"], json.loads(tc["function"]["arguments"]))
            messages.append({"role": "tool", "tool_call_id": tc["id"], "content": result})
    return "Max iterations reached."

if __name__ == "__main__":
    request = "Check open POs for vendor 100045, then verify we have enough stock for PUMP-001 in plant 1000."
    print("User:", request)
    print("Agent:", run_agent(request))
