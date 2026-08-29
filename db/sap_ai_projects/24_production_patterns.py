"""
Project: SAP AI Core Python Examples
Topic:   24_production_patterns
Goal:    Resilient AI client with tenacity retry + circuit breaker decorator.
Requirements: pip install tenacity requests
"""
import requests, os, time, functools
from tenacity import retry, stop_after_attempt, wait_exponential, retry_if_exception_type

BASE    = os.environ["AICORE_BASE_URL"]
TOKEN   = os.environ["AICORE_TOKEN"]
DEPID   = os.environ["AICORE_DEPLOYMENT_ID"]
RG      = os.environ.get("AICORE_RG", "default")
HEADERS = {
    "Authorization": f"Bearer {TOKEN}",
    "Content-Type": "application/json",
    "AI-Resource-Group": RG,
}
URL = f"{BASE}/inference/deployments/{DEPID}/chat/completions"

# --- Circuit Breaker ---
class CircuitBreaker:
    def __init__(self, failure_threshold=3, recovery_timeout=30):
        self.failure_threshold = failure_threshold
        self.recovery_timeout  = recovery_timeout
        self.failures = 0
        self.last_failure_time = None
        self.state = "CLOSED"

    def __call__(self, func):
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            if self.state == "OPEN":
                if time.time() - self.last_failure_time > self.recovery_timeout:
                    self.state = "HALF-OPEN"
                    print("[CircuitBreaker] HALF-OPEN: trying recovery...")
                else:
                    raise RuntimeError(f"CircuitBreaker OPEN – retry after {self.recovery_timeout}s")
            try:
                result = func(*args, **kwargs)
                if self.state == "HALF-OPEN":
                    self.state, self.failures = "CLOSED", 0
                    print("[CircuitBreaker] CLOSED: recovered.")
                return result
            except Exception as e:
                self.failures += 1
                self.last_failure_time = time.time()
                if self.failures >= self.failure_threshold:
                    self.state = "OPEN"
                    print(f"[CircuitBreaker] OPEN after {self.failures} failures.")
                raise
        return wrapper

circuit = CircuitBreaker(failure_threshold=3, recovery_timeout=30)

@circuit
@retry(
    retry=retry_if_exception_type(requests.HTTPError),
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=2, max=10),
    reraise=True,
)
def resilient_chat(prompt: str) -> str:
    r = requests.post(URL, headers=HEADERS, json={
        "model": "gpt-4o",
        "messages": [{"role": "user", "content": prompt}],
        "max_tokens": 150,
    }, timeout=30)
    r.raise_for_status()
    return r.json()["choices"][0]["message"]["content"].strip()

SAP_QUERIES = [
    "What is the purpose of SAP transaction SM21?",
    "Explain SAP work process types in one sentence each.",
    "What does ABAP stand for and when was it introduced?",
]

if __name__ == "__main__":
    for query in SAP_QUERIES:
        try:
            answer = resilient_chat(query)
            print(f"Q: {query}\nA: {answer}\n")
        except Exception as e:
            print(f"Q: {query}\nERROR: {e}\n")
