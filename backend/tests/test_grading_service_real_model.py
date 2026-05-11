from __future__ import annotations

from app.schemas.grading_forecast import GradeEnum
from app.services.grading_forecast import grading_service


def test_grading_service_probability_weighted_quality_score(monkeypatch) -> None:
    def _fake_predict(_image_bytes: bytes):
        prob_map = {
            GradeEnum.grade_1: 0.10,
            GradeEnum.grade_2: 0.85,
            GradeEnum.grade_3: 0.05,
        }
        return (GradeEnum.grade_2, 0.90, prob_map)

    monkeypatch.setattr(grading_service, "_predict_grade_with_onnx", _fake_predict)

    result = grading_service.build_grading_result(image_bytes=b"not-a-real-image", image_name="x.jpg")
    assert result.predicted_grade == GradeEnum.grade_2
    assert result.confidence == 0.9
    # Expected score: 0.10*85 + 0.85*70 + 0.05*55 = 70.75 -> 70.8 (1 dp)
    assert result.quality_score == 70.8

