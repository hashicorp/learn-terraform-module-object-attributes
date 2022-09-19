# Terraform configuration

resource "aws_s3_bucket" "web" {
  bucket        = var.bucket_name
  bucket_prefix = var.bucket_prefix

  tags = var.tags
}

resource "aws_s3_bucket_website_configuration" "web" {
  bucket = aws_s3_bucket.web.id

  index_document {
    suffix = var.index_document_suffix
  }

  error_document {
    key = var.error_document_key
  }
}

resource "aws_s3_bucket_acl" "web" {
  bucket = aws_s3_bucket.web.id

  acl = "public-read"
}

resource "aws_s3_bucket_policy" "web" {
  bucket = aws_s3_bucket.web.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource = [
          aws_s3_bucket.web.arn,
          "${aws_s3_bucket.web.arn}/*",
        ]
      },
    ]
  })
}

module "template_files" {
  source  = "hashicorp/dir/template"
  version = "1.0.2"

  base_dir = var.www_path != null ? var.www_path : "${path.module}/www"
}

resource "aws_s3_object" "web" {
  for_each = var.terraform_managed_files ? module.template_files.files : {}

  bucket = aws_s3_bucket.web.id

  key          = each.key
  source       = each.value.source_path
  content      = each.value.content
  etag         = each.value.digests.md5
  content_type = each.value.content_type
}
