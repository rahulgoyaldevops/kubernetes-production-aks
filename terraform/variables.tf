variable "environment" {
  type        = string
  description = "Environment identifier (dev, uat, prod)"
  default     = "prod"
}

variable "workload_name" {
  type        = string
  description = "Name of platform or workload"
  default     = "enterprise-core"
}

variable "location" {
  type        = string
  description = "Azure region"
  default     = "Central India"
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version release"
  default     = "1.30"
}

variable "system_vm_size" {
  type        = string
  default     = "Standard_D4s_v5"
}

variable "user_vm_size" {
  type        = string
  default     = "Standard_D8s_v5"
}

variable "common_tags" {
  type        = map(string)
  default = {
    ManagedBy   = "Terraform"
    EngineeringLead = "Rahul Goyal"
    CostCenter  = "CoreInfra"
    Tier        = "Tier-1 Production"
  }
}