from __future__ import annotations

from enum import Enum

from pydantic import BaseModel, Field


class GradeEnum(str, Enum):
    grade_1 = "Grade 1"
    grade_2 = "Grade 2"
    grade_3 = "Grade 3"


class TrendEnum(str, Enum):
    upward = "upward"
    downward = "downward"
    stable = "stable"


class DecisionEnum(str, Enum):
    wait = "WAIT"
    target_export_buyer = "TARGET_EXPORT_BUYER"
    sell_export = "SELL_EXPORT"
    sell_soon = "SELL_SOON"
    monitor = "MONITOR"
    sort_or_process = "SORT_OR_PROCESS"
    process_local = "PROCESS_LOCAL"
    process_or_sell_immediately = "PROCESS_OR_SELL_IMMEDIATELY"


class ImageAnalysis(BaseModel):
    image_id: str
    processed: bool
    note: str


class VisualFeatures(BaseModel):
    color_uniformity_score: float = Field(..., ge=0.0, le=1.0)
    dark_berry_ratio: float = Field(..., ge=0.0, le=1.0)
    light_berry_ratio: float = Field(..., ge=0.0, le=1.0)
    texture_score: float = Field(..., ge=0.0, le=1.0)
    defect_ratio: float = Field(..., ge=0.0, le=1.0)
    cleanliness_score: float = Field(..., ge=0.0, le=1.0)


class SupportingLabels(BaseModel):
    size_quality: str = Field(..., description="good / medium / poor")
    color_quality: str = Field(..., description="good / medium / poor")
    texture_quality: str = Field(..., description="good / medium / poor")
    broken_level: str = Field(..., description="low / medium / high")
    light_berry_level: str = Field(..., description="low / medium / high")
    pinhead_level: str = Field(..., description="low / medium / high")
    foreign_matter_visible: bool
    mould_visible: bool
    insect_damage_visible: bool


class GradingResult(BaseModel):
    predicted_grade: GradeEnum
    quality_score: float = Field(..., ge=0.0, le=100.0)
    confidence: float = Field(..., ge=0.0, le=1.0)
    visual_features: VisualFeatures
    supporting_labels: SupportingLabels
    explanation: list[str]
    limitation: str


class ForecastMetrics(BaseModel):
    mae: float | None = None
    rmse: float | None = None


class ForecastResult(BaseModel):
    model: str
    current_price_lkr_per_kg: int = Field(..., ge=0)
    predicted_price_lkr_per_kg: int = Field(..., ge=0)
    trend: TrendEnum
    forecast_period: str
    metrics: ForecastMetrics


class RecommendationResult(BaseModel):
    decision: DecisionEnum
    message: str


class StorageResult(BaseModel):
    saved_to_firebase: bool
    document_id: str | None = None


class AnalyzeResponse(BaseModel):
    status: str
    component: str
    image_analysis: ImageAnalysis
    grading: GradingResult
    forecast: ForecastResult
    recommendation: RecommendationResult
    storage: StorageResult


class GradeOnlyResponse(BaseModel):
    status: str
    component: str
    grading: GradingResult


class PriceForecastResponse(BaseModel):
    status: str
    component: str
    forecast: ForecastResult


class RecommendRequest(BaseModel):
    grade: GradeEnum
    trend: TrendEnum


class RecommendResponse(BaseModel):
    status: str
    component: str
    recommendation: RecommendationResult

