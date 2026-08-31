from __future__ import annotations

import json
import sqlite3
from datetime import datetime, timezone
from typing import Annotated
from uuid import uuid4

import jwt
from fastapi import Depends, FastAPI, HTTPException, Request, Response, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from .config import load_settings
from .database import connection, initialize_database
from .schemas import Credentials, StudyDocumentResponse, StudyDocumentUpdate, TokenResponse
from .security import create_access_token, decode_access_token, hash_password, verify_password


MAX_DOCUMENT_BYTES = 2 * 1024 * 1024
bearer_scheme = HTTPBearer(auto_error=False)
settings = load_settings()
initialize_database(settings.database_path)

app = FastAPI(title="Study Manager API", version="0.1.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=False,
    allow_methods=["GET", "POST", "PUT", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type"],
)


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def unauthorized() -> HTTPException:
    return HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="登录状态已失效")


def current_user_id(
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(bearer_scheme)],
    request: Request,
) -> str:
    token = credentials.credentials if credentials and credentials.scheme.lower() == "bearer" else request.cookies.get("study_manager_session")
    if not token:
        raise unauthorized()
    try:
        return decode_access_token(token, settings.jwt_secret)
    except jwt.InvalidTokenError as error:
        raise unauthorized() from error


def document_response(user_id: str) -> StudyDocumentResponse:
    with connection(settings.database_path) as database:
        row = database.execute(
            "SELECT document_json, version, updated_at FROM study_documents WHERE user_id = ?",
            (user_id,),
        ).fetchone()
    if row is None:
        return StudyDocumentResponse(document=None, version=0)
    return StudyDocumentResponse(
        document=json.loads(row["document_json"]),
        version=row["version"],
        updated_at=row["updated_at"],
    )


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


def session_response(response: Response, user_id: str, email: str) -> TokenResponse:
    token = create_access_token(user_id, settings.jwt_secret)
    response.set_cookie("study_manager_session", token, httponly=True, samesite="lax", secure=False, max_age=14 * 24 * 60 * 60, path="/api")
    return TokenResponse(access_token=token, email=email)


@app.post("/v1/auth/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
def register(credentials: Credentials, response: Response) -> TokenResponse:
    user_id = str(uuid4())
    try:
        with connection(settings.database_path) as database:
            database.execute(
                "INSERT INTO users (id, email, password_hash, created_at) VALUES (?, ?, ?, ?)",
                (user_id, credentials.email, hash_password(credentials.password), now_iso()),
            )
    except sqlite3.IntegrityError as error:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="该邮箱已注册") from error
    return session_response(response, user_id, credentials.email)


@app.post("/v1/auth/login", response_model=TokenResponse)
def login(credentials: Credentials, response: Response) -> TokenResponse:
    with connection(settings.database_path) as database:
        row = database.execute(
            "SELECT id, email, password_hash FROM users WHERE email = ?", (credentials.email,)
        ).fetchone()
    if row is None or not verify_password(credentials.password, row["password_hash"]):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="邮箱或密码不正确")
    return session_response(response, row["id"], row["email"])


@app.get("/v1/auth/session")
def session(user_id: Annotated[str, Depends(current_user_id)]) -> dict[str, str]:
    with connection(settings.database_path) as database:
        row = database.execute("SELECT email FROM users WHERE id = ?", (user_id,)).fetchone()
    if row is None:
        raise unauthorized()
    return {"email": row["email"]}


@app.post("/v1/auth/logout", status_code=status.HTTP_204_NO_CONTENT)
def logout(response: Response) -> Response:
    response.delete_cookie("study_manager_session", path="/api")
    return response


@app.get("/v1/study-document", response_model=StudyDocumentResponse)
def get_study_document(user_id: Annotated[str, Depends(current_user_id)]) -> StudyDocumentResponse:
    return document_response(user_id)


@app.put("/v1/study-document", response_model=StudyDocumentResponse)
def save_study_document(
    update: StudyDocumentUpdate,
    user_id: Annotated[str, Depends(current_user_id)],
) -> StudyDocumentResponse:
    serialized = json.dumps(update.document, ensure_ascii=False, separators=(",", ":"))
    if len(serialized.encode("utf-8")) > MAX_DOCUMENT_BYTES:
        raise HTTPException(status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE, detail="学习数据超过 2MB 限制")

    updated_at = now_iso()
    with connection(settings.database_path) as database:
        current = database.execute(
            "SELECT version FROM study_documents WHERE user_id = ?", (user_id,)
        ).fetchone()
        current_version = 0 if current is None else current["version"]
        if current_version != update.expected_version and not update.force:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="云端数据已更新，请刷新后重试",
            )
        next_version = current_version + 1
        database.execute(
            """
            INSERT INTO study_documents (user_id, document_json, version, updated_at)
            VALUES (?, ?, ?, ?)
            ON CONFLICT(user_id) DO UPDATE SET
                document_json = excluded.document_json,
                version = excluded.version,
                updated_at = excluded.updated_at
            """,
            (user_id, serialized, next_version, updated_at),
        )
    return StudyDocumentResponse(
        document=update.document, version=next_version, updated_at=updated_at
    )
