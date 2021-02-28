#criacao do provider
provider "azurerm" {
  subscription_id = "2129a764-fdca-41c9-b27c-a35ef18705af"
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