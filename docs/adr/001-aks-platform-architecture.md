# ADR-001: Production AKS Platform Architecture

- **Status:** Accepted
- **Date:** 2026-11-19
- **Owner:** Platform Engineering (`rahulgoyaldevops`)

## Context

We are designing a production-grade Azure Kubernetes Service (AKS) platform that balances high availability, strict enterprise security, IP address efficiency, cost optimization, and declarative multi-tenant GitOps delivery.

## Architectural Decisions

### 1. Three-Tier Node Pool Strategy (System, User, Spot)
- **Decision:** Partition cluster compute into three dedicated node pools:
  1. **System Pool:** Dedicated to critical cluster add-ons (`coredns`, `metrics-server`, `calico-node`, `argocd`) with `CriticalAddonsOnly=true:NoSchedule` taint to prevent application workloads from starving control-plane components.
  2. **User Pool:** General-purpose on-demand nodes for stateful, latency-sensitive, or SLA-bound production workloads.
  3. **Spot Pool:** Azure Spot VMs with `kubernetes.azure.com/scalesetpriority=spot:NoSchedule` taint for fault-tolerant, stateless batch jobs, CI runners, and burst workloads.
- **Trade-offs:** Slightly higher operational complexity in workload scheduling (`tolerations` and `nodeAffinity`), offset by strong blast-radius isolation and 60-80% compute savings on Spot-eligible workloads.

### 2. Networking: Azure CNI Overlay vs. Kubenet
- **Decision:** Adopt **Azure CNI Overlay** as the cluster CNI plugin.
- **Trade-offs:**
  - **Azure CNI Overlay:** Assigns pod IPs from a private overlay CIDR (`10.244.0.0/16`) decoupled from the Azure VNet subnet, avoiding VNet IP exhaustion at scale while retaining high-throughput VXLAN/overlay routing and native Azure integration without user-defined route (UDR) table limits.
  - **Kubenet (Rejected):** Simpler IP conservation, but constrained by Azure route table limits (400 routes per table), extra hop NAT overhead, and lack of native Azure CNI feature parity.
  - **Traditional Azure CNI (Rejected):** Consumes a VNet IP per pod, leading to rapid subnet exhaustion in large multi-tenant clusters.

### 3. Identity & Access Control: Microsoft Entra ID RBAC
- **Decision:** Enforce **Microsoft Entra ID (formerly Azure AD) integration with Kubernetes RBAC** and Azure RBAC for Kubernetes Authorization, disabling local cluster admin accounts in production.
- **Trade-offs:** Requires Entra ID group governance and conditional access alignment, but eliminates static `kubeconfig` credential sprawl, enables just-in-time (JIT) privileged access via PIM, and provides centralized auditability.

### 4. Network Segmentation: Calico Default-Deny Network Policies
- **Decision:** Deploy **Calico** as the network policy engine and enforce a baseline **default-deny ingress/egress** `NetworkPolicy` per tenant namespace, with explicit allow-list rules for DNS (`kube-dns`), ingress controllers, and approved service-to-service paths.
- **Trade-offs:** Increases initial onboarding friction for new services (requiring explicit egress/ingress manifests), but enforces zero-trust lateral movement protection across namespaces.

### 5. Continuous Delivery: ArgoCD App-of-Apps GitOps
- **Decision:** Standardize cluster add-ons and tenant onboarding on **ArgoCD using the App-of-Apps pattern** with automated sync, self-heal, and prune policies.
- **Trade-offs:** Introduces a centralized GitOps controller dependency, mitigated by HA ArgoCD deployment and read-only RBAC boundaries, while guaranteeing declarative drift detection, instant rollbacks, and auditable Git-backed deployments.

## Consequences
- All tenant namespaces must define explicit Calico `NetworkPolicy` rules and appropriate node pool `tolerations` for Spot workloads.
- Infrastructure changes flow through Terraform CI validation before ArgoCD reconciles cluster state.
