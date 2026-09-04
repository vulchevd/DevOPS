# Bakes the migration SQL into the Flyway image so the migration Job
# (deploy/helm/tasks-api/templates/migration-job.yaml) just runs an
# immutable, versioned image — same promotion model as the app image, and
# no reliance on Helm's chart-relative file globbing to reach db/migrations.
FROM flyway/flyway:13-alpine

# Patch the base Alpine OS packages — the image as published can lag a few
# days behind Alpine's own security repo, and Trivy flags whatever CVEs
# have since been fixed upstream.
RUN apk update && apk upgrade --no-cache

# NOTE: we previously tried deleting unused vendor JDBC driver jars here
# (Snowflake, Databricks, MySQL, etc.) to clear their CVEs. That broke
# Flyway itself — its plugin loader enumerates every registered
# database-type plugin at startup regardless of which one you actually
# use, so removing one driver's jar while its registration elsewhere in
# the distribution still references it crashes Flyway with
# NoClassDefFoundError before it ever reaches Postgres. Reverted: any
# vendor-driver CVEs Trivy finds here are handled via .trivyignore
# instead (see repo root), not by deleting files from this image.

COPY migrations /flyway/sql
