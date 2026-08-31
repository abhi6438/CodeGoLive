import os
from dotenv import load_dotenv

load_dotenv()  # reads .env file

app = Server("sap-mcp-server")
