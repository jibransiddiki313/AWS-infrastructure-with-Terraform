# ☁️ Terraform AWS Infrastructure Automation

Infrastructure as Code project that provisions a scalable, secure AWS
environment using **Terraform**, plus a multi-account IAM security baseline
deployed via **CloudFormation StackSets**.

---

## Architecture

```text
                              Internet
                                 │
                        ┌────────▼─────────┐
                        │ Internet Gateway  │
                        └────────┬──────────┘
                                 │
                            ┌────▼────┐
                            │   VPC   │  10.0.0.0/16
                            └────┬────┘
              ┌──────────────────┴───────────────────┐
              │                                       │
      Public Subnets (2 AZs)                Private Subnets (2 AZs)
      10.0.1.0/24, 10.0.2.0/24              10.0.10.0/24, 10.0.11.0/24
              │                                       │
      ┌───────▼────────┐                    ┌─────────▼─────────┐
      │ Application LB  │───────────────────▶│  Auto Scaling      │
      │  (port 80)      │   forwards to       │  Group (EC2 x N)   │
      └────────┬────────┘   target group      │  via Launch        │
               │                              │  Template + Docker │
        NAT Gateway ◀── outbound only ────────┴─────────┬──────────┘
        (in public subnet)                              │
                                                IAM Role (SSM only,
                                                no SSH key required)
```

---

## What this provisions

**Terraform (per-account application infrastructure):**
- VPC with public + private subnets across 2 Availability Zones
- Internet Gateway (public) and NAT Gateway (private, outbound-only)
- Application Load Balancer + target group + listener
- Launch Template (Ubuntu 22.04, Docker pre-installed via user data)
- Auto Scaling Group with a CPU-based target tracking scaling policy
- IAM role + instance profile for **SSM Session Manager** — no SSH keys,
  no open port 22, every session is logged

**CloudFormation StackSets (org-wide security baseline, see `cloudformation/`):**
- Deploys a consistent SSM-enabled IAM role baseline to every AWS account
  in the organization automatically (new accounts inherit it too)
- Deploys a read-only cross-account audit role for centralized review

---

## Project structure

```text
.
├── main.tf                   # wires networking + asg modules together
├── variables.tf
├── outputs.tf
├── provider.tf
├── terraform.tfvars.example
├── modules/
│   ├── networking/            # VPC, subnets, IGW, NAT, route tables
│   └── asg/                   # Launch Template, ASG, ALB, IAM/SSM, security groups
└── cloudformation/
    ├── iam-baseline-stackset.yaml
    └── README.md               # how to deploy the StackSet across accounts
```

---

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars   # edit values as needed
terraform init
terraform plan
terraform apply
```

After apply, the app is reachable at the ALB DNS name (see `app_url` output).
To connect to any running instance without an SSH key:

```bash
aws autoscaling describe-auto-scaling-instances
aws ssm start-session --target <instance-id>
```

For the CloudFormation StackSet, see [`cloudformation/README.md`](cloudformation/README.md).

---

## Design decisions worth knowing for review

- **SSM over SSH** — avoids managing/rotating SSH keys and keeps port 22
  closed entirely; access is controlled through IAM instead.
- **ASG instead of a single EC2 instance** — the app survives an instance
  failure (ASG replaces it) and scales out under load via the CPU target
  tracking policy.
- **NAT Gateway in the public subnet, instances in the private subnet** —
  instances get outbound internet access (e.g. to pull Docker images)
  without being directly reachable from the internet; only the ALB is
  internet-facing.
- **CloudFormation StackSets kept separate from Terraform** — StackSets
  handles org-wide, rarely-changing security baselines across accounts;
  Terraform handles the application infrastructure inside one account.
  This mirrors how these tools are typically split in real environments.

## Possible next improvements

- Remote Terraform state (S3 backend + DynamoDB locking) — currently commented out in `provider.tf`
- Per-environment `tfvars` (dev/staging/prod) instead of a single default
- CI/CD pipeline (GitHub Actions: `terraform fmt`, `validate`, `plan` on PRs)
- HTTPS listener on the ALB with an ACM certificate
