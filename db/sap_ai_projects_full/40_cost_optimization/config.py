import os
from dotenv import load_dotenv

load_dotenv()  # reads .env file

BASE    = os.environ["AICORE_BASE_URL"]
TOKEN   = os.environ["AICORE_TOKEN"]
DEPID   = os.environ["AICORE_DEPLOYMENT_ID"]
RG      = os.environ.get("AICORE_RG", "default")
HEADERS = {"Authorization": f"Bearer {TOKEN}", "Content-Type": "application/json", "AI-Resource-Group": RG}
URL     = f"{BASE}/inference/deployments/{DEPID}/chat/completions"

MODEL_COSTS = {
    "gpt-4o":      {"input": 0.0025, "output": 0.010},
    "gpt-4o-mini": {"input": 0.00015, "output": 0.0006},
}

COMPLEX_KEYWORDS = ["analyze", "compare", "explain", "design", "architect", "optimize", "evaluate",
                    "pros and cons", "deep dive", "comprehensive", "strategy"]

_prompt_cache: dict[str, str] = {}
