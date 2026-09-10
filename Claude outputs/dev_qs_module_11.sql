-- Module 11 topics for dev-quickstart


INSERT INTO topics (module_id, number, slug, title, focus, description, content_md, order_index, status) VALUES (
  (SELECT id FROM modules WHERE course_id = 'dev-quickstart' AND number = '11'),
  '740',
  'dev-qs-ai-core-instance',
  'Create an AI Core Instance on BTP',
  'Provision an SAP AI Core service instance in your BTP subaccount',
  'Add the AI Core entitlement to your BTP subaccount, create a service instance, and create a service key with the credentials your local scripts will use.',
  '# Create an AI Core Instance on BTP

SAP AI Core is a BTP service that hosts and runs AI/ML models and pipelines.

## Prerequisites

- A BTP trial or paid account
- A subaccount with Cloud Foundry enabled

## Step 1 — Add the AI Core entitlement

1. Go to your **Global Account** in the BTP Cockpit
2. Click **Entitlements** → **Configure Entitlements** → **Add Service Plans**
3. Search for **SAP AI Core**
4. Select the **extended** plan (free on trial)
5. Click **Add** → **Save**

## Step 2 — Create a service instance

1. Go to your **subaccount** → **Services** → **Service Marketplace**
2. Search for **SAP AI Core**
3. Click → **Create**
4. Plan: **extended**
5. Instance name: `ai-core-dev`
6. Click **Create**

Wait 1-2 minutes for provisioning to complete.

## Step 3 — Create a service key

1. Open the `ai-core-dev` instance
2. Click **Service Keys** → **Create**
3. Key name: `ai-core-key`
4. Click **Create**

## Step 4 — Download the credentials

Click the service key → **Download** or copy the JSON. It looks like:

```json
{
  "clientid": "sb-...",
  "clientsecret": "...",
  "url": "https://yourtenant.authentication.eu10.hana.ondemand.com",
  "serviceurls": {
    "AI_API_URL": "https://api.ai.prod.eu-central-1.aws.ml.hana.ondemand.com"
  }
}
```

Keep this file safe — **never commit it to git**.

## Step 5 — Save credentials locally

Create `~/.ai-core-credentials.json` and paste the JSON there:

```bash
# macOS / Linux
cp ~/Downloads/ai-core-key.json ~/.ai-core-credentials.json
chmod 600 ~/.ai-core-credentials.json
```

Or set environment variables (better for CI/CD):

```bash
export AICORE_CLIENT_ID="sb-..."
export AICORE_CLIENT_SECRET="..."
export AICORE_AUTH_URL="https://yourtenant.authentication.eu10.hana.ondemand.com"
export AICORE_API_URL="https://api.ai.prod.eu-central-1.aws.ml.hana.ondemand.com"
```
',
  0,
  'published'
);


INSERT INTO topics (module_id, number, slug, title, focus, description, content_md, order_index, status) VALUES (
  (SELECT id FROM modules WHERE course_id = 'dev-quickstart' AND number = '11'),
  '741',
  'dev-qs-ai-core-sdk',
  'Install SAP AI Core SDK & Make Your First Call',
  'Install the Python or Node.js SDK and call the AI Core API',
  'Install the SAP AI Core SDK for Python or Node.js, authenticate using your service key, and make a test API call to list available resource groups.',
  '# Install SAP AI Core SDK & Make Your First Call

## Python SDK (most common)

### Install

```bash
pip install ai-core-sdk
```

### Authenticate

Create `test_ai_core.py`:

```python
from ai_core_sdk.ai_core_v2_client import AICoreV2Client

client = AICoreV2Client(
    base_url="https://api.ai.prod.eu-central-1.aws.ml.hana.ondemand.com/v2",
    auth_url="https://yourtenant.authentication.eu10.hana.ondemand.com/oauth/token",
    client_id="sb-...",
    client_secret="..."
)

# List resource groups
resource_groups = client.resource_groups.query()
print("Resource groups:", [rg.resource_group_id for rg in resource_groups.resources])
```

Run it:

```bash
python test_ai_core.py
# Resource groups: [''default'']
```

### Load credentials from file (cleaner)

```python
import json, os
from ai_core_sdk.ai_core_v2_client import AICoreV2Client

with open(os.path.expanduser("~/.ai-core-credentials.json")) as f:
    creds = json.load(f)

client = AICoreV2Client(
    base_url=creds["serviceurls"]["AI_API_URL"] + "/v2",
    auth_url=creds["url"] + "/oauth/token",
    client_id=creds["clientid"],
    client_secret=creds["clientsecret"]
)
```

---

## Node.js / JavaScript SDK

```bash
npm install @sap-ai-sdk/core @sap-ai-sdk/foundation-models
```

Create `test-ai-core.js`:

```js
import { AiCoreDeploymentApi } from ''@sap-ai-sdk/core'';

const deployments = await AiCoreDeploymentApi.deploymentQuery(
  { resourceGroup: ''default'' }
).execute();

console.log(''Deployments:'', deployments.resources.map(d => d.deploymentId));
```

Set environment variables before running:

```bash
export AICORE_SERVICE_URL="https://api.ai.prod.eu-central-1.aws.ml.hana.ondemand.com"
export AICORE_CLIENT_ID="sb-..."
export AICORE_CLIENT_SECRET="..."
export AICORE_AUTH_URL="https://yourtenant.authentication.eu10.hana.ondemand.com"

node test-ai-core.js
```

---

## Troubleshoot: 401 Unauthorized

Check that:
1. `clientid` and `clientsecret` are from the **service key** (not your BTP login)
2. `auth_url` ends in `/oauth/token`
3. The AI Core service instance status is **Created** in the BTP cockpit

## Troubleshoot: 403 Forbidden

Your service key may not have the right scopes. Delete the key and create a new one.
',
  1,
  'published'
);
