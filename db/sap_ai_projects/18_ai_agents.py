"""
Project: SAP AI Core Python Examples
Topic:   18_ai_agents
Goal:    Autonomous procurement agent with 3 tools. Agentic loop until task is complete.
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

TOOLS = [
    {"type": "function", "function": {
        "name": "check_material_availability",
        "description": "Check if a material is available in sufficient quantity in a plant.",
        "parameters": {"type": "object", "properties": {
            "material_id": {"type": "string"}, "plant": {"type": "string"}, "quantity": {"type": "number"},
        }, "required": ["material_id", "plant", "quantity"]},
    }},
    {"type": "function", "function": {
        "name": "create_purchase_requisition",
        "description": "Create a purchase requisition in SAP MM for materials to be procured.",
        "parameters": {"type": "object", "properties": {
            "material_id": {"type": "string"}, "quantity": {"type": "number"},
            "plant": {"type": "string"}, "required_date": {"type": "string"},
        }, "required": ["material_id", "quantity", "plant", "required_date"]},
    }},
    {"type": "function", "function": {
        "name": "get_approved_vendors",
        "description": "Returns list of approved vendors for a given material.",
        "parameters": {"type": "object", "properties": {
            "material_id": {"type": "string"},
        }, "required": ["material_id"]},
    }},
]

def mock_tool(name, args):
    if name == "check_material_availability":
        in_stock = args["quantity"] <= 5
        return json.dumps({"material": args["material_id"], "plant": args["plant"],
                           "available": in_stock, "current_stock": 5, "requested": args["quantity"]})
    if name == "create_purchase_requisition":
        return json.dumps({"status": "created", "pr_number": "PR2024-0042",
                           "material": args["material_id"], "qty": args["quantity"]})
    if name == "get_approved_vendors":
        return json.dumps({"material": args["material_id"],
                           "vendors": [{"id": "100045", "name": "Bosch GmbH", "lead_time_days": 7},
                                       {"id": "100089", "name": "Siemens AG", "lead_time_days": 14}]})
    return json.dumps({"error": "unknown"})

if __name__ == "__main__":
    task = ("We need 20 units of material PUMP-003 in plant 1000 by 2024-04-15. "
            "Check availability, find vendors if needed, and create a PR if stock is insufficient.")
    messages = [
        {"role": "system", "content": "You are an autonomous SAP procurement agent. Complete the task step by step."},
        {"role": "user", "content": task},
    ]
    print(f"Task: {task}\n{'=' * 60}")
    for step in range(1, 8):
        r = requests.post(URL, headers=HEADERS,
                          json={"model": "gpt-4o", "messages": messages, "tools": TOOLS, "max_tokens": 400},
                          timeout=30)
        r.raise_for_status()
        msg = r.json()["choices"][0]["message"]
        messages.append(msg)
        if not msg.get("tool_calls"):
            print(f"\nFinal answer:\n{msg['content']}")
            break
        for tc in msg["tool_calls"]:
            fn, args_raw = tc["function"]["name"], tc["function"]["arguments"]
            args   = json.loads(args_raw)
            result = mock_tool(fn, args)
            print(f"Step {step}: {fn}({args_raw}) -> {result}")
            messages.append({"role": "tool", "tool_call_id": tc["id"], "content": result})
