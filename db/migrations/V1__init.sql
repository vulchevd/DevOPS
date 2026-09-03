-- Baseline schema. Applied by Flyway; validated in CI (ci.yml) against an
-- ephemeral Postgres container, applied for real by the pre-deploy
-- migration Job (deploy/helm/tasks-api/templates/migration-job.yaml).
CREATE TABLE tasks (
    id          VARCHAR(36) PRIMARY KEY,
    title       VARCHAR(200) NOT NULL,
    done        BOOLEAN NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMP NOT NULL DEFAULT now()
);
