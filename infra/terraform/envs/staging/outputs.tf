output "cluster_name" {
  value = module.eks.cluster_name
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "rds_endpoint" {
  value = module.rds.endpoint
}

output "db_secret_arn" {
  description = "Feed this into the ExternalSecret in the Helm chart"
  value       = module.rds.secret_arn
}
