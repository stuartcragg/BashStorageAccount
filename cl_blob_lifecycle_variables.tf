variable "enable_blob_lifecycle" {
  description = "Enable blob lifecycle management policy"
  type        = bool
  default     = false
}

variable "blob_lifecycle_policies" {
  description = "Map of blob lifecycle management policies"
  type = map(object({
    name    = string
    enabled = bool
    filters = optional(object({
      prefix_match = optional(list(string))
      blob_types   = optional(list(string), ["blockBlob"])
      match_blob_index_tag = optional(list(object({
        name      = string
        operation = optional(string, "==")
        value     = string
      })), [])
    }))
    actions = object({
      base_blob = optional(object({
        tier_to_cool_after_days_since_modification_greater_than                     = optional(number)
        tier_to_cool_after_days_since_last_access_time_greater_than                 = optional(number)
        tier_to_cool_after_days_since_creation_greater_than                         = optional(number)
        auto_tier_to_hot_from_cool_enabled                                          = optional(bool)
        tier_to_archive_after_days_since_modification_greater_than                  = optional(number)
        tier_to_archive_after_days_since_last_access_time_greater_than              = optional(number)
        tier_to_archive_after_days_since_creation_greater_than                      = optional(number)
        tier_to_archive_after_days_since_last_tier_change_greater_than              = optional(number)
        tier_to_cold_after_days_since_modification_greater_than                     = optional(number)
        tier_to_cold_after_days_since_last_access_time_greater_than                 = optional(number)
        tier_to_cold_after_days_since_creation_greater_than                         = optional(number)
        delete_after_days_since_modification_greater_than                           = optional(number)
        delete_after_days_since_last_access_time_greater_than                       = optional(number)
        delete_after_days_since_creation_greater_than                               = optional(number)
      }))
      snapshot = optional(object({
        change_tier_to_archive_after_days_since_creation                            = optional(number)
        change_tier_to_cool_after_days_since_creation                               = optional(number)
        tier_to_archive_after_days_since_last_tier_change_greater_than              = optional(number)
        tier_to_cold_after_days_since_creation_greater_than                         = optional(number)
        delete_after_days_since_creation_greater_than                               = optional(number)
      }))
      version = optional(object({
        change_tier_to_archive_after_days_since_creation                            = optional(number)
        change_tier_to_cool_after_days_since_creation                               = optional(number)
        tier_to_archive_after_days_since_last_tier_change_greater_than              = optional(number)
        tier_to_cold_after_days_since_creation_greater_than                         = optional(number)
        delete_after_days_since_creation                                            = optional(number)
      }))
    })
  }))
  default = {}
}
