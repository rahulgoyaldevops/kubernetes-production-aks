# ============================================================================
# Production Enterprise Azure Kubernetes Service (AKS) Architecture
# Designed & Implemented by: Rahul Goyal (14+ Years Total IT | Senior DevOps Engineer)
# ============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "aks_rg" {
  name     = "rg-aks-${var.environment}-${var.workload_name}"
  location = var.location
  tags     = var.common_tags
}

# Centralized Log Analytics for Kubernetes Container Insights & Observability
resource "azurerm_log_analytics_workspace" "aks_logs" {
  name                = "log-aks-${var.environment}-${var.workload_name}"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.common_tags
}

# Production AKS Cluster with Multi-Zone Resiliency, Calico CNI & Workload Identity
resource "azurerm_kubernetes_cluster" "aks" {
  name                      = "aks-${var.environment}-${var.workload_name}"
  location                  = azurerm_resource_group.aks_rg.location
  resource_group_name       = azurerm_resource_group.aks_rg.name
  dns_prefix                = "aks-${var.environment}-${var.workload_name}"
  kubernetes_version        = var.kubernetes_version
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  default_node_pool {
    name                 = "systempool"
    vm_size              = var.system_vm_size
    min_count            = 3
    max_count            = 5
    auto_scaling_enabled = true
    os_disk_type         = "Ephemeral"
    zones                = [1, 2, 3]
    vnet_subnet_id       = azurerm_subnet.aks_nodes_snet.id

    node_labels = {
      "role"        = "system"
      "environment" = var.environment
    }
  }

  identity {
    type = "SystemAssigned"
  }

  # Azure CNI + Calico for fine-grained zero-trust microsegmentation
  network_profile {
    network_plugin    = "azure"
    network_policy    = "calico"
    load_balancer_sku = "standard"
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.aks_logs.id
  }

  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "3m"
  }

  tags = var.common_tags
}

# Dedicated User Workload Node Pool (Isolated from System Critical Services)
resource "azurerm_kubernetes_cluster_node_pool" "user_workloads" {
  name                  = "userpool"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = var.user_vm_size
  min_count             = 2
  max_count             = 12
  auto_scaling_enabled  = true
  os_disk_type          = "Ephemeral"
  zones                 = [1, 2, 3]
  vnet_subnet_id        = azurerm_subnet.aks_nodes_snet.id

  node_labels = {
    "tier"        = "backend-apps"
    "environment" = var.environment
  }

  tags = var.common_tags
}
