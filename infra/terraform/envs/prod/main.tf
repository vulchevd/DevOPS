terraform {
  required_version = ">= 1.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  name = "tasks-prod"
  tags = {
    Project     = "tasks-api"
    Environment = "prod"
    ManagedBy   = "terraform"
  }
}

module "network" {
  source = "../../modules/network"
  name   = local.name
  azs    = var.azs
  tags   = local.tags
}

# Reuses the same ECR repository as staging (module.ecr is not redeclared
# here) — one image, one registry, promoted between environments rather than
# rebuilt. See docs/architecture.md for the promotion flow.

module "eks" {
  source     = "../../modules/eks"
  name       = local.name
  subnet_ids = module.network.private_subnet_ids
  tags       = local.tags

  node_instance_types = ["t3.large"]
  node_desired_size    = 3
  node_min_size        = 3
  node_max_size        = 6
}

module "rds" {
  source                     = "../../modules/rds"
  name                       = local.name
  vpc_id                     = module.network.vpc_id
  private_subnet_ids         = module.network.private_subnet_ids
  allowed_security_group_id  = module.eks.node_security_group_id
  instance_class              = "db.t4g.small"
  deletion_protection         = true
  tags                        = local.tags
}
