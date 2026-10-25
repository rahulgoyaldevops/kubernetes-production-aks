<div align="center">

# ☸️ Production-Grade AKS — Kubernetes on Azure

[![Kubernetes](https://img.shields.io/badge/Kubernetes-AKS-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)](https://azure.microsoft.com/en-us/products/kubernetes-service)
[![Terraform](https://img.shields.io/badge/Terraform-Provisioning-623CE4?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![ArgoCD](https://img.shields.io/badge/ArgoCD-GitOps-EF7B4D?style=for-the-badge&logo=argo&logoColor=white)](https://argo-cd.readthedocs.io/)
[![Prometheus](https://img.shields.io/badge/Prometheus-Monitoring-E6522C?style=for-the-badge&logo=prometheus&logoColor=white)](https://prometheus.io/)

**Production-ready AKS cluster deployment with Terraform — including monitoring, RBAC, network policies, GitOps, and day-2 operations.**

*Not a tutorial cluster. This is how production actually runs.*

</div>

---

## 🎯 Design Principles

> Running Kubernetes in production is not about `kubectl apply`. It's about:
> - **Security by default** — RBAC, network policies, pod security standards
> - **Observability** — know what's happening before users tell you
> - **GitOps** — the cluster state matches the git state, always
> - **Cost efficiency** — right-sized nodes, autoscaling, spot instances

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    AZURE KUBERNETES SERVICE                      │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    AKS Cluster                            │   │
│  │                                                           │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │   │
│  │  │ System Pool  │  │  User Pool  │  │  Spot Pool   │     │   │
│  │  │ (3 nodes)    │  │  (2-10)     │  │  (0-5)       │     │   │
│  │  │              │  │             │  │              │      │   │
│  │  │ CoreDNS      │  │ App Pods    │  │ Batch Jobs   │     │   │
│  │  │ kube-proxy   │  │ Services    │  │ Dev/Test     │     │   │
│  │  │ Monitoring   │  │             │  │              │      │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘      │   │
│  │                                                           │   │
│  │  ┌──────────────────────────────────────────────────┐    │   │
│  │  │              Ingress Controller                   │    │   │
│  │  │         (NGINX / Azure App Gateway)               │    │   │
│  │  └──────────────────────────────────────────────────┘    │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │ Azure CNI    │  │ Key Vault    │  │ Container    │           │
│  │ Networking   │  │ CSI Driver   │  │ Registry     │           │
│  └──────────────┘  └──────────────┘  └──────────────┘           │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              Monitoring Stack                             │   │
│  │  Prometheus → Grafana → AlertManager → PagerDuty/Teams   │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              GitOps — ArgoCD                              │   │
│  │  Git Repo ──▶ ArgoCD ──▶ Kubernetes ──▶ Auto-Sync        │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## 📁 Repository Structure

```
kubernetes-production-aks/
│
├── terraform/                            # AKS Infrastructure
│   ├── main.tf                           # AKS cluster + node pools
│   ├── networking.tf                     # VNet, Subnet, NSG for AKS
│   ├── acr.tf                            # Azure Container Registry
│   ├── monitoring.tf                     # Log Analytics workspace
│   ├── keyvault.tf                       # Key Vault + CSI integration
│   ├── variables.tf                      # Input variables
│   ├── outputs.tf                        # Cluster outputs
│   ├── providers.tf                      # Provider configuration
│   └── environments/
│       ├── dev.tfvars
│       ├── uat.tfvars
│       └── prod.tfvars
│
├── kubernetes/                           # K8s Manifests
│   ├── namespaces/                       # Namespace definitions + quotas
│   ├── rbac/                             # Role, RoleBinding, ClusterRole
│   ├── network-policies/                 # Pod-to-pod traffic rules
│   ├── ingress/                          # Ingress controller config
│   ├── monitoring/                       # Prometheus + Grafana stack
│   └── sample-app/                       # Example deployment
│
├── argocd/                               # GitOps Configuration
│   ├── install/                          # ArgoCD installation
│   ├── applications/                     # ArgoCD Application CRDs
│   └── projects/                         # ArgoCD Projects
│
├── helm-charts/                          # Custom Helm Charts
│   └── base-app/                         # Base application chart
│
├── docs/
│   ├── AKS_BEST_PRACTICES.md
│   ├── TROUBLESHOOTING.md
│   └── SCALING_GUIDE.md
│
└── README.md
```

## 🔐 Security Configuration

| Feature | Implementation |
|:--|:--|
| **RBAC** | Azure AD integrated, namespace-level roles |
| **Network Policies** | Calico/Azure NPM — deny-all default, explicit allow |
| **Pod Security** | Restricted pod security standards enforced |
| **Secrets** | Azure Key Vault CSI driver — no K8s secrets |
| **Image Security** | ACR with vulnerability scanning, no public images |
| **API Server** | Private cluster option, authorized IP ranges |
| **Node Security** | Automatic OS patches, ephemeral disks |
| **Audit Logging** | Full API server audit logs to Log Analytics |

## 📊 Monitoring Stack

```
  Application Metrics          Infrastructure Metrics
        │                              │
        ▼                              ▼
  ┌──────────┐                  ┌──────────────┐
  │ App Pods  │                 │  Node Exporter │
  │ /metrics  │                 │  cAdvisor      │
  └─────┬────┘                  └──────┬─────────┘
        │                              │
        └──────────┬───────────────────┘
                   ▼
          ┌──────────────┐
          │  Prometheus   │
          │  (scrape)     │
          └──────┬───────┘
                 │
        ┌────────┴────────┐
        ▼                 ▼
  ┌──────────┐    ┌──────────────┐
  │ Grafana   │    │ AlertManager │
  │ Dashboards│    │ → Teams      │
  │           │    │ → PagerDuty  │
  └──────────┘    └──────────────┘
```

## ⚡ Key Terraform Configuration

```hcl
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-${var.environment}-${var.project}"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  dns_prefix          = "aks-${var.environment}"
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name                = "system"
    vm_size             = "Standard_D4s_v5"
    min_count           = 3
    max_count           = 5
    enable_auto_scaling = true
    os_disk_type        = "Ephemeral"
    zones               = [1, 2, 3]
    
    node_labels = {
      "nodepool-type" = "system"
      "environment"   = var.environment
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "calico"
    load_balancer_sku = "standard"
    service_cidr      = "10.0.0.0/16"
    dns_service_ip    = "10.0.0.10"
  }

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled = true
    tenant_id          = var.tenant_id
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.aks.id
  }

  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "5m"
  }

  tags = var.common_tags
}
```

## 🚀 Quick Start

```bash
# 1. Deploy AKS cluster
cd terraform
terraform init
terraform plan -var-file="environments/dev.tfvars"
terraform apply -var-file="environments/dev.tfvars"

# 2. Get credentials
az aks get-credentials --resource-group rg-aks-dev --name aks-dev-project

# 3. Deploy monitoring
kubectl apply -f kubernetes/monitoring/

# 4. Install ArgoCD
kubectl apply -f argocd/install/

# 5. Deploy sample app
kubectl apply -f kubernetes/sample-app/
```

## 📋 Day-2 Operations Checklist

- [ ] Node pool scaling policies reviewed monthly
- [ ] Kubernetes version upgrade plan (stay within N-2)
- [ ] Certificate rotation automated
- [ ] RBAC audit quarterly
- [ ] Network policy review
- [ ] Cost analysis — node utilization > 70%
- [ ] Backup strategy for persistent volumes
- [ ] DR runbook tested quarterly

---

<div align="center">

**Built by [Rahul Goyal](https://github.com/rahulgoyaldevops)** — Senior DevOps & Cloud Engineer | 14+ Years

*"A Kubernetes cluster without monitoring is just a ticking time bomb."*

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Rahul_Goyal-0A66C2?style=flat-square&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/rahulgoyaldevops/)

</div>