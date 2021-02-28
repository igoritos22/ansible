#criacao do provider
provider "azurerm" {
  subscription_id = var.id_sub
  features {}
}

terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "2.46.1"
    }
  }
}