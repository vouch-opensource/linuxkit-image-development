resource "aws_s3_bucket" "linuxkit" {
  bucket = var.linuxkit_bucket_name
  acl    = "private"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "linuxkit" {
  bucket = aws_s3_bucket.linuxkit.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
