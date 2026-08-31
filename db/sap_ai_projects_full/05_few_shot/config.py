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

SYSTEM = """Classify SAP error messages into exactly one category: AUTH | DATA | NETWORK | CONFIG

Examples:
"User JSMITH not authorized for activity 02 on object S_TCODE" -> AUTH
"RFC connection to system PRD failed: CPIC-CALL 'ThSAPOCMINIT', communication rc=20" -> NETWORK
"Table MARA: field MATNR exceeds maximum length of 18 characters" -> DATA
"Parameter login/min_password_lng not set in profile DEFAULT.PFL" -> CONFIG
"SNC name for user BATCHJOB could not be determined" -> AUTH
"ORA-01653: unable to extend table SAPR3.BSEG by 128 in tablespace PSAPSR3" -> DATA

Reply with only the category word."""

TEST_ERRORS = [
    "HTTP 401 Unauthorized: Invalid credentials for OData service /sap/opu/odata/sap/MM_PUR_PO_MAINT_V2_SRV",
    "Field KOSTL (Cost Center) is required but missing in posting document",
    "SSL handshake with remote host api.sap.com failed: certificate expired",
    "ICM parameter icm/max_conn is set to 0, must be >= 1",
    "User BASIS_ADMIN missing authorization for transaction SM50",
]
