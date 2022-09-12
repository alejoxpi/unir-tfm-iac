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
  identificador_unico         = "16928129"
  general_region              = "eastus2"
  general_tags                = { app = "unir-tfm-iac-demo", owner = "Jose Alejandro Benitez Aragon", identificador_unico= local.identificador_unico }
  general_resource_group_name = "rg-unir-tfm-iac-demo-${local.identificador_unico}"

  #Se debe usar un numero unico para evitar que el sa sea rechazado por existir en otra cuenta 
  general_storage_account_name = "saunirtfmiacdemo${local.identificador_unico}"
}

# Grupo de recursos para el ambiente
resource "azurerm_resource_group" "rg" {
  name     = local.general_resource_group_name
  location = local.general_region
  tags     = local.general_tags
}

# Monitorización del ambiente
resource "azurerm_application_insights" "application_insights" {
  depends_on = [
    azurerm_resource_group.rg
  ]
  name                = "ai-unir-tfm-iac-demo-${local.identificador_unico}"
  location            = local.general_region
  resource_group_name = local.general_resource_group_name
  application_type    = "web"
  retention_in_days   = 30
  tags                = local.general_tags
}

#Cuenta de almacenamiento
resource "azurerm_storage_account" "storage_account" {
  depends_on = [
    azurerm_resource_group.rg
  ]
  name                     = local.general_storage_account_name
  location                 = local.general_region
  resource_group_name      = local.general_resource_group_name
  tags                     = local.general_tags
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
}

resource "azurerm_cosmosdb_account" "cosmosdb" {
  name                = "cosmosdb-unir-tfn-iac-demo-${local.identificador_unico}"
  location            = local.general_region
  resource_group_name = local.general_resource_group_name
  offer_type          = "Standard"
  kind                = "MongoDB"

  enable_automatic_failover = false
  enable_free_tier          = true
  mongo_server_version      =  "4.0"

  capabilities {
    name = "EnableAggregationPipeline"
  }

  capabilities {
    name = "mongoEnableDocLevelTTL"
  } 

  capabilities {
    name = "EnableMongo"
  }

  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 300
    max_staleness_prefix    = 100000
  }

  geo_location {
    location          = local.general_region
    failover_priority = 1
  }

  geo_location {
    location          = "eastus"
    failover_priority = 0
  }
}

resource "azurerm_service_plan" "fapps_service_plan" {
  depends_on = [
    azurerm_resource_group.rg
  ]
  name                = "asp-unir-tfm-iac-demo-${local.identificador_unico}"
  location            = local.general_region
  resource_group_name = local.general_resource_group_name
  os_type             = "Linux"
  sku_name            = "Y1"
}

resource "azurerm_linux_function_app" "fapp_function_backend" {
  depends_on = [
    azurerm_resource_group.rg,
    azurerm_service_plan.fapps_service_plan,
    azurerm_storage_account.storage_account
  ]
  name                       = "fapp-unir-tfm-iac-demo-${local.identificador_unico}"
  location                   = local.general_region
  resource_group_name        = local.general_resource_group_name
  storage_account_name       = local.general_storage_account_name
  storage_account_access_key = azurerm_storage_account.storage_account.primary_access_key
  service_plan_id            = azurerm_service_plan.fapps_service_plan.id
  https_only                 = true


  app_settings = {
    FUNCTIONS_WORKER_RUNTIME = "dotnet"    
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = true
    WEBSITE_RUN_FROM_PACKAGE            = "1"
    WEBSITE_ENABLE_SYNC_UPDATE_SITE     = true
  }

  connection_string {
    name = "CosmosDBConnectionString"
    type = "Custom"
    value = azurerm_cosmosdb_account.cosmosdb.connection_strings[0]
  }
  site_config {
    always_on                = "false"
    use_32_bit_worker        = true
    ftps_state               = "FtpsOnly"
    http2_enabled            = "true"
    websockets_enabled       = "false"
    application_insights_key = azurerm_application_insights.application_insights.instrumentation_key
    application_insights_connection_string = azurerm_application_insights.application_insights.connection_string    
    minimum_tls_version      = "1.2"
  }

  tags = local.general_tags
}

