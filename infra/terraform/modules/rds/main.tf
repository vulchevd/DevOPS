# Single-AZ, small instance class — sized for a course project, not
# production load. Password is generated and stored in Secrets Manager, never
# passed as a plain tfvar; the cluster reads it via External Secrets
# (deploy/helm/tasks-api/templates/externalsecret.yaml), matching the
# "runtime secrets, not just committed secrets" point in the security deep
# dive (docs/architecture.md).

resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-subnets"
  subnet_ids = var.private_subnet_ids
  tags       = var.tags
}

resource "aws_security_group" "rds" {
  name_prefix = "${var.name}-rds-"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Postgres from the EKS node/pod security group only"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.allowed_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "random_password" "master" {
  length  = 24
  special = false # avoid characters that need escaping in a JDBC/psycopg URL
}

resource "aws_secretsmanager_secret" "db" {
  name = "${var.name}-db-credentials"
  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  # Keys are named to match the env vars the app and the Flyway migration
  # Job read directly (see deploy/helm/tasks-api/templates/deployment.yaml
  # and migration-job.yaml) — the ExternalSecret extracts this JSON verbatim
  # into a Kubernetes Secret, so the key names here *are* the env var names.
  secret_string = jsonencode({
    DB_USERNAME      = var.username
    DB_PASSWORD      = random_password.master.result
    DB_HOST          = aws_db_instance.this.address
    DB_PORT          = "5432"
    DB_NAME          = var.database_name
    DATABASE_URL     = "postgresql+psycopg://${var.username}:${random_password.master.result}@${aws_db_instance.this.address}:5432/${var.database_name}"
    DATABASE_URL_JDBC = "postgresql://${aws_db_instance.this.address}:5432/${var.database_name}"
  })
}

resource "aws_db_instance" "this" {
  identifier     = var.name
  engine         = "postgres"
  engine_version = "16.4"
  instance_class = var.instance_class

  allocated_storage     = 20
  storage_encrypted     = true
  db_name                = var.database_name
  username               = var.username
  password               = random_password.master.result
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  multi_az                  = false
  publicly_accessible       = false
  backup_retention_period    = 0
  deletion_protection        = var.deletion_protection
  skip_final_snapshot        = !var.deletion_protection
  auto_minor_version_upgrade = true

  tags = var.tags
}
