var workflowSchema = 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'

resource storage_example 'Microsoft.Storage/storageAccounts@2020-08-01-preview' = {
  name: 'storexampleweeu001'
  location: resourceGroup().location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
  properties: {
    supportsHttpsTrafficOnly: true
    isHnsEnabled: true
    minimumTlsVersion: 'TLS1_2'
    accessTier: 'Hot'
  }
}

resource storage_blob_container 'Microsoft.Storage/storageAccounts/blobServices/containers@2020-08-01-preview' = {
  name: '${storage_example.name}/default/logicappstore'
}

resource logic_app_blob_connection 'Microsoft.Web/connections@2016-06-01' = {
  name: 'api-example-weeu-001'
  location: resourceGroup().location
  properties: {
    displayName: 'api-example-weeu-001'
    parameterValues: {
      accountName: storage_example.name
      accessKey: listKeys(storage_example.id, '2019-06-01').keys[0].value
    }
    api: {
      id: concat('/subscriptions/', subscription().subscriptionId, '/providers/Microsoft.Web/locations/', resourceGroup().location, '/managedApis/azureblob')
    }
  }
}

resource logic_app_example 'Microsoft.Logic/workflows@2019-05-01' = {
  name: 'logic-example-weeu-001'
  location: resourceGroup().location
  properties: {
    definition: {
      '$schema': workflowSchema
      triggers: {
        'http_request': {
          type: 'request'
          kind: 'http'
          inputs: {
            schema: {
              '$schema': 'http://json-schema.org/draft-04/schema#'
              type: 'object'
              properties: {
                hello: {
                  type: 'string'
                }
              }
              required: [
                'hello'
              ]
            }
          }
          operationOptions: 'EnableSchemaValidation'
        }
      }
      actions: {
        'HTTP_Response': {
          type: 'Response'
          inputs: {
            body: 'Hello @{triggerBody()?[\'hello\']}'
            headers: {
              'Content-Type': 'text/plain'
            }
            statusCode: 200
          }
          runAfter: {
            'Create_Blob': [
              'Succeeded'
            ]
          }
        }
        'Create_Blob': {
          inputs: {
            body: 'Hello @{triggerBody()[\'hello\']}'
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
          azureblob: {
            connectionId: logic_app_blob_connection.id
            connectionName: logic_app_blob_connection.name
            id: concat('/subscriptions/', subscription().subscriptionId, '/providers/Microsoft.Web/locations/', resourceGroup().location, '/managedApis/azureblob')
          }
        }
      }
    }
  }
}

output url string = listCallbackURL(concat(logic_app_example.id, '/triggers/http_request'), '2016-06-01').value