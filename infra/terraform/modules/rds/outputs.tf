output "endpoint" {
  value = aws_db_instance.this.address
}

output "secret_arn" {
  description = "ARN of the Secrets Manager secret holding the connection URL — referenced by the ExternalSecret in the Helm chart"
  value       = aws_secretsmanager_secret.db.arn
}

output "security_group_id" {
  value = aws_security_group.rds.id
}
