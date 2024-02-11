# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = {
      Environment     = var.environment
      Application     = var.application_name
    }
  }
}

# This provider is used to create ACM certificate to us-east-1
provider "aws" {
  alias  = "acm"
  region = "us-east-1"
  profile = var.aws_profile

  default_tags {
    tags = {
      Environment     = var.environment
      Application     = var.application_name
    }
  }
}