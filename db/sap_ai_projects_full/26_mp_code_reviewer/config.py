import os
from dotenv import load_dotenv

load_dotenv()  # reads .env file

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
