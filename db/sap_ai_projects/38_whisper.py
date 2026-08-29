"""
Project: SAP GenAI Hub Integration Series
Topic:   38_whisper
Goal:    Transcribe SAP meeting audio with Whisper, extract action items, SAP transactions, create tasks
Requirements: pip install requests
Env vars: AICORE_BASE_URL, AICORE_TOKEN, AICORE_WHISPER_DEPLOYMENT_ID, AICORE_DEPLOYMENT_ID, AICORE_RG
"""

import os, json, re
import requests

BASE          = os.environ["AICORE_BASE_URL"]
TOKEN         = os.environ["AICORE_TOKEN"]
WHISPER_DEPID = os.environ["AICORE_WHISPER_DEPLOYMENT_ID"]
CHAT_DEPID    = os.environ["AICORE_DEPLOYMENT_ID"]
RG            = os.environ.get("AICORE_RG", "default")
HEADERS       = {"Authorization": f"Bearer {TOKEN}", "AI-Resource-Group": RG}
CHAT_URL      = f"{BASE}/inference/deployments/{CHAT_DEPID}/chat/completions"
WHISPER_URL   = f"{BASE}/inference/deployments/{WHISPER_DEPID}/audio/transcriptions"

MOCK_TRANSCRIPT = """
Good morning everyone. Today's Q3 procurement review. John, can you run MM60 to check inventory turnover?
We need to post the vendor invoices for October using MIRO before the period close on Friday.
Sarah will run transaction ME2N to pull all open purchase orders above 10k.
Action item: John Chen to complete inventory analysis by November 15th.
Action item: Sarah Mueller to run ME2N report and share with CFO by November 10th.
Action item: Mark Thompson to review outstanding invoices in MIRO and post by November 8th.
We also discussed running FB03 to display the posted documents from last quarter.
Please use SE16N to check the EKKO table for any POs missing GRs.
"""


def transcribe_audio(audio_file_path: str) -> str:
    with open(audio_file_path, "rb") as audio_file:
        files = {"file": (os.path.basename(audio_file_path), audio_file, "audio/mp4"),
                 "model": (None, "whisper-1")}
        resp = requests.post(WHISPER_URL, headers=HEADERS, files=files, timeout=120)
        resp.raise_for_status()
        return resp.json()["text"]


def extract_action_items(transcript: str) -> list[dict]:
    payload = {
        "model": "gpt-4o",
        "messages": [
            {"role": "system", "content": "Extract action items from SAP meeting transcripts. Return JSON array."},
            {"role": "user", "content": f"""Extract action items from this transcript. Return JSON array with fields:
owner, task, due_date, priority (high/medium/low).

Transcript: {transcript}

Return only the JSON array."""},
        ],
        "max_tokens": 400,
    }
    resp = requests.post(CHAT_URL, headers={**HEADERS, "Content-Type": "application/json"}, json=payload, timeout=30)
    resp.raise_for_status()
    raw = resp.json()["choices"][0]["message"]["content"]
    try:
        start = raw.index("[")
        end = raw.rindex("]") + 1
        return json.loads(raw[start:end])
    except (ValueError, json.JSONDecodeError):
        return [{"owner": "Unknown", "task": raw[:80], "due_date": "TBD", "priority": "medium"}]


def extract_sap_transactions(transcript: str) -> list[str]:
    pattern = r'\b([A-Z]{2,4}[0-9]{1,3}[A-Z]?[0-9]?|SE[0-9]+[A-Z]?)\b'
    transactions = list(set(re.findall(pattern, transcript)))
    return sorted(transactions)


def create_sap_tasks(action_items: list[dict]) -> list[dict]:
    tasks = []
    for i, item in enumerate(action_items, 1):
        task = {
            "task_id": f"TASK-2024-{i:04d}",
            "type": "ServiceRequest",
            "subject": item.get("task", "Follow-up task"),
            "processor": item.get("owner", "Unassigned"),
            "due_date": item.get("due_date", "TBD"),
            "priority": {"high": "1-High", "medium": "2-Medium", "low": "3-Low"}.get(
                item.get("priority", "medium"), "2-Medium"),
            "status": "Open",
            "category": "Meeting Action Item",
        }
        tasks.append(task)
        print(f"  Created SAP Task {task['task_id']}: {task['subject'][:50]} -> {task['processor']}")
    return tasks


if __name__ == "__main__":
    print("=== SAP Whisper Meeting Transcription Pipeline ===\n")
    print("[Step 1] Using mock transcript (no audio file provided)")
    transcript = MOCK_TRANSCRIPT
    print(f"Transcript ({len(transcript)} chars):\n{transcript[:150]}...\n")

    print("[Step 2] Extracting SAP Transactions mentioned:")
    transactions = extract_sap_transactions(transcript)
    print(f"  Found: {transactions}\n")

    print("[Step 3] Extracting Action Items via LLM:")
    action_items = extract_action_items(transcript)
    print(f"  Found {len(action_items)} action items\n")

    print("[Step 4] Creating SAP Tasks:")
    tasks = create_sap_tasks(action_items)
    print(f"\nSummary: {len(transactions)} transactions, {len(action_items)} action items, {len(tasks)} tasks created")
