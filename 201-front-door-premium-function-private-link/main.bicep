param location string {
  allowed:[
    'eastus'
    'westus2'
    'southcentralus'
  ]
  default: 'eastus'
  metadata: {
    description: 'The location into which regionally scoped resources should be deployed. Note that Front Door is a global resource. When using Private Link origins with Front Door Premium during the preview period, there is a limited set of regions available for use. See https://docs.microsoft.com/en-us/azure/frontdoor/standard-premium/concept-private-link#limitations for more details.'
  }
}
param appName string {
  default: 'fn-${uniqueString(resourceGroup().id)}'
  metadata: {
    description: 'The name of the Azure Functins application to create. This must be globally unique.'
  }
}
param functionAppServicePlanSkuName string {
  default: 'EP1'
  metadata: {
    description: 'The SKU name to use for Azure Functions. This must be a SKU that is compatible with private endpoints, i.e. EP1 or better.'
  }
}
param frontDoorEndpointName string {
  default: 'afd-${uniqueString(resourceGroup().id)}'
  metadata: {
    description: 'The name of the Front Door endpoint to create. This must be globally unique.'
  }
}

var frontDoorSkuName = 'Premium_AzureFrontDoor' // Private Link origins require the premium SKU.

module functionApp 'modules/function.bicep' = {
  name: 'function'
  params: {
    location: location
    appName: appName
    functionPlanSkuName: functionAppServicePlanSkuName
  }
}

module frontDoor 'modules/front-door.bicep' = {
  name: 'front-door'
  params: {
    skuName: frontDoorSkuName
    endpointName: frontDoorEndpointName
    originHostName: functionApp.outputs.functionAppHostName
    privateEndpointResourceId: functionApp.outputs.functionAppResourceId
    privateLinkResourceType: 'sites' // For App Service and Azure Functions, this needs to be 'sites'.
    privateEndpointLocation: location
  }
}

output frontDoorEndpointFunctionUrl string = 'https://${frontDoor.outputs.frontDoorEndpointHostName}/api/${functionApp.outputs.functionName}'
output functionAppFunctionUrl string = 'https://${functionApp.outputs.functionAppHostName}/api/${functionApp.outputs.functionName}'
