# Bakes the migration SQL into the Flyway image so the migration Job
# (deploy/helm/tasks-api/templates/migration-job.yaml) just runs an
# immutable, versioned image — same promotion model as the app image, and
# no reliance on Helm's chart-relative file globbing to reach db/migrations.
FROM flyway/flyway:13-alpine

# This project only ever migrates PostgreSQL. Flyway's official image
# bundles JDBC drivers — and each driver's own dependency tree — for many
# database vendors we never use (Snowflake, Databricks, MySQL, Oracle, SQL
# Server, etc.), which is where Trivy's Netty/HttpComponents/vendor-JDBC
# findings keep coming from. Strip that unused surface out rather than
# chase each vendor's own release cadence; the postgresql driver and
# Flyway's own core jars are left untouched.
RUN find /flyway -iname '*.jar' \
      \( -iname '*snowflake*' -o -iname '*databricks*' -o -iname '*redshift*' \
         -o -iname '*mysql*' -o -iname '*mariadb*' -o -iname '*mssql*' \
         -o -iname '*sqlserver*' -o -iname '*ojdbc*' -o -iname '*oracle*' \
         -o -iname '*db2*' -o -iname '*sqlite*' -o -iname '*saphana*' \
         -o -iname '*hana*' -o -iname '*informix*' -o -iname '*teradata*' \
         -o -iname '*cockroach*' -o -iname '*netty*' \) \
      -delete

COPY migrations /flyway/sql
