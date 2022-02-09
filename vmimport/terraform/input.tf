variable "bucket_name" {
  description = "S3 bucket name for storing the exported linuxkit images"
  type        = string
}

variable "bucket_enabled" {
  description = "Enable S3 bucket creation"
  type = bool
  default = true
}

variable "service_role_enabled" {
  description = "Enable vmimport service role creation"
  type = bool
  default = true
}

variable "role_name" {
  default = "vmimport"
}

variable "policy_name" {
  default = "VMImportAccess"
}
