###############################################################################
# Baseline read-only monitoring policy
#
# Used only when var.monitoring_policy_documents is empty. This is a sensible
# least-privilege starting point covering the module's default feature_sets.
# The AUTHORITATIVE policy set is published by Dynatrace; for production, mirror
# Dynatrace's two managed policies into var.monitoring_policy_documents.
###############################################################################

data "aws_iam_policy_document" "baseline" {
  statement {
    sid    = "DynatraceReadOnlyDiscovery"
    effect = "Allow"
    actions = [
      "cloudwatch:GetMetricData",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:ListMetrics",
      "tag:GetResources",
      "tag:GetTagKeys",
      "tag:GetTagValues",
      "ec2:DescribeInstances",
      "ec2:DescribeVolumes",
      "ec2:DescribeRegions",
      "ec2:DescribeTags",
      "ec2:DescribeAvailabilityZones",
      "autoscaling:DescribeAutoScalingGroups",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTags",
      "rds:DescribeDBInstances",
      "rds:DescribeDBClusters",
      "rds:ListTagsForResource",
      "lambda:ListFunctions",
      "lambda:ListTags",
      "s3:ListAllMyBuckets",
      "s3:GetBucketTagging",
      "s3:GetBucketLocation",
      "dynamodb:ListTables",
      "dynamodb:DescribeTable",
      "dynamodb:ListTagsOfResource",
      "sqs:ListQueues",
      "sqs:ListQueueTags",
      "sns:ListTopics",
      "sns:ListTagsForResource",
    ]
    resources = ["*"]
  }
}

locals {
  # Choose operator-supplied policies if provided; otherwise the baseline.
  policy_documents = length(var.monitoring_policy_documents) > 0 ? var.monitoring_policy_documents : [data.aws_iam_policy_document.baseline.json]
}

resource "aws_iam_policy" "monitoring" {
  count = length(local.policy_documents)

  name        = "${var.iam_role_name}-policy-${count.index + 1}"
  description = "Dynatrace AWS monitoring read-only permissions (${count.index + 1}/${length(local.policy_documents)})."
  policy      = local.policy_documents[count.index]
  tags        = var.tags
}

# Trust policy: only Dynatrace's AWS account may assume the role, and only when
# presenting the connection's objectId as ExternalId (confused-deputy guard).
data "aws_iam_policy_document" "trust" {
  statement {
    sid     = "DynatraceAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.dynatrace_aws_account_id}:root"]
    }

    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [dynatrace_aws_connection.this.id]
    }
  }
}

resource "aws_iam_role" "monitoring" {
  name               = var.iam_role_name
  description        = "Assumed by Dynatrace (account ${var.dynatrace_aws_account_id}) for agentless AWS monitoring."
  assume_role_policy = data.aws_iam_policy_document.trust.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "monitoring" {
  count = length(aws_iam_policy.monitoring)

  role       = aws_iam_role.monitoring.name
  policy_arn = aws_iam_policy.monitoring[count.index].arn
}
