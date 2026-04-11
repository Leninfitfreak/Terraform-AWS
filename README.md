# Terraform-AWS

Minimal AWS staging baseline for LeninKart Phase 1.

## What this provisions (phase 1)
- VPC + public subnet
- Internet gateway + route table
- Security group for Kafka EC2
- Kafka EC2 instance
- Optional IAM role + instance profile

## What this does NOT do yet
- EKS
- NAT / private subnets
- Load balancers
- DNS

## Structure
- `envs/staging/` contains the staging baseline.

## Usage (plan only)
```
cd envs/staging
terraform init
terraform plan -var-file=terraform.tfvars
```
