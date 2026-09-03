# Tasks API — Pipeline Blueprint Reference Implementation

A small FastAPI + PostgreSQL service, built specifically to give a CI/CD pipeline
something real to build, scan, migrate, and deploy. The app is intentionally
boring — the pipeline is the point.

Full design writeup: see `docs/architecture.md`.

## What's here

| Path | Purpose |
|---|---|
| `app/` | FastAPI service (source + tests + Dockerfile) |
| `db/migrations/` | Flyway-versioned SQL migrations |
| `infra/terraform/` | AWS infra as code: VPC, EKS, ECR, RDS |
| `deploy/helm/tasks-api/` | Helm chart for the Kubernetes deployment |
| `security/policies/kyverno/` | Cluster admission policies (defense in depth) |
| `.github/workflows/` | `ci.yml` (PR checks) and `cd.yml` (build/deploy) |
| `docs/` | Architecture and operational runbook |

## Local development

```bash
cd app
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt -r requirements-dev.txt

# run against a local Postgres, or export DATABASE_URL for anything else
export DATABASE_URL=postgresql+psycopg://tasks:tasks@localhost:5432/tasks

uvicorn src.main:app --reload
```

Run the tests (they use an in-memory SQLite DB, no Postgres required):

```bash
pytest
```

Lint:

```bash
ruff check .
```

## Building the image

```bash
docker build -t tasks-api:local ./app
docker run -p 8080:8080 -e DATABASE_URL=... tasks-api:local
```

## Provisioning AWS (manual, before the first pipeline run)

The pipeline deploys into infrastructure — it doesn't create the cluster from
scratch on every run. Provision once per environment:

```bash
cd infra/terraform/envs/staging
cp terraform.tfvars.example terraform.tfvars   # fill in your values
terraform init
terraform plan
terraform apply
```

This is deliberately a manual, human-run step for this project (see
`docs/architecture.md` for why) — the pipeline's CI stage only ever runs
`terraform plan` for review; nothing applies automatically.

## Deploying

Once staging infra exists and `KUBECONFIG` points at it:

```bash
helm upgrade --install tasks-api ./deploy/helm/tasks-api \
  -f deploy/helm/tasks-api/values-staging.yaml \
  --namespace tasks-api --create-namespace
```

In normal operation this happens via `.github/workflows/cd.yml` on merge to `main`.

## Status

Scaffold stage — see `docs/architecture.md` for the full design and
`docs/runbook.md` for exam-day / operational notes. Terraform has not been
applied against any real AWS account yet.
