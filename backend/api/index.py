import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from app.main import app  # noqa: E402,F401

# Vercel's Python runtime detects and serves this `app` object directly
# (it must be an ASGI or WSGI-compatible callable named `app`).
