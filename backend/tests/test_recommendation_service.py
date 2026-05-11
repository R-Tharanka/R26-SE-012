import pytest

from app.schemas.grading_forecast import (
    DecisionEnum,
    GradeEnum,
    TrendEnum,
    UrgencyLevelEnum,
)
from app.services.grading_forecast.recommendation_service import (
    LIMITATION_NOTE,
    build_recommendation,
)


@pytest.mark.parametrize(
    "grade,trend,expected_decision",
    [
        (GradeEnum.grade_1, TrendEnum.upward, DecisionEnum.wait_or_target_export_buyer),
        (GradeEnum.grade_1, TrendEnum.stable, DecisionEnum.sell_export),
        (GradeEnum.grade_1, TrendEnum.downward, DecisionEnum.sell_soon),
        (GradeEnum.grade_2, TrendEnum.upward, DecisionEnum.wait_shortly),
        (GradeEnum.grade_2, TrendEnum.stable, DecisionEnum.monitor),
        (GradeEnum.grade_2, TrendEnum.downward, DecisionEnum.sell_soon),
        (GradeEnum.grade_3, TrendEnum.upward, DecisionEnum.sort_or_process),
        (GradeEnum.grade_3, TrendEnum.stable, DecisionEnum.process_local),
        (GradeEnum.grade_3, TrendEnum.downward, DecisionEnum.process_or_sell_immediately),
    ],
)
def test_recommendation_rule_table_all_combinations(
    grade: GradeEnum,
    trend: TrendEnum,
    expected_decision: DecisionEnum,
) -> None:
    rec = build_recommendation(grade=grade, trend=trend)
    assert rec.decision == expected_decision
    assert rec.limitation_note == LIMITATION_NOTE

    assert isinstance(rec.message, str)
    assert rec.message.strip()

    assert isinstance(rec.suggested_action, str)
    assert rec.suggested_action.strip()

    assert rec.urgency_level in {
        UrgencyLevelEnum.low,
        UrgencyLevelEnum.medium,
        UrgencyLevelEnum.high,
    }

    assert isinstance(rec.explanation, list)
    assert 2 <= len(rec.explanation) <= 4
    for line in rec.explanation:
        assert isinstance(line, str)
        assert line.strip()


def test_recommendation_includes_quality_and_prices_when_provided() -> None:
    rec = build_recommendation(
        grade=GradeEnum.grade_2,
        trend=TrendEnum.upward,
        quality_score=72.5,
        current_price_lkr_per_kg=1350,
        predicted_price_lkr_per_kg=1420,
    )
    assert any("Quality score:" in line for line in rec.explanation)
    assert any("Current:" in line for line in rec.explanation)
