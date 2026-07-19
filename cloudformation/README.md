# CloudFormation StackSets — Multi-Account IAM Baseline

This folder is separate from the Terraform code on purpose. Terraform manages
the application infrastructure inside **one** account (VPC, ASG, ALB).
CloudFormation StackSets manages a small **security/IAM baseline** that gets
deployed consistently across **multiple** AWS accounts from a single hub —
this is the standard split used in real multi-account AWS environments,
where Terraform is per-workload and StackSets is for org-wide guardrails.

## What it deploys

`iam-baseline-stackset.yaml` creates, in every target account:
1. An IAM role + instance profile for SSM Session Manager (same purpose as
   the Terraform `ssm_role`, but applied as an org-wide baseline).
2. A read-only cross-account audit role, assumable from the management
   account, for centralized security review without handing out
   long-lived credentials in each account.

## Prerequisites

- AWS Organizations enabled, with a designated **management account** or
  **delegated administrator account** for StackSets.
- Trusted access enabled between StackSets and Organizations
  (`aws organizations enable-aws-service-access --service-principal=member.org.stacksets.cloudformation.amazonaws.com`).

## Deploy (via AWS CLI)

```bash
# 1. Create the StackSet
aws cloudformation create-stack-set \
  --stack-set-name iam-baseline \
  --template-body file://iam-baseline-stackset.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --permission-model SERVICE_MANAGED \
  --auto-deployment Enabled=true,RetainStacksOnAccountRemoval=false

# 2. Deploy it to every account under a given OU, in multiple regions
aws cloudformation create-stack-instances \
  --stack-set-name iam-baseline \
  --deployment-targets OrganizationalUnitIds=["ou-xxxx-xxxxxxxx"] \
  --regions '["ap-south-1","us-east-1"]'

# 3. Check rollout status
aws cloudformation list-stack-instances --stack-set-name iam-baseline
```

## Deploy (via AWS Console)

CloudFormation → StackSets → Create StackSet → upload
`iam-baseline-stackset.yaml` → choose **Service-managed permissions** →
select the target Organizational Unit(s) → select regions → deploy.

## Why StackSets instead of Terraform here

- StackSets is natively account/region-aware and integrates directly with
  AWS Organizations — new accounts added to the OU automatically inherit
  the baseline with no extra step (`auto-deployment: Enabled`).
- Keeps a hard boundary between "security baseline, org-wide, rarely
  changes" (CloudFormation) and "application infrastructure, per-project,
  changes often" (Terraform) — a common pattern in real DevSecOps setups.
