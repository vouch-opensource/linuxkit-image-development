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

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject*",
      "s3:PutObject*"
    ]
    resources = [
      "arn:aws:s3:::${var.linuxkit_bucket_name}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:RegisterImage",
      "ec2:ImportSnapshot",
      "ec2:DescribeImportSnapshotTasks"
    ]
    resources = [
      "*"
    ]
  }

}

resource "aws_iam_policy" "vmimport" {
  name = "${var.linuxkit_bucket_name}-vm-import"
  policy = data.aws_iam_policy_document.vmimport.json
}
