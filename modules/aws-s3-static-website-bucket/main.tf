# Terraform configuration

resource "aws_s3_bucket" "s3_bucket" {
  bucket        = var.bucket_name
  bucket_prefix = var.bucket_prefix

  tags = var.tags
}

resource "aws_s3_bucket_website_configuration" "s3_bucket" {
  bucket = aws_s3_bucket.s3_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_acl" "s3_bucket" {
  bucket = aws_s3_bucket.s3_bucket.id

  acl = "public-read"
}

resource "aws_s3_bucket_policy" "s3_bucket" {
  bucket = aws_s3_bucket.s3_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource = [
          aws_s3_bucket.s3_bucket.arn,
          "${aws_s3_bucket.s3_bucket.arn}/*",
        ]
      },
    ]
  })
}

locals {
  www_path = var.www_path != null ? var.www_path : "${path.module}/www"
}

module "template_files" {
  source  = "hashicorp/dir/template"
  version = "1.0.2"

  base_dir = var.www_path != null ? var.www_path : "${path.module}/www"
}

resource "aws_s3_object" "object" {
  for_each = module.template_files.files

  bucket = aws_s3_bucket.s3_bucket.id

  key          = each.key
  source       = each.value.source_path
  content      = each.value.content  
  etag         = each.value.digests.md5
  content_type = each.value.content_type  
}
