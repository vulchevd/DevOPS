# Database migrations

Flyway-versioned SQL, applied in order: `V<n>__description.sql`. Never edit a
migration that has already run anywhere (staging included) — add a new one.

## Local validation

```bash
docker run --rm -v "$(pwd)/migrations:/flyway/sql" \
  -e FLYWAY_URL=jdbc:postgresql://host.docker.internal:5432/tasks \
  -e FLYWAY_USER=tasks -e FLYWAY_PASSWORD=tasks \
  flyway/flyway:10 validate
```

CI runs the equivalent against a disposable `postgres:16` service container
on every PR that touches `db/migrations/**`.
