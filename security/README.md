# Security controls

This directory holds the one thing that doesn't live naturally inside a
single pipeline stage: the Kyverno admission policies applied directly to
the cluster (`policies/kyverno/`), as a backstop for anything that reaches
the cluster without going through `.github/workflows/`.

Everything else in the security deep dive is defined where it runs:

| Control | Defined in |
|---|---|
| SAST (CodeQL + Semgrep) | `.github/workflows/ci.yml` |
| Secret scanning (gitleaks) | `.github/workflows/ci.yml` |
| SCA / dependency scan (pip-audit) | `.github/workflows/ci.yml` |
| IaC scan (tfsec, checkov) | `.github/workflows/ci.yml` |
| Container image scan (Trivy) | `.github/workflows/cd.yml` |
| DAST (OWASP ZAP baseline) | `.github/workflows/cd.yml` |
| Admission control (Kyverno) | `security/policies/kyverno/` (applied once to the cluster, not per-deploy) |

Apply the policies once per cluster, after the cluster exists and Kyverno is
installed:

```bash
kubectl apply -f security/policies/kyverno/
```

See `docs/architecture.md` for why each control sits where it does.

## Placeholders

`restrict-image-registries.yaml` has `REPLACE_ME.dkr.ecr.*.amazonaws.com` —
replace with your account's actual ECR registry hostname once
`infra/terraform` has been applied (`aws ecr describe-repositories` or the
Terraform output `ecr_repository_url`).
