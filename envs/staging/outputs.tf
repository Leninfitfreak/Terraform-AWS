output "kafka_instance_id" {
  value       = aws_instance.kafka.id
  description = "Kafka EC2 instance ID"
}

output "kafka_public_ip" {
  value       = aws_instance.kafka.public_ip
  description = "Kafka EC2 public IP"
}

output "kafka_private_ip" {
  value       = aws_instance.kafka.private_ip
  description = "Kafka EC2 private IP"
}

output "vpc_id" {
  value       = local.vpc_id
  description = "VPC ID"
}

output "public_subnet_id" {
  value       = local.public_subnet_id
  description = "Public subnet ID"
}

output "eks_cluster_name" {
  value       = local.eks_cluster_name
  description = "EKS cluster name"
}

output "eks_cluster_endpoint" {
  value       = local.eks_cluster_endpoint
  description = "EKS cluster API endpoint"
}

output "eks_node_group_status" {
  value       = var.create_eks_resources ? aws_eks_node_group.staging[0].status : null
  description = "EKS node group status"
}
output "github_oidc_role_arn" {
  value       = local.github_oidc_role_arn
  description = "GitHub OIDC IAM role ARN for Terraform-AWS workflows"
}

output "github_oidc_provider_arn" {
  value       = local.github_oidc_provider_arn
  description = "GitHub Actions OIDC provider ARN"
}


