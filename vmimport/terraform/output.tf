output "iam_role_arn" {
  value = var.service_role_enabled == "false" ? aws_iam_role.vmimportCommon.0.arn : null
}
