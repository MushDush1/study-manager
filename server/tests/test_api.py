from __future__ import annotations

import os
import tempfile
from pathlib import Path


def test_authentication_and_document_sync() -> None:
    with tempfile.TemporaryDirectory() as directory:
        os.environ["STUDY_MANAGER_DB_PATH"] = str(Path(directory) / "test.db")
        os.environ["STUDY_MANAGER_JWT_SECRET"] = "test-secret-that-is-at-least-thirty-two-bytes-long"
        os.environ["STUDY_MANAGER_ENV"] = "test"

        from fastapi.testclient import TestClient
        from app.main import app

        client = TestClient(app)
        registered = client.post(
            "/v1/auth/register", json={"email": "mush@example.com", "password": "safe-password"}
        )
        assert registered.status_code == 201
        token = registered.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        empty = client.get("/v1/study-document", headers=headers)
        assert empty.status_code == 200
        assert empty.json()["version"] == 0

        saved = client.put(
            "/v1/study-document",
            headers=headers,
            json={"document": {"goals": [{"id": "goal-1", "title": "英语"}]}, "expected_version": 0},
        )
        assert saved.status_code == 200
        assert saved.json()["version"] == 1

        conflict = client.put(
            "/v1/study-document",
            headers=headers,
            json={"document": {"goals": []}, "expected_version": 0},
        )
        assert conflict.status_code == 409
