# Learn Terraform Modules - Object Attributes

Learn how and why to use object attributes in your Terraform modules.

This repo is a companion repo to the [FIXME: Add title](https://learn.hashicorp.com/tutorials/terraform/FIXME?in=terraform/modules).

## Apply configuration to create bucket

```shell-session
$ terraform apply
```

Visit the `website_bucket_endpoint` to see the content.

## Refactor to put "file-related" options into an object

In `modules/aws-s3-static-website/variables.tf`:

Comment out/delete `variable "index_document_suffix" {` to end of file.

Replace with:

```hcl
variable "files" {
  description = "Configuration for website files."
  type = object({
    terraform_managed     = bool
    error_document_key    = optional(string, "error.html")
    index_document_suffix = optional(string, "index.html")
    www_path              = optional(string)
  })
}
```

Update `modules/aws-s3-static-website/main.tf` to use the `files` object instead of vars:

```hcl
resource "aws_s3_bucket_website_configuration" "web" {
  bucket = aws_s3_bucket.web.id

  index_document {
    suffix = var.files.index_document_suffix
  }

  error_document {
    key = var.files.error_document_key
  }
}
```

and:

```hcl
module "template_files" {
  source  = "hashicorp/dir/template"
  version = "1.0.2"

  base_dir = var.files.www_path != null ? var.files.www_path : "${path.module}/www"
}

resource "aws_s3_object" "web" {
  for_each = var.files.terraform_managed ? module.template_files.files : {}

```

Now when you use the module, you can:

1. Use the `files` attribute with `terraform_managed` set to `false` to manage files outside of Terraform.
1. Set `terraform_managed` to `true`, and either use the default files (in `modules/aws-s3-static-website/www`) or specify your own path.
1. Either way, optionally configure `index_document_suffix` and/or `error_document_key`.
1. Since the `files` attribute doesn't have a default value, it is required.

Update `main.tf` (in the root) to use this attribute:

```hcl
module "website_s3_bucket" {
  source = "./modules/aws-s3-static-website"

  bucket_prefix = "module-object-attributes-"

  files = {
    terraform_managed = true
    www_path          = "./www"
  }
```

Apply the configuration. Terraform will replace the website content with the files in `./www`.

## Use a list of objects to configure CORS

Add to `modules/aws-s3-static-website/variables.tf`:

```hcl
variable "cors_rules" {
  description = "List of CORS rules."
  type = list(object({
    allowed_headers = optional(set(string)),
    allowed_methods = set(string),
    allowed_origins = set(string),
    expose_headers  = optional(set(string)),
    max_age_seconds = optional(number)
  }))
  default = []
}
```

The `cors_rules` variable contains a list of objects. Since the default is an empty list (`[]`), you don't have to specify this as an attribute when you use the module. When you do, you must set `allowed_methods` and `allowed_origins`, the other attributes are optional.

Use this variable in `modules/aws-s3-static-website/main.tf`.

```hcl
resource "aws_s3_bucket_cors_configuration" "web" {
  count = length(var.cors_rules) > 0 ? 1 : 0

  bucket = aws_s3_bucket.web.id

  dynamic "cors_rule" {
    for_each = var.cors_rules

    content {
      allowed_headers = cors_rule.value["allowed_headers"]
      allowed_methods = cors_rule.value["allowed_methods"]
      allowed_origins = cors_rule.value["allowed_origins"]
      expose_headers  = cors_rule.value["expose_headers"]
      max_age_seconds = cors_rule.value["max_age_seconds"]
    }
  }
}
```

If the list is empty, this block won't be used at all. Otherwise, the `dynamic`
block will create a CORS rule for each object in the list. Since the optional
attributes default to `null`, they will not be set unless you specify a value.

Use this new variable to add two CORS rules to your bucket in `main.tf`:

```hcl
module "website_s3_bucket" {
  source = "./modules/aws-s3-static-website"

  bucket_prefix = "module-object-attributes-"

  files = {
    terraform_managed = true
  }

  cors_rules = [
    {
      allowed_headers = ["*"],
      allowed_methods = ["PUT", "POST"],
      allowed_origins = ["https://test.example.com"],
      expose_headers  = ["ETag"],
      max_age_seconds = 3000
    },

    {
      allowed_methods = ["GET"],
      allowed_origins = ["*"]
    }
  ]
```

Apply this change:

```shell-session
$ terraform apply
```

## Clean up your infrastructure

```shell-session
$ terraform destroy
```
