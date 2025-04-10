// Parameters
param subscriptionId string = subscription().subscriptionId
param managedIdentityPrincipalId string // Principal ID of your user-assigned managed identity
param location string = resourceGroup().location

// Variables for role definition IDs (from Azure documentation as of April 10, 2025)
var roleDefinitionIds = {
  storageAccountBackupContributor: '/subscriptions/${subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/434105ee-43f9-465e-9b28-4c6d0cc91b7b'
  diskBackupReader: '/subscriptions/${subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/3e5e47e6-65f7-47ef-90b5-e5dd4d455f24'
  diskSnapshotContributor: '/subscriptions/${subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/7efff54f-a5b4-42b5-a1c5-5f3bcc950df1'
  postgreSqlLtrBackup: '/subscriptions/${subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/1f12053e-4f4a-40d1-bcfc-be19d7e8e9e1'
}

// Custom role definition
resource restrictedRoleAssigner 'Microsoft.Authorization/roleDefinitions@2022-04-01' = {
  name: guid('RestrictedRoleAssigner-BackupRoles') // Generates a unique GUID for the role
  properties: {
    roleName: 'Restricted Role Assigner - Backup Roles'
    description: 'Can assign only Storage Account Backup Contributor, Disk Backup Reader, Disk Snapshot Contributor, and PostgreSQL Flexible Server Long Term Retention Backup Role.'
    assignableScopes: [
      '/subscriptions/${subscriptionId}'
    ]
    permissions: [
      {
        actions: [
          'Microsoft.Authorization/roleAssignments/write'
          'Microsoft.Authorization/roleAssignments/read'
          'Microsoft.Authorization/roleAssignments/delete'
        ]
        notActions: []
        dataActions: []
        notDataActions: []
      }
    ]
  }
}

// Role assignment with condition
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscriptionId, managedIdentityPrincipalId, restrictedRoleAssigner.id)
  properties: {
    principalId: managedIdentityPrincipalId
    roleDefinitionId: restrictedRoleAssigner.id
    principalType: 'ServicePrincipal' // Managed identities are treated as service principals
    condition: '((@Resource[Microsoft.Authorization/roleAssignments:RoleDefinitionId] == \'${roleDefinitionIds.storageAccountBackupContributor}\') || (@Resource[Microsoft.Authorization/roleAssignments:RoleDefinitionId] == \'${roleDefinitionIds.diskBackupReader}\') || (@Resource[Microsoft.Authorization/roleAssignments:RoleDefinitionId] == \'${roleDefinitionIds.diskSnapshotContributor}\') || (@Resource[Microsoft.Authorization/roleAssignments:RoleDefinitionId] == \'${roleDefinitionIds.postgreSqlLtrBackup}\'))'
    conditionVersion: '2.0'
  }
}

// Output the custom role ID for reference
output customRoleId string = restrictedRoleAssigner.id
