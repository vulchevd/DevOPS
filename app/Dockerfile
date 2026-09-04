# Multi-stage build: the runtime image never sees a compiler, pip cache, or
# the requirements.txt / build tooling used to assemble the venv.
FROM python:3.12-slim AS builder

WORKDIR /build
COPY requirements.txt .
RUN python -m venv /venv \
    && /venv/bin/pip install --no-cache-dir --upgrade pip setuptools \
    && /venv/bin/pip install --no-cache-dir -r requirements.txt

FROM python:3.12-slim AS runtime

# Non-root, unprivileged user — also enforced cluster-side by the Kyverno
# policy in security/policies/kyverno/disallow-root.yaml as a backstop.
RUN groupadd --gid 10001 app && useradd --uid 10001 --gid app --no-create-home app

WORKDIR /app
COPY --from=builder /venv /venv
COPY src ./src

# The app only ever runs /venv/bin/uvicorn — it never invokes pip at
# runtime. Rather than chase CVEs in whatever pip/setuptools versions
# happen to ship in the base image and the venv (and pip's internally
# vendored msgpack, which can lag behind upstream fixes pip has no
# control over), just remove all of it: smaller image, smaller attack
# surface, nothing build-time-only left for a scanner to flag.
RUN pip uninstall -y pip setuptools \
    && /venv/bin/pip uninstall -y pip setuptools

ENV PATH="/venv/bin:$PATH" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

USER app
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/healthz')" || exit 1

CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8080"]
