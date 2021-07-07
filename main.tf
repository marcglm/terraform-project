terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 2.26"
    }
  }
}

resource "random_id" "server" {
  keepers = {
    azi_id = 1
  }

  byte_length = 8
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "projet2021" {
  name     = "oualiken_chatelin_rubayiza_ghalem"
  location = "West Europe"
}

# Create a storage account
resource "azurerm_storage_account" "projet2021" {
  name                     = "sa1809esgial151095"
  resource_group_name      = azurerm_resource_group.projet2021.name
  location                 = azurerm_resource_group.projet2021.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
}


resource "azurerm_traffic_manager_profile" "projet2021" {
  name                = random_id.server.hex
  resource_group_name = azurerm_resource_group.projet2021.name

  traffic_routing_method = "Weighted"

  dns_config {
    relative_name = random_id.server.hex
    ttl           = 100
  }

  monitor_config {
    protocol                     = "http"
    port                         = 80
    path                         = "/"
    interval_in_seconds          = 30
    timeout_in_seconds           = 9
    tolerated_number_of_failures = 3
  }

  tags = {
    environment = "Production"
  }
}


resource "azurerm_traffic_manager_endpoint" "projet2021" {
  name                = random_id.server.hex
  resource_group_name = azurerm_resource_group.projet2021.name
  profile_name        = azurerm_traffic_manager_profile.projet2021.name
  target              = "terraform.io"
  type                = "externalEndpoints"
  weight              = 100
}


resource "azurerm_app_service_plan" "example" {
  name                = "example-appserviceplan"
  location            = azurerm_resource_group.projet2021.location
  resource_group_name = azurerm_resource_group.projet2021.name

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_app_service" "projet2021" {
  name                = "example-app-service"
  location            = azurerm_resource_group.projet2021.location
  resource_group_name = azurerm_resource_group.projet2021.name
  app_service_plan_id = azurerm_app_service_plan.example.id


  connection_string {
    name  = azurerm_mysql_server.projet2021.name
    type  = "SQLServer"
    value = "Server=some-server.projet2021.com;Integrated Security=SSPI"
  }
}

resource "azurerm_mysql_server" "projet2021" {
  name                = "projet2021-mysqlserver"
  location            = azurerm_resource_group.projet2021.location
  resource_group_name = azurerm_resource_group.projet2021.name

  sku_name   = "B_Gen5_2"
  storage_mb = 5120
  version    = "5.7"

  auto_grow_enabled                 = true
  backup_retention_days             = 7
  geo_redundant_backup_enabled      = false
  infrastructure_encryption_enabled = false
  public_network_access_enabled     = true
  ssl_enforcement_enabled           = true
  ssl_minimal_tls_version_enforced  = "TLS1_2"
}

resource "azurerm_storage_table" "projet2021" {
  name                 = random_id.server.hex
  storage_account_name = azurerm_storage_account.projet2021.name
}