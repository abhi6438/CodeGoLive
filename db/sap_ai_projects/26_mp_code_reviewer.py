"""
Project: SAP AI Core Python Examples
Topic:   26_mp_code_reviewer
Goal:    Review 2 ABAP code snippets for security/performance issues.
         Returns JSON with issues list, score (0-10), and summary.
"""
import requests, os, json

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

ABAP_SNIPPETS = {
    "snippet_1_dynamic_sql": """
REPORT zdyn_query.
DATA: lv_table TYPE string VALUE 'MARA',
      lv_where TYPE string.
PARAMETERS: p_matnr TYPE matnr.

lv_where = 'MATNR = ''' && p_matnr && ''''.
SELECT * FROM (lv_table) WHERE (lv_where) INTO TABLE @DATA(lt_results).
LOOP AT lt_results INTO DATA(ls_row).
  WRITE: / ls_row-matnr, ls_row-matkl.
ENDLOOP.
""",
    "snippet_2_auth_bypass": """
REPORT zuser_data.
TABLES: usr02.
DATA: lt_users TYPE TABLE OF usr02.

" Get all users without authorization check
SELECT * FROM usr02 INTO TABLE lt_users.
LOOP AT lt_users INTO DATA(ls_user).
  IF ls_user-bname CP '*ADMIN*'.
    WRITE: / ls_user-bname, ls_user-class, ls_user-pwdstate.
  ENDIF.
ENDLOOP.
""",
}

REVIEW_SYSTEM = """You are a senior SAP ABAP security and performance expert.
Review the ABAP code and return a JSON object with this exact structure:
{
  "score": <integer 0-10, where 10 is perfect code>,
  "issues": [
    {
      "severity": "CRITICAL|HIGH|MEDIUM|LOW",
      "type": "SECURITY|PERFORMANCE|MAINTAINABILITY",
      "description": "...",
      "fix": "..."
    }
  ],
  "summary": "One sentence overall assessment"
}"""

def review_abap(name, code):
    r = requests.post(URL, headers=HEADERS, json={
        "model": "gpt-4o",
        "messages": [
            {"role": "system", "content": REVIEW_SYSTEM},
            {"role": "user", "content": f"Review this ABAP code:\n```abap{code}```"},
        ],
        "response_format": {"type": "json_object"},
        "max_tokens": 500,
    }, timeout=30)
    r.raise_for_status()
    return json.loads(r.json()["choices"][0]["message"]["content"])

if __name__ == "__main__":
    for name, code in ABAP_SNIPPETS.items():
        print(f"\n{'=' * 60}\nReviewing: {name}\n{'=' * 60}")
        result = review_abap(name, code)
        print(f"Score: {result['score']}/10")
        print(f"Summary: {result['summary']}")
        print(f"\nIssues ({len(result['issues'])}):")
        for issue in result["issues"]:
            print(f"  [{issue['severity']:8}] [{issue['type']:15}] {issue['description']}")
            print(f"           Fix: {issue['fix']}")
