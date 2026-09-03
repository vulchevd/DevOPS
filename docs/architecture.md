# Architecture

This is the written form of the design walked through live in the exam —
see the presentation order in `docs/runbook.md`. The interactive version
(with the pipeline diagram) is the published blueprint:
https://claude.ai/code/artifact/30b0e5c3-430c-440e-8ab9-8bc90a633c1b

## Why this app

Tasks API (FastAPI + PostgreSQL) exists to give the pipeline something real
to build, scan, migrate, and deploy — it's a means, not the deliverable.
Two endpoints and a health check were enough to justify every pipeline
stage without adding demo risk.

## High-level flow

```
Developer → feature branch → PR → CI (lint, SAST, SCA, secrets, IaC scan)
   → merge to main → CD (build → scan → migrate → deploy staging → DAST)
   → manual approval → promote to prod
```

Two loops, two different risk levels: the **PR loop** (`.github/workflows/ci.yml`)
is fast and cheap and never touches real infrastructure. The **release loop**
(`.github/workflows/cd.yml`) only runs on `main` and is where anything with
real consequences happens — a built image, a database migration, a rolling
deploy, real (staging) traffic.

## Low-level design

- **Branching:** GitHub Flow — protected `main`, short-lived `feature/*`
  branches, required PR review, required status checks (every `ci.yml` job).
- **Repo layout:** `app/` (service), `db/` (migrations + the Flyway image
  used to apply them), `infra/terraform/` (VPC/EKS/ECR/RDS, one module per
  concern), `deploy/helm/tasks-api/` (the chart), `security/` (Kyverno
  policies + the Semgrep ruleset), `.github/workflows/` (ci.yml, cd.yml).
- **Images:** one ECR repository (`tasks-api`) holds both the app image
  (tag = git SHA) and the migration image (tag = `migrate-<SHA>`) — one
  registry to scan and promote, not two.
- **Secrets:** Terraform writes the RDS connection details to AWS Secrets
  Manager (`infra/terraform/modules/rds`); the External Secrets Operator
  syncs them into a Kubernetes Secret the pod and the migration Job both
  read via `envFrom` — never a plaintext value in a Helm values file or a
  committed manifest.
- **AWS auth from CI:** GitHub OIDC → an assumable IAM role
  (`AWS_DEPLOY_ROLE_ARN`), not long-lived access keys in repo secrets.

## Security deep dive

Six controls, each answering a different question, each placed at the
earliest point in the pipeline where that question can actually be
answered:

| Stage | Tool | Runs | Gate |
|---|---|---|---|
| SAST | CodeQL + Semgrep | every PR | blocks merge on high/critical |
| Secret scan | gitleaks | every PR + push | blocks on any match |
| SCA | pip-audit + Dependabot | every PR | blocks on known CVE |
| IaC scan | tfsec + Checkov | PR, infra changes | warns / blocks on critical |
| Container image scan | Trivy | on `main`, after build | blocks push to ECR on critical |
| DAST | OWASP ZAP baseline | post-deploy, staging | warns; reviewed before prod promotion |

**Why this ordering:** code-level issues (SAST, secrets, SCA) are caught on
every PR, before a build even happens — cheapest possible failure. IaC
misconfiguration is caught in the same PR review, before `terraform apply`
would ever touch a real AWS account. The image itself can only be scanned
once it exists, so Trivy sits right after `docker build`, gating entry into
ECR. DAST necessarily comes last — it needs something actually running —
which is also why it gates the prod-promotion approval rather than the
merge itself.

**Runtime backstop:** a small Kyverno policy set
(`security/policies/kyverno/`) enforces at admission time what the pipeline
can't: no root containers, mandatory resource limits, images only from this
project's own ECR. This catches anything that reaches the cluster outside
the pipeline's own path.

## Kubernetes deploy (mandatory component)

`deploy/helm/tasks-api` — `RollingUpdate` with `maxSurge: 1`,
`maxUnavailable: 0`: new pods must pass their readiness probe
(`GET /healthz`) before any old pod is removed, so a rollout never drops
capacity. Resource requests/limits are set on every container — also what
the Kyverno `require-resource-limits` policy is backstopping.

## Database changes

Flyway migrations (`db/migrations/V<n>__description.sql`) are validated in
CI against a throwaway `postgres:16` service container, then applied for
real by a Helm `pre-upgrade` hook Job — built as its own immutable, scanned
image (`db/Dockerfile`) so `helm upgrade` fails (and rolls back) before any
new application code runs against a schema it doesn't expect.

Migrations are additive-only for this project — new columns nullable or
defaulted, no destructive drops in the same release that ships code
depending on them (the standard expand/contract approach). `V2__add_due_date.sql`
is the example: adds a nullable column ahead of the code that starts using it.

## Future improvements

Deliberately left out of the initial build, in rough order of value:

1. **GitOps with Argo CD** — pull-based reconciliation instead of
   `helm upgrade` from a runner; better audit trail, `git revert` as
   rollback, no long-lived cluster credentials in CI.
2. **Progressive delivery** — Argo Rollouts canary/blue-green with
   automated analysis (error rate, latency) gating promotion instead of a
   human clicking approve.
3. **SBOM + provenance** — Syft-generated SBOM and SLSA provenance
   attestation on every image: "what's in this container" and "did our
   pipeline really build this," answered definitively.
4. **Observability** — Prometheus/Grafana + OpenTelemetry tracing; today
   the design has health checks but no real signal once traffic is live.
5. **Policy-as-code pre-merge** — statically check the Kyverno rules
   against the Helm chart in CI, so a bad manifest is caught before merge,
   not at admission time.
6. **Cost** — Karpenter autoscaling instead of a fixed node group; the
   current design provisions for peak, not actual load.
