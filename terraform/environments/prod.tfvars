# ============================================================================
# AKS Production Environment Deployment Parameters
# ============================================================================

environment         = "prod"
workload_name       = "enterprise-core"
location            = "Central India"
kubernetes_version  = "1.30"
system_vm_size      = "Standard_D4s_v5"
user_vm_size        = "Standard_D8s_v5"

common_tags = {
  Environment       = "Production"
  ManagedBy         = "Terraform"
  TechnicalOwner    = "Rahul Goyal (Senior DevOps Engineer)"
  CostCenter        = "Core-Platform-Prod"
  DataSensitivity   = "Confidential"
  ComplianceScope   = "PCI-DSS-v4.0"
}