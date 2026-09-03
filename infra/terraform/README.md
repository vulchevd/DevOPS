# Infrastructure as code

Four modules (`network`, `ecr`, `eks`, `rds`) composed per environment under
`envs/staging` and `envs/prod`. Nothing here has been applied against a real
AWS account yet — this repo ships the code, not the running infra.

## Before the first `apply`

1. Create an S3 bucket + DynamoDB table for remote state and lock, and fill
   them into `envs/<env>/backend.tf` (replace the `REPLACE_ME-...` names).
2. `cp terraform.tfvars.example terraform.tfvars` in the env directory and
   adjust region/AZs if needed.
3. `terraform init && terraform plan` — review before `apply`.

## What CI does vs. what a human does

`ci.yml` runs `terraform fmt -check`, `terraform validate`, and the tfsec /
Checkov IaC scan on every PR that touches `infra/terraform/**`, and posts a
`terraform plan` for review — but nothing in this repo's automation runs
`terraform apply`. That's a deliberate choice for this project: provisioning
real, billable cloud infrastructure from an automated pipeline is exactly
the kind of step worth keeping a human in the loop for, and it's also the
first thing worth automating away in a follow-up (see "GitOps" and
"policy-as-code pre-merge" in docs/architecture.md's future-improvements
section) once the project has to run unattended.
