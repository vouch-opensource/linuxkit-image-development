terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "3.33.0"
    }
  #Added cloudinit
	cloudinit = {
      version = "1.0.0"
    }
  }
  required_version = ">= 0.14"
}
