locals {
  build_machine = {
    instance_id = var.instance_ondemand ? aws_instance.build_machine[0].id : aws_spot_instance_request.build_machine[0].id
    tag_name  = var.instance_ondemand ? aws_instance.build_machine[0].tags.Name : aws_spot_instance_request.build_machine[0].tags.Name
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
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
    content = templatefile("${path.module}/install.sh",merge(var.install,{linuxkit_bucket_name=var.linuxkit_bucket_name}))
    filename = "install.sh"
  }
}


data "aws_region" "region" {}
data "aws_caller_identity" "identity" {}
