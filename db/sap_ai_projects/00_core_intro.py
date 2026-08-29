"""
Project: SAP AI Core – Environment Health Check
Topic: ai-00-core-intro
Goal: Verify your AI Core credentials and list available scenarios & executables.
"""
from ai_core_sdk.ai_core_v2_client import AICoreV2Client

client = AICoreV2Client(
    base_url="https://<your-ai-api-url>/v2",
    auth_url="https://<your-auth-url>/oauth/token",
    client_id="<your-client-id>",
    client_secret="<your-client-secret>",
    resource_group="default"
)

print("=== Scenarios ===")
scenarios = client.scenario.query()
for s in scenarios.resources:
    print(f"  {s.id}  ({s.name})")

print("\n=== Executables ===")
for s in scenarios.resources:
    execs = client.executable.query(scenario_id=s.id)
    for e in execs.resources:
        print(f"  Scenario={s.id}  Executable={e.id}  ({e.name})")

print("\n✅ Credentials verified – AI Core is reachable.")
