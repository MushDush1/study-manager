from __future__ import annotations

from typing import Any

from pydantic import BaseModel, Field, field_validator


class Credentials(BaseModel):
    email: str = Field(min_length=3, max_length=254)
    password: str = Field(min_length=8, max_length=128)

    @field_validator("email")
    @classmethod
    def normalize_email(cls, value: str) -> str:
        normalized = value.strip().lower()
        if "@" not in normalized or normalized.startswith("@") or normalized.endswith("@"):
            raise ValueError("请输入有效邮箱")
        return normalized


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    email: str


class StudyDocumentResponse(BaseModel):
    document: dict[str, Any] | None
    version: int
    updated_at: str | None = None


class StudyDocumentUpdate(BaseModel):
    document: dict[str, Any]
    expected_version: int = Field(ge=0)
    force: bool = False
