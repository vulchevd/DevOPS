"""In-memory SQLite for tests — no Postgres needed to run `pytest`.

CI runs these on every PR (see .github/workflows/ci.yml); Flyway's own
`validate` step, run separately against a throwaway Postgres container, is
what actually checks the migration SQL.
"""
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from src.db import Base, get_db
from src.main import app

engine = create_engine(
    "sqlite:///:memory:",
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSession = sessionmaker(bind=engine)


@pytest.fixture(autouse=True)
def _fresh_schema():
    Base.metadata.create_all(engine)
    yield
    Base.metadata.drop_all(engine)


def _override_get_db():
    db = TestingSession()
    try:
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = _override_get_db
client = TestClient(app)


def test_healthz():
    resp = client.get("/healthz")
    assert resp.status_code == 200
    assert resp.json() == {"status": "ok"}


def test_create_and_list_task():
    resp = client.post("/tasks", json={"title": "write the runbook"})
    assert resp.status_code == 201
    body = resp.json()
    assert body["title"] == "write the runbook"
    assert body["done"] is False

    resp = client.get("/tasks")
    assert resp.status_code == 200
    assert len(resp.json()) == 1


def test_get_missing_task_404():
    resp = client.get("/tasks/does-not-exist")
    assert resp.status_code == 404


def test_update_task():
    created = client.post("/tasks", json={"title": "draft"}).json()
    resp = client.patch(f"/tasks/{created['id']}", json={"done": True})
    assert resp.status_code == 200
    assert resp.json()["done"] is True


def test_delete_task():
    created = client.post("/tasks", json={"title": "temp"}).json()
    resp = client.delete(f"/tasks/{created['id']}")
    assert resp.status_code == 204
    assert client.get(f"/tasks/{created['id']}").status_code == 404
