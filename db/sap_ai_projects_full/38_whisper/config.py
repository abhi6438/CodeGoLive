import os
from dotenv import load_dotenv

load_dotenv()  # reads .env file

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
