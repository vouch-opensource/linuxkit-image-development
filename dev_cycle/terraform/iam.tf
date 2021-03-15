data "aws_iam_policy_document" "build_machine" {

  statement {
    effect = "Allow"
    actions = [
      "ec2:AttachVolume",
      "ec2:DetachVolume"
    ]
    resources = [
      "arn:aws:ec2:*:*:instance/${local.build_machine.instance_id}",
      "arn:aws:ec2:*:*:instance/${data.aws_instance.linuxkit_instance.instance_id}",
      "arn:aws:ec2:*:*:volume/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:CreateGrant",
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    resources = [
      var.ebs_kms_key_arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:StartInstances",
      "ec2:StopInstances"
    ]
    resources = [
      "arn:aws:ec2:*:*:instance/${data.aws_instance.linuxkit_instance.instance_id}"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeVolumes"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:ListMultipartUploadParts"
    ]
    resources = [
      "arn:aws:s3:::${var.linuxkit_bucket_name}"
    ]
  }

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
      "ec2:ImportSnapshot",
      "ec2:DescribeImportSnapshotTasks",
      "ec2:RegisterImage"
    ]
    resources = [
      "*"
    ]
  }

  depends_on = [data.aws_instance.linuxkit_instance]
}

resource "aws_iam_instance_profile" "build_node" {
  name_prefix = var.machine_name
  role = var.aws_iam_role_id
}

resource "aws_iam_policy" "allow_build_volume_attachment" {
  name = "${local.build_machine.tag_name}-volume-attachment"
  policy = data.aws_iam_policy_document.build_machine.json
  depends_on = [data.aws_instance.linuxkit_instance]
}

resource "aws_iam_role_policy_attachment" "allow_build_volume_attachment" {
  policy_arn = aws_iam_policy.allow_build_volume_attachment.arn
  role = var.aws_iam_role_id
}
