resource "azurerm_storage_management_policy" "lifecycle_policy" {
  count              = var.enable_blob_lifecycle ? 1 : 0
  storage_account_id = var.storage_account_id

  dynamic "rule" {
    for_each = var.blob_lifecycle_policies
    content {
      name    = rule.value.name
      enabled = rule.value.enabled

      # Filters block - at minimum blob_types must be specified
      filters {
        prefix_match = try(rule.value.filters.prefix_match, null)
        blob_types   = try(rule.value.filters.blob_types, ["blockBlob"])

        # Dynamic block for blob index tags
        dynamic "match_blob_index_tag" {
          for_each = try(rule.value.filters.match_blob_index_tag, [])
          content {
            name      = match_blob_index_tag.value.name
            operation = match_blob_index_tag.value.operation
            value     = match_blob_index_tag.value.value
          }
        }
      }

      # Actions block
      actions {
        # Base blob actions
        dynamic "base_blob" {
          for_each = rule.value.actions.base_blob != null ? [rule.value.actions.base_blob] : []
          content {
            # Cool tier transitions
            tier_to_cool_after_days_since_modification_greater_than = base_blob.value.tier_to_cool_after_days_since_modification_greater_than
            tier_to_cool_after_days_since_last_access_time_greater_than = base_blob.value.tier_to_cool_after_days_since_last_access_time_greater_than
            tier_to_cool_after_days_since_creation_greater_than = base_blob.value.tier_to_cool_after_days_since_creation_greater_than
            
            # Auto-tier to hot from cool
            auto_tier_to_hot_from_cool_enabled = base_blob.value.auto_tier_to_hot_from_cool_enabled
            
            # Archive tier transitions
            tier_to_archive_after_days_since_modification_greater_than = base_blob.value.tier_to_archive_after_days_since_modification_greater_than
            tier_to_archive_after_days_since_last_access_time_greater_than = base_blob.value.tier_to_archive_after_days_since_last_access_time_greater_than
            tier_to_archive_after_days_since_creation_greater_than = base_blob.value.tier_to_archive_after_days_since_creation_greater_than
            tier_to_archive_after_days_since_last_tier_change_greater_than = base_blob.value.tier_to_archive_after_days_since_last_tier_change_greater_than
            
            # Cold tier transitions
            tier_to_cold_after_days_since_modification_greater_than = base_blob.value.tier_to_cold_after_days_since_modification_greater_than
            tier_to_cold_after_days_since_last_access_time_greater_than = base_blob.value.tier_to_cold_after_days_since_last_access_time_greater_than
            tier_to_cold_after_days_since_creation_greater_than = base_blob.value.tier_to_cold_after_days_since_creation_greater_than
            
            # Delete actions
            delete_after_days_since_modification_greater_than = base_blob.value.delete_after_days_since_modification_greater_than
            delete_after_days_since_last_access_time_greater_than = base_blob.value.delete_after_days_since_last_access_time_greater_than
            delete_after_days_since_creation_greater_than = base_blob.value.delete_after_days_since_creation_greater_than
          }
        }

        # Snapshot actions
        dynamic "snapshot" {
          for_each = rule.value.actions.snapshot != null ? [rule.value.actions.snapshot] : []
          content {
            change_tier_to_archive_after_days_since_creation = snapshot.value.change_tier_to_archive_after_days_since_creation
            change_tier_to_cool_after_days_since_creation = snapshot.value.change_tier_to_cool_after_days_since_creation
            tier_to_archive_after_days_since_last_tier_change_greater_than = snapshot.value.tier_to_archive_after_days_since_last_tier_change_greater_than
            tier_to_cold_after_days_since_creation_greater_than = snapshot.value.tier_to_cold_after_days_since_creation_greater_than
            delete_after_days_since_creation_greater_than = snapshot.value.delete_after_days_since_creation_greater_than
          }
        }

        # Version actions (for blob versioning)
        dynamic "version" {
          for_each = rule.value.actions.version != null ? [rule.value.actions.version] : []
          content {
            change_tier_to_archive_after_days_since_creation = version.value.change_tier_to_archive_after_days_since_creation
            change_tier_to_cool_after_days_since_creation = version.value.change_tier_to_cool_after_days_since_creation
            tier_to_archive_after_days_since_last_tier_change_greater_than = version.value.tier_to_archive_after_days_since_last_tier_change_greater_than
            tier_to_cold_after_days_since_creation_greater_than = version.value.tier_to_cold_after_days_since_creation_greater_than
            delete_after_days_since_creation = version.value.delete_after_days_since_creation
          }
        }
      }
    }
  }
}
