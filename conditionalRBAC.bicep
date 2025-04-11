// Parameters
param subscriptionId string = subscription().subscriptionId
param managedIdentityPrincipalId string // Principal ID of your user-assigned managed identity
param location string = resourceGroup().location

// Variables for role definition IDs (from Azure documentation as of April 10, 2025)
var roleDefinitionIds = {
  storageAccountBackupContributor: '/subscriptions/${subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/e5e2a7ff-d759-4cd2-bb51-3152d37e2eb1'
  diskBackupReader: '/subscriptions/${subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/3e5e47e6-65f7-47ef-90b5-e5dd4d455f24'
  diskSnapshotContributor: '/subscriptions/${subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/7efff54f-a5b4-42b5-a1c5-5411624893ce'
  postgreSqlLtrBackup: '/subscriptions/${subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/c088a766-074b-43ba-90d4-1fb21feae531'
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
    condition: '''
      (
        (!(ActionMatches('Microsoft.Authorization/roleAssignments/write')))
        OR
        (
          @Request[Microsoft.Authorization/roleAssignments:roleDefinitionId] StringEqualsIgnoreCase '${roleDefinitionIds.storageAccountBackupContributor}' ||
          @Request[Microsoft.Authorization/roleAssignments:roleDefinitionId] StringEqualsIgnoreCase '${roleDefinitionIds.diskBackupReader}' ||
          @Request[Microsoft.Authorization/roleAssignments:roleDefinitionId] StringEqualsIgnoreCase '${roleDefinitionIds.diskSnapshotContributor}' ||
          @Request[Microsoft.Authorization/roleAssignments:roleDefinitionId] StringEqualsIgnoreCase '${roleDefinitionIds.postgreSqlLtrBackup}'
        )
      )
      AND
      (
        @Request[Microsoft.Authorization/roleAssignments:scope] StringStartsWith '/subscriptions/${subscriptionId}/resourceGroups/${resourceGroup().name}'
      )
    '''
    conditionVersion: '2.0'
  }
}

// Output the custom role ID for reference
output customRoleId string = restrictedRoleAssigner.id

(
 (
  !(ActionMatches{'Microsoft.Authorization/roleAssignments/write'})
 )
 OR 
 (
  @Request[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {e5e2a7ff-d759-4cd2-bb51-3152d37e2eb1, 3e5e47e6-65f7-47ef-90b5-e5dd4d455f24, 7efff54f-a5b4-42b5-a1c5-5411624893ce, c088a766-074b-43ba-90d4-1fb21feae531}
  AND
  @Request[Microsoft.Authorization/roleAssignments:PrincipalType] ForAnyOfAnyValues:StringEqualsIgnoreCase {'ServicePrincipal'}
 )
)
AND
(
 (
  !(ActionMatches{'Microsoft.Authorization/roleAssignments/delete'})
 )
 OR 
 (
  @Resource[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {e5e2a7ff-d759-4cd2-bb51-3152d37e2eb1, 3e5e47e6-65f7-47ef-90b5-e5dd4d455f24, 7efff54f-a5b4-42b5-a1c5-5411624893ce, c088a766-074b-43ba-90d4-1fb21feae531}
  AND
  @Resource[Microsoft.Authorization/roleAssignments:PrincipalType] ForAnyOfAnyValues:StringEqualsIgnoreCase {'ServicePrincipal'}
 )
)

(
 (
  !(ActionMatches{'Microsoft.Authorization/roleAssignments/write'})
 )
 OR 
 (
  @Request[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {e5e2a7ff-d759-4cd2-bb51-3152d37e2eb1, 3e5e47e6-65f7-47ef-90b5-e5dd4d455f24, 7efff54f-a5b4-42b5-a1c5-5411624893ce, c088a766-074b-43ba-90d4-1fb21feae531}
 )
)
AND
(
 (
  !(ActionMatches{'Microsoft.Authorization/roleAssignments/delete'})
 )
 OR 
 (
  @Resource[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {e5e2a7ff-d759-4cd2-bb51-3152d37e2eb1, 3e5e47e6-65f7-47ef-90b5-e5dd4d455f24, 7efff54f-a5b4-42b5-a1c5-5411624893ce, c088a766-074b-43ba-90d4-1fb21feae531}
 )
)
