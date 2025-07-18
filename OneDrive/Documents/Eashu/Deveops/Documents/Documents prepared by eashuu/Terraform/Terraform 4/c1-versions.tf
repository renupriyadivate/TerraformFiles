#Terraform setting up block
terraform {
  required_providers {
    aws = {
      version = ">= 2.15.53"
      source  = "hashicorp/aws"
    }
  }
}


#Provider block
provider "aws" {
  region = "us-east-1"
}

