from fastapi.testclient import TestClient
from app import main as main_module


def test_lifespan_initializes_phase7_onnx_runtime(monkeypatch) -> None:
    calls: list[str] = []
    monkeypatch.setattr(main_module, "load_dotenv", lambda: calls.append("load_dotenv"))
    monkeypatch.setattr(main_module, "initialize_grading_runtime", lambda: calls.append("initialize_grading_runtime"))
    with TestClient(main_module.create_app()):
        pass
    assert calls == ["load_dotenv", "initialize_grading_runtime"]
