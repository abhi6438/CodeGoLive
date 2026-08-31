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
