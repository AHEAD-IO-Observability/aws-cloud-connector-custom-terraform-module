# terraform-dynatrace-aws-connector

Terraform module that onboards a single AWS account to a Dynatrace Gen 3 tenant's
**cloud connector** (agentless AWS monitoring) — no CloudFormation. It composes the
official `dynatrace-oss/dynatrace` provider resources with native AWS IAM into one
dependency graph, so a single `terraform apply` does the whole flow and the apply
itself proves the cross-account trust.

## What it creates (all zero-cost: IAM + Dynatrace config only)

| Phase | Resource | Surface |
|---|---|---|
| 1 | `dynatrace_aws_connection` (empty role ARN) | Dynatrace classic settings |
| 2 | `aws_iam_role` + `aws_iam_policy` (×N) + attachment | AWS IAM |
| 3 | `dynatrace_aws_connection_role_arn` (binds ARN → connection) | Dynatrace classic settings |
| 4 | `dynatrace_hub_extension_v2_config` (which services/regions to poll) | Dynatrace platform extensions |

The connection's `id` is the IAM trust-policy **ExternalId** — Terraform wires this
automatically, resolving the chicken-and-egg the manual API flow has.

## The one manual prerequisite (per tenant, once)

This module does **not** do tenant bootstrap. Before first use, once per tenant:

1. Create a Dynatrace service user + least-privilege policy and cut **one credential**
   (see Auth below).
2. Run the da-aws "first-time setup" hub call once:
   `POST https://<tenant>.live.dynatrace.com/api/v2/hub/extensions2/com.dynatrace.extension.da-aws/actions/addToEnvironment`
   (classic token, scope `hub.install`). **Re-running silently upgrades the extension** —
   do it once, then pin `extension_version`.
3. Read the active version (`GET .../platform/extensions/v2/extensions?filter=name='com.dynatrace.extension.da-aws'&add-fields=activeVersion`)
   and pass it as `extension_version`.

## Auth (provider credentials)

Set via environment variables. **Recommended: an OAuth client** — a single credential
drives both the classic settings surface (connection + role binding) and the platform
extensions surface (monitoring config):

```sh
export DYNATRACE_ENV_URL="https://<tenant>.live.dynatrace.com"
export DT_CLIENT_ID=... DT_CLIENT_SECRET=... DT_ACCOUNT_ID=...
export DYNATRACE_HTTP_OAUTH_PREFERENCE=true
```

A **bare platform token cannot create the connection** (it's a classic resource). The
mixed-token alternative works: `DYNATRACE_API_TOKEN` (classic: `settings.read/write`)
for phases 1+3 and `DYNATRACE_PLATFORM_TOKEN` (platform: `extensions:configurations:*`)
for phase 4. AWS auth is standard (`aws sso login` / env / profile).

### OAuth client scopes (minimal)

| Scope | Used by |
|---|---|
| `settings:objects:read` | connection + role-ARN binding |
| `settings:objects:write` | connection + role-ARN binding |
| `extensions:configurations:read` | monitoring config |
| `extensions:configurations:write` | monitoring config |
| `settings:objects:admin` *(optional)* | only if managing object ownership via `dynatrace_settings_permissions` |

The one-time bootstrap (`hub addToEnvironment`) is separate and needs a **classic** token
with `hub.install` — not part of this OAuth client.

## Usage

See [`examples/single-account`](examples/single-account). Minimal:

```hcl
module "connector" {
  source            = "github.com/AHEAD-IO-Observability/aws-cloud-connector-custom-terraform-module//modules/dynatrace-aws-connector"
  connection_name   = "payments-prod-us-east-1"
  aws_account_id    = "111122223333"
  deployment_region = "us-east-1"
  monitored_regions = ["us-east-1", "us-west-2"]
  extension_version = "1.0.11"
}
```

## Pipeline placement

Instantiate this in the **account-vending / landing-zone baseline**, not per-application
stacks. Server validators enforce 1 AWS account ↔ 1 connection ↔ 1 monitoring config,
and the connection + IAM role are coupled by ExternalId, so they belong in one module /
state for correct create *and destroy* ordering. Account teams parameterize only
`aws_account_id`, regions, and `feature_sets`.

## IAM policy source of truth

The module ships a read-only **baseline** policy covering the default `feature_sets`.
For production, mirror Dynatrace's two officially published monitoring policies into
`monitoring_policy_documents` (the list shape supports the documented 2-policy split
that exists to stay under the 6144-char managed-policy limit). The policy is the
permission ceiling; `feature_sets` is the throttle.

## License

Apache License 2.0 — see [`LICENSE`](LICENSE).

## Dynatrace documentation

- AWS monitoring overview — https://docs.dynatrace.com/docs/ingest-from/amazon-web-services
- AWS onboarding — https://docs.dynatrace.com/docs/ingest-from/amazon-web-services/aws-onboarding
- **Create an AWS connection (API)** — https://docs.dynatrace.com/docs/ingest-from/amazon-web-services/create-an-aws-connection/aws-connection-api
- AWS connection settings schema (`builtin:hyperscaler-authentication.connections.aws`) — https://docs.dynatrace.com/docs/discover-dynatrace/references/dynatrace-api/environment-api/settings/schemas/builtin-hyperscaler-authentication-aws-connection
- AWS services / feature sets — https://docs.dynatrace.com/docs/ingest-from/amazon-web-services/integrate-with-aws/aws-all-services
- Platform tokens — https://docs.dynatrace.com/docs/manage/identity-access-management/access-tokens-and-oauth-clients/platform-tokens
- Terraform provider `dynatrace_aws_connection` — https://registry.terraform.io/providers/dynatrace-oss/dynatrace/latest/docs/resources/aws_connection
- Terraform provider `dynatrace_aws_connection_role_arn` — https://registry.terraform.io/providers/dynatrace-oss/dynatrace/latest/docs/resources/aws_connection_role_arn
- Terraform provider `dynatrace_hub_extension_v2_config` — https://registry.terraform.io/providers/dynatrace-oss/dynatrace/latest/docs/resources/hub_extension_v2_config

## Validation status

Validated against `dynatrace-oss/dynatrace` v1.98 + `hashicorp/aws` v5.100 on a Gen 3 SaaS lab tenant, 2026-06-15. See [`VALIDATION.md`](VALIDATION.md) for the full record.

- `terraform init` + `validate`: pass.
- **All four phases applied live end-to-end via a single OAuth client, one `terraform apply` (6 resources), and destroyed clean.** connection → IAM role + policy + attachment → role-ARN binding → monitoring config.
- The role-ARN binding's live `sts:AssumeRole` from Dynatrace **succeeded** (~9s); independently verified the connection carries the ARN and the IAM trust ExternalId equals the connection id.
- The monitoring config landed enabled, on extension version 1.0.11, wired to the connection with the correct account id, feature sets, and region.
- Teardown confirmed: 0 monitoring configs, 0 connections, IAM role `NoSuchEntity`.

> **AWS credential bridge.** If your `aws` CLI works but Terraform reports "No valid credential sources found" (common with SSO/wrapper logins that don't write `~/.aws/credentials`), bridge the resolved creds into the environment: `eval "$(aws configure export-credentials --format env)"`.
