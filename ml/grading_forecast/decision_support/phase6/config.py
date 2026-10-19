# =============================================================================
# File: config
# Purpose: Loads frozen workflow settings and repository paths.
# =============================================================================
"""Phase 6 configuration loading with repository-relative path resolution."""

from __future__ import annotations

from pathlib import Path

import yaml


ROOT = Path(__file__).resolve().parents[4]
CONFIG_PATH = Path(__file__).with_name("phase6_config.yaml")


def load_config() -> dict:
    # Load the frozen workflow configuration from disk.
    return yaml.safe_load(CONFIG_PATH.read_text(encoding="utf-8"))


def repo_path(relative: str) -> Path:
    # Resolve a repository-relative configuration path safely.
    path = (ROOT / relative).resolve()
    path.relative_to(ROOT.resolve())
    return path
