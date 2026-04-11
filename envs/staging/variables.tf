variable "aws_region" {
  type        = string
  description = "AWS region for staging"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block"
}

variable "public_subnet_cidr" {
  type        = string
  description = "Public subnet CIDR"
}

variable "public_subnet_az" {
  type        = string
  description = "Availability zone for public subnet"
}

variable "ssh_key_name" {
  type        = string
  description = "EC2 key pair name for SSH access"
}

variable "ssh_ingress_cidrs" {
  type        = list(string)
  description = "CIDRs allowed to SSH"
}

variable "kafka_ingress_cidrs" {
  type        = list(string)
  description = "CIDRs allowed to reach Kafka port 9092"
}

variable "kafka_instance_type" {
  type        = string
  description = "EC2 instance type for Kafka"
}

variable "create_instance_profile" {
  type        = bool
  description = "Whether to create IAM role + instance profile for Kafka"
  default     = true
}

variable "eks_cluster_name" {
  type        = string
  description = "EKS cluster name"
}

variable "eks_cluster_version" {
  type        = string
  description = "EKS cluster Kubernetes version"
  default     = "1.29"
}

variable "eks_node_instance_type" {
  type        = string
  description = "EKS node instance type"
}

variable "eks_node_desired_size" {
  type        = number
  description = "EKS node group desired size"
}

variable "eks_node_min_size" {
  type        = number
  description = "EKS node group minimum size"
}

variable "eks_node_max_size" {
  type        = number
  description = "EKS node group maximum size"
}

variable "public_subnet_2_cidr" {
  type        = string
  description = "Second public subnet CIDR"
}

variable "public_subnet_2_az" {
  type        = string
  description = "Availability zone for second public subnet"
}
variable "github_repo" {
  type        = string
  description = "GitHub repository slug that can assume the Terraform OIDC role (owner/repo)"
}

variable "github_branch" {
  type        = string
  description = "GitHub branch allowed to assume the Terraform OIDC role"
  default     = "main"
}

variable "oidc_thumbprint" {
  type        = string
  description = "OIDC thumbprint for token.actions.githubusercontent.com"
  default     = "6938fd4d98bab03faadb97b34396831e3780aea1"
}
variable "create_github_oidc_provider" {
  type        = bool
  description = "Whether to create the GitHub Actions OIDC provider"
  default     = false
}

variable "create_github_oidc_role" {
  type        = bool
  description = "Whether to create the GitHub Actions OIDC IAM role"
  default     = false
}

variable "create_eks_cluster_role" {
  type        = bool
  description = "Whether to create the EKS cluster IAM role"
  default     = false
}

variable "create_eks_node_role" {
  type        = bool
  description = "Whether to create the EKS node IAM role"
  default     = false
}

variable "create_eks_resources" {
  type        = bool
  description = "Whether to create EKS cluster, node group, and addons"
  default     = false
}
