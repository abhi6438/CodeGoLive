"""
Project: SAP AI Core Python Examples
Topic:   04_system_prompts
Goal:    Demonstrate role-switching: same question answered by CFO, CTO, and End-User personas.
"""
import requests, os

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

PERSONAS = {
    "CFO": (
        "You are a Chief Financial Officer. Focus on ROI, cost savings, "
        "budget impact, and financial risk. Be precise and use financial metrics."
    ),
    "CTO": (
        "You are a Chief Technology Officer. Focus on architecture, scalability, "
        "integration complexity, and technical risk. Use technical terminology."
    ),
    "End User": (
        "You are an SAP end user in the Accounts Payable department. "
        "Focus on day-to-day usability, workflow changes, and training needs. "
        "Use plain language."
    ),
}

QUESTION = "Should our company upgrade from SAP ECC 6.0 to SAP S/4HANA?"

def ask_persona(persona_name, system_prompt):
    r = requests.post(URL, headers=HEADERS, json={
        "model": "gpt-4o",
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": QUESTION},
        ],
        "max_tokens": 180,
    }, timeout=30)
    r.raise_for_status()
    return r.json()["choices"][0]["message"]["content"].strip()

if __name__ == "__main__":
    print(f"Question: {QUESTION}\n{'=' * 60}")
    for persona, prompt in PERSONAS.items():
        answer = ask_persona(persona, prompt)
        print(f"\n[{persona}]\n{answer}")
    print()
