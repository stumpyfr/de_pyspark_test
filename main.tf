resource "random_pet" "candidate_names" {
  count  = 4
  length = 1
}

resource "random_password" "password" {
  length           = 12
  special          = true
  override_special = "_%@"
}

resource "random_password" "password_sql_pool" {
  length           = 12
  special          = true
  override_special = "_%@"
}

resource "azuread_user" "candidate_names" {
  count = length(random_pet.candidate_names)

  user_principal_name = "candidate-${random_pet.candidate_names[count.index].id}@${var.tld}"
  display_name        = "candidate-${random_pet.candidate_names[count.index].id}"
  mail_nickname       = "candidate-${random_pet.candidate_names[count.index].id}"
  password            = random_password.password.result
}

resource "azuread_group" "de_test_candidates_group" {
  display_name     = "DE Test Candidates"
  owners           = [var.owner_uuid]
  security_enabled = true
}

resource "azuread_group_member" "de_test_candidates_group_members" {
  count = length(azuread_user.candidate_names)

  group_object_id  = azuread_group.de_test_candidates_group.id
  member_object_id = azuread_user.candidate_names[count.index].id
}

resource "azurerm_resource_group" "de_test_rg" {
  name     = "de_test_rg_${var.env}"
  location = var.location

  tags = {
    env = var.env
  }
}

resource "azurerm_storage_account" "de_test_storage_account" {
  name                     = "deteststorageaccount${var.env}"
  resource_group_name      = azurerm_resource_group.de_test_rg.name
  location                 = azurerm_resource_group.de_test_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = "true"
}

resource "azurerm_storage_container" "de_test_storage_account_bronze" {
  name                  = "bronze"
  storage_account_name  = azurerm_storage_account.de_test_storage_account.name
  container_access_type = "private"
}

resource "azurerm_storage_blob" "de_test_storage_account_bronze_data" {
  for_each = fileset(path.module, "bronze_data/*")

  name                   = trim(each.key, "bronze_data/")
  storage_account_name   = azurerm_storage_account.de_test_storage_account.name
  storage_container_name = azurerm_storage_container.de_test_storage_account_bronze.name
  type                   = "Block"
  source                 = each.key
}

# resource "azurerm_storage_blob" "de_test_storage_account_exercice" {
#   name                   = "exercice.ipynb"
#   storage_account_name   = azurerm_storage_account.de_test_storage_account.name
#   storage_container_name = azurerm_storage_container.de_test_storage_account_bronze.name
#   type                   = "Block"
#   source                 = "exercice.ipynb"
# }

resource "azurerm_storage_container" "de_test_storage_account_silver" {
  name                  = "silver"
  storage_account_name  = azurerm_storage_account.de_test_storage_account.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "de_test_storage_account_gold" {
  name                  = "gold"
  storage_account_name  = azurerm_storage_account.de_test_storage_account.name
  container_access_type = "private"
}

resource "azurerm_storage_data_lake_gen2_filesystem" "de_test_storage_gen2_fs" {
  name               = "deteststoragegen2fs${var.env}"
  storage_account_id = azurerm_storage_account.de_test_storage_account.id
}

resource "azurerm_synapse_workspace" "de_test_synapse_workspace" {
  name                                 = "de-test-synapse-workspace-${var.env}"
  resource_group_name                  = azurerm_resource_group.de_test_rg.name
  location                             = azurerm_resource_group.de_test_rg.location
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.de_test_storage_gen2_fs.id
  sql_administrator_login              = "sqladminuser"
  sql_administrator_login_password     = random_password.password_sql_pool.result
  managed_virtual_network_enabled      = true

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_synapse_firewall_rule" "de_test_synapse_workspace_fw_rule" {
  name                 = "AllowAll"
  synapse_workspace_id = azurerm_synapse_workspace.de_test_synapse_workspace.id
  start_ip_address     = "0.0.0.0"
  end_ip_address       = "255.255.255.255"
}

resource "azurerm_synapse_managed_private_endpoint" "synapse_endpoint" {
  name                 = "de-test-synapse-workspace-endpoint-${var.env}"
  synapse_workspace_id = azurerm_synapse_workspace.de_test_synapse_workspace.id
  target_resource_id   = azurerm_storage_account.de_test_storage_account.id
  subresource_name     = "blob"

  depends_on = [azurerm_synapse_firewall_rule.de_test_synapse_workspace_fw_rule]
}

resource "azurerm_role_assignment" "de_test_synapse_storage_blob_data_contributor" {
  role_definition_name = "Storage Blob Data Contributor"
  scope                = azurerm_storage_account.de_test_storage_account.id
  principal_id         = azurerm_synapse_workspace.de_test_synapse_workspace.identity[0].principal_id
}

resource "azurerm_role_assignment" "de_test_synapse_storage_blob_data_contributor_niels" {
  role_definition_name = "Storage Blob Data Contributor"
  scope                = azurerm_storage_account.de_test_storage_account.id
  principal_id         = "808672c4-e35f-4749-ba8f-d81d5e061f19"
}

resource "azurerm_role_assignment" "de_test_synapse_storage_blob_data_contributor_candidate" {
  role_definition_name = "Storage Blob Data Contributor"
  scope                = azurerm_storage_account.de_test_storage_account.id
  principal_id         = azuread_group.de_test_candidates_group.id
}

resource "azurerm_synapse_integration_runtime_azure" "de_test_synapse_integration_runtime_azure" {
  name                 = "de-test-synapse-workspace-integration-${var.env}"
  synapse_workspace_id = azurerm_synapse_workspace.de_test_synapse_workspace.id
  location             = azurerm_resource_group.de_test_rg.location
}

resource "time_sleep" "wait_30_seconds" {
  # depends_on = [null_resource.previous]

  create_duration = "30s"
}

resource "azurerm_synapse_role_assignment" "de_test_synapse_candidate_role" {
  depends_on = [time_sleep.wait_30_seconds]

  synapse_workspace_id = azurerm_synapse_workspace.de_test_synapse_workspace.id
  role_name            = "Synapse Administrator"
  principal_id         = azuread_group.de_test_candidates_group.id
  principal_type       = "Group"
}

resource "azurerm_synapse_spark_pool" "de_test_synapse_spark_pool" {
  name                 = "detestspark${var.env}"
  synapse_workspace_id = azurerm_synapse_workspace.de_test_synapse_workspace.id
  node_size_family     = "MemoryOptimized"
  node_size            = "Small"
  cache_size           = 100
  spark_version        = 3.3

  auto_scale {
    max_node_count = 3
    min_node_count = 3
  }

  auto_pause {
    delay_in_minutes = 5
  }
}
