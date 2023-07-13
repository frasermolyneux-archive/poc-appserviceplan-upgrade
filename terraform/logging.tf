resource "azurerm_resource_group" "log" {
  for_each = toset(var.locations)

  name     = format("rg-log-%s-%s-%s", random_id.environment_id.hex, var.environment, each.value)
  location = each.value

  tags = var.tags
}

resource "azurerm_log_analytics_workspace" "law" {
  name = format("la-%s-%s-%s", random_id.environment_id.hex, var.environment, var.primary_location)

  location            = var.primary_location
  resource_group_name = azurerm_resource_group.log[var.primary_location].name

  sku = "PerGB2018"

  retention_in_days = 30
}

resource "azurerm_application_insights" "ai" {
  for_each = toset(var.locations)

  name = format("ai-%s-%s-%s", random_id.environment_id.hex, var.environment, each.value)

  resource_group_name = azurerm_resource_group.log[each.value].name
  location            = azurerm_resource_group.log[each.value].location

  workspace_id = azurerm_log_analytics_workspace.law.id

  application_type = "web"
}

