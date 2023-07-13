terraform {
  required_version = ">= 1.4.6"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.58.0"
    }
    azapi = {
      source = "azure/azapi"
    }
  }

  backend "azurerm" {}
}

provider "azurerm" {
  subscription_id = var.subscription_id

  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azapi" {}

data "azurerm_client_config" "current" {}

data "azuread_client_config" "current" {}

resource "random_id" "environment_id" {
  byte_length = 6
}

// Create a random string that will be used when creating resources to prevent naming conflicts
resource "random_string" "location" {
  for_each = toset(var.locations)

  length  = 12
  special = false
}

resource "time_rotating" "rotate" {
  rotation_days = 30
}
