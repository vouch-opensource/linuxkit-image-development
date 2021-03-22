variable "linuxkit_instance_id" {
  description = "The linuxkit instance under management"
}


variable "vmimport_service_role_enabled" {
  description = "Enable vmimport service role creation"
  type = bool
  default = true
}

variable "bucket_name" {
  description = "S3 bucket name for storing the exported linuxkit image"
}

variable "machine_name" {
  description = "Name of build machine"
  default = "linuxkit-build"
}

variable "instance_ondemand" {
  description = "Whether the instance is ondemand or spot"
  default = true
}

variable "instance_type" {
  description = "The instance type of build machine to start"
}

variable "key_pair_name" {
  description = "Key name of the Key Pair to use for the instance"
}

variable "vpc_id" {
  description = "VPC ID of the build machine to launch in"
}

variable "subnet_id" {
  description = "VPC Subnet ID of the build machine to launch in"
}

variable "ebs_kms_key_arn" {
  description = "ARN of the KMS key to use when linuxkit instances has encrypted volumes"
}

variable "install" {
  description = "Set of strings with versions of packages to be installed from userdata script"
  type = object({
    linuxkit_version = string
    babashka_version = string
  })
  default = {
    linuxkit_version = "master"
    babashka_version = "master"
  }
}
