# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

terraform {
  cloud {
    workspaces {
      name = "learn-terraform-module-object-attributes"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.30.0"
    }
  }

  required_version = ">= 1.3"
}
