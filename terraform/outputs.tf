locals {
  logic_apps = [for logic_app in azurerm_logic_app_standard.logic : {
    name                = logic_app.name
    resource_group_name = logic_app.resource_group_name
  }]
}

output "logic_apps" {
  value = local.logic_apps
}
