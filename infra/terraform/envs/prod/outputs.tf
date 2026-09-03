output "cluster_name" {
  value = module.eks.cluster_name
}

output "rds_endpoint" {
  value = module.rds.endpoint
}

output "db_secret_arn" {
  value = module.rds.secret_arn
}
