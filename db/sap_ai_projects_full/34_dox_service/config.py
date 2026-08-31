import os
from dotenv import load_dotenv

load_dotenv()  # reads .env file

DOX_BASE_URL    = os.environ["DOX_BASE_URL"]
CLIENT_ID       = os.environ["DOX_CLIENT_ID"]
CLIENT_SECRET   = os.environ["DOX_CLIENT_SECRET"]

TOKEN_URL = f"{DOX_BASE_URL}/oauth/token"
