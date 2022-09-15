# Output variable definitions

output "arn" {
  description = "ARN of the bucket"
  value       = aws_s3_bucket.web.arn
}

output "name" {
  description = "Name (id) of the bucket"
  value       = aws_s3_bucket.web.id
}

output "domain" {
  description = "Domain name of the bucket"
  value       = aws_s3_bucket_website_configuration.web.website_domain
}

output "endpoint" {
  description = "Domain name of the bucket"
  value       = aws_s3_bucket_website_configuration.web.website_endpoint
}
