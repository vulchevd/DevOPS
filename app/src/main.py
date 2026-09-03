"""Tasks API.

Deliberately small: three resource endpoints plus a health check. The point
of this service is to give the pipeline (build, scan, migrate, deploy)
something real to operate on, not to be a complete product.
"""
from fastapi import Depends, FastAPI, HTTPException
from sqlalchemy.orm import Session

from .db import get_db
from .models import Task, TaskCreate, TaskOut, TaskUpdate

app = FastAPI(title="Tasks API", version="0.1.0")


@app.get("/healthz")
def healthz() -> dict:
    """Liveness/readiness target — see deploy/helm/tasks-api/values.yaml."""
    return {"status": "ok"}


@app.get("/tasks", response_model=list[TaskOut])
def list_tasks(db: Session = Depends(get_db)) -> list[Task]:
    return db.query(Task).order_by(Task.created_at.desc()).all()


@app.post("/tasks", response_model=TaskOut, status_code=201)
def create_task(payload: TaskCreate, db: Session = Depends(get_db)) -> Task:
    task = Task(title=payload.title, due_date=payload.due_date)
    db.add(task)
    db.commit()
    db.refresh(task)
    return task


@app.get("/tasks/{task_id}", response_model=TaskOut)
def get_task(task_id: str, db: Session = Depends(get_db)) -> Task:
    task = db.get(Task, task_id)
    if task is None:
        raise HTTPException(status_code=404, detail="task not found")
    return task


@app.patch("/tasks/{task_id}", response_model=TaskOut)
def update_task(task_id: str, payload: TaskUpdate, db: Session = Depends(get_db)) -> Task:
    task = db.get(Task, task_id)
    if task is None:
        raise HTTPException(status_code=404, detail="task not found")
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(task, field, value)
    db.commit()
    db.refresh(task)
    return task


@app.delete("/tasks/{task_id}", status_code=204)
def delete_task(task_id: str, db: Session = Depends(get_db)) -> None:
    task = db.get(Task, task_id)
    if task is None:
        raise HTTPException(status_code=404, detail="task not found")
    db.delete(task)
    db.commit()
