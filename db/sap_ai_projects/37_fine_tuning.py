"""
Project: SAP GenAI Hub Integration Series
Topic:   37_fine_tuning
Goal:    Submit fine-tuning job to SAP AI Core: prepare data, upload artifact, create config, poll
Requirements: pip install ai-core-sdk requests
"""

import os, json, time, tempfile
import requests
from ai_core_sdk.ai_core_v2_client import AICoreV2Client

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


def prepare_training_file() -> str:
    with tempfile.NamedTemporaryFile(mode="w", suffix=".jsonl", delete=False) as f:
        for record in SAP_TRAINING_DATA:
            f.write(json.dumps(record) + "\n")
        path = f.name
    print(f"Training file prepared: {path} ({len(SAP_TRAINING_DATA)} records)")
    return path


def upload_artifact(client: AICoreV2Client, file_path: str) -> str:
    artifact = client.artifact.create(
        name="sap-support-training-data",
        kind="dataset",
        url=f"ai://default/training-data/sap-support.jsonl",
        description="SAP support Q&A fine-tuning dataset",
        scenario_id="foundation-models",
    )
    print(f"Artifact created: {artifact.id}")
    return artifact.id


def create_training_config(client: AICoreV2Client, artifact_id: str) -> str:
    config = client.configuration.create(
        name="sap-support-finetune-config",
        scenario_id="foundation-models",
        executable_id="azure-openai-finetune",
        parameter_bindings=[
            {"key": "modelName", "value": "gpt-35-turbo"},
            {"key": "trainingEpochs", "value": "3"},
            {"key": "learningRateMultiplier", "value": "1.0"},
        ],
        input_artifact_bindings=[{"key": "trainingData", "artifact_id": artifact_id}],
    )
    print(f"Configuration created: {config.id}")
    return config.id


def submit_and_poll(client: AICoreV2Client, config_id: str):
    execution = client.execution.create(configuration_id=config_id)
    exec_id = execution.id
    print(f"Execution submitted: {exec_id}")

    for attempt in range(12):
        time.sleep(10)
        status = client.execution.get(exec_id)
        print(f"  [{attempt+1}] Status: {status.status}")
        if status.status in ("COMPLETED", "DEAD", "STOPPED"):
            print(f"Fine-tuning {'succeeded' if status.status == 'COMPLETED' else 'failed'}")
            return status
    print("Timeout waiting for fine-tuning job.")


if __name__ == "__main__":
    print("=== SAP AI Core Fine-Tuning Pipeline ===")
    file_path = prepare_training_file()

    client = AICoreV2Client(base_url=BASE, auth_url="", client_id="", client_secret="")

    print("\nNote: AICoreV2Client requires OAuth credentials from BTP service binding.")
    print("Steps that would execute:")
    print(f"  1. Upload {len(SAP_TRAINING_DATA)}-record JSONL from {file_path}")
    print("  2. Create artifact reference in AI Core")
    print("  3. Create training configuration (gpt-35-turbo, 3 epochs)")
    print("  4. Submit execution and poll for completion")
    print("  5. Deploy fine-tuned model as new AI Core deployment")
