"""
Project: SAP AI Core Python Examples
Topic:   22_batch_processing
Goal:    Async classify 20 invoice descriptions concurrently (asyncio + aiohttp, semaphore=5).
Requirements: pip install aiohttp
"""
import asyncio, aiohttp, os, json

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

INVOICES = [
    "IT consulting services for SAP S/4HANA migration project - 40 hours",
    "Office supplies: paper, pens, printer cartridges for Munich office",
    "Cloud server rental AWS EC2 - 3 instances for 30 days",
    "Business travel: flight Frankfurt-London, hotel 2 nights",
    "SAP S/4HANA license renewal - 500 users annual fee",
    "Catering for quarterly board meeting - 25 attendees",
    "Network infrastructure: 2x Cisco switches, cabling",
    "Marketing campaign: LinkedIn ads for SAP consultants recruitment",
    "Legal fees: contract review for vendor agreement",
    "Training: SAP Fiori development bootcamp - 10 developers",
    "Vehicle fuel reimbursement - field service team Q1",
    "Software subscription: Jira, Confluence, GitHub Enterprise annual",
    "Industrial cleaning services - warehouse facility",
    "Customs duty and import tax for hardware shipment from USA",
    "Translation services: technical documentation German to English",
    "Security audit: penetration testing SAP landscape",
    "Postage and courier fees - document delivery March",
    "Ergonomic furniture: standing desks for developer team",
    "SAP Integration Suite API calls - monthly usage billing",
    "Insurance premium: professional liability for IT services",
]

SYSTEM = "Classify the invoice into: IT_SERVICES | OFFICE_SUPPLIES | CLOUD_INFRA | TRAVEL | LICENSES | FACILITIES | MARKETING | LEGAL | TRAINING | OTHER. Reply with only the category."

async def classify_one(session, sem, idx, description):
    async with sem:
        payload = {
            "model": "gpt-4o",
            "messages": [
                {"role": "system", "content": SYSTEM},
                {"role": "user", "content": description},
            ],
            "max_tokens": 15,
        }
        async with session.post(URL, headers=HEADERS, json=payload) as resp:
            resp.raise_for_status()
            data  = await resp.json()
            label = data["choices"][0]["message"]["content"].strip()
            return idx, label

async def main():
    sem = asyncio.Semaphore(5)
    async with aiohttp.ClientSession(timeout=aiohttp.ClientTimeout(total=60)) as session:
        tasks   = [classify_one(session, sem, i, desc) for i, desc in enumerate(INVOICES)]
        results = await asyncio.gather(*tasks)
    results.sort()
    print(f"{'#':<4} {'Category':<18} Invoice Description")
    print("-" * 80)
    for idx, label in results:
        print(f"{idx+1:<4} {label:<18} {INVOICES[idx][:58]}")

if __name__ == "__main__":
    asyncio.run(main())
