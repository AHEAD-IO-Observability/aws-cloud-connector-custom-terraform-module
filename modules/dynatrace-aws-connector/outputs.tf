output "connection_id" {
  description = "Dynatrace connection settings objectId. Also the IAM trust-policy ExternalId."
  value       = dynatrace_aws_connection.this.id
}

output "connection_name" {
  description = "Name of the Dynatrace AWS connection."
  value       = dynatrace_aws_connection.this.name
}

output "monitoring_role_arn" {
  description = "ARN of the cross-account IAM role Dynatrace assumes."
  value       = aws_iam_role.monitoring.arn
}

output "monitoring_role_name" {
  description = "Name of the cross-account IAM role."
  value       = aws_iam_role.monitoring.name
}

output "monitoring_policy_arns" {
  description = "ARNs of the monitoring policies attached to the role."
  value       = aws_iam_policy.monitoring[*].arn
}

output "monitoring_config_id" {
  description = "Dynatrace da-aws monitoring configuration objectId."
  value       = dynatrace_hub_extension_v2_config.this.id
}

output "external_id" {
  description = "The ExternalId enforced on the IAM trust relationship (equals connection_id)."
  value       = dynatrace_aws_connection.this.id
}
