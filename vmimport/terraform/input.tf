variable "linuxkit_bucket_name" {
  description = "S3 bucket name for storing the exported linuxkit images"
  type        = string
}

variable "vmimport_service_role" {
  description = "Enable vmimport service role creation"
  type = bool
  default = true
}
