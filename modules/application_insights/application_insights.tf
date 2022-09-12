resource "azurerm_application_insights" "application_insights" {
  name                = var.ai_name
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = var.ai_application_type
  retention_in_days   = var.ai_retention_in_days
  tags = var.default_tags  
}