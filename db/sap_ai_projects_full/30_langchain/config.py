import os
from dotenv import load_dotenv

load_dotenv()  # reads .env file

BASE  = os.environ["AICORE_BASE_URL"]
TOKEN = os.environ["AICORE_TOKEN"]
DEPID = os.environ["AICORE_DEPLOYMENT_ID"]
RG    = os.environ.get("AICORE_RG", "default")

llm = ChatOpenAI(
    base_url=f"{BASE}/inference/deployments/{DEPID}",
    api_key=TOKEN,
    model="gpt-4o",
    default_headers={"AI-Resource-Group": RG},
)
