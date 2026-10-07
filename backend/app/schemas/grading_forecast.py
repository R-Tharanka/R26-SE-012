from __future__ import annotations

from enum import Enum

from pydantic import BaseModel, Field


class Phase7GradingResult(BaseModel):
    status: str
    decision: str
    grade: str | None = None
    model_confidence: float | None = None
    detection_confidence: float | None = None
    class_margin: float | None = None
    quality_status: str
    rejection_reason: str | None = None
    physical_sample_id: str | None = None
    confidence_interpretation: str
    image_decisions: list[dict] | None = None
    aggregation: dict | None = None


class Phase7ForecastInterval(BaseModel):
    lower: float
    upper: float
    label: str
    probability_claim: bool


class Phase7MarketResult(BaseModel):
    status: str
    source: str | None = None
    source_organization: str | None = None
    source_url: str | None = None
    unit: str | None = None
    price_grade: str | None = None
    model_scope: str | None = None
    latest_reference_date: str | None = None
    latest_reference_price: float | None = None
    latest_price_interpretation: str | None = None
    previous_reference_price: float | None = None
    latest_observed_return: float | None = None
    forecast_target_date: str | None = None
    forecast_log_return: float | None = None
    forecast_return: float | None = None
    forecast_price: float | None = None
    forecast_direction: str | None = None
    forecast_interval: Phase7ForecastInterval | None = None
    persistence_price: float | None = None
    model_vs_persistence: str | None = None
    forecast_signal: str | None = None
    evidence_partition: str | None = None


class Phase7DecisionSupport(BaseModel):
    category: str
    summary: str
    limitations: list[str]


class Phase7Runtime(BaseModel):
    grading: str
    price: str
    mobile: str
    tflite: str


class Phase7AnalyzeResponse(BaseModel):
    schema_version: str
    grading: Phase7GradingResult
    market: Phase7MarketResult
    decision_support: Phase7DecisionSupport
    trace: dict
    runtime: Phase7Runtime


class GradeEnum(str, Enum):
    grade_1 = "Grade 1"
    grade_2 = "Grade 2"
    grade_3 = "Grade 3"


class TrendEnum(str, Enum):
    upward = "upward"
    downward = "downward"
    stable = "stable"


class DecisionEnum(str, Enum):
    wait_or_target_export_buyer = "WAIT_OR_TARGET_EXPORT_BUYER"
    sell_export = "SELL_EXPORT"
    sell_soon = "SELL_SOON"
    wait_shortly = "WAIT_SHORTLY"
    monitor = "MONITOR"
    sort_or_process = "SORT_OR_PROCESS"
    process_local = "PROCESS_LOCAL"
    process_or_sell_immediately = "PROCESS_OR_SELL_IMMEDIATELY"


class UrgencyLevelEnum(str, Enum):
    low = "LOW"
    medium = "MEDIUM"
    high = "HIGH"


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
    explanation: list[str]
    urgency_level: UrgencyLevelEnum
    suggested_action: str
    limitation_note: str


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
    quality_score: float | None = Field(default=None, ge=0.0, le=100.0)
    current_price_lkr_per_kg: int | None = Field(default=None, ge=0)
    predicted_price_lkr_per_kg: int | None = Field(default=None, ge=0)


class RecommendResponse(BaseModel):
    status: str
    component: str
    recommendation: RecommendationResult
