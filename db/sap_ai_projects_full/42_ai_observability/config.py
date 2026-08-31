import os
from dotenv import load_dotenv

load_dotenv()  # reads .env file

# ── Env vars ──────────────────────────────────────────────────────────────────
BASE_URL   = os.environ["AICORE_BASE_URL"]
TOKEN      = os.environ["AICORE_TOKEN"]
DEPLOY_ID  = os.environ["AICORE_DEPLOYMENT_ID"]
EMB_DEPLOY = os.environ["AICORE_EMB_DEPLOYMENT_ID"]
RG         = os.environ["AICORE_RG"]

LF_PUBLIC  = os.environ["LANGFUSE_PUBLIC_KEY"]
LF_SECRET  = os.environ["LANGFUSE_SECRET_KEY"]
LF_HOST    = os.environ["LANGFUSE_HOST"]

AI_HEADERS = {
    "Authorization": f"Bearer {TOKEN}",
    "Content-Type": "application/json",
    "AI-Resource-Group": RG,
}

QUESTIONS = [
    "What is SAP BTP and what are its main capabilities?",
    "How does SAP AI Core manage model deployments?",
    "What is the difference between SAP Analytics Cloud and SAP Datasphere?",
]

CORPUS = [
    "SAP BTP (Business Technology Platform) provides integration, extension, AI, and analytics tools.",
    "SAP AI Core orchestrates AI workloads using Kubernetes-based infrastructure with ArgoCD.",
    "SAP Analytics Cloud covers BI, planning, and predictive analytics in a unified SaaS product.",
    "SAP Datasphere provides a business data fabric layer for harmonizing and federating enterprise data.",
    "GenAI Hub in SAP AI Launchpad gives access to LLMs from OpenAI, Anthropic, Google, and others.",
    "SAP AI Core uses deployments and serving templates to manage inference endpoints.",
    "SAP BTP supports multi-cloud and hybrid landscapes across AWS, Azure, and Google Cloud.",
]

# ── Helpers ───────────────────────────────────────────────────────────────────
