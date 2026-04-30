"""Pytest config: ensure scripts.* package imports resolve.

Tests import as `from scripts.lib import classify`. We add the repo root
to sys.path so pytest invoked from anywhere finds the `scripts` package.
"""
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))
