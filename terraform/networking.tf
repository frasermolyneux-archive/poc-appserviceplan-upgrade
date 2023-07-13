resource "azurerm_resource_group" "vnet" {
  for_each = toset(var.locations)

  name     = format("rg-vnet-%s-%s-%s", random_id.environment_id.hex, var.environment, each.value)
  location = each.value

  tags = var.tags
}

resource "azurerm_virtual_network" "apps" {
  for_each = toset(var.locations)

  name          = format("vnet-%s-%s-%s", random_id.environment_id.hex, var.environment, each.value)
  address_space = [var.address_spaces[each.value]]

  resource_group_name = azurerm_resource_group.vnet[each.value].name
  location            = azurerm_resource_group.vnet[each.value].location
}

resource "azurerm_subnet" "endpoints" {
  for_each = toset(var.locations)

  name = format("snet-integration-%s-%s-%s", random_id.environment_id.hex, var.environment, each.value)

  resource_group_name  = azurerm_resource_group.vnet[each.value].name
  virtual_network_name = azurerm_virtual_network.apps[each.value].name

  address_prefixes = [var.subnets[each.value]["endpoints"]]
}

resource "azurerm_subnet" "app_01" {
  for_each = toset(var.locations)

  name = format("snet-app-01-%s-%s-%s", random_id.environment_id.hex, var.environment, each.value)

  resource_group_name  = azurerm_resource_group.vnet[each.value].name
  virtual_network_name = azurerm_virtual_network.apps[each.value].name

  address_prefixes = [var.subnets[each.value]["app_01"]]

  delegation {
    name = "delegation"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_subnet" "app_02" {
  for_each = toset(var.locations)

  name = format("snet-app-02-%s-%s-%s", random_id.environment_id.hex, var.environment, each.value)

  resource_group_name  = azurerm_resource_group.vnet[each.value].name
  virtual_network_name = azurerm_virtual_network.apps[each.value].name

  address_prefixes = [var.subnets[each.value]["app_02"]]

  delegation {
    name = "delegation"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}
