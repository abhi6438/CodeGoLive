import sys
import os

# Add repo root to path so "backend.app.main" resolves
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from backend.app.main import app  # noqa: E402,F401
