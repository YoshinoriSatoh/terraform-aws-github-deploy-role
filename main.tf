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
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRoleWithWebIdentity",
        "Principal": {
          "Federated": "${aws_iam_openid_connect_provider.github_deployment.arn}"
        },
        "Effect": "Allow",
        "Condition": {
          "StringLike": {
            "token.actions.githubusercontent.com:sub": "repo:${var.github.organization}/*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_deployment" {
  role       = aws_iam_role.github_deployment.name
  policy_arn = aws_iam_policy.github_deployment.arn
}

resource "aws_iam_policy" "github_deployment" {
  name = "${var.tf.fullname}-github-deployment"

  policy = jsonencode({
    Version: "2012-10-17",
    Statement: [
      {
        Effect: "Allow",
        Action: [
          "sts:GetCallerIdentity"
        ],
        Resource: ["*"]
      },
      {
        Action: [
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
        Effect: "Allow",
        Resource: [
          "*"
        ]
      },
      {
        Sid: "RegisterTaskDefinition",
        ffect: "Allow",
        Action: [
          "ecs:RegisterTaskDefinition"
        ],
        Resource: "*"
      },
      {
        Sid: "PassRolesInTaskDefinition",
        Effect: "Allow",
        Action: [
          "iam:PassRole"
        ],
        Resource: length(var.roles_for_pass_role_arns) > 0 ? "${var.roles_for_pass_role_arns}" : null
      },
      {
        Sid: "DeployService",
        Effect: "Allow",
        Action: [
          "ecs:UpdateService",
          "ecs:DescribeServices"
        ],
        Resource: length(var.ecs_service_arns) > 0 ? "${var.ecs_service_arns}" : null
      }
    ]
  })
}
