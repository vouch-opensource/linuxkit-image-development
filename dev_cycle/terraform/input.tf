variable "linuxkit_instance_id" {
  description = "The instance under management"
}
variable "instance_type" {}
variable "key_pair_name" {}
variable "machine_name" {}
variable "vpc_id" {}
variable "aws_iam_role_id" {}
variable "ebs_kms_key_arn" {}

variable "install" {
  type = object({
    linuxkit_download_url = string
    babashka_download_url = string
  })
  default = {
    linuxkit_download_url = "https://github.com/vouch-opensource/linuxkit/releases/download/1f93eab/linuxkit-amd64-linux"
    babashka_download_url = "https://raw.githubusercontent.com/borkdude/babashka/master/install"
  }
}
