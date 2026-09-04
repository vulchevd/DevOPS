# Bakes the migration SQL into the Flyway image so the migration Job
# (deploy/helm/tasks-api/templates/migration-job.yaml) just runs an
# immutable, versioned image — same promotion model as the app image, and
# no reliance on Helm's chart-relative file globbing to reach db/migrations.
FROM flyway/flyway:13-alpine
COPY migrations /flyway/sql
