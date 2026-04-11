aws_region = "us-east-1"

vpc_cidr          = "10.20.0.0/16"
public_subnet_cidr = "10.20.1.0/24"
public_subnet_az  = "us-east-1a"

ssh_key_name      = "leninkart-staging-key"
ssh_ingress_cidrs = ["0.0.0.0/0"]

kafka_ingress_cidrs = ["0.0.0.0/0"]
kafka_instance_type = "t3.micro"

eks_cluster_name = "leninkart-staging-eks"
eks_cluster_version = "1.29"
eks_node_instance_type = "t3.small"
eks_node_desired_size = 3
eks_node_min_size = 1
eks_node_max_size = 3
public_subnet_2_cidr = "10.20.2.0/24"
public_subnet_2_az = "us-east-1b"
github_repo = "Leninfitfreak/Terraform-AWS"
github_branch = "main"
create_github_oidc_provider = false
create_github_oidc_role = false
