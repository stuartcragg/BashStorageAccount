variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "my-resource-group"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "East US"
}

variable "storage_account_name" {
  description = "Name of the storage account"
  type        = string
  default     = "mystorageaccount"
}

variable "enable_blob_lifecycle" {
  description = "Whether to enable blob lifecycle management policies"
  type        = bool
  default     = false
}

variable "blob_lifecycle_policies" {
  description = "Map of blob lifecycle management policies"
  type = map(object({
    name = string
    rules = list(object({
      name    = string
      enabled = bool
      actions = object({
        base_blob = optional(object({
          tier_to_cool_after_days_since_modification_greater_than    = optional(number)
          tier_to_cool_after_days_since_last_access_time_greater_than = optional(number)
          tier_to_cool_after_days_since_creation_greater_than         = optional(number)
          tier_to_archive_after_days_since_modification_greater_than = optional(number)
          tier_to_archive_after_days_since_last_access_time_greater_than = optional(number)
          tier_to_archive_after_days_since_creation_greater_than      = optional(number)
          tier_to_cold_after_days_since_modification_greater_than    = optional(number)
          tier_to_cold_after_days_since_last_access_time_greater_than = optional(number)
          tier_to_cold_after_days_since_creation_greater_than         = optional(number)
          delete_after_days_since_modification_greater_than          = optional(number)
          delete_after_days_since_last_access_time_greater_than      = optional(number)
          delete_after_days_since_creation_greater_than              = optional(number)
        }))
        snapshot = optional(object({
          delete_after_days_since_creation_greater_than              = optional(number)
          tier_to_cool_after_days_since_creation_greater_than        = optional(number)
          tier_to_archive_after_days_since_creation_greater_than     = optional(number)
          tier_to_cold_after_days_since_creation_greater_than        = optional(number)
          tier_to_hot_after_days_since_creation_greater_than         = optional(number)
        }))
        version = optional(object({
          delete_after_days_since_creation_greater_than              = optional(number)
          tier_to_cool_after_days_since_creation_greater_than        = optional(number)
          tier_to_archive_after_days_since_creation_greater_than     = optional(number)
          tier_to_cold_after_days_since_creation_greater_than        = optional(number)
          tier_to_hot_after_days_since_creation_greater_than         = optional(number)
        }))
      })
      filters = optional(object({
        prefix_match = optional(list(string))
        blob_types   = list(string)
      }))
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.blob_lifecycle_policies : alltrue([
        for rule in v.rules : alltrue([
          for bt in try(rule.filters.blob_types, []) : contains(["blockBlob", "appendBlob"], bt)
        ])
      ])
    ])
    error_message = "The 'blob_types' in each rule's filters must only contain 'blockBlob' or 'appendBlob'."
  }
}
