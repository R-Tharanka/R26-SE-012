# =============================================================================
# File: runtime artifact service
# Purpose: Finds or downloads the frozen model and price-data files safely.
# =============================================================================
from __future__ import annotations

import os
import tempfile
from dataclasses import dataclass
from pathlib import Path
from urllib.parse import unquote, urlparse
from urllib.request import Request, urlopen


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


@dataclass(frozen=True)
class UrlArtifactConfig:
    grading_model_url: str
    class_names_url: str
    forecast_model_url: str
    forecast_metrics_url: str
    forecast_data_url: str
    token: str | None = None


_runtime_artifacts: RuntimeArtifacts | None = None


def _repo_root() -> Path:
    # Find the repository root from this module's fixed directory position.
    return Path(__file__).resolve().parents[4]


def _required_env(name: str) -> str:
    # Read one required setting and fail clearly when it is missing.
    value = os.getenv(name, "").strip()
    if not value:
        raise ArtifactConfigurationError(f"Missing required environment variable: {name}")
    return value


def _optional_env(name: str) -> str:
    # Read one optional setting as a trimmed string.
    return os.getenv(name, "").strip()


def load_hugging_face_artifact_config() -> HuggingFaceArtifactConfig:
    # Build the complete Hugging Face configuration from environment settings.
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


def load_url_artifact_config() -> UrlArtifactConfig:
    # Build the direct-download fallback configuration from environment settings.
    return UrlArtifactConfig(
        grading_model_url=_required_env("ARTIFACT_GRADING_MODEL_URL"),
        class_names_url=_required_env("ARTIFACT_CLASS_NAMES_URL"),
        forecast_model_url=_required_env("ARTIFACT_FORECAST_MODEL_URL"),
        forecast_metrics_url=_required_env("ARTIFACT_FORECAST_METRICS_URL"),
        forecast_data_url=_required_env("ARTIFACT_FORECAST_DATA_URL"),
        token=_optional_env("ARTIFACT_DOWNLOAD_TOKEN") or None,
    )


def _download_hugging_face_file(config: HuggingFaceArtifactConfig, filename: str) -> Path:
    # Download one version-pinned file and return its local cache path.
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


def _url_cache_dir() -> Path:
    # Create and return the dedicated cache directory for URL downloads.
    cache_dir = Path(_optional_env("ARTIFACT_CACHE_DIR") or tempfile.gettempdir())
    cache_dir = cache_dir / "pepper_runtime_artifacts"
    cache_dir.mkdir(parents=True, exist_ok=True)
    return cache_dir


def _filename_from_url(url: str, fallback_name: str) -> str:
    # Use the URL filename when available, otherwise keep the known safe name.
    parsed = urlparse(url)
    name = Path(unquote(parsed.path)).name
    return name or fallback_name


def _download_url_file(
    url: str,
    fallback_name: str,
    *,
    token: str | None,
) -> Path:
    # Download one protected or public URL into the local artifact cache.
    destination = _url_cache_dir() / _filename_from_url(url, fallback_name)
    try:
        headers = {"User-Agent": "pepper-ai-backend-artifact-loader"}
        if token:
            headers["Authorization"] = f"Bearer {token}"

        request = Request(url, headers=headers)
        with urlopen(request, timeout=120) as response:
            data = response.read()

        if not data:
            raise ArtifactDownloadError(f"Artifact URL returned an empty file: {fallback_name}")

        destination.write_bytes(data)
        return destination
    except ArtifactDownloadError:
        raise
    except Exception as exc:
        raise ArtifactDownloadError(
            f"Failed to download required artifact '{fallback_name}' from artifact URL."
        ) from exc


def _download_hugging_face_artifacts() -> RuntimeArtifacts:
    # Download every required runtime file from the primary provider.
    config = load_hugging_face_artifact_config()
    return RuntimeArtifacts(
        grading_model_path=_download_hugging_face_file(config, config.grading_model_file),
        class_names_path=_download_hugging_face_file(config, config.class_names_file),
        forecast_model_path=_download_hugging_face_file(config, config.forecast_model_file),
        forecast_metrics_path=_download_hugging_face_file(config, config.forecast_metrics_file),
        forecast_data_path=_download_hugging_face_file(config, config.forecast_data_file),
    )


def _download_url_artifacts() -> RuntimeArtifacts:
    # Download every required runtime file from the configured fallback URLs.
    config = load_url_artifact_config()
    return RuntimeArtifacts(
        grading_model_path=_download_url_file(
            config.grading_model_url,
            "berry_mobilenetv2_v2_best.onnx",
            token=config.token,
        ),
        class_names_path=_download_url_file(
            config.class_names_url,
            "class_names.json",
            token=config.token,
        ),
        forecast_model_path=_download_url_file(
            config.forecast_model_url,
            "forecast_model.joblib",
            token=config.token,
        ),
        forecast_metrics_path=_download_url_file(
            config.forecast_metrics_url,
            "naive_persistence_metrics.json",
            token=config.token,
        ),
        forecast_data_path=_download_url_file(
            config.forecast_data_url,
            "national_grade1_average_weekly.csv",
            token=config.token,
        ),
    )


def _bundled_runtime_artifacts() -> RuntimeArtifacts:
    # Describe the artifact paths that are shipped inside the repository.
    root = _repo_root()
    return RuntimeArtifacts(
        grading_model_path=root
        / "ml"
        / "grading_forecast"
        / "berry_grading"
        / "models"
        / "v2"
        / "berry_mobilenetv2_v2_best.onnx",
        class_names_path=root
        / "ml"
        / "grading_forecast"
        / "berry_grading"
        / "models"
        / "v2"
        / "class_names.json",
        forecast_model_path=root
        / "ml"
        / "grading_forecast"
        / "price_forecasting"
        / "models"
        / "v2"
        / "forecast_model.joblib",
        forecast_metrics_path=root
        / "ml"
        / "grading_forecast"
        / "price_forecasting"
        / "models"
        / "v2"
        / "naive_persistence_metrics.json",
        forecast_data_path=root
        / "data"
        / "processed"
        / "grading_forecast"
        / "price_v2"
        / "national_grade1_average_weekly.csv",
    )


def _bundled_runtime_artifacts_ready() -> RuntimeArtifacts | None:
    # Return bundled artifacts only when every required file exists.
    artifacts = _bundled_runtime_artifacts()
    if all(
        path.is_file()
        for path in (
            artifacts.grading_model_path,
            artifacts.class_names_path,
            artifacts.forecast_model_path,
            artifacts.forecast_metrics_path,
            artifacts.forecast_data_path,
        )
    ):
        return artifacts
    return None


def download_runtime_artifacts() -> RuntimeArtifacts:
    """Download all required runtime artifacts once and store local cache paths.

    Hugging Face is the primary source. Repository-bundled artifacts and direct
    artifact URLs are fallbacks for deployments where Hugging Face access is
    unavailable or rate-limited.
    """

    # Try the approved sources in order and remember the resolved local paths.
    global _runtime_artifacts

    try:
        artifacts = _download_hugging_face_artifacts()
    except (ArtifactConfigurationError, ArtifactDownloadError):
        bundled = _bundled_runtime_artifacts_ready()
        if bundled is not None:
            artifacts = bundled
        else:
            try:
                artifacts = _download_url_artifacts()
            except (ArtifactConfigurationError, ArtifactDownloadError) as fallback_exc:
                raise ArtifactDownloadError(
                    "Failed to load runtime artifacts from Hugging Face, bundled files, or artifact URLs."
                ) from fallback_exc

    _runtime_artifacts = artifacts
    return artifacts


def set_runtime_artifacts_for_tests(artifacts: RuntimeArtifacts | None) -> None:
    # Let isolated tests set or clear the in-memory artifact paths.
    global _runtime_artifacts
    _runtime_artifacts = artifacts


def get_runtime_artifacts() -> RuntimeArtifacts | None:
    # Return the currently loaded artifact paths without changing state.
    return _runtime_artifacts


def runtime_artifacts_ready() -> bool:
    # Confirm that all recorded artifact paths still point to real files.
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
