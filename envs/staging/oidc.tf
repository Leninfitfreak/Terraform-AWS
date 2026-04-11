data "aws_iam_openid_connect_provider" "github" {
  count = var.create_github_oidc_provider ? 0 : 1
  url   = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "github" {
  count           = var.create_github_oidc_provider ? 1 : 0
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [var.oidc_thumbprint]
}

locals {
  github_oidc_provider_arn = var.create_github_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : data.aws_iam_openid_connect_provider.github[0].arn
}

data "aws_iam_role" "github_oidc_role" {
  count = var.create_github_oidc_role ? 0 : 1
  name  = "leninkart-terraform-github-oidc-role"
}

resource "aws_iam_role" "github_oidc_role" {
  count = var.create_github_oidc_role ? 1 : 0
  name  = "leninkart-terraform-github-oidc-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = local.github_oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:ref:refs/heads/${var.github_branch}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_oidc_admin" {
  count      = var.create_github_oidc_role ? 1 : 0
  role       = aws_iam_role.github_oidc_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

locals {
  github_oidc_role_arn = var.create_github_oidc_role ? aws_iam_role.github_oidc_role[0].arn : data.aws_iam_role.github_oidc_role[0].arn
}
