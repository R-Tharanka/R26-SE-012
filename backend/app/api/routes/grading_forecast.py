from __future__ import annotations

import io
import logging

from fastapi import APIRouter, HTTPException, UploadFile, status
from PIL import Image, UnidentifiedImageError

from app.schemas.grading_forecast import (
    AnalyzeResponse,
    GradeOnlyResponse,
    PriceForecastResponse,
    RecommendRequest,
    RecommendResponse,
)
from app.services.grading_forecast.artifact_service import get_runtime_artifacts, runtime_artifacts_ready
from app.services.grading_forecast.grading_service import GradingRuntimeError, build_grading_result
from app.services.grading_forecast.price_forecast_service import build_price_forecast
from app.services.grading_forecast.recommendation_service import build_recommendation
from app.services.grading_forecast.result_storage_service import build_storage_result

router = APIRouter(prefix="/api/v1/grading-forecast", tags=["grading-forecast"])
LOGGER = logging.getLogger(__name__)
MAX_IMAGE_UPLOAD_BYTES = 10 * 1024 * 1024
SUPPORTED_IMAGE_FORMATS = {"JPEG", "PNG", "WEBP"}
FORECAST_UNAVAILABLE_MODEL = "forecast_unavailable"


async def _read_valid_image_upload(image: UploadFile | None) -> tuple[bytes, str]:
    if image is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Image upload is required.",
        )

    image_name = image.filename or "uploaded_image"
    try:
        image_bytes = await image.read()
    except Exception as exc:
        LOGGER.warning("Failed to read uploaded image: %s", type(exc).__name__)
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Image upload could not be read.",
        ) from exc

    if not image_bytes:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Image upload is empty.",
        )

    if len(image_bytes) > MAX_IMAGE_UPLOAD_BYTES:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail="Image upload exceeds the 10 MB limit.",
        )

    try:
        with Image.open(io.BytesIO(image_bytes)) as img:
            img.verify()
            if str(img.format).upper() not in SUPPORTED_IMAGE_FORMATS:
                raise HTTPException(
                    status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
                    detail="Unsupported image format. Use JPEG, PNG, or WEBP.",
                )
    except HTTPException:
        raise
    except (UnidentifiedImageError, OSError, ValueError) as exc:
        LOGGER.warning("Invalid uploaded image: %s", type(exc).__name__)
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Uploaded image is invalid or unreadable.",
        ) from exc

    return image_bytes, image_name


def _require_forecast_available(forecast_model: str) -> None:
    if forecast_model == FORECAST_UNAVAILABLE_MODEL:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Price forecast is unavailable from the configured research data.",
        )


def _safe_grading_result(image_bytes: bytes, image_name: str):
    try:
        return build_grading_result(image_bytes=image_bytes, image_name=image_name)
    except GradingRuntimeError as exc:
        LOGGER.warning("Berry grading failed safely: %s", exc)
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Berry grading model is unavailable or failed to produce a safe result.",
        ) from exc
    except Exception as exc:
        LOGGER.exception("Unexpected berry grading failure.")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Berry grading failed unexpectedly.",
        ) from exc


@router.get("/health")
def health() -> dict[str, str]:
    return {
        "status": "ok",
        "component": "berry_grading_export_price_forecasting",
    }


@router.get("/ready")
def ready() -> dict[str, object]:
    artifacts = get_runtime_artifacts()
    ready_status = runtime_artifacts_ready()
    return {
        "status": "ready" if ready_status else "not_ready",
        "component": "berry_grading_export_price_forecasting",
        "artifacts_loaded": artifacts is not None,
        "artifacts_available": ready_status,
    }


@router.post("/analyze", response_model=AnalyzeResponse)
async def analyze(image: UploadFile | None = None) -> AnalyzeResponse:
    component = "berry_grading_export_price_forecasting"
    image_bytes, image_name = await _read_valid_image_upload(image)
    processed = True

    grading = _safe_grading_result(image_bytes, image_name)

    forecast = build_price_forecast(seed_hint=image_name)
    _require_forecast_available(forecast.model)
    try:
        recommendation = build_recommendation(
            grade=grading.predicted_grade,
            trend=forecast.trend,
            quality_score=grading.quality_score,
            current_price_lkr_per_kg=forecast.current_price_lkr_per_kg,
            predicted_price_lkr_per_kg=forecast.predicted_price_lkr_per_kg,
        )
    except Exception as exc:
        LOGGER.exception("Unexpected recommendation failure.")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Recommendation generation failed unexpectedly.",
        ) from exc

    image_id = image_name or "DEMO_IMAGE"
    storage = build_storage_result(
        component=component,
        image_id=image_id,
        image_processed=processed,
        grading=grading,
        forecast=forecast,
        recommendation=recommendation,
    )

    return AnalyzeResponse(
        status="success",
        component=component,
        image_analysis={
            "image_id": image_id,
            "processed": processed,
            "note": "Camera-based visual analysis only",
        },
        grading=grading,
        forecast=forecast,
        recommendation=recommendation,
        storage=storage,
    )


@router.post("/grade-only", response_model=GradeOnlyResponse)
async def grade_only(image: UploadFile | None = None) -> GradeOnlyResponse:
    image_bytes, image_name = await _read_valid_image_upload(image)

    grading = _safe_grading_result(image_bytes, image_name)
    return GradeOnlyResponse(
        status="success",
        component="berry_grading_export_price_forecasting",
        grading=grading,
    )


@router.get("/price-forecast", response_model=PriceForecastResponse)
def price_forecast() -> PriceForecastResponse:
    forecast = build_price_forecast(seed_hint="price-forecast")
    _require_forecast_available(forecast.model)
    return PriceForecastResponse(
        status="success",
        component="berry_grading_export_price_forecasting",
        forecast=forecast,
    )


@router.post("/recommend", response_model=RecommendResponse)
def recommend(payload: RecommendRequest) -> RecommendResponse:
    try:
        recommendation = build_recommendation(
            grade=payload.grade,
            trend=payload.trend,
            quality_score=payload.quality_score,
            current_price_lkr_per_kg=payload.current_price_lkr_per_kg,
            predicted_price_lkr_per_kg=payload.predicted_price_lkr_per_kg,
        )
    except Exception as exc:
        LOGGER.exception("Unexpected recommendation failure.")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Recommendation generation failed unexpectedly.",
        ) from exc
    return RecommendResponse(
        status="success",
        component="berry_grading_export_price_forecasting",
        recommendation=recommendation,
    )
