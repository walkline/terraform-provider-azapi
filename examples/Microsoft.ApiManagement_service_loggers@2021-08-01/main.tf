terraform {
  required_providers {
    azapi = {
      source = "Azure/azapi"
    }
  }
}

provider "azapi" {
  skip_provider_registration = false
}

variable "resource_name" {
  type    = string
  default = "acctest0001"
}

variable "location" {
  type    = string
  default = "westeurope"
}

resource "azapi_resource" "resourceGroup" {
  type                      = "Microsoft.Resources/resourceGroups@2020-06-01"
  name                      = var.resource_name
  location                  = var.location
}

resource "azapi_resource" "component" {
  type      = "Microsoft.Insights/components@2020-02-02"
  parent_id = azapi_resource.resourceGroup.id
  name      = var.resource_name
  location  = var.location
  body = jsonencode({
    kind = "web"
    properties = {
      Application_Type                = "web"
      DisableIpMasking                = false
      DisableLocalAuth                = false
      ForceCustomerStorageForProfiler = false
      RetentionInDays                 = 90
      SamplingPercentage              = 100
      publicNetworkAccessForIngestion = "Enabled"
      publicNetworkAccessForQuery     = "Enabled"
    }
  })
  schema_validation_enabled = false
  response_export_values    = ["*"]
}

resource "azapi_resource" "service" {
  type      = "Microsoft.ApiManagement/service@2021-08-01"
  parent_id = azapi_resource.resourceGroup.id
  name      = var.resource_name
  location  = var.location
  body = jsonencode({
    properties = {
      certificates = [
      ]
      customProperties = {
        "Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Ssl30" = "false"
        "Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls10" = "false"
        "Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls11" = "false"
        "Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls10"         = "false"
        "Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls11"         = "false"
      }
      disableGateway      = false
      publicNetworkAccess = "Enabled"
      publisherEmail      = "pub1@email.com"
      publisherName       = "pub1"
      virtualNetworkType  = "None"
    }
    sku = {
      capacity = 0
      name     = "Consumption"
    }
  })
  schema_validation_enabled = false
  response_export_values    = ["*"]
}

resource "azapi_resource" "logger" {
  type      = "Microsoft.ApiManagement/service/loggers@2021-08-01"
  parent_id = azapi_resource.service.id
  name      = var.resource_name
  body = jsonencode({
    properties = {
      credentials = {
        instrumentationKey = jsondecode(azapi_resource.component.output).properties.InstrumentationKey
      }
      description = ""
      isBuffered  = true
      loggerType  = "applicationInsights"
    }
  })
  schema_validation_enabled = false
  response_export_values    = ["*"]
  ignore_body_changes            = ["properties.credentials.instrumentationKey"]
}

