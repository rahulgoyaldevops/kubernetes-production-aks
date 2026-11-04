# Enterprise Cross-Region BCDR Architecture & Runbook
**Target Tier:** Enterprise Tier-1 Workloads (19 Applications)  
**Primary Region:** Central India (Pune)  
**Secondary Region:** South India (Chennai) — Paired Region  
**Service Level Objectives:** **RTO < 30 minutes** | **RPO < 5 minutes**  
**Author:** Rahul Goyal (Senior Azure DevOps Engineer)

---

## 1. Executive Summary & Topology

This runbook establishes the automated multi-region Business Continuity and Disaster Recovery (BCDR) strategy for enterprise platforms running on Azure Kubernetes Service (AKS) and Azure Landing Zones.

```
                   ┌───────────────────────────────────────┐
                   │    Azure Front Door (Global Anycast)   │
                   │  Health Probes (Path: /healthz, 10s)  │
                   └──────────────────┬────────────────────┘
                                      │
            ┌─────────────────────────┴─────────────────────────┐
            │ Active Route (Priority 1)                         │ Standby Route (Priority 2)
            ▼                                                   ▼
┌───────────────────────────────────────┐   Geo-Replication   ┌───────────────────────────────────────┐
│ Primary Region: Central India (inc)   │ ◄─────────────────► │ Secondary Region: South India (ins)   │
│ • AKS Multi-Zone Cluster (Zones 1,2,3)│   (ACR Premium)     │ • AKS Pilot-Light Cluster (Standby)   │
│ • Private DNS & Hub-Spoke VNet        │                     │ • Hot-Standby Private DNS Resolver    │
│ • Internal App Gateway + WAF v2       │                     │ • Internal App Gateway + WAF v2       │
│ • Azure SQL / Cosmos DB (Geo-Primary) │ ── Geo-Replication ─►│ • Azure SQL / Cosmos DB (Read Replica)│
│ • Velero Daily State Backup           │   (Failover Group)  │ • Velero Scheduled State Restore      │
└───────────────────────────────────────┘                     └───────────────────────────────────────┘
```

---

## 2. Recovery Objectives

| Metric | Target | Measurement Mechanism |
| :--- | :--- | :--- |
| **RPO (Recovery Point Objective)** | **< 5 minutes** | Azure SQL Auto-Failover Group replication lag & Velero snapshot sync |
| **RTO (Recovery Time Objective)** | **< 30 minutes** | Front Door health probe failure detection (60s) + AKS node pool autoscale (5m) + App state ready (15m) |
| **Cluster Ingress Cutover** | **Zero DNS propagation delay** | Azure Front Door Anycast VIP dynamic backend failover |
| **Data Consistency** | **Transactional Consistency** | Azure SQL Geo-Secondary failover with forced data sync |

---

## 3. Pre-Requisite Replication Architecture

1. **Container Images (ACR):**
   - Azure Container Registry (`acrprodinc001`) configured with Premium SKU and active geo-replication to `South India`.
   - Pods pull from single FQDN `acrprodinc001.azurecr.io` which auto-resolves to the nearest region.

2. **Database & Persistent State:**
   - Azure SQL Database / PostgreSQL Flexible Server configured in an **Auto-Failover Group** with Central India as Primary and South India as Secondary.
   - Read-Write listener endpoint remains invariant across failover (`db-prod.database.windows.net`).

3. **Kubernetes Cluster State (GitOps & Velero):**
   - ArgoCD root application synchronized from Git (`github.com/rahulgoyaldevops/kubernetes-production-aks`).
   - Cluster configuration is 100% declarative in Git.
   - Velero backups scheduled every 2 hours to geo-redundant Azure Storage Blob container (GRS).

---

## 4. Disaster Declaration & Triage Protocol

A disaster condition is declared when any of the following triggers occur:
1. Complete Azure Central India regional outage confirmed by Microsoft Azure Status Health Dashboard.
2. Ingress failure exceeding 15 minutes across all 3 Availability Zones in Central India.
3. Critical corruption or disruption of core storage/network infrastructure in primary region.

**Triage Escalation:**
- Incident Commander: Senior DevOps Engineer / Platform Architect
- Cloud Operations: DevOps Engineering On-Call
- Communication: Enterprise Incident Management Bridge

---

## 5. Failover Execution Workflow

### Step 1: Automated Traffic Diversion Verification (0 - 2 mins)
Azure Front Door health probe monitors `https://app.enterprise.domain/healthz`.
- If 3 consecutive probes fail (30 seconds), Front Door automatically reroutes 100% of global ingress traffic to South India backend pool.
- Verify status via Azure CLI:
```bash
az network front-door backend-pool list \
  --front-door-name fd-enterprise-prod \
  --resource-group rg-core-platform-prod-inc-01 \
  --query "[].backends[].enabled"
```

### Step 2: Database Failover Execution (2 - 7 mins)
Initiate planned or forced failover of Azure SQL Auto-Failover Group:
```bash
az sql failover-group set-primary \
  --name fog-core-platform-prod \
  --resource-group rg-core-platform-prod-inc-01 \
  --server sql-core-platform-prod-ins-01
```

### Step 3: Secondary AKS Cluster Scaling (7 - 15 mins)
Scale South India pilot-light node pool to production workload capacity:
```bash
az aks nodepool scale \
  --resource-group rg-core-platform-prod-ins-01 \
  --cluster-name aks-prod-southindia-01 \
  --name workernp01 \
  --node-count 6
```

### Step 4: GitOps & Workload Reconciliation (15 - 22 mins)
Trigger ArgoCD hard-refresh to synchronize all applications to the South India cluster:
```bash
argocd app sync platform-root-app-of-apps --prune --force
```

### Step 5: Verification & Health Checks (22 - 30 mins)
1. Verify pod distribution and readiness:
```bash
kubectl get pods -n core-apps -o wide
kubectl get ingress -n core-apps
```
2. Validate end-to-end synthetic transaction through Azure Front Door:
```bash
curl -svI https://app.enterprise.domain/healthz
```

---

## 6. Failback Protocol (Return to Central India)

Once Azure Central India region health is fully restored and certified stable for > 4 hours:
1. Verify database synchronization from South India (now primary) back to Central India (now secondary).
2. Schedule a planned 15-minute maintenance window.
3. Initiate graceful failover of SQL Failover Group back to Central India.
4. Scale up Central India AKS cluster node pool.
5. In Azure Front Door, update backend pool weight back to Primary: 100, Secondary: 0.
6. Scale down South India AKS node pool back to pilot-light baseline (2 nodes).
