# ============================================================================
# Azure Container Registry (ACR) with Private Link & AKS Integration
# ============================================================================

resource "azurerm_container_registry" "acr" {
  name                = "acrenterprisecoreprod01"
  resource_group_name = azurerm_resource_group.aks_rg.name
  location            = azurerm_resource_group.aks_rg.location
  sku                 = "Premium"
  admin_enabled       = false

  georeplications {
    location                = "South India"
    zone_redundancy_enabled = true
    tags                    = var.common_tags
  }

  tags = var.common_tags
}

# Native RBAC AcrPull Binding (Managed Identity to ACR)
resource "azurerm_role_assignment" "aks_to_acr" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}