resource "aws_s3_bucket" "create" {
  bucket = "s3-${var.company}-${var.department}-${var.project}-modelstore"
  tags   = var.tags

  lifecycle {
    # prevent_destroy = true
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encrypt" {
  bucket = aws_s3_bucket.create.bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }

  lifecycle {
    # prevent_destroy = true
  }
}

resource "aws_s3_bucket_public_access_block" "s3private" {
  bucket                  = aws_s3_bucket.create.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  lifecycle {
    # prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "version" {
  bucket = aws_s3_bucket.create.id
  versioning_configuration {
    status = var.versioning
  }

  lifecycle {
    # prevent_destroy = true
  }
}


output "bucket_name" {
  value = aws_s3_bucket.create.bucket
}