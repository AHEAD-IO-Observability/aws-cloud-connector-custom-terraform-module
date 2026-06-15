###############################################################################
# Identity / naming
###############################################################################

variable "connection_name" {
  description = "Name of the Dynatrace AWS connection (settings object). 3-100 chars; ':' is not allowed."
  type        = string

  validation {
    condition     = length(var.connection_name) >= 3 && length(var.connection_name) <= 100 && !strcontains(var.connection_name, ":")
    error_message = "connection_name must be 3-100 characters and must not contain ':'."
  }
}

variable "iam_role_name" {
  description = "Name of the cross-account IAM role Dynatrace assumes for monitoring."
  type        = string
  default     = "DynatraceMonitoringRole"
}

variable "tags" {
  description = "Tags applied to AWS resources created by this module."
  type        = map(string)
  default     = {}
}

###############################################################################
# AWS account / region scope
###############################################################################

variable "aws_account_id" {
  description = "12-digit AWS account ID being onboarded. Must match the account the IAM role lives in."
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "aws_account_id must be exactly 12 digits."
  }
}

variable "deployment_region" {
  description = "Primary AWS region for the Dynatrace data-acquisition deployment (e.g. us-east-1)."
  type        = string
}

variable "monitored_regions" {
  description = <<-EOT
    Regions Dynatrace polls for metrics/topology. Include us-east-1 if you want
    global-service topology (Route53, CloudFront, IAM) — global resources are
    surfaced via us-east-1. Empirically not server-enforced, but recommended.
  EOT
  type        = list(string)

  validation {
    condition     = length(var.monitored_regions) > 0
    error_message = "Provide at least one monitored region."
  }
}

###############################################################################
# Dynatrace side
###############################################################################

variable "dynatrace_aws_account_id" {
  description = "Dynatrace's AWS account ID that assumes the monitoring role (the trust-policy principal). Verified live 2026-06; override only if Dynatrace changes it."
  type        = string
  default     = "314146291599"
}

variable "extension_name" {
  description = "Fully qualified da-aws extension name."
  type        = string
  default     = "com.dynatrace.extension.da-aws"
}

variable "extension_version" {
  description = "da-aws extension version the monitoring config targets. Must already be active in the tenant (run the one-time hub addToEnvironment bootstrap first). Pin this — re-running the hub call silently upgrades to latest."
  type        = string
}

variable "consumers" {
  description = "Dynatrace services allowed to consume the connection. SVC:com.dynatrace.da = Data Acquisition (the cloud connector)."
  type        = list(string)
  default     = ["SVC:com.dynatrace.da"]
}

variable "feature_sets" {
  description = "AWS service feature sets to enable in the monitoring config. The IAM policy is the permission ceiling; feature_sets are the throttle."
  type        = list(string)
  default = [
    "EC2_essential",
    "EBS_essential",
    "Lambda_essential",
    "RDS_essential",
    "S3_essential",
    "ApplicationELB_essential",
    "NetworkELB_essential",
    "ELB_essential",
    "DynamoDB_essential",
    "SQS_essential",
    "SNS_essential",
    "AutoScaling_essential",
  ]
}

variable "monitoring_config_enabled" {
  description = "Whether the monitoring configuration is enabled on creation."
  type        = bool
  default     = true
}

variable "enable_cloudwatch_logs" {
  description = "Enable CloudWatch Logs ingestion regions in the monitoring config (Pattern 2 territory; leave false for connector-only)."
  type        = bool
  default     = false
}

###############################################################################
# IAM monitoring policy
###############################################################################

variable "monitoring_policy_documents" {
  description = <<-EOT
    List of IAM policy JSON documents attached to the monitoring role. Defaults to a
    read-only baseline covering the default feature_sets. For full coverage, paste
    Dynatrace's two officially published monitoring policies here (the canonical source
    of truth) — the list shape supports the documented 2-policy split that exists to
    stay under the 6144-char managed-policy limit.
  EOT
  type        = list(string)
  default     = []
}

variable "role_arn_create_timeout" {
  description = "Timeout for the connection->role binding while waiting for IAM propagation. The provider does a live AssumeRole; a just-created role can transiently fail."
  type        = string
  default     = "2m"
}
