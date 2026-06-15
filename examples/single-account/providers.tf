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

# Dynatrace auth via environment variables (recommended). Pick ONE model:
#
#   Recommended (single credential, drives both classic + platform surfaces):
#     DYNATRACE_ENV_URL=https://<tenant>.live.dynatrace.com
#     DT_CLIENT_ID / DT_CLIENT_SECRET / DT_ACCOUNT_ID   (OAuth client)
#     DYNATRACE_HTTP_OAUTH_PREFERENCE=true
#
#   Mixed tokens (works, less clean ownership):
#     DYNATRACE_ENV_URL + DYNATRACE_API_TOKEN          (classic: connection + role binding)
#     DYNATRACE_PLATFORM_TOKEN                          (platform: monitoring config)
#
# NOTE: a bare platform token alone CANNOT create the connection (classic resource).
provider "dynatrace" {}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}
