variable "linuxkit_instance_id" {
  description = "The instance under management"
}
variable "instance_type" {}
variable "key_pair_name" {}
variable "machine_name" {}
variable "vpc_id" {}
variable "aws_iam_role_id" {}
variable "ebs_kms_key_arn" {}

variable "linuxkit_download_url" {
  default = "https://github.com/vouch-opensource/linuxkit/releases/download/1f93eab/linuxkit-amd64-linux"
}

variable "babashka_download_url" {
  default = "https://raw.githubusercontent.com/borkdude/babashka/master/install"
}
