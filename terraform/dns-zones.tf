locals {
  private_dns_zones = {
    "azurewebsites" = "privatelink.azurewebsites.net",
    "blob"          = "privatelink.blob.core.windows.net",
    "table"         = "privatelink.table.core.windows.net",
    "queue"         = "privatelink.queue.core.windows.net",
    "file"          = "privatelink.file.core.windows.net",
    "vault"         = "privatelink.vaultcore.azure.net",
    "servicebus"    = "privatelink.servicebus.windows.net",
  }

  location_private_dns_zones = flatten([
    for location in var.locations : [
      for private_dns_zone_key, private_dns_zone in local.private_dns_zones : {
        key                  = format("%s-%s", private_dns_zone_key, location)
        location             = location
        private_dns_zone_key = private_dns_zone_key
        private_dns_zone     = private_dns_zone
      }
    ]
  ])
}

resource "azurerm_resource_group" "dns" {
  name     = format("rg-dns-%s-%s-%s", random_id.environment_id.hex, var.environment, var.primary_location)
  location = var.primary_location

  tags = var.tags
}

resource "azurerm_private_dns_zone" "dns" {
  for_each = { for key, value in local.private_dns_zones : key => value }

  name                = each.value
  resource_group_name = azurerm_resource_group.dns.name

  tags = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns" {
  for_each = { for each in local.location_private_dns_zones : each.key => each }

  name                  = format("link-%s-%s", each.key, lower(random_string.location[each.value.location].result))
  resource_group_name   = azurerm_resource_group.dns.name
  private_dns_zone_name = azurerm_private_dns_zone.dns[each.value.private_dns_zone_key].name
  virtual_network_id    = azurerm_virtual_network.apps[each.value.location].id
}
