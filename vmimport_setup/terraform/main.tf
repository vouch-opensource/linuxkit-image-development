resource "aws_s3_bucket" "vmimport" {
  bucket = var.bucket_name
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

  statement {
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject",
      "s3:GetBucketAcl"
    ]
    resources = [
      "arn:aws:s3:::${var.bucket_name}",
      "arn:aws:s3:::${var.bucket_name}/*"

    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:ModifySnapshotAttribute",
      "ec2:CopySnapshot",
      "ec2:DescribeImportSnapshotTasks",
      "ec2:RegisterImage",
      "ec2:Describe*",
    ]
    resources = [
      "*"
    ]
  }

}

resource "aws_iam_policy" "vmimport" {
  name = "${var.bucket_name}-vm-import"
  policy = data.aws_iam_policy_document.vmimport.json
}
