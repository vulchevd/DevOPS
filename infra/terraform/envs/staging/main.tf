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
  name = "tasks-staging"
  tags = {
    Project     = "tasks-api"
    Environment = "staging"
    ManagedBy   = "terraform"
  }
}

module "network" {
  source = "../../modules/network"
  name   = local.name
  azs    = var.azs
  tags   = local.tags
}

module "ecr" {
  source = "../../modules/ecr"
  name   = "tasks-api"
  tags   = local.tags
}

module "eks" {
  source     = "../../modules/eks"
  name       = local.name
  subnet_ids = module.network.private_subnet_ids
  tags       = local.tags

  # Deliberately small — this is a demo/staging environment, not prod load.
  # t3.micro (not the module default t3.medium) to stay free-tier eligible.
  node_instance_types = ["t3.micro"]
  node_desired_size    = 2
  node_max_size        = 3
}

module "rds" {
  source                     = "../../modules/rds"
  name                       = local.name
  vpc_id                     = module.network.vpc_id
  private_subnet_ids         = module.network.private_subnet_ids
  allowed_security_group_id  = module.eks.node_security_group_id
  deletion_protection        = false
  tags                       = local.tags
}
