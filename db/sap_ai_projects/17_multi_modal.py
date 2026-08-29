"""
Project: SAP AI Core Python Examples
Topic:   17_multi_modal
Goal:    Send a SAP screenshot to GPT-4V for UI analysis.
         If no image file is found, uses a detailed text description instead.
"""
import requests, os, base64, pathlib

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

SCREENSHOT_DESCRIPTION = """
[SAP Fiori Screenshot Description]
The screen shows the SAP S/4HANA Fiori launchpad with the following layout:
- Top navigation bar: SAP logo on left, search icon, bell icon (3 notifications), user avatar 'JS' on right
- Main area shows 4 tile groups:
  Group 1 'Finance': 'Post Journal Entry', 'Display GL Account', 'Manage Bank Accounts' tiles
  Group 2 'Procurement': 'Create Purchase Order' tile with a red badge showing '12 pending approvals'
  Group 3 'Reports': 'Cash Flow Analysis' tile showing sparkline chart trending down 8% this month
  Group 4 'Administration': 'User Management', 'System Status' tiles
- System Status tile shows WARNING icon with text 'Background jobs: 2 failed'
- Footer shows current user: John Smith | Company: ACME Corp | System: S4H PRD
"""

def analyze_screenshot(use_real_image=False, image_path="sap_screenshot.png"):
    if use_real_image and pathlib.Path(image_path).exists():
        img_data = base64.b64encode(pathlib.Path(image_path).read_bytes()).decode()
        content = [
            {"type": "text", "text": "Analyze this SAP Fiori screenshot. Identify UX issues, action items, and system health indicators."},
            {"type": "image_url", "image_url": {"url": f"data:image/png;base64,{img_data}"}},
        ]
    else:
        print("No screenshot file found – using text description.\n")
        content = (
            f"Analyze this SAP Fiori screenshot description as if you could see it.\n\n"
            f"{SCREENSHOT_DESCRIPTION}\n\n"
            "Identify: 1) Urgent action items, 2) UX issues, 3) System health concerns."
        )

    r = requests.post(URL, headers=HEADERS, json={
        "model": "gpt-4o",
        "messages": [
            {"role": "system", "content": "You are an SAP UX consultant and Basis expert."},
            {"role": "user", "content": content},
        ],
        "max_tokens": 350,
    }, timeout=30)
    r.raise_for_status()
    return r.json()["choices"][0]["message"]["content"].strip()

if __name__ == "__main__":
    analysis = analyze_screenshot()
    print("SAP Screenshot Analysis\n" + "=" * 40)
    print(analysis)
