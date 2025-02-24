# This `terraform/common` code is run by privileged accounts only
# The IAM policies below grant specific permissions to the `Deployments` role
# They are used when a GitHub Actions workflow uses `terraform apply`
# The `Deployments` role does not need permission to create an ACM certificate

resource "aws_iam_user" "deploy" {
  name = "deploy"
  path = "/${local.service_name}/"
}

resource "aws_iam_access_key" "deploy" {
  user = aws_iam_user.deploy.name
}

# Terraform state

# By specifically granting permissions on these prefixes
# We are defending against the unintentional creation of further namespaces
data "aws_iam_policy_document" "edit_terraform_state" {
  statement {
    actions = ["s3:GetObject", "s3:PutObject"]
    resources = [
      "arn:aws:s3:::${data.aws_s3_bucket.terraform_state.bucket}/dev/*",
      "arn:aws:s3:::${data.aws_s3_bucket.terraform_state.bucket}/production/*",
      "arn:aws:s3:::${data.aws_s3_bucket.terraform_state.bucket}/qa/*",
      "arn:aws:s3:::${data.aws_s3_bucket.terraform_state.bucket}/review/*",
      "arn:aws:s3:::${data.aws_s3_bucket.terraform_state.bucket}/staging/*"
    ]
  }
  statement {
    actions = ["s3:DeleteObject"]
    resources = [
      "arn:aws:s3:::${data.aws_s3_bucket.terraform_state.bucket}/review/*"
    ]
  }
  statement {
    actions = ["s3:ListBucket"]
    resources = [
      "arn:aws:s3:::${data.aws_s3_bucket.terraform_state.bucket}"
    ]
  }
}

resource "aws_iam_policy" "edit_terraform_state" {
  name   = "edit-terraform-state"
  policy = data.aws_iam_policy_document.edit_terraform_state.json
}

# SSM

data "aws_iam_policy_document" "read_ssm_parameters" {
  statement {
    actions   = ["ssm:GetParameter", "ssm:GetParametersByPath"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "read_ssm_parameters" {
  name   = "read-ssm-parameter"
  policy = data.aws_iam_policy_document.read_ssm_parameters.json
}

# Cloudwatch

data "aws_iam_policy_document" "cloudwatch" {
  statement {
    actions   = ["iam:*"]
    resources = ["arn:aws:iam::*:role/*-slack-lambda-role"]
  }
  statement {
    actions   = ["kms:*"]
    resources = ["*"]
  }
  statement {
    actions   = ["sns:*"]
    resources = ["*"]
  }
  statement {
    actions   = ["logs:*"]
    resources = ["*"]
  }
  statement {
    actions   = ["lambda:*"]
    resources = ["arn:aws:lambda:*:*:function:*"]
  }
}

resource "aws_iam_policy" "cloudwatch" {
  name   = "cloudwatch"
  policy = data.aws_iam_policy_document.cloudwatch.json
}

# ACM

data "aws_iam_policy_document" "acm" {
  statement {
    actions = [
      "acm:DescribeCertificate",
      "acm:ListCertificates",
      "acm:ListTagsForCertificate"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "acm" {
  name   = "acm"
  policy = data.aws_iam_policy_document.acm.json
}

# Cloudfront

data "aws_iam_policy_document" "cloudfront" {
  statement {
    actions   = ["cloudfront:*"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "cloudfront" {
  name   = "cloudfront"
  policy = data.aws_iam_policy_document.cloudfront.json
}

# DB backups in S3

data "aws_iam_policy_document" "db_backups_in_s3_fullaccess" {
  statement {
    actions = ["s3:GetObject", "s3:GetObjectAcl", "s3:PutObject"]
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.db_backups.bucket}/full/*",
      "arn:aws:s3:::${aws_s3_bucket.db_backups.bucket}/sanitised/*"
    ]
  }
  statement {
    actions   = ["s3:GetBucketAcl", "s3:GetBucketLocation", "s3:ListBucket", "s3:PutBucketAcl"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.db_backups.bucket}"]
  }
}


resource "aws_iam_policy" "db_backups_in_s3_fullaccess" {
  name   = "db_backups_in_s3_fullaccess"
  policy = data.aws_iam_policy_document.db_backups_in_s3_fullaccess.json
}

data "aws_iam_policy_document" "deny_sensitive_data_in_s3" {
  statement {
    actions = [
      "s3:GetObject"
    ]
    effect = "Deny"
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.db_backups.bucket}/full/*",
      "arn:aws:s3:::${data.aws_s3_bucket.terraform_state.bucket}/production/*"
    ]
  }
  statement {
    actions   = ["s3:ListBucket"]
    effect    = "Deny"
    resources = ["arn:aws:s3:::${aws_s3_bucket.db_backups.bucket}"]
    condition {
      test     = "StringEquals"
      variable = "s3:prefix"

      values = [
        "",
        "full"
      ]
    }
  }
}

resource "aws_iam_policy" "deny_sensitive_data_in_s3" {
  name   = "deny_sensitive_data_in_s3"
  policy = data.aws_iam_policy_document.deny_sensitive_data_in_s3.json
}

resource "aws_iam_role_policy_attachment" "deny_sensitive_data_in_s3" {
  role       = aws_iam_role.readonly.name
  policy_arn = aws_iam_policy.deny_sensitive_data_in_s3.arn
}

# Offline site S3

data "aws_iam_policy_document" "offline_site_full_access" {
  statement {
    actions   = ["s3:GetObject", "s3:GetObjectAcl", "s3:DeleteObject", "s3:PutObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.offline_site.bucket}/teaching-vacancies-offline/*"]
  }
  statement {
    actions   = ["s3:GetBucketAcl", "s3:GetBucketLocation", "s3:ListBucket", "s3:PutBucketAcl"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.offline_site.bucket}"]
  }
}

resource "aws_iam_policy" "offline_site_full_access" {
  name   = "offline_site_full_access"
  policy = data.aws_iam_policy_document.offline_site_full_access.json
}
