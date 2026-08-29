"""
Project: SAP GenAI Hub Integration Series
Topic:   32_a2a_protocol
Goal:    Simulate A2A protocol between Procurement Agent and Finance Agent
Requirements: pip install fastapi uvicorn requests
"""

import json, threading, time, uuid
import requests
from fastapi import FastAPI
from fastapi.responses import JSONResponse
import uvicorn

FINANCE_AGENT_URL = "http://localhost:8765/a2a/tasks"


def create_task_card(skill_name: str, input_data: dict) -> dict:
    return {
        "id": str(uuid.uuid4()),
        "jsonrpc": "2.0",
        "method": "tasks/send",
        "params": {
            "id": str(uuid.uuid4()),
            "message": {
                "role": "user",
                "parts": [{"type": "text", "text": json.dumps(input_data)}],
            },
        },
        "agent_card": {
            "name": "Procurement Agent",
            "description": "SAP procurement automation agent",
            "url": "http://localhost:8766",
            "version": "1.0.0",
            "skills": [
                {
                    "id": skill_name,
                    "name": skill_name,
                    "description": f"Execute {skill_name} skill",
                    "inputModes": ["text/plain", "application/json"],
                    "outputModes": ["application/json"],
                }
            ],
        },
    }


finance_app = FastAPI(title="Finance Agent A2A Endpoint")


@finance_app.post("/a2a/tasks")
async def handle_task(task_card: dict):
    task_id = task_card.get("params", {}).get("id", "unknown")
    message_parts = task_card.get("params", {}).get("message", {}).get("parts", [])
    input_text = message_parts[0].get("text", "{}") if message_parts else "{}"

    try:
        input_data = json.loads(input_text)
    except json.JSONDecodeError:
        input_data = {}

    po_amount = input_data.get("po_amount", 0)
    vendor = input_data.get("vendor", "Unknown")

    budget_check = po_amount <= 100000
    result = {
        "task_id": task_id,
        "status": "completed",
        "result": {
            "budget_available": budget_check,
            "approved_amount": po_amount if budget_check else 0,
            "cost_center": "CC1000",
            "gl_account": "520000",
            "vendor": vendor,
            "message": "Budget approved, posting to FI" if budget_check else "Insufficient budget",
        },
    }
    print(f"[Finance Agent] Task {task_id[:8]}... processed: {'APPROVED' if budget_check else 'REJECTED'}")
    return JSONResponse(content=result)


def start_finance_agent():
    uvicorn.run(finance_app, host="0.0.0.0", port=8765, log_level="error")


def procurement_agent_send_task():
    time.sleep(1.5)
    print("[Procurement Agent] Creating task card for Finance Agent...")

    task_card = create_task_card(
        skill_name="budget_check",
        input_data={"po_amount": 45000, "vendor": "TechCorp GmbH", "po_number": "PO-2024-0456"},
    )

    print(f"[Procurement Agent] Task card ID: {task_card['params']['id'][:8]}...")
    print(f"[Procurement Agent] Agent card skills: {[s['id'] for s in task_card['agent_card']['skills']]}")

    try:
        response = requests.post(FINANCE_AGENT_URL, json=task_card, timeout=10)
        result = response.json()
        print(f"[Procurement Agent] Received result: {json.dumps(result['result'], indent=2)}")
    except requests.RequestException as e:
        print(f"[Procurement Agent] Error: {e}")


if __name__ == "__main__":
    print("Starting A2A protocol simulation...")
    server_thread = threading.Thread(target=start_finance_agent, daemon=True)
    server_thread.start()

    client_thread = threading.Thread(target=procurement_agent_send_task, daemon=False)
    client_thread.start()
    client_thread.join(timeout=15)
    print("A2A simulation complete.")
