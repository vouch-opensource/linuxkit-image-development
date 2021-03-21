resource "aws_s3_bucket" "vmimport" {
  bucket = var.linuxkit_bucket_name
  acl    = "private"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "vmimport" {
  bucket = aws_s3_bucket.vmimport.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "vmimport" {
  count = var.vmimport_service_role ? 1 : 0
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
  count = var.vmimport_service_role ? 1 : 0
  name               = "vmimport"
  assume_role_policy = data.aws_iam_policy_document.vmimport.0.json
}

data "aws_iam_policy_document" "vmimport_access" {
  count = var.vmimport_service_role ? 1 : 0
  statement {
    actions = [
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket"
    ]
    effect = "Allow"
    resources = [
      "arn:aws:s3:::${var.linuxkit_bucket_name}",
      "arn:aws:s3:::${var.linuxkit_bucket_name}/*"
    ]
  }
  statement {
    actions = [
      "ec2:ModifySnapshotAttribute",
      "ec2:CopySnapshot",
      "ec2:RegisterImage",
      "ec2:Describe*"
    ]
    effect    = "Allow"
    resources = ["*"]
  }
}

resource "aws_iam_policy" "vmimport_access" {
  count = var.vmimport_service_role ? 1 : 0
  name   = "VMImportAccess"
  policy = data.aws_iam_policy_document.vmimport_access.0.json
}

resource "aws_iam_role_policy_attachment" "vmimport_access" {
  count = var.vmimport_service_role ? 1 : 0
  role       = aws_iam_role.vmimport.0.name
  policy_arn = aws_iam_policy.vmimport_access.0.arn
}
