variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_account_id" {
  type = string
}

variable "connection_name" {
  type = string
}

variable "extension_version" {
  type = string
}

variable "monitored_regions" {
  type    = list(string)
  default = ["us-east-1"]
}

variable "tags" {
  type = map(string)
  default = {
    managed-by = "terraform"
    purpose    = "dynatrace-aws-connector"
  }
}

module "connector" {
  source = "../../modules/dynatrace-aws-connector"

  connection_name   = var.connection_name
  aws_account_id    = var.aws_account_id
  deployment_region = var.aws_region
  monitored_regions = var.monitored_regions
  extension_version = var.extension_version
  iam_role_name     = "DynatraceMonitoringRole-${var.connection_name}"
  tags              = var.tags
}

output "connection_id" {
  value = module.connector.connection_id
}

output "monitoring_role_arn" {
  value = module.connector.monitoring_role_arn
}

output "monitoring_config_id" {
  value = module.connector.monitoring_config_id
}
