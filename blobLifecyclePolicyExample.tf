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

provider "azurerm" {
  features {}
}

# Call the module and define custom blob lifecycle policies
module "blob_lifecycle" {
  source                 = "./modules/blob-lifecycle"
  resource_group_name    = "example-resource-group"
  location               = "East US"
  storage_account_name   = "examplestorageaccount"
  enable_blob_lifecycle  = true

  # Define custom blob lifecycle policies
  blob_lifecycle_policies = {
    "main-policy" = {
      name = "main-lifecycle-policy"
      rules = [
        {
          name    = "rule1"
          enabled = true
          actions = {
            base_blob = {
              tier_to_cool_after_days_since_modification_greater_than    = 7
              tier_to_archive_after_days_since_last_access_time_greater_than = 30
              delete_after_days_since_creation_greater_than              = 90
            }
            snapshot = {
              delete_after_days_since_creation_greater_than              = 30
              tier_to_cool_after_days_since_creation_greater_than        = 15
            }
            version = {
              delete_after_days_since_creation_greater_than              = 60
              tier_to_archive_after_days_since_creation_greater_than     = 45
            }
          }
          filters = {
            prefix_match = ["container1/"]
            blob_types   = ["blockBlob"]
          }
        },
        {
          name    = "rule2"
          enabled = true
          actions = {
            base_blob = {
              tier_to_cold_after_days_since_modification_greater_than    = 14
              delete_after_days_since_last_access_time_greater_than      = 60
            }
          }
          filters = {
            prefix_match = ["container2/"]
            blob_types   = ["blockBlob", "appendBlob"]
          }
        }
      ]
    }
  }
}

# Outputs
output "storage_account_id" {
  value = module.blob_lifecycle.storage_account_id
}

output "lifecycle_policy_names" {
  value = module.blob_lifecycle.lifecycle_policy_names
}
