# Remote state — fill in a bucket/table you own before the first `terraform
# init`. A local backend is fine to start with (comment this whole block
# out) but switch before more than one person, or CI, ever runs apply.
terraform {
  backend "s3" {
    bucket         = "REPLACE_ME-tasks-tfstate"
    key            = "staging/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "REPLACE_ME-tasks-tf-locks"
    encrypt        = true
  }
}
