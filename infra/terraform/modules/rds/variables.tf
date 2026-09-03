variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "allowed_security_group_id" {
  description = "Security group (EKS nodes) permitted to reach Postgres on 5432"
  type        = string
}

variable "instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "database_name" {
  type    = string
  default = "tasks"
}

variable "username" {
  type    = string
  default = "tasks"
}

variable "deletion_protection" {
  description = "Set true for prod; false lets `terraform destroy` clean up a demo/staging env"
  type        = bool
  default     = false
}

variable "tags" {
  type    = map(string)
  default = {}
}
