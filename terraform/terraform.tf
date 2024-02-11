terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.25.0"
    }
    null = {
      source = "hashicorp/null"
      version = "3.2.1"
    }
    archive = {
      source = "hashicorp/archive"
      version = "2.4.0"
    }
  }
}