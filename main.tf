# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

locals {
    general_region = "eastus2"
    general_tags = { app = "unir-tfm-iac-demo", owner = "Jose Alejandro Benitez Aragon" }
}

# Grupo de recursos para el ambiente
resource "azurerm_resource_group" "rg" {
  name     = "rg-unir-tfm-iac-demo"
  location = local.general_region
  tags     = local.general_tags
}

# Monitorización del ambiente
module "application_insights" {
  source               = "./modules/application_insights"
  depends_on = [
    azurerm_resource_group.rg
  ]
  location             = local.general_region
  resource_group_name  = "rg-unir-tfm-iac-demo"
  ai_name              = "ai-unir-tfm-iac-demo-01"
  ai_application_type  = "web"
  ai_retention_in_days = 30
  default_tags         = local.general_tags
}

#Cuenta de almacenamiento
module "storage_account" {
  source  = "./modules/storage_account"
  depends_on = [
    azurerm_resource_group.rg
  ]
  location = local.general_region
  resource_group_name = "rg-unir-tfm-iac-demo"
  default_tags = local.general_tags
  storage_account_name = "saunirtfmiacdemo"
  storage_account_tier = "Standard"
  storage_account_replication_type = "LRS"  
}
