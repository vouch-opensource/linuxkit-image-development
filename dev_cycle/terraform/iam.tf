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

  depends_on = [data.aws_instance.linuxkit_instance]
}

resource "aws_iam_instance_profile" "build_machine" {
  name_prefix = var.machine_name
  role = aws_iam_role.build_machine.name
}

resource "aws_iam_policy" "allow_build_volume_attachment" {
  name = "${local.build_machine.tag_name}-volume-attachment"
  policy = data.aws_iam_policy_document.build_machine.json
  depends_on = [data.aws_instance.linuxkit_instance]
}

resource "aws_iam_role_policy_attachment" "allow_build_volume_attachment" {
  policy_arn = aws_iam_policy.allow_build_volume_attachment.arn
  role = aws_iam_role.build_machine.name
}

resource "aws_iam_role_policy_attachment" "vmimport" {
  policy_arn = module.vmimport.iam_policy_arn
  role = aws_iam_role.build_machine.name

}
