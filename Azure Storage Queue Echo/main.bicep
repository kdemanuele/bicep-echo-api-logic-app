param resourceLocation string = resourceGroup().location

var workflowSchema = 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
var queueName = 'samplequeue'

resource storage_example 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: 'storesampleweu001'
  location: resourceLocation
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    supportsHttpsTrafficOnly: true
    isHnsEnabled: true
    minimumTlsVersion: 'TLS1_2'
    accessTier: 'Hot'
  }
}

resource storage_queue 'Microsoft.Storage/storageAccounts/queueServices/queues@2021-08-01' = {
  name: '${storage_example.name}/default/${queueName}'
}

resource storage_blob_container 'Microsoft.Storage/storageAccounts/blobServices/containers@2020-08-01-preview' = {
  name: '${storage_example.name}/default/logicappstore'
}

resource logic_app_storage_queue_connection 'Microsoft.Web/connections@2016-06-01' = {
  name: 'api-example-weu-001'
  location: resourceLocation
  properties: {
    displayName: 'api-storage-queue-weu-001'
    parameterValues: {
      storageAccount: storage_example.name
      sharedkey: listKeys(storage_example.id, '2021-08-01').keys[0].value
    }
    api: {
      id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${resourceLocation}/managedApis/azurequeues'
    }
  }
}

resource logic_app_blob_connection 'Microsoft.Web/connections@2016-06-01' = {
  name: 'api-example-weu-002'
  location: resourceLocation
  properties: {
    displayName: 'api-blob-weu-001'
    parameterValues: {
      accountName: storage_example.name
      accessKey: listKeys(storage_example.id, '2021-08-01').keys[0].value
    }
    api: {
      id:  '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${resourceLocation}/managedApis/azureblob'
    }
  }
}

resource logic_app_example 'Microsoft.Logic/workflows@2019-05-01' = {
  name: 'logic-example-weeu-001'
  location: resourceLocation
  properties: {
    definition: {
      '$schema': workflowSchema
      triggers: {
        'When_there_are_messages_in_a_queue_(V2)': {
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'azurequeue\'][\'connectionId\']'
              }
            }
            method: 'get'
            path: '/v2/storageAccounts/@{encodeURIComponent(encodeURIComponent(\'AccountNameFromSettings\'))}/queues/@{encodeURIComponent(\'${queueName}\')}/message_trigger'
          }
          recurrence: {
            frequency: 'Minute'
            interval: 1
          }
          splitOn: '@triggerBody()?[\'QueueMessagesList\']?[\'QueueMessage\']'
        }
      }
      actions: {
        'Create_Blob': {
          inputs: {
            body: 'Message Details: \n@{triggerBody()?[\'MessageText\']}'
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'azureblob\'][\'connectionId\']'
              }
            }
            method: 'post'
            path: '/datasets/default/files'
            queries: {
              folderPath: '/logicappstore'
              name: '@{utcNow()}'
              queryParametersSingleEncoded: true
            }
          }
          runAfter: {}
          runtimeConfiguration: {
            contentTransfer: {
              transferMode: 'Chunked'
            }
          }
          type: 'ApiConnection'
        }
      }
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
    }
    parameters: {
      '$connections': {
        value: {
          azurequeue: {
            connectionId: logic_app_storage_queue_connection.id
            connectionName: logic_app_storage_queue_connection.name
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${resourceLocation}/managedApis/azurequeues'
          }
          azureblob: {
            connectionId: logic_app_blob_connection.id
            connectionName: logic_app_blob_connection.name
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${resourceLocation}/managedApis/azureblob'
          }
        }
      }
    }
  }
}
