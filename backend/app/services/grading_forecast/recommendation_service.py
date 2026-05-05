from __future__ import annotations

from app.schemas.grading_forecast import (
    DecisionEnum,
    GradeEnum,
    RecommendationResult,
    TrendEnum,
)


def build_recommendation(*, grade: GradeEnum, trend: TrendEnum) -> RecommendationResult:
    if grade == GradeEnum.grade_1 and trend == TrendEnum.upward:
        return RecommendationResult(
            decision=DecisionEnum.target_export_buyer,
            message=(
                "High-quality batch and price trend is upward. Consider waiting briefly or targeting "
                "export buyer."
            ),
        )

    if grade == GradeEnum.grade_1 and trend == TrendEnum.stable:
        return RecommendationResult(
            decision=DecisionEnum.sell_export,
            message=(
                "High-quality batch. Suitable for export market if other non-camera quality checks are passed."
            ),
        )

    if grade == GradeEnum.grade_1 and trend == TrendEnum.downward:
        return RecommendationResult(
            decision=DecisionEnum.sell_soon,
            message=(
                "High-quality batch but price trend is downward. Consider selling soon."
            ),
        )

    if grade == GradeEnum.grade_2 and trend == TrendEnum.upward:
        return RecommendationResult(
            decision=DecisionEnum.wait,
            message=(
                "Medium-quality batch and price trend is upward. Wait shortly if storage conditions are acceptable."
            ),
        )

    if grade == GradeEnum.grade_2 and trend == TrendEnum.stable:
        return RecommendationResult(
            decision=DecisionEnum.monitor,
            message=(
                "Medium-quality batch. Monitor market or consider selling if storage is limited."
            ),
        )

    if grade == GradeEnum.grade_2 and trend == TrendEnum.downward:
        return RecommendationResult(
            decision=DecisionEnum.sell_soon,
            message=(
                "Medium-quality batch and price trend is downward. Consider selling soon."
            ),
        )

    if grade == GradeEnum.grade_3 and trend == TrendEnum.upward:
        return RecommendationResult(
            decision=DecisionEnum.sort_or_process,
            message=(
                "Lower-quality batch. Improve sorting/cleaning or process locally before selling."
            ),
        )

    if grade == GradeEnum.grade_3 and trend == TrendEnum.stable:
        return RecommendationResult(
            decision=DecisionEnum.process_local,
            message=(
                "Lower-quality batch. Consider local processing or local market."
            ),
        )

    return RecommendationResult(
        decision=DecisionEnum.process_or_sell_immediately,
        message=(
            "Lower-quality batch and price trend is downward. Consider processing or selling immediately."
        ),
    )

