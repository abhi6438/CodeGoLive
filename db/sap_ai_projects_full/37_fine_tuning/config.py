import os
from dotenv import load_dotenv

load_dotenv()  # reads .env file

BASE    = os.environ["AICORE_BASE_URL"]
TOKEN   = os.environ["AICORE_TOKEN"]
RG      = os.environ.get("AICORE_RG", "default")
HEADERS = {"Authorization": f"Bearer {TOKEN}", "Content-Type": "application/json", "AI-Resource-Group": RG}

SAP_TRAINING_DATA = [
    {"messages": [{"role": "user", "content": "What is SAP FICO?"},
                  {"role": "assistant", "content": "SAP FICO combines Financial Accounting (FI) and Controlling (CO) modules for complete financial management."}]},
    {"messages": [{"role": "user", "content": "Explain SAP MM module"},
                  {"role": "assistant", "content": "SAP MM (Materials Management) handles procurement, inventory management, and warehouse operations."}]},
    {"messages": [{"role": "user", "content": "What is an SAP BOM?"},
                  {"role": "assistant", "content": "A Bill of Materials (BOM) in SAP lists all components required to manufacture a finished product."}]},
    {"messages": [{"role": "user", "content": "What is SAP Basis?"},
                  {"role": "assistant", "content": "SAP Basis is the technical foundation providing system administration, transport management, and user management."}]},
    {"messages": [{"role": "user", "content": "Explain SAP SD module"},
                  {"role": "assistant", "content": "SAP SD (Sales and Distribution) manages order-to-cash processes including sales orders, deliveries, and billing."}]},
    {"messages": [{"role": "user", "content": "What is a SAP plant?"},
                  {"role": "assistant", "content": "A plant in SAP is an organizational unit within a company where materials are produced or goods and services provided."}]},
    {"messages": [{"role": "user", "content": "What does MIGO transaction do?"},
                  {"role": "assistant", "content": "MIGO (Movement of Goods) is used to post goods receipts, goods issues, and stock transfers in SAP."}]},
    {"messages": [{"role": "user", "content": "Explain SAP Workflow"},
                  {"role": "assistant", "content": "SAP Workflow automates business processes by routing work items to appropriate users based on organizational rules."}]},
    {"messages": [{"role": "user", "content": "What is SAP CRM?"},
                  {"role": "assistant", "content": "SAP CRM manages customer relationships including sales, marketing, and service processes across all channels."}]},
    {"messages": [{"role": "user", "content": "What is a SAP client?"},
                  {"role": "assistant", "content": "A client in SAP is the highest organizational unit; each client has separate master data, transactions, and customizing."}]},
]
