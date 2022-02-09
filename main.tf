/**
 * # Terraform AWS Deploy role for github actions.
 *
 * Github Actionsで使用可能なデプロイロールを作成します。
 */

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_iam_openid_connect_provider" "github_deployment" {
  url             = var.github.id_provider.url
  client_id_list  = var.github.id_provider.client_id_list
  thumbprint_list = var.github.id_provider.thumbprint_list
}

resource "aws_iam_role" "github_deployment" {
  name = "${var.tf.fullname}-github-deployment"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Principal" : {
          "Federated" : "${aws_iam_openid_connect_provider.github_deployment.arn}"
        },
        "Effect" : "Allow",
        "Condition" : {
          "StringLike" : {
            "token.actions.githubusercontent.com:sub" : "repo:${var.github.organization}/*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "all_resources" {
  name = "${var.tf.fullname}-github-deployment-all-resources"

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Action : [
          "sts:GetCallerIdentity"
        ],
        Resource : "*"
      },
      {
        Effect : "Allow",
        Action : [
          "ecr:GetAuthorizationToken",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:DescribeImages",
          "ecr:DescribeRepositories",
          "ecr:GetDownloadUrlForLayer",
          "ecr:ListImages"
        ],
        Resource : "*"
      },
      {
        Effect : "Allow",
        Action : [
          "ecs:RegisterTaskDefinition"
        ],
        Resource : "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "all_resources" {
  role       = aws_iam_role.github_deployment.name
  policy_arn = aws_iam_policy.all_resources.arn
}

resource "aws_iam_policy" "passrole" {
  count = length(var.roles_for_pass_role_arns) > 0 ? 1 : 0
  name  = "${var.tf.fullname}-github-deployment-passrole"
  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Action : [
          "iam:PassRole"
        ],
        Resource : var.roles_for_pass_role_arns
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "passrole" {
  count      = length(var.roles_for_pass_role_arns) > 0 ? 1 : 0
  role       = aws_iam_role.github_deployment.name
  policy_arn = aws_iam_policy.passrole[0].arn
}

resource "aws_iam_policy" "ecs" {
  count = length(var.ecs_service_arns) > 0 ? 1 : 0
  name  = "${var.tf.fullname}-github-deployment-ecs"
  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Action : [
          "ecs:UpdateService",
          "ecs:DescribeServices"
        ],
        Resource : var.ecs_service_arns
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs" {
  count      = length(var.ecs_service_arns) > 0 ? 1 : 0
  role       = aws_iam_role.github_deployment.name
  policy_arn = aws_iam_policy.ecs[0].arn
}