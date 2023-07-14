locals {
  logic_appsa = [for logic_app in azurerm_logic_app_standard.logica : {
    name                = logic_app.name
    resource_group_name = logic_app.resource_group_name
  }]

  logic_appsb = [for logic_app in azurerm_logic_app_standard.logicb : {
    name                = logic_app.name
    resource_group_name = logic_app.resource_group_name
  }]
}

output "logic_apps" {
  value = setunion(local.logic_appsa, local.logic_appsb)
}
