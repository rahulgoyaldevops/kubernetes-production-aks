# ☸️ Enterprise AKS Day-2 Operations Runbook

> **Author:** Rahul Goyal — Senior DevOps & Cloud Engineer (14+ Years)

---

## 1. Zero-Downtime Kubernetes Minor Version Upgrade Protocol

```bash
# 1. Inspect supported target version upgrades
az aks get-upgrades --resource-group rg-aks-prod-enterprise-core --name aks-prod-enterprise-core --output table

# 2. Upgrade the Kubernetes Control Plane first (managed by Microsoft)
az aks upgrade \
  --resource-group rg-aks-prod-enterprise-core \
  --name aks-prod-enterprise-core \
  --kubernetes-version 1.30.2 \
  --control-plane-only \
  --yes

# 3. Upgrade Node Pools with surge buffer (zero disruption to active pods)
az aks nodepool upgrade \
  --resource-group rg-aks-prod-enterprise-core \
  --cluster-name aks-prod-enterprise-core \
  --name userpool \
  --kubernetes-version 1.30.2 \
  --max-surge 33%
```

---

## 2. Pod Disruption Budgets (PDB) & High Availability
All production deployments must enforce a PodDisruptionBudget ensuring `minAvailable: 50%` to prevent outages during worker node cordoning and draining.

---
*Created by [Rahul Goyal](https://github.com/rahulgoyaldevops)*