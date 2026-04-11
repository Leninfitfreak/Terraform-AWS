provider "aws" {
  region = var.aws_region
}

data "tls_certificate" "eks_oidc" {
  url = aws_eks_cluster.staging.identity[0].oidc[0].issuer
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "leninkart-staging-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "leninkart-staging-igw"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.public_subnet_az
  map_public_ip_on_launch = true
  tags = {
    Name = "leninkart-staging-public-1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_2_cidr
  availability_zone       = var.public_subnet_2_az
  map_public_ip_on_launch = true
  tags = {
    Name = "leninkart-staging-public-2"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "leninkart-staging-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "kafka_sg" {
  name        = "leninkart-staging-kafka-sg"
  description = "Kafka EC2 security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Kafka PLAINTEXT"
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = var.kafka_ingress_cidrs
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_ingress_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "leninkart-staging-kafka-sg"
  }
}

resource "aws_iam_role" "kafka_role" {
  count = var.create_instance_profile ? 1 : 0
  name  = "leninkart-staging-kafka-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = { Service = "ec2.amazonaws.com" },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  count      = var.create_instance_profile ? 1 : 0
  role       = aws_iam_role.kafka_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "kafka_profile" {
  count = var.create_instance_profile ? 1 : 0
  name  = "leninkart-staging-kafka-profile"
  role  = aws_iam_role.kafka_role[0].name
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_instance" "kafka" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.kafka_instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.kafka_sg.id]
  key_name                    = var.ssh_key_name
  associate_public_ip_address = true

  iam_instance_profile = var.create_instance_profile ? aws_iam_instance_profile.kafka_profile[0].name : null

  tags = {
    Name = "leninkart-staging-kafka"
  }
}

# --- EKS (staging) ---
data "aws_iam_role" "eks_cluster_role" {
  count = var.create_eks_cluster_role ? 0 : 1
  name  = "leninkart-staging-eks-cluster-role"
}

resource "aws_iam_role" "eks_cluster_role" {
  count = var.create_eks_cluster_role ? 1 : 0
  name  = "leninkart-staging-eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = { Service = "eks.amazonaws.com" },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  count      = var.create_eks_cluster_role ? 1 : 0
  role       = aws_iam_role.eks_cluster_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cluster_vpc_controller" {
  count      = var.create_eks_cluster_role ? 1 : 0
  role       = aws_iam_role.eks_cluster_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

locals {
  eks_cluster_role_arn = var.create_eks_cluster_role ? aws_iam_role.eks_cluster_role[0].arn : data.aws_iam_role.eks_cluster_role[0].arn
}

resource "aws_security_group" "eks_cluster_sg" {
  name        = "leninkart-staging-eks-cluster-sg"
  description = "EKS control plane security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Kubernetes API"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "leninkart-staging-eks-cluster-sg"
  }
}

resource "aws_eks_cluster" "staging" {
  name     = var.eks_cluster_name
  role_arn = local.eks_cluster_role_arn
  version  = var.eks_cluster_version

  vpc_config {
    subnet_ids         = [aws_subnet.public.id, aws_subnet.public_2.id]
    security_group_ids = [aws_security_group.eks_cluster_sg.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_cluster_vpc_controller
  ]
}

data "aws_iam_role" "eks_node_role" {
  count = var.create_eks_node_role ? 0 : 1
  name  = "leninkart-staging-eks-node-role"
}

resource "aws_iam_role" "eks_node_role" {
  count = var.create_eks_node_role ? 1 : 0
  name  = "leninkart-staging-eks-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = { Service = "ec2.amazonaws.com" },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_node_worker" {
  count      = var.create_eks_node_role ? 1 : 0
  role       = aws_iam_role.eks_node_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_node_cni" {
  count      = var.create_eks_node_role ? 1 : 0
  role       = aws_iam_role.eks_node_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_node_ecr" {
  count      = var.create_eks_node_role ? 1 : 0
  role       = aws_iam_role.eks_node_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

locals {
  eks_node_role_arn = var.create_eks_node_role ? aws_iam_role.eks_node_role[0].arn : data.aws_iam_role.eks_node_role[0].arn
}

resource "aws_eks_node_group" "staging" {
  cluster_name    = aws_eks_cluster.staging.name
  node_group_name = "leninkart-staging-ng"
  node_role_arn   = local.eks_node_role_arn
  subnet_ids      = [aws_subnet.public.id, aws_subnet.public_2.id]
  instance_types  = [var.eks_node_instance_type]

  scaling_config {
    desired_size = var.eks_node_desired_size
    min_size     = var.eks_node_min_size
    max_size     = var.eks_node_max_size
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_node_worker,
    aws_iam_role_policy_attachment.eks_node_cni,
    aws_iam_role_policy_attachment.eks_node_ecr
  ]
}

resource "aws_iam_openid_connect_provider" "eks" {
  url             = aws_eks_cluster.staging.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_oidc.certificates[0].sha1_fingerprint]
}

resource "aws_iam_role" "ebs_csi_irsa" {
  name = "leninkart-staging-ebs-csi-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${replace(aws_eks_cluster.staging.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa",
            "${replace(aws_eks_cluster.staging.identity[0].oidc[0].issuer, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi_policy" {
  role       = aws_iam_role.ebs_csi_irsa.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = aws_eks_cluster.staging.name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.ebs_csi_irsa.arn

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [
    aws_iam_role_policy_attachment.ebs_csi_policy,
    aws_eks_node_group.staging
  ]
}


