# Configure the Azure provider
terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Create a resource group
resource "azurerm_resource_group" "default" {
  name     = var.resource_group_name
  location = var.location
}

# Create a storage account
resource "azurerm_storage_account" "default" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.default.name
  location                 = azurerm_resource_group.default.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Define local configurations for blob lifecycle policies
locals {
  blob_lifecycle_policies = var.enable_blob_lifecycle ? var.blob_lifecycle_policies : {}
}

# Configure blob lifecycle management policies
resource "azurerm_storage_management_policy" "lifecycle" {
  for_each           = local.blob_lifecycle_policies
  storage_account_id = azurerm_storage_account.default.id

  dynamic "rule" {
    for_each = each.value.rules
    content {
      name    = rule.value.name
      enabled = rule.value.enabled

      definition {
        # Actions for base_blob
        dynamic "actions" {
          for_each = rule.value.actions.base_blob != null ? [rule.value.actions.base_blob] : []
          content {
            tier_to_cool_after_days_since_modification_greater_than    = try(actions.value.tier_to_cool_after_days_since_modification, null)
            tier_to_cool_after_days_since_last_access_time_greater_than = try(actions.value.tier_to_cool_after_days_since_last_access, null)
            tier_to_cool_after_days_since_creation_greater_than         = try(actions.value.tier_to_cool_after_days_since_creation, null)
            tier_to_archive_after_days_since_modification_greater_than = try(actions.value.tier_to_archive_after_days_since_modification, null)
            tier_to_archive_after_days_since_last_access_time_greater_than = try(actions.value.tier_to_archive_after_days_since_last_access, null)
            tier_to_archive_after_days_since_creation_greater_than      = try(actions.value.tier_to_archive_after_days_since_creation, null)
            tier_to_cold_after_days_since_modification_greater_than    = try(actions.value.tier_to_cold_after_days_since_modification, null)
            tier_to_cold_after_days_since_last_access_time_greater_than = try(actions.value.tier_to_cold_after_days_since_last_access, null)
            tier_to_cold_after_days_since_creation_greater_than         = try(actions.value.tier_to_cold_after_days_since_creation, null)
            delete_after_days_since_modification_greater_than          = try(actions.value.delete_after_days_since_modification, null)
            delete_after_days_since_last_access_time_greater_than      = try(actions.value.delete_after_days_since_last_access, null)
            delete_after_days_since_creation_greater_than              = try(actions.value.delete_after_days_since_creation, null)
          }
        }

        # Actions for snapshot
        dynamic "actions" {
          for_each = rule.value.actions.snapshot != null ? [rule.value.actions.snapshot] : []
          content {
            delete_after_days_since_creation_greater_than              = try(actions.value.delete_after_days_since_creation, null)
            tier_to_cool_after_days_since_creation_greater_than        = try(actions.value.tier_to_cool_after_days_since_creation, null)
            tier_to_archive_after_days_since_creation_greater_than     = try(actions.value.tier_to_archive_after_days_since_creation, null)
            tier_to_cold_after_days_since_creation_greater_than        = try(actions.value.tier_to_cold_after_days_since_creation, null)
            tier_to_hot_after_days_since_creation_greater_than         = try(actions.value.tier_to_hot_after_days_since_creation, null)
          }
        }

        # Actions for version
        dynamic "actions" {
          for_each = rule.value.actions.version != null ? [rule.value.actions.version] : []
          content {
            delete_after_days_since_creation_greater_than              = try(actions.value.delete_after_days_since_creation, null)
            tier_to_cool_after_days_since_creation_greater_than        = try(actions.value.tier_to_cool_after_days_since_creation, null)
            tier_to_archive_after_days_since_creation_greater_than     = try(actions.value.tier_to_archive_after_days_since_creation, null)
            tier_to_cold_after_days_since_creation_greater_than        = try(actions.value.tier_to_cold_after_days_since_creation, null)
            tier_to_hot_after_days_since_creation_greater_than         = try(actions.value.tier_to_hot_after_days_since_creation, null)
          }
        }

        # Filters
        dynamic "filter" {
          for_each = rule.value.filters != null ? [rule.value.filters] : []
          content {
            prefix_match = try(filter.value.prefix_match, null)
            blob_types   = filter.value.blob_types
          }
        }
      }
    }
  }
}

# Outputs
output "storage_account_id" {
  value = azurerm_storage_account.default.id
}

output "lifecycle_policy_names" {
  value = var.enable_blob_lifecycle ? [for policy in local.blob_lifecycle_policies : policy.name] : []
}
