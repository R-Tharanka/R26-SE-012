from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path


class ArtifactConfigurationError(RuntimeError):
    """Raised when required model artifact configuration is missing."""


class ArtifactDownloadError(RuntimeError):
    """Raised when model artifacts cannot be downloaded."""


@dataclass(frozen=True)
class HuggingFaceArtifactConfig:
    token: str
    repo_id: str
    revision: str
    grading_model_file: str
    class_names_file: str
    forecast_model_file: str
    forecast_metrics_file: str
    forecast_data_file: str


@dataclass(frozen=True)
class RuntimeArtifacts:
    grading_model_path: Path
    class_names_path: Path
    forecast_model_path: Path
    forecast_metrics_path: Path
    forecast_data_path: Path


_runtime_artifacts: RuntimeArtifacts | None = None


def _required_env(name: str) -> str:
    value = os.getenv(name, "").strip()
    if not value:
        raise ArtifactConfigurationError(f"Missing required environment variable: {name}")
    return value


def load_hugging_face_artifact_config() -> HuggingFaceArtifactConfig:
    return HuggingFaceArtifactConfig(
        token=_required_env("HF_TOKEN"),
        repo_id=_required_env("HF_MODEL_REPO"),
        revision=_required_env("HF_MODEL_REVISION"),
        grading_model_file=_required_env("HF_GRADING_MODEL_FILE"),
        class_names_file=_required_env("HF_CLASS_NAMES_FILE"),
        forecast_model_file=_required_env("HF_FORECAST_MODEL_FILE"),
        forecast_metrics_file=_required_env("HF_FORECAST_METRICS_FILE"),
        forecast_data_file=_required_env("HF_FORECAST_DATA_FILE"),
    )


def _download_file(config: HuggingFaceArtifactConfig, filename: str) -> Path:
    try:
        from huggingface_hub import hf_hub_download

        return Path(
            hf_hub_download(
                repo_id=config.repo_id,
                filename=filename,
                revision=config.revision,
                token=config.token,
            )
        )
    except Exception as exc:
        raise ArtifactDownloadError(
            f"Failed to download required artifact '{filename}' from Hugging Face Hub."
        ) from exc


def download_runtime_artifacts() -> RuntimeArtifacts:
    """Download all required runtime artifacts once and store local cache paths."""

    global _runtime_artifacts

    config = load_hugging_face_artifact_config()
    artifacts = RuntimeArtifacts(
        grading_model_path=_download_file(config, config.grading_model_file),
        class_names_path=_download_file(config, config.class_names_file),
        forecast_model_path=_download_file(config, config.forecast_model_file),
        forecast_metrics_path=_download_file(config, config.forecast_metrics_file),
        forecast_data_path=_download_file(config, config.forecast_data_file),
    )
    _runtime_artifacts = artifacts
    return artifacts


def set_runtime_artifacts_for_tests(artifacts: RuntimeArtifacts | None) -> None:
    global _runtime_artifacts
    _runtime_artifacts = artifacts


def get_runtime_artifacts() -> RuntimeArtifacts | None:
    return _runtime_artifacts


def runtime_artifacts_ready() -> bool:
    artifacts = _runtime_artifacts
    if artifacts is None:
        return False
    return all(
        path.is_file()
        for path in (
            artifacts.grading_model_path,
            artifacts.class_names_path,
            artifacts.forecast_model_path,
            artifacts.forecast_metrics_path,
            artifacts.forecast_data_path,
        )
    )
