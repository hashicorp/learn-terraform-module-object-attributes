# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# Terraform configuration

provider "aws" {
  region = "us-west-2"

  default_tags {
    tags = {
      hashicorp-learn = "module-object-attributes"
    }
  }
}

module "website_s3_bucket" {
  source = "./modules/aws-s3-static-website"

  bucket_prefix = "module-object-attributes-"

  tags = {
    terraform     = "true"
    environment   = "dev"
    public-bucket = true
  }
}
