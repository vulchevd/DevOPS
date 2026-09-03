"""Database engine/session setup.

DATABASE_URL is read from the environment so the same image runs unmodified
against local Postgres, CI's ephemeral Postgres container, and RDS in
staging/prod — only the connection string changes, injected via the Helm
chart from a Kubernetes Secret populated by External Secrets (see
deploy/helm/tasks-api/templates/externalsecret.yaml).
"""
import os
from collections.abc import Generator

from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker

DATABASE_URL = os.environ.get(
    "DATABASE_URL", "postgresql+psycopg://tasks:tasks@localhost:5432/tasks"
)

# pool_pre_ping avoids handing out dead connections after an RDS failover
engine = create_engine(DATABASE_URL, pool_pre_ping=True)
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)


class Base(DeclarativeBase):
    pass


def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
