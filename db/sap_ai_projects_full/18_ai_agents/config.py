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
