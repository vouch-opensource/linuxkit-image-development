variable "linuxkit_instance_id" {
  description = "The instance under management"
}

variable "instance_type" {}
variable "key_pair_name" {}
variable "machine_name" {}
variable "vpc_id" {}
variable "subnet_id" {}
variable "ebs_kms_key_arn" {}
variable "linuxkit_bucket_name" {}

variable "vmimport_service_role" {
  description = "Enable vmimport service role creation"
  type = bool
  default = true
}

variable "install" {
  type = object({
    linuxkit_version = string
    babashka_version = string
  })
  default = {
    linuxkit_version = "master"
    babashka_version = "master"
  }
}

variable "instance_ondemand" {
  default = true
}
