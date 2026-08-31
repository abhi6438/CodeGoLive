import os
from dotenv import load_dotenv

load_dotenv()  # reads .env file

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
        "name": "get_open_purchase_orders",
        "description": "Returns list of open purchase orders for a vendor in SAP MM.",
        "parameters": {"type": "object", "properties": {
            "vendor_id": {"type": "string", "description": "SAP vendor number (e.g. 100045)"},
        }, "required": ["vendor_id"]},
    }},
    {"type": "function", "function": {
        "name": "get_material_stock",
        "description": "Returns current stock level for a material in a plant.",
        "parameters": {"type": "object", "properties": {
            "material_id": {"type": "string"},
            "plant":       {"type": "string"},
        }, "required": ["material_id", "plant"]},
    }},
]
