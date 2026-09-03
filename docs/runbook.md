# Runbook

## First-time setup (before any pipeline run)

1. `infra/terraform/envs/staging`: create the S3/DynamoDB backend, fill in
   `terraform.tfvars`, `terraform init && terraform apply`. Same for `prod`
   when you're ready for it. This is a manual, human-run step — see
   `infra/terraform/README.md` for why.
2. Note the Terraform outputs `ecr_repository_url`, `cluster_name`, and
   `db_secret_arn` — the last one goes into
   `deploy/helm/tasks-api/values-staging.yaml` /`values-prod.yaml`
   (`externalSecret.secretArn`) and the `STAGING_DB_SECRET_ARN` /
   `PROD_DB_SECRET_ARN` GitHub Actions secrets.
3. Install the External Secrets Operator and Kyverno on each cluster, then
   `kubectl apply -f security/policies/kyverno/` (after replacing the
   `REPLACE_ME` registry placeholder in `restrict-image-registries.yaml`
   with the real ECR hostname).
4. Create the `AWS_DEPLOY_ROLE_ARN` GitHub secret (an IAM role trusting
   GitHub's OIDC provider, scoped to ECR push + EKS deploy) and the
   `STAGING_URL` secret used by the DAST job.
5. In repo Settings → Environments, create a `production` environment with
   required reviewers — that's what makes `promote-prod` in `cd.yml` wait
   for a human.

## Everyday flow

Open an issue → branch → PR (CI runs automatically) → merge → CD deploys to
staging automatically → DAST scan runs → a reviewer approves the
`production` environment → prod deploy runs.

## Rolling back

- **Bad app release:** `helm rollback tasks-api <revision> -n tasks-api`, or
  re-run `cd.yml` against the last-known-good commit SHA.
- **Bad migration:** migrations are additive-only by convention (see
  `docs/architecture.md`), so a rollback is almost always "roll the app back
  and leave the schema" rather than reversing SQL — unwind data changes by
  hand only if a migration genuinely needs it.

## Exam-day checklist

Format: high-level design → low-level design → deep dive (security) →
future improvements → questions, 12–15 minutes total.

- [ ] Presentation slot booked
- [ ] Staging cluster/RDS/ECR already provisioned and idle before the slot
      starts (`terraform apply` the night before — this is the brief's
      required "preset environment")
- [ ] A pre-staged branch with a deliberately bad dependency or a hardcoded
      secret, ready to open as a PR, so a gate can fail live on stage
- [ ] `docs/architecture.md` and this runbook committed — documentation is
      graded as part of the solution
- [ ] Rehearsed once against the clock — the security deep dive (5 of the
      ~13 minutes) is the segment most likely to run long

Suggested time budget: high-level ~2 min, low-level ~3 min, security deep
dive ~5 min (live: open the pre-staged PR, watch SAST run; then show the
Trivy gate refusing a vulnerable image), future improvements ~2 min (pick
two or three from the list, not all six), questions ~2–3 min buffer.
