"""
Project: SAP AI Core Python Examples
Topic:   14_cap_ai
Goal:    Expense categorization – classify 5 corporate expenses with AI and print results table.
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

EXPENSES = [
    {"id": "E001", "description": "Flight MUC-SFO + hotel for SAP TechEd conference", "amount": 2340.00},
    {"id": "E002", "description": "AWS EC2 instances for BTP development sandbox", "amount": 187.50},
    {"id": "E003", "description": "Team lunch at Zum Franziskaner restaurant, Munich", "amount": 312.80},
    {"id": "E004", "description": "SAP Learning Hub subscription – 12 months", "amount": 1200.00},
    {"id": "E005", "description": "Taxi from Frankfurt airport to customer site", "amount": 65.00},
]

CATEGORIES = ["TRAVEL", "IT_INFRASTRUCTURE", "MEALS_ENTERTAINMENT", "TRAINING", "LOCAL_TRANSPORT"]

SYSTEM = (
    f"Classify the expense into exactly one category: {', '.join(CATEGORIES)}. "
    "Reply with only the category name and a confidence (HIGH/MEDIUM/LOW) separated by '|'."
)

def classify(description):
    r = requests.post(URL, headers=HEADERS, json={
        "model": "gpt-4o",
        "messages": [
            {"role": "system", "content": SYSTEM},
            {"role": "user", "content": description},
        ],
        "max_tokens": 20,
    }, timeout=30)
    r.raise_for_status()
    raw = r.json()["choices"][0]["message"]["content"].strip()
    parts = raw.split("|")
    category   = parts[0].strip() if len(parts) > 0 else "UNKNOWN"
    confidence = parts[1].strip() if len(parts) > 1 else "?"
    return category, confidence

if __name__ == "__main__":
    print(f"{'ID':<6}  {'Amount':>8}  {'Conf':<6}  {'Category':<20}  Description")
    print("-" * 90)
    for exp in EXPENSES:
        cat, conf = classify(exp["description"])
        print(f"{exp['id']:<6}  {exp['amount']:>8.2f}  {conf:<6}  {cat:<20}  {exp['description'][:45]}")
