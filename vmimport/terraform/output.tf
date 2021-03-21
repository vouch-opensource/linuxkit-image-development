output "iam_role_arn" {
  value = var.vmimport_service_role == "false" ? aws_iam_role.vmimport.0.arn : null
}
