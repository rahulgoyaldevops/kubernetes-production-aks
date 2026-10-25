# ============================================================================
# AKS Dedicated Virtual Network & Microsegmentation
# ============================================================================

resource "azurerm_virtual_network" "aks_vnet" {
  name                = "vnet-aks-${var.environment}-inc"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  address_space       = ["10.240.0.0/16"]

  tags = var.common_tags
}

resource "azurerm_subnet" "aks_nodes_snet" {
  name                 = "snet-aks-nodes-01"
  resource_group_name  = azurerm_resource_group.aks_rg.name
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  address_prefixes     = ["10.240.0.0/20"] # Supports up to 4096 IP addresses for nodes & pods (Azure CNI)
}

resource "azurerm_subnet" "aks_ingress_snet" {
  name                 = "snet-aks-ingress-appgw-01"
  resource_group_name  = azurerm_resource_group.aks_rg.name
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  address_prefixes     = ["10.240.16.0/24"]
}