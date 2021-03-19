resource "aws_instance" "build_machine" {

  count = var.instance_ondemand ? 1 : 0

  ami = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  iam_instance_profile = aws_iam_instance_profile.build_machine.id
  key_name = var.key_pair_name
  subnet_id = var.subnet_id
  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
    volume_type = "gp2"
  }

  tags = {
    Name = var.machine_name
  }

  vpc_security_group_ids = [aws_security_group.build_machine_access.id]
  user_data_base64 = data.cloudinit_config.install.rendered
}

resource "aws_spot_instance_request" "build_machine" {

  count = var.instance_ondemand ? 0 : 1

  ami = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  iam_instance_profile = aws_iam_instance_profile.build_machine.id
  key_name = var.key_pair_name
  subnet_id = var.subnet_id
  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
    volume_type = "gp2"
  }

  tags = {
    Name = var.machine_name
  }

  vpc_security_group_ids = [aws_security_group.build_machine_access.id]
  user_data_base64 = data.cloudinit_config.install.rendered
}

resource "aws_security_group" "build_machine_access" {
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
