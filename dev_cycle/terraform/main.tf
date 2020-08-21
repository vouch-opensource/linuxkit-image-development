data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "aws_instance" "linuxkit_instance" {
  instance_id = var.linuxkit_instance_id
}

provider "cloudinit" {
  version = "1.0.0"
}

data "cloudinit_config" "install" {
  part {
    content_type = "text/x-shellscript"
    content = file("${path.module}/install.sh")
    filename = "install.sh"
  }
}

resource "aws_instance" "build_machine" {
  ami = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  iam_instance_profile = aws_iam_instance_profile.build_node.id
  key_name = var.key_pair_name
  subnet_id = data.aws_instance.linuxkit_instance.subnet_id
  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
    volume_type = "gp2"
  }

  tags = {
    Name = var.machine_name
  }

  vpc_security_group_ids = [aws_security_group.build_node_access.id]
  user_data_base64 = data.cloudinit_config.install.rendered
}

data "aws_region" "region" {}
data "aws_caller_identity" "identity" {}

data "aws_iam_policy_document" "build_machine" {

  statement {
    effect = "Allow"
    actions = [
      "ec2:AttachVolume",
      "ec2:DetachVolume"
    ]
    resources = [
      "arn:aws:ec2:*:*:instance/${aws_instance.build_machine.id}",
      "arn:aws:ec2:*:*:instance/${data.aws_instance.linuxkit_instance.instance_id}",
      "arn:aws:ec2:*:*:volume/*"
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

resource "aws_iam_instance_profile" "build_node" {
  name_prefix = var.machine_name
  role = var.aws_iam_role_id
}

resource "aws_iam_policy" "allow_build_volume_attachment" {
  name = "${aws_instance.build_machine.tags.Name}-volume-attachment"
  policy = data.aws_iam_policy_document.build_machine.json
  depends_on = [data.aws_instance.linuxkit_instance]
}

resource "aws_iam_role_policy_attachment" "allow_build_volume_attachment" {
  policy_arn = aws_iam_policy.allow_build_volume_attachment.arn
  role = var.aws_iam_role_id
}

resource "aws_security_group" "build_node_access" {
  name_prefix = var.machine_name
  vpc_id = var.vpc_id

  ingress {
    description = "SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
}
