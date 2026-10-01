param entraTenantId string
param sqlEntraAdminObjectId string
param sqlEntraAdminName string
param keyVaultName string
param storageAccountName string
param sqlServerName string
param sqlDatabaseName string
param importContainerName string
param logRetentionDays int
param apiIdentityPrincipalIds array
param logAnalyticsWorkspaceId string
param tags object

resource vault 'Microsoft.KeyVault/vaults@2024-11-01' existing = {
  name: keyVaultName
}
resource vaultRoles 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for principalId in apiIdentityPrincipalIds: {
    scope: vault
    name: guid(vault.id, principalId, 'Key Vault Secrets User')
    properties: {
      roleDefinitionId: subscriptionResourceId(
        'Microsoft.Authorization/roleDefinitions',
        '4633458b-17de-408a-b874-0445c86b69e6'
      )
      principalId: principalId
      principalType: 'ServicePrincipal'
      description: 'Managed by ${tags.managedBy} for ${tags.workload}.'
    }
  }
]
resource vaultDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: vault
  name: 'send-to-log-analytics'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        categoryGroup: 'audit'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
}
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storage
  name: 'default'
  properties: {
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}
resource importContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blobService
  name: importContainerName
  properties: {
    publicAccess: 'None'
  }
}
resource storageRoles 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for principalId in apiIdentityPrincipalIds: {
    scope: importContainer
    name: guid(importContainer.id, principalId, 'Storage Blob Data Contributor')
    properties: {
      roleDefinitionId: subscriptionResourceId(
        'Microsoft.Authorization/roleDefinitions',
        'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
      )
      principalId: principalId
      principalType: 'ServicePrincipal'
      description: 'Managed by ${tags.managedBy} for ${tags.workload}.'
    }
  }
]
resource lifecycle 'Microsoft.Storage/storageAccounts/managementPolicies@2023-05-01' = {
  parent: storage
  name: 'default'
  properties: {
    policy: {
      rules: [
        {
          enabled: true
          name: 'delete-expired-synthetic-imports'
          type: 'Lifecycle'
          definition: {
            actions: {
              baseBlob: {
                delete: {
                  daysAfterModificationGreaterThan: 30
                }
              }
            }
            filters: {
              blobTypes: ['blockBlob']
              prefixMatch: ['discovery-imports/']
            }
          }
        }
      ]
    }
  }
}
resource storageDefender 'Microsoft.Security/defenderForStorageSettings@2022-12-01-preview' = {
  scope: storage
  name: 'current'
  properties: {
    isEnabled: true
    malwareScanning: {
      onUpload: {
        isEnabled: true
        capGBPerMonth: 10
      }
    }
    sensitiveDataDiscovery: {
      isEnabled: false
    }
    overrideSubscriptionLevelSettings: true
  }
}
resource storageMalwareScanResultsDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: storageDefender
  name: 'service'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'ScanResults'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: logRetentionDays
        }
      }
    ]
  }
}
resource storageDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: blobService
  name: 'send-to-log-analytics'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

resource sqlServer 'Microsoft.Sql/servers@2023-08-01-preview' existing = {
  name: sqlServerName
}
resource sqlAdministrator 'Microsoft.Sql/servers/administrators@2023-08-01-preview' = {
  parent: sqlServer
  name: 'ActiveDirectory'
  properties: {
    administratorType: 'ActiveDirectory'
    login: sqlEntraAdminName
    sid: sqlEntraAdminObjectId
    tenantId: entraTenantId
  }
}
resource sqlEntraOnlyAuthentication 'Microsoft.Sql/servers/azureADOnlyAuthentications@2023-08-01-preview' = {
  parent: sqlServer
  name: 'Default'
  properties: {
    azureADOnlyAuthentication: true
  }
  dependsOn: [sqlAdministrator]
}
resource sqlDatabase 'Microsoft.Sql/servers/databases@2023-08-01-preview' existing = {
  parent: sqlServer
  name: sqlDatabaseName
}
resource sqlAudit 'Microsoft.Sql/servers/auditingSettings@2023-08-01-preview' = {
  parent: sqlServer
  name: 'default'
  properties: {
    state: 'Enabled'
    isAzureMonitorTargetEnabled: true
    retentionDays: 30
  }
}
resource sqlDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: sqlDatabase
  name: 'send-to-log-analytics'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        categoryGroup: 'audit'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'Basic'
        enabled: true
      }
    ]
  }
}

output sqlServerId string = sqlServer.id
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
output sqlDatabaseId string = sqlDatabase.id
output sqlDatabaseName string = sqlDatabase.name
output keyVaultId string = vault.id
output keyVaultUri string = vault.properties.vaultUri
output storageAccountId string = storage.id
output storageAccountUri string = 'https://${storage.name}.blob.${environment().suffixes.storage}'
output storageMalwareScanResultsDiagnosticId string = storageMalwareScanResultsDiagnostics.id
