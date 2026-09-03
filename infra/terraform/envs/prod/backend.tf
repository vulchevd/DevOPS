terraform {
  backend "s3" {
    bucket         = "REPLACE_ME-tasks-tfstate"
    key            = "prod/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "REPLACE_ME-tasks-tf-locks"
    encrypt        = true
  }
}
