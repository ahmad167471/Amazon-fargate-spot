terraform {
  backend "s3" {
    bucket  = "ahmad-strapi-fargate-task"
    key     = "ahmad-fargate/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

provider "aws" {
  region = var.region
}
