resource "azurerm_resource_group" "main" {
  location = var.azure_location
  name     = "travigo"
}

resource "azurerm_virtual_network" "core" {
  address_space       = ["10.52.0.0/16"]
  location            = var.azure_location
  name                = "app-core"
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "kube" {
  address_prefixes     = ["10.52.0.0/24"]
  name                 = "app-core-kube"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.core.name
}