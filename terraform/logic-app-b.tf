resource "azurerm_resource_group" "logicb" {
  for_each = toset(var.locations)

  name     = format("rg-logic-%s-%s-%s-b", random_id.environment_id.hex, var.environment, each.value)
  location = each.value

  tags = var.tags
}

// Initiall app service plan - no zone balancing. Enabling zone balancing would destroy the app service plan and recreate it.
resource "azurerm_service_plan" "logicb" {
  for_each = toset(var.locations)

  name = format("sp-logic-%s-%s-%s-b", random_id.environment_id.hex, var.environment, each.value)

  resource_group_name = azurerm_resource_group.logicb[each.value].name
  location            = azurerm_resource_group.logicb[each.value].location

  os_type  = "Windows"
  sku_name = "WS1"
}

resource "azurerm_monitor_diagnostic_setting" "logicb_svcplan" {
  for_each = toset(var.locations)

  name = azurerm_log_analytics_workspace.law.name

  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  target_resource_id = azurerm_service_plan.logicb[each.value].id

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }
}

resource "azurerm_storage_account" "logicb" {
  for_each = toset(var.locations)

  name = format("sala%sb", lower(random_string.location[each.value].result))

  resource_group_name = azurerm_resource_group.logicb[each.value].name
  location            = azurerm_resource_group.logicb[each.value].location

  account_tier             = "Standard"
  account_replication_type = "LRS"

  min_tls_version = "TLS1_2"


  // Public network access must be enabled for the demo as the GitHub Actions runner is not network connected.
  public_network_access_enabled = true

  network_rules {
    default_action = "Allow"
    bypass         = ["AzureServices"]
  }
}

resource "azurerm_private_endpoint" "logicb_sa_blob_pe" {
  for_each = toset(var.locations)

  name = format("pe-%s-blob", azurerm_storage_account.logicb[each.value].name)

  resource_group_name = azurerm_resource_group.logicb[each.value].name
  location            = azurerm_resource_group.logicb[each.value].location

  subnet_id = azurerm_subnet.endpoints[each.value].id

  private_dns_zone_group {
    name = "default"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.dns["blob"].id,
    ]
  }

  private_service_connection {
    name                           = format("pe-%s-blob", azurerm_storage_account.logicb[each.value].name)
    private_connection_resource_id = azurerm_storage_account.logicb[each.value].id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_endpoint" "logicb_sa_table_pe" {
  for_each = toset(var.locations)

  name = format("pe-%s-table", azurerm_storage_account.logicb[each.value].name)

  resource_group_name = azurerm_resource_group.logicb[each.value].name
  location            = azurerm_resource_group.logicb[each.value].location

  subnet_id = azurerm_subnet.endpoints[each.value].id

  private_dns_zone_group {
    name = "default"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.dns["table"].id,
    ]
  }

  private_service_connection {
    name                           = format("pe-%s-table", azurerm_storage_account.logicb[each.value].name)
    private_connection_resource_id = azurerm_storage_account.logicb[each.value].id
    subresource_names              = ["table"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_endpoint" "logicb_sa_queue_pe" {
  for_each = toset(var.locations)

  name = format("pe-%s-queue", azurerm_storage_account.logicb[each.value].name)

  resource_group_name = azurerm_resource_group.logicb[each.value].name
  location            = azurerm_resource_group.logicb[each.value].location

  subnet_id = azurerm_subnet.endpoints[each.value].id

  private_dns_zone_group {
    name = "default"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.dns["queue"].id,
    ]
  }

  private_service_connection {
    name                           = format("pe-%s-queue", azurerm_storage_account.logicb[each.value].name)
    private_connection_resource_id = azurerm_storage_account.logicb[each.value].id
    subresource_names              = ["queue"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_endpoint" "logicb_sa_file_pe" {
  for_each = toset(var.locations)

  name = format("pe-%s-file", azurerm_storage_account.logicb[each.value].name)

  resource_group_name = azurerm_resource_group.logicb[each.value].name
  location            = azurerm_resource_group.logicb[each.value].location

  subnet_id = azurerm_subnet.endpoints[each.value].id

  private_dns_zone_group {
    name = "default"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.dns["file"].id,
    ]
  }

  private_service_connection {
    name                           = format("pe-%s-file", azurerm_storage_account.logicb[each.value].name)
    private_connection_resource_id = azurerm_storage_account.logicb[each.value].id
    subresource_names              = ["file"]
    is_manual_connection           = false
  }
}

resource "azurerm_storage_share" "logicb" {
  for_each = toset(var.locations)

  name                 = format("logicb-%s-%s-%s", random_id.environment_id.hex, var.environment, each.value)
  storage_account_name = azurerm_storage_account.logicb[each.value].name
  quota                = 50
}

resource "azurerm_logic_app_standard" "logicb" {
  for_each = toset(var.locations)

  name = format("logicb-%s-%s-%s", random_id.environment_id.hex, var.environment, each.value)

  version = "~4"

  resource_group_name = azurerm_resource_group.logicb[each.value].name
  location            = azurerm_resource_group.logicb[each.value].location

  storage_account_name       = azurerm_storage_account.logicb[each.value].name
  storage_account_access_key = azurerm_storage_account.logicb[each.value].primary_access_key
  storage_account_share_name = azurerm_storage_share.logicb[each.value].name
  app_service_plan_id        = azurerm_service_plan.logicb[each.value].id

  virtual_network_subnet_id = azurerm_subnet.app_02[each.value].id

  https_only = true

  app_settings = {
    "APPINSIGHTS_INSTRUMENTATIONKEY"        = azurerm_application_insights.ai[each.value].instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.ai[each.value].connection_string
    "FUNCTIONS_WORKER_RUNTIME"              = "node"
    "WEBSITE_NODE_DEFAULT_VERSION"          = "~16"
    "WEBSITE_CONTENTOVERVNET"               = "1"
    "WEBSITE_RUN_FROM_PACKAGE"              = "1"
    "Workflows.Stateful1.FlowState"         = "Disabled"
    "Workflows.Stateful2.FlowState"         = "Disabled"
  }

  site_config {
    vnet_route_all_enabled = true

    use_32_bit_worker_process = false

    ftps_state = "Disabled"
  }

  identity {
    type = "SystemAssigned"
  }

  depends_on = [
    azurerm_private_endpoint.logicb_sa_blob_pe,
    azurerm_private_endpoint.logicb_sa_table_pe,
    azurerm_private_endpoint.logicb_sa_queue_pe,
    azurerm_private_endpoint.logicb_sa_file_pe
  ]
}
