from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Settings:
    environment: str
    jwt_secret: str
    database_path: Path
    cors_origins: list[str]

    @property
    def is_production(self) -> bool:
        return self.environment.lower() == "production"


def load_settings() -> Settings:
    environment = os.getenv("STUDY_MANAGER_ENV", "development")
    secret = os.getenv("STUDY_MANAGER_JWT_SECRET", "")
    if not secret:
        if environment.lower() == "production":
            raise RuntimeError("STUDY_MANAGER_JWT_SECRET must be configured in production")
        secret = "development-only-secret-change-before-deployment"

    default_database = Path(__file__).resolve().parents[1] / "data" / "study_manager.db"
    database_path = Path(os.getenv("STUDY_MANAGER_DB_PATH", str(default_database)))
    origins = [
        value.strip()
        for value in os.getenv(
            "STUDY_MANAGER_CORS_ORIGINS",
            "http://localhost:3000,http://localhost:5000,http://localhost:8080",
        ).split(",")
        if value.strip()
    ]
    return Settings(environment, secret, database_path, origins)
