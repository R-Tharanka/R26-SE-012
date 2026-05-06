from __future__ import annotations

from fastapi import APIRouter, UploadFile

from app.schemas.grading_forecast import (
    AnalyzeResponse,
    GradeOnlyResponse,
    PriceForecastResponse,
    RecommendRequest,
    RecommendResponse,
)
from app.services.grading_forecast.grading_service import build_grading_result
from app.services.grading_forecast.price_forecast_service import build_price_forecast
from app.services.grading_forecast.recommendation_service import build_recommendation
from app.services.grading_forecast.result_storage_service import build_storage_result

router = APIRouter(prefix="/api/v1/grading-forecast", tags=["grading-forecast"])


@router.get("/health")
def health() -> dict[str, str]:
    return {
        "status": "ok",
        "component": "berry_grading_export_price_forecasting",
    }


@router.post("/analyze", response_model=AnalyzeResponse)
async def analyze(image: UploadFile | None = None) -> AnalyzeResponse:
    image_bytes: bytes | None = None
    image_name: str | None = None
    processed = False

    if image is not None:
        image_name = image.filename or "uploaded_image"
        try:
            image_bytes = await image.read()
            processed = bool(image_bytes)
        except Exception:
            image_bytes = None
            processed = False

    grading = build_grading_result(image_bytes=image_bytes, image_name=image_name)
    forecast = build_price_forecast(seed_hint=image_name)
    recommendation = build_recommendation(
        grade=grading.predicted_grade,
        trend=forecast.trend,
        quality_score=grading.quality_score,
        current_price_lkr_per_kg=forecast.current_price_lkr_per_kg,
        predicted_price_lkr_per_kg=forecast.predicted_price_lkr_per_kg,
    )
    storage = build_storage_result()

    return AnalyzeResponse(
        status="success",
        component="berry_grading_export_price_forecasting",
        image_analysis={
            "image_id": (image_name or "DEMO_IMAGE"),
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
    image_bytes: bytes | None = None
    image_name: str | None = None

    if image is not None:
        image_name = image.filename or "uploaded_image"
        try:
            image_bytes = await image.read()
        except Exception:
            image_bytes = None

    grading = build_grading_result(image_bytes=image_bytes, image_name=image_name)
    return GradeOnlyResponse(
        status="success",
        component="berry_grading_export_price_forecasting",
        grading=grading,
    )


@router.get("/price-forecast", response_model=PriceForecastResponse)
def price_forecast() -> PriceForecastResponse:
    forecast = build_price_forecast(seed_hint="price-forecast")
    return PriceForecastResponse(
        status="success",
        component="berry_grading_export_price_forecasting",
        forecast=forecast,
    )


@router.post("/recommend", response_model=RecommendResponse)
def recommend(payload: RecommendRequest) -> RecommendResponse:
    recommendation = build_recommendation(
        grade=payload.grade,
        trend=payload.trend,
        quality_score=payload.quality_score,
        current_price_lkr_per_kg=payload.current_price_lkr_per_kg,
        predicted_price_lkr_per_kg=payload.predicted_price_lkr_per_kg,
    )
    return RecommendResponse(
        status="success",
        component="berry_grading_export_price_forecasting",
        recommendation=recommendation,
    )
