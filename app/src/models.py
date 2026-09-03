"""ORM model + API schemas.

The ORM model's columns are the ground truth for what the database actually
looks like; db/migrations/ is where changes to it get made explicit and
versioned (see V1__init.sql, V2__add_due_date.sql). The two are kept in sync
by hand deliberately — no autogenerate-from-model magic — so every schema
change is a reviewed, named migration file.
"""
import datetime as dt
import uuid

from pydantic import BaseModel, ConfigDict
from sqlalchemy import Boolean, Date, DateTime, String
from sqlalchemy.orm import Mapped, mapped_column

from .db import Base


class Task(Base):
    __tablename__ = "tasks"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    title: Mapped[str] = mapped_column(String(200))
    done: Mapped[bool] = mapped_column(Boolean, default=False)
    due_date: Mapped[dt.date | None] = mapped_column(Date, nullable=True)
    created_at: Mapped[dt.datetime] = mapped_column(DateTime, default=dt.datetime.utcnow)


class TaskCreate(BaseModel):
    title: str
    due_date: dt.date | None = None


class TaskUpdate(BaseModel):
    title: str | None = None
    done: bool | None = None
    due_date: dt.date | None = None


class TaskOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    title: str
    done: bool
    due_date: dt.date | None
    created_at: dt.datetime
