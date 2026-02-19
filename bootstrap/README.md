# EKS Platform Bootstrap

This directory contains scripts to bootstrap your EKS cluster with platform blueprints. **Assumes EKS managed add-ons are already enabled** (ArgoCD, KRO, ACK, Auto Mode).

## Prerequisites

Your EKS cluster should have these **managed add-ons enabled**:

1. **ArgoCD** - GitOps continuous delivery (EKS add-on)
2. **KRO** - Kubernetes Resource Orchestrator (EKS add-on)
3. **ACK Controllers** - AWS Controllers for Kubernetes (EKS add-on)
   - IAM Controller
   - EKS Controller
   - Prometheus Service Controller
4. **Auto Mode** - EKS Auto Mode enabled

If not already enabled, enable them via:
```bash
aws eks create-addon --cluster-name <cluster> --addon-name argo-cd
aws eks create-addon --cluster-name <cluster> --addon-name kro
aws eks create-addon --cluster-name <cluster> --addon-name ack-iam
aws eks create-addon --cluster-name <cluster> --addon-name ack-eks
aws eks create-addon --cluster-name <cluster> --addon-name ack-prometheusservice
```

## Quick Start

```bash
cd bootstrap

# Step 1: Deploy Blueprint Templates
./deploy-blueprints.sh

# Step 2: Deploy ArgoCD App of Apps (GitOps)
```

**Total time**: ~2 minutes

---

## Detailed Steps

### Step 1: Deploy Blueprints

```bash
./deploy-blueprints.sh
```

**What it does:**
1. **Deploys KRO RBAC** - Grants KRO controller permissions to manage custom resources
2. **Restarts KRO controller** - Applies new permissions
3. **Deploys ResourceGraphDefinitions** - All blueprint templates

**Blueprints deployed:**
- `observability-platform`
- `observability-cluster`
- `external-dns-cluster`
- `karpenter-nodepool`
- `team-namespace`
- `eks-platform`

**Verify:**
```bash
kubectl get resourcegraphdefinitions
```

**Time**: ~30 seconds

---

### Step 2: Deploy ArgoCD Apps (GitOps)

```bash
```

**What it does:**
- Prompts for Git repository URL
- Deploys ArgoCD App of Apps
- Sets up GitOps automation

**Two modes:**
1. **GitOps Mode** (recommended): ArgoCD automatically syncs from Git
2. **Manual Mode**: You deploy manually with kubectl

**GitOps workflow:**
```
Git Commit → ArgoCD Detects → Auto Deploy → Kubernetes
```

**Time**: ~30 seconds

---

## After Bootstrap

### Verify Everything is Running

```bash
# Check ArgoCD
kubectl get pods -n argocd

# Check KRO
kubectl get pods -n kro-system

# Check ACK
kubectl get pods -n ack-system

# Check Blueprints
kubectl get resourcegraphdefinitions

# Check ArgoCD Applications
kubectl get applications -n argocd
```

---

## What's Next?

### Option 1: GitOps Workflow (Recommended)

**Platform is now GitOps-enabled!**

```bash
# 1. Customize platform config
vim ../platform/examples/production-platform.yaml

# 2. Commit to Git
git add ../platform/examples/production-platform.yaml
git commit -m "Configure production platform"
git push

# 3. ArgoCD automatically deploys (within 3 minutes)
kubectl get eksplatform -w
```

### Option 2: Manual Deployment

```bash
# Deploy platform manually
kubectl apply -f ../platform/examples/production-platform.yaml

# Deploy teams manually
kubectl apply -f ../team-onboarding/examples/teams/backend-team.yaml
```

---

## Troubleshooting

### Verify EKS Managed Add-ons

```bash
# Check ArgoCD add-on
aws eks describe-addon --cluster-name <cluster-name> --addon-name argo-cd

# Check KRO add-on
aws eks describe-addon --cluster-name <cluster-name> --addon-name kro

# Check ACK add-ons
aws eks describe-addon --cluster-name <cluster-name> --addon-name ack-iam
aws eks describe-addon --cluster-name <cluster-name> --addon-name ack-eks
aws eks describe-addon --cluster-name <cluster-name> --addon-name ack-prometheusservice

# Check pods
kubectl get pods -n argocd
kubectl get pods -n kro-system
kubectl get pods -n ack-system
```

### Blueprints Not Deploying

```bash
# Check ResourceGraphDefinitions
kubectl get resourcegraphdefinitions

# Check KRO controller logs
kubectl logs -n kro-system -l control-plane=controller-manager

# Redeploy
./deploy-blueprints.sh
```

---

## Deploy Specific Blueprints Only

If you want to deploy only certain blueprints:

```bash
# Deploy only observability
kubectl apply -f ../observability/kro-resourcegroups/observability-platform.yaml
kubectl apply -f ../observability/kro-resourcegroups/observability-cluster.yaml

# Deploy only ExternalDNS
kubectl apply -f ../external-dns/kro-resourcegroups/external-dns-cluster.yaml

# Deploy only Karpenter
kubectl apply -f ../karpenter-config/kro-resourcegroups/karpenter-nodepool.yaml

# Deploy only Team Onboarding
kubectl apply -f ../team-onboarding/kro-resourcegroups/team-namespace.yaml
```

---

## Cleanup

To remove platform resources:

```bash
# Remove ArgoCD applications
kubectl delete application --all -n argocd

# Remove platform instances
kubectl delete eksplatform --all

# Remove team instances
kubectl delete teamnamespace --all

# Remove blueprints (templates)
kubectl delete resourcegraphdefinitions --all

# Note: EKS managed add-ons (ArgoCD, KRO, ACK) should be removed via AWS console or CLI:
# aws eks delete-addon --cluster-name <cluster-name> --addon-name argo-cd
# aws eks delete-addon --cluster-name <cluster-name> --addon-name kro
# aws eks delete-addon --cluster-name <cluster-name> --addon-name ack-iam
```

---

## Architecture

```
EKS Cluster (with managed add-ons)
    │
    ├─→ ArgoCD (EKS managed add-on)
    ├─→ KRO (EKS managed add-on)
    ├─→ ACK Controllers (EKS managed add-ons)
    │   ├── IAM Controller
    │   ├── EKS Controller
    │   └── Prometheus Controller
    │
Bootstrap Process
    │
    ├─→ Step 1: Deploy Blueprints (Templates)
    │   ├── Platform
    │   ├── Observability
    │   ├── ExternalDNS
    │   ├── Karpenter
    │   └── Team Onboarding
    │
    └─→ Step 2: Deploy ArgoCD Apps (GitOps automation)
        └── App of Apps pattern

Result: GitOps-enabled platform with reusable blueprints
```

---

## Time Breakdown

| Step | Component | Time |
|------|-----------|------|
| Prerequisites | EKS managed add-ons enabled | (Already done) |
| 1 | Blueprints deployment | 30 sec |
| 2 | ArgoCD apps | 30 sec |
| **Total** | **Complete bootstrap** | **~1 minute** |

---

## Related Resources

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [KRO Documentation](https://kro.run/)
- [ACK Documentation](https://aws-controllers-k8s.github.io/community/)
- [EKS Auto Mode](https://docs.aws.amazon.com/eks/latest/userguide/automode.html)
