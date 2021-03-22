resource "aws_iam_role" "build_machine" {
  name = var.machine_name

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "volume_attachment" {

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
      "ec2:DescribeInstances",
      "ec2:DescribeVolumes"
    ]
    resources = ["*"]
  }

  depends_on = [data.aws_instance.linuxkit_instance]
}

data "aws_iam_policy_document" "linuxkit_push" {

  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject"
    ]
    resources = [
      "arn:aws:s3:::${var.bucket_name}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:RegisterImage",
      "ec2:ImportSnapshot",
      "ec2:DescribeImportSnapshotTasks"
    ]
    resources = ["*"]
  }

  depends_on = [data.aws_instance.linuxkit_instance]
}

resource "aws_iam_instance_profile" "build_machine" {
  name_prefix = var.machine_name
  role = aws_iam_role.build_machine.name
}

resource "aws_iam_policy" "linuxkit_push" {
  name = "${local.build_machine.tag_name}-linuxkit-push"
  policy = data.aws_iam_policy_document.linuxkit_push.json
  depends_on = [data.aws_instance.linuxkit_instance]
}

resource "aws_iam_policy" "volume_attachment" {
  name = "${local.build_machine.tag_name}-volume-attachment"
  policy = data.aws_iam_policy_document.volume_attachment.json
  depends_on = [data.aws_instance.linuxkit_instance]
}

resource "aws_iam_role_policy_attachment" "linuxkit_push" {
  policy_arn = aws_iam_policy.linuxkit_push.arn
  role = aws_iam_role.build_machine.name
}

resource "aws_iam_role_policy_attachment" "volume_attachment" {
  policy_arn = aws_iam_policy.volume_attachment.arn
  role = aws_iam_role.build_machine.name
}
