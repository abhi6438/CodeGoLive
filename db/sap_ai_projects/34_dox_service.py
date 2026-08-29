"""
Project: SAP GenAI Hub Integration Series
Topic:   34_dox_service
Goal:    Call SAP Document Information Extraction (DOX) API on BTP to extract invoice fields
Requirements: pip install requests
Env vars: DOX_BASE_URL, DOX_CLIENT_ID, DOX_CLIENT_SECRET
"""

import os, base64, time, json
import requests

DOX_BASE_URL    = os.environ["DOX_BASE_URL"]
CLIENT_ID       = os.environ["DOX_CLIENT_ID"]
CLIENT_SECRET   = os.environ["DOX_CLIENT_SECRET"]

TOKEN_URL = f"{DOX_BASE_URL}/oauth/token"


def get_oauth_token() -> str:
    resp = requests.post(
        TOKEN_URL,
        data={"grant_type": "client_credentials", "client_id": CLIENT_ID, "client_secret": CLIENT_SECRET},
        headers={"Content-Type": "application/x-www-form-urlencoded"},
        timeout=30,
    )
    resp.raise_for_status()
    token = resp.json()["access_token"]
    print(f"OAuth token obtained (expires in {resp.json().get('expires_in', '?')}s)")
    return token


def create_dummy_pdf_b64() -> str:
    pdf_bytes = b"%PDF-1.4\n1 0 obj<</Type /Catalog /Pages 2 0 R>>endobj\n"
    return base64.b64encode(pdf_bytes).decode()


def upload_invoice(token: str, pdf_b64: str) -> str:
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    payload = {
        "options": {
            "extraction": {
                "headerFields": ["documentNumber", "vendorName", "grossAmount", "documentDate", "currencyCode"],
                "lineItemFields": ["description", "quantity", "unitPrice", "netAmount"],
            },
            "clientId": "default",
            "documentType": "invoice",
        },
        "document": {"content": pdf_b64, "mimeType": "application/pdf", "name": "invoice.pdf"},
    }
    upload_url = f"{DOX_BASE_URL}/document-information-extraction/v1/document/jobs"
    resp = requests.post(upload_url, headers=headers, json=payload, timeout=60)
    resp.raise_for_status()
    job_id = resp.json()["id"]
    print(f"Uploaded invoice. Job ID: {job_id}")
    return job_id


def poll_for_results(token: str, job_id: str, max_wait: int = 60) -> dict:
    headers = {"Authorization": f"Bearer {token}"}
    status_url = f"{DOX_BASE_URL}/document-information-extraction/v1/document/jobs/{job_id}"
    elapsed = 0
    while elapsed < max_wait:
        resp = requests.get(status_url, headers=headers, timeout=30)
        resp.raise_for_status()
        data = resp.json()
        status = data.get("status", "PENDING")
        print(f"  Status: {status} ({elapsed}s elapsed)")
        if status == "DONE":
            return data
        if status == "FAILED":
            raise RuntimeError(f"DOX job failed: {data.get('message', 'unknown error')}")
        time.sleep(5)
        elapsed += 5
    raise TimeoutError(f"DOX job {job_id} did not complete in {max_wait}s")


def parse_extraction_results(result: dict) -> dict:
    extracted = result.get("extraction", {})
    header_fields = {f["name"]: f.get("value") for f in extracted.get("headerFields", [])}
    line_items = []
    for item in extracted.get("lineItems", []):
        line_items.append({f["name"]: f.get("value") for f in item.get("columns", [])})

    parsed = {
        "invoice_number": header_fields.get("documentNumber"),
        "vendor": header_fields.get("vendorName"),
        "amount": header_fields.get("grossAmount"),
        "currency": header_fields.get("currencyCode"),
        "date": header_fields.get("documentDate"),
        "line_items": line_items,
    }
    return parsed


if __name__ == "__main__":
    print("=== SAP DOX Invoice Extraction ===")
    token = get_oauth_token()
    pdf_b64 = create_dummy_pdf_b64()
    job_id = upload_invoice(token, pdf_b64)
    print("Polling for results...")
    result = poll_for_results(token, job_id)
    parsed = parse_extraction_results(result)
    print("\nExtracted Invoice Fields:")
    print(json.dumps(parsed, indent=2))
