variable "name" {
  description = "ECR repository name, e.g. \"tasks-api\""
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
