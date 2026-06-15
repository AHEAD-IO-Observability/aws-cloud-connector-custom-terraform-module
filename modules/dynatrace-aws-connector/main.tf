###############################################################################
# Phase 1 — Dynatrace connection (created with NO role ARN).
# Its exported `id` is the settings objectId, which doubles as the IAM ExternalId.
###############################################################################

resource "dynatrace_aws_connection" "this" {
  name = var.connection_name

  role_based_auth {
    consumers = var.consumers
  }
}

###############################################################################
# Phase 2 — IAM role + policies live in iam.tf, keyed off the connection id.
###############################################################################

###############################################################################
# Phase 3 — Bind the role ARN onto the connection.
# Writing the ARN triggers a live sts:AssumeRole from Dynatrace using the
# connection id as ExternalId. A 200 here IS the integration test: it proves
# the cross-account trust works. The provider retries through IAM propagation.
###############################################################################

resource "dynatrace_aws_connection_role_arn" "this" {
  aws_connection_id = dynatrace_aws_connection.this.id
  role_arn          = aws_iam_role.monitoring.arn

  timeouts {
    create = var.role_arn_create_timeout
  }

  depends_on = [aws_iam_role_policy_attachment.monitoring]
}

###############################################################################
# Phase 4 — Monitoring configuration (which AWS services/regions to poll).
# Server validators enforce: 1 account <-> 1 connection <-> 1 config, and the
# referenced connection must already have a valid (assumable) role — hence the
# dependency on the role-arn binding above.
###############################################################################

resource "dynatrace_hub_extension_v2_config" "this" {
  name  = var.extension_name
  scope = "integration-aws"

  value = jsonencode({
    enabled     = var.monitoring_config_enabled
    description = var.connection_name
    version     = var.extension_version
    featureSets = var.feature_sets
    aws = {
      deploymentRegion = var.deployment_region
      credentials = [{
        enabled      = var.monitoring_config_enabled
        description  = var.connection_name
        connectionId = dynatrace_aws_connection.this.id
        accountId    = var.aws_account_id
      }]
      regionFiltering = var.monitored_regions
      metricsConfiguration = {
        enabled = true
        regions = var.monitored_regions
      }
      cloudWatchLogsConfiguration = {
        enabled = var.enable_cloudwatch_logs
        regions = var.enable_cloudwatch_logs ? var.monitored_regions : []
      }
      configurationMode        = "QUICK_START"
      deploymentScope          = "SINGLE_ACCOUNT"
      deploymentMode           = "MANUAL"
      manualDeploymentStatus   = "COMPLETE"
      automatedDeploymentStatus = "NA"
    }
  })

  depends_on = [dynatrace_aws_connection_role_arn.this]
}
