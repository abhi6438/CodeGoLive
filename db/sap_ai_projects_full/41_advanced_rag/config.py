import os
from dotenv import load_dotenv

load_dotenv()  # reads .env file

BASE_URL    = os.environ["AICORE_BASE_URL"]
TOKEN       = os.environ["AICORE_TOKEN"]
DEPLOY_ID   = os.environ["AICORE_DEPLOYMENT_ID"]
EMB_DEPLOY  = os.environ["AICORE_EMB_DEPLOYMENT_ID"]
RG          = os.environ["AICORE_RG"]

HEADERS = {
    "Authorization": f"Bearer {TOKEN}",
    "Content-Type": "application/json",
    "AI-Resource-Group": RG,
}

# ── Corpus ──────────────────────────────────────────────────────────────────
CORPUS = [
    "SAP S/4HANA is SAP's next-generation ERP suite built on the in-memory SAP HANA database.",
    "SAP BTP (Business Technology Platform) provides tools for integration, extension, and analytics.",
    "SAP Fiori is a design system and UX framework for SAP applications using a tile-based UI.",
    "The SAP AI Core service runs AI workloads on Kubernetes and manages model deployments.",
    "SAP Integration Suite connects SAP and non-SAP systems via APIs, events, and integrations.",
    "SAP Datasphere provides a business data fabric for connecting and harmonizing enterprise data.",
    "SAP Analytics Cloud combines BI, planning, and predictive analytics in a single SaaS product.",
    "SAP Work Zone creates unified digital workplaces that aggregate business apps and workflows.",
    "SAP Build is a low-code/no-code suite for creating apps, automations, and process workflows.",
    "GenAI Hub in SAP AI Core provides access to foundation models from multiple providers.",
]

QUESTIONS = [
    "What database does SAP S/4HANA use?",
    "How do I access foundation models in SAP?",
    "What is SAP Fiori used for?",
]

# ── Embedding ────────────────────────────────────────────────────────────────
