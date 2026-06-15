# Module: dynatrace-aws-connector

Onboards a single AWS account to a Dynatrace Gen 3 tenant's cloud connector
(agentless AWS monitoring) in one `terraform apply`. See the
[repository README](../../README.md) for the full picture (bootstrap prerequisite,
auth/OAuth scopes, pipeline placement, Dynatrace doc links, validation).

## Requirements

| Name | Version |
|---|---|
| terraform | >= 1.5.0 |
| dynatrace-oss/dynatrace | ~> 1.96 |
| hashicorp/aws | ~> 5.40 |

## Usage

```hcl
module "connector" {
  source = "github.com/AHEAD-IO-Observability/aws-cloud-connector-custom-terraform-module//modules/dynatrace-aws-connector"

  connection_name   = "payments-prod-us-east-1"
  aws_account_id    = "111122223333"
  deployment_region = "us-east-1"
  monitored_regions = ["us-east-1", "us-west-2"]
  extension_version = "1.0.11" # the active da-aws version in your tenant

  # optional
  iam_role_name = "DynatraceMonitoringRole-payments-prod"
  feature_sets  = ["EC2_essential", "Lambda_essential", "RDS_essential", "S3_essential"]
  tags          = { team = "payments", managed-by = "terraform" }
}
```

Pin the module to a released tag in production, e.g.
`source = "github.com/AHEAD-IO-Observability/aws-cloud-connector-custom-terraform-module//modules/dynatrace-aws-connector?ref=v1.0.0"`.

## Inputs

| Name | Type | Default | Required |
|---|---|---|:--:|
| `connection_name` | string | – | yes |
| `aws_account_id` | string (12 digits) | – | yes |
| `deployment_region` | string | – | yes |
| `monitored_regions` | list(string) | – | yes |
| `extension_version` | string | – | yes |
| `iam_role_name` | string | `DynatraceMonitoringRole` | no |
| `consumers` | list(string) | `["SVC:com.dynatrace.da"]` | no |
| `feature_sets` | list(string) | 12 essential sets | no |
| `monitoring_config_enabled` | bool | `true` | no |
| `enable_cloudwatch_logs` | bool | `false` | no |
| `monitoring_policy_documents` | list(string) | `[]` (baseline policy) | no |
| `dynatrace_aws_account_id` | string | `314146291599` | no |
| `role_arn_create_timeout` | string | `2m` | no |
| `tags` | map(string) | `{}` | no |

## Outputs

| Name | Description |
|---|---|
| `connection_id` | Connection settings objectId (also the IAM ExternalId) |
| `connection_name` | Connection name |
| `monitoring_role_arn` | Cross-account IAM role ARN |
| `monitoring_role_name` | IAM role name |
| `monitoring_policy_arns` | Attached policy ARNs |
| `monitoring_config_id` | da-aws monitoring configuration objectId |
| `external_id` | ExternalId enforced on the IAM trust (equals `connection_id`) |
