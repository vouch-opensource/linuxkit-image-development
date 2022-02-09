resource "aws_s3_bucket" "vmimport" {
  count = var.bucket_enabled ? 1 : 0

  bucket = var.bucket_name
  acl    = "private"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "vmimport" {
  count = var.bucket_enabled ? 1 : 0

  bucket = aws_s3_bucket.vmimport.0.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "vmimport" {
  count = var.service_role_enabled ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["vmie.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "sts:Externalid"
      values   = ["vmimport"]
    }
  }
}

resource "aws_iam_role" "vmimport" {
  count = var.service_role_enabled ? 1 : 0
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.vmimport.0.json
}

data "aws_iam_policy_document" "vmimport_access" {
  count = var.service_role_enabled ? 1 : 0
  statement {
    actions = [
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket"
    ]
    effect = "Allow"
    resources = [
      "arn:aws:s3:::${var.bucket_name}",
      "arn:aws:s3:::${var.bucket_name}/*"
    ]
  }
  statement {
    actions = [
      "ec2:ModifySnapshotAttribute",
      "ec2:CopySnapshot",
      "ec2:RegisterImage",
      "ec2:Describe*",
      "ec2:CreateTags"
    ]
    effect    = "Allow"
    resources = ["*"]
  }
}

resource "aws_iam_policy" "vmimport_access" {
  count = var.service_role_enabled ? 1 : 0
  name   = var.policy_name
  policy = data.aws_iam_policy_document.vmimport_access.0.json
}

resource "aws_iam_role_policy_attachment" "vmimport_access" {
  count = var.service_role_enabled ? 1 : 0
  role       = aws_iam_role.vmimport.0.name
  policy_arn = aws_iam_policy.vmimport_access.0.arn
}
