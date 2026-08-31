from __future__ import annotations

from datetime import datetime, timedelta, timezone

import jwt
from pwdlib import PasswordHash


PASSWORD_HASH = PasswordHash.recommended()
TOKEN_LIFETIME = timedelta(days=14)


def hash_password(password: str) -> str:
    return PASSWORD_HASH.hash(password)


def verify_password(password: str, password_hash: str) -> bool:
    return PASSWORD_HASH.verify(password, password_hash)


def create_access_token(user_id: str, secret: str) -> str:
    expires_at = datetime.now(timezone.utc) + TOKEN_LIFETIME
    return jwt.encode({"sub": user_id, "exp": expires_at}, secret, algorithm="HS256")


def decode_access_token(token: str, secret: str) -> str:
    payload = jwt.decode(token, secret, algorithms=["HS256"])
    subject = payload.get("sub")
    if not isinstance(subject, str) or not subject:
        raise jwt.InvalidTokenError("token subject missing")
    return subject
