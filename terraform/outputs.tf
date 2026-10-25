# ============================================================================
# AKS Cluster Production Outputs
# ============================================================================

output "aks_cluster_name" {
  description = "The Name of the Azure Kubernetes Service Cluster"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "aks_cluster_id" {
  description = "The Resource ID of the AKS Cluster"
  value       = azurerm_kubernetes_cluster.aks.id
}

output "aks_oidc_issuer_url" {
  description = "The OIDC issuer URL for Workload Identity Federation"
  value       = azurerm_kubernetes_cluster.aks.oidc_issuer_url
}

output "kubelet_identity_object_id" {
  description = "Kubelet Managed Identity Object ID for Azure RBAC role assignments"
  value       = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

output "acr_login_server" {
  description = "The URL endpoint used for logging into Azure Container Registry"
  value       = azurerm_container_registry.acr.login_server
}