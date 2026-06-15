# Validation record

**Date:** 2026-06-15
**Providers:** `dynatrace-oss/dynatrace` v1.98.0, `hashicorp/aws` v5.100.0 · Terraform v1.14.0
**Tenant:** Gen 3 SaaS (lab) · **AWS account:** lab account (12-digit, redacted) · **Region:** us-east-1
**Dynatrace auth:** OAuth client (`settings:objects:read/write/admin`, `extensions:configurations:read/write`) — single credential, both surfaces.

## Results — full end-to-end PASS

| Check | Result |
|---|---|
| `terraform init` (both providers resolve + lock) | PASS |
| `terraform validate` | PASS |
| Live apply: **all 4 phases, one `terraform apply`** (6 resources) | PASS — 6 added, 0 changed, 0 destroyed |
| Phase 1 — `dynatrace_aws_connection` | PASS |
| Phase 2 — `aws_iam_role` + policy + attachment | PASS |
| Phase 3 — `dynatrace_aws_connection_role_arn` (live cross-account `sts:AssumeRole`) | **PASS — completed ~9s** |
| Phase 4 — `dynatrace_hub_extension_v2_config` (monitoring config) | PASS — created enabled |
| Verify: connection carries role ARN | PASS |
| Verify: IAM trust principal = `314146291599`, ExternalId = connection id | PASS — exact match to `terraform output connection_id` |
| Verify: monitoring config enabled, v1.0.11, correct accountId/connectionId/featureSets/region | PASS |
| `terraform destroy` | PASS — 6 destroyed; 0 configs, 0 connections, IAM role `NoSuchEntity` |

## Auth notes

- One **OAuth client** drove the entire module across both the classic settings surface
  (connection + role binding) and the platform extensions surface (monitoring config).
  client_credentials exchange granted all requested scopes; bearer TTL 300s (provider re-mints).
- A bare platform token cannot create the connection (classic resource). Mixed
  classic + platform tokens also work but are less clean for ownership.

## Environment gotchas (carried into the deliverable)

- **AWS credential bridge for SSO/wrapper logins** that don't write `~/.aws/credentials`
  (Terraform reports "No valid credential sources found"):
  `eval "$(aws configure export-credentials --format env)"`.
- The role-ARN binding's ~9s create time is the live AssumeRole + IAM-propagation retry
  window; the provider's default 2-minute create timeout (`role_arn_create_timeout`) covers it.
- Server rule confirmed: 1 AWS account ↔ 1 connection ↔ 1 monitoring config per tenant.
  A second config for an already-onboarded account is rejected (`Account ID must be unique`).
