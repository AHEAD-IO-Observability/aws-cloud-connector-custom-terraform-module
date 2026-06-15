terraform {
  required_version = ">= 1.5.0"

  required_providers {
    dynatrace = {
      source  = "dynatrace-oss/dynatrace"
      version = "~> 1.96"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40"
    }
  }
}
