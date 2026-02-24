# EKS Platform Blueprints: Enterprise-Grade Kubernetes Platform Engineering

**Transform complex infrastructure into simple, reusable patterns** using Amazon EKS capabilities (KRO, ACK, Auto Mode).

## 🎯 3-Tier Architecture for Enterprise Adoption

This project provides a **clear, layered approach** to platform engineering:

```
┌─────────────────────────────────────────────────────────┐
│  Tier 1: Platform Foundation (Infrastructure)           │
│  Deploy once per cluster - Complete platform in 2 min   │
│  • Observability  • DNS  • Compute  • Metrics           │
│  • Secrets  • Logging                                   │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  Tier 2: Platform Security (Governance)                 │
│  Deploy once per cluster - Security baseline            │
│  • Pod Security  • RBAC  • Network Policies             │
│  • Image Security  • Resource Governance                │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  Tier 3: Team Services (Application-Level)              │
│  Deploy per team/app - Self-service                     │
│  • Team Namespaces  • GitHub Runners  • Backup          │
└─────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start: 3 Commands to Production

```bash
# Step 1: Deploy platform infrastructure (2 minutes)
kubectl apply -f platform/foundation/examples/full.yaml

# Step 2: Deploy security baseline (30 seconds)
kubectl apply -f platform/security/examples/restricted.yaml

# Step 3: Onboard teams (10 seconds per team)
kubectl apply -f team-services/team-namespace/examples/backend-team.yaml
```

**Result**: Production-ready EKS platform with observability, DNS, compute optimization, security policies, and team namespaces!

---

## Why This Approach?

### The Problem with Traditional Methods

**Before** (Traditional approach):
- Multiple Terraform modules to maintain
- Multiple Helm charts with version conflicts
- Multiple Kustomize overlays per environment
- Separate tools for AWS resources (Terraform) and K8s resources (Helm)
- 2-3 hours to set up monitoring per cluster
- Inconsistent configurations across clusters

**After** (This project):
- **Single YAML file** per tier
- **8-10 parameters** instead of 50+
- **100% Kubernetes-native** (no Terraform/Helm)
- **2 minutes** to deploy complete platform
- **Consistent** across all clusters
- **GitOps-ready** out of the box

### Key Benefits

✅ **Simplicity**: 3 YAML files instead of 50+ configuration files  
✅ **Speed**: 2 minutes vs 2-3 hours for platform setup  
✅ **Consistency**: Same patterns across 1 or 100 clusters  
✅ **Self-Service**: Teams deploy without platform team intervention  
✅ **Cost-Optimized**: Leverage EKS managed capabilities (no operational overhead)  
✅ **GitOps-Native**: All changes tracked and automated  

---

## Architecture Overview

### Tier 1: Platform Foundation

**One resource creates complete infrastructure**:

```yaml
apiVersion: platform.company.com/v1alpha1
kind: EKSPlatformFoundation
metadata:
  name: production
spec:
  # Core (3 params)
  clusterName: <YOUR_CLUSTER_NAME>
  region: <YOUR_AWS_REGION>
  accountID: "<YOUR_AWS_ACCOUNT_ID>"
  
  # Profile-based defaults
  profile: production  # production|staging|development
  
  # Module toggles (all true by default)
  modules:
    observability: true  # AMP + AMG + ADOT
    dns: true           # ExternalDNS + Route53
    compute: true       # Karpenter NodePools
    metrics: true       # Metrics Server
    secrets: true       # External Secrets Operator
    logging: true       # CloudWatch/OpenSearch
  
  # Module configurations (smart defaults)
  observability:
    ampWorkspaceID: <YOUR_AMP_WORKSPACE_ID>
    ampRemoteWriteEndpoint: <YOUR_AMP_REMOTE_WRITE_ENDPOINT>
  
  dns:
    hostedZoneID: <YOUR_HOSTED_ZONE_ID>
    domainFilter: <YOUR_DOMAIN>
  
  compute:
    spotEnabled: true
```

**What you get**: Up to 50+ resources from 8-10 parameters

### Tier 2: Platform Security

**Security baseline for governance**:

```yaml
apiVersion: platform.company.com/v1alpha1
kind: EKSPlatformSecurity
metadata:
  name: restricted
spec:
  clusterName: <YOUR_CLUSTER_NAME>
  
  # Security profile
  securityProfile: restricted  # permissive|standard|restricted
  
  # Policy enforcement
  policyEnforcement:
    mode: deny  # deny|dryrun|warn
  
  # Pod Security Standards
  podSecurity:
    enabled: true
    defaultLevel: restricted
  
  # Image security
  imageSecurity:
    enableAllowlist: true
    allowedRegistries: "<YOUR_AWS_ACCOUNT_ID>.dkr.ecr.<YOUR_AWS_REGION>.amazonaws.com"
    blockLatestTag: true
  
  # Resource governance
  resourceGovernance:
    enforceResourceLimits: true
    requiredLabels: "team,environment,cost-center"
```

**What you get**: Complete security baseline with pod security standards, RBAC, and network policies

### Tier 3: Team Services

**Self-service for development teams**:

```yaml
apiVersion: platform.company.com/v1alpha1
kind: TeamNamespace
metadata:
  name: backend-team
spec:
  teamName: backend
  clusterName: <YOUR_CLUSTER_NAME>
  region: <YOUR_AWS_REGION>
  accountID: "<YOUR_AWS_ACCOUNT_ID>"
  
  # RBAC profile
  rbacProfile: developer  # viewer|developer|admin
  adminUsers: "<ADMIN_USER_1>,<ADMIN_USER_2>"
  developerUsers: "<DEV_USER_1>,<DEV_USER_2>"
  
  # Resource quotas
  cpuQuota: "20"
  memoryQuota: "40Gi"
  
  # Secrets access
  secretsPrefix: "backend/"
  enableSecretsAccess: true
  
  # Optional AWS service access
  enableAWSAccess: true
  awsServices: "s3,dynamodb"
```

**What you get**: Namespace with RBAC, quotas, network policies, secrets access, and AWS permissions

---

## Repository Structure

```
eks-platform-blueprints/
├── platform/                    # Tier 1 & 2: Platform-level
│   ├── foundation/             # Infrastructure layer
│   │   ├── kro-resourcegroups/
│   │   │   └── eks-platform-foundation.yaml
│   │   └── examples/
│   │       ├── full.yaml
│   │       ├── standard.yaml
│   │       └── minimal.yaml
│   │
│   ├── security/               # Security & governance layer
│   │   ├── kro-resourcegroups/
│   │   │   └── eks-platform-security.yaml
│   │   └── examples/
│   │       ├── restricted.yaml
│   │       ├── standard.yaml
│   │       └── permissive.yaml
│
├── team-services/              # Tier 3: Team-level
│   ├── team-namespace/         # Team onboarding with RBAC
│   ├── github-runner/          # Self-hosted runners
│   └── backup-strategy/        # Velero backup/DR per cluster
│
├── data-services/              # Tier 4: AWS managed data services
│   ├── database/               # RDS Aurora via ACK
│   ├── cache/                  # ElastiCache Serverless via ACK
│   ├── queue/                  # SQS via ACK
│   └── storage/                # S3 via ACK
│
├── ai-ml/                      # Tier 5: AI/ML platform
│   ├── gpu-nodepool/           # GPU Karpenter NodePools
│   ├── bedrock-access/         # Bedrock model access + guardrails
│   ├── bedrock-agent/          # Bedrock agents via ACK
│   ├── notebook/               # SageMaker notebooks via ACK
│   ├── sagemaker-endpoint/     # SageMaker inference via ACK
│   └── training-job/           # SageMaker training via ACK
│
├── modules/                    # Individual modules (advanced users)
│   ├── observability/          # AMP + AMG + ADOT
│   ├── external-dns/           # DNS automation
│   ├── karpenter/              # Compute optimization
│   ├── metrics-server/         # HPA enablement
│   ├── external-secrets/       # Secrets sync
│   ├── ingress-controller/     # ALB/NLB
│   ├── centralized-logging/    # CloudWatch/OpenSearch
│   ├── certificate-manager/    # cert-manager + Let's Encrypt
│   └── cost-visibility/        # Split cost allocation
│
├── bootstrap/                  # One-command deployment
│   ├── deploy-blueprints.sh   # Deploy all templates
│   └── health-check.sh        # Validate platform
│
├── argocd/                     # GitOps automation
│   ├── root-app.yaml          # App of Apps
│   ├── platform/              # Platform applications
│   └── teams/                 # Team applications
│
└── README.md                   # This file
```

---

## Detailed Guides

### Platform Foundation
- [Platform Foundation Guide](platform/foundation/README.md) - Complete infrastructure setup
- Includes: Observability, DNS, Compute, Metrics, Secrets, Logging

### Platform Security
- [Platform Security Guide](platform/security/README.md) - Security baseline and governance
- Includes: Pod Security, RBAC, Network Policies, Image Security

### Team Services
- Team Namespace - Team onboarding with RBAC (`team-services/team-namespace/`)

### Data Services
- Database - Aurora PostgreSQL/MySQL via ACK (`data-services/database/`)
- Cache - ElastiCache Serverless Redis via ACK (`data-services/cache/`)
- Queue - SQS via ACK (`data-services/queue/`)
- Storage - S3 via ACK (`data-services/storage/`)

### AI/ML
- GPU NodePool - Karpenter GPU pools for Auto Mode (`ai-ml/gpu-nodepool/`)
- Bedrock Access - Model access with guardrails (`ai-ml/bedrock-access/`)
- Bedrock Agent - Agents via ACK (`ai-ml/bedrock-agent/`)
- SageMaker Notebook - Managed notebooks (`ai-ml/notebook/`)
- SageMaker Endpoint - Model serving (`ai-ml/sagemaker-endpoint/`)
- Training Job - SageMaker training (`ai-ml/training-job/`)
- GitHub Runner - Self-hosted CI/CD (`team-services/github-runner/`)

### Individual Modules (Advanced)
- [Observability](modules/observability/README.md) - AMP + AMG + ADOT
- [ExternalDNS](modules/external-dns/README.md) - DNS automation
- [Karpenter](modules/karpenter/README.md) - Compute optimization
- [Metrics Server](modules/metrics-server/README.md) - HPA enablement
- [External Secrets](modules/external-secrets/README.md) - Secrets sync
- Ingress Controller (`modules/ingress-controller/`)
- Centralized Logging (`modules/centralized-logging/`)
- Certificate Manager (`modules/certificate-manager/`)
- Cost Visibility (`modules/cost-visibility/`)
---

## Prerequisites

- **Amazon EKS Auto Mode cluster** (version 1.28+)
- **EKS Capabilities** enabled:
  - `kro` - Kubernetes Resource Orchestrator
  - `ack` - AWS Controllers for Kubernetes (IAM, EKS, Prometheus Service)
  - `argo-cd` - GitOps automation
- **kubectl** configured for your cluster
- **AWS CLI** with appropriate permissions

For **data-services** blueprints (database, cache, queue, storage), the ACK controller role needs permissions for the corresponding AWS services (RDS, ElastiCache, SQS, S3).

For **ai-ml** blueprints (Bedrock, SageMaker), the ACK controller role needs `bedrock:*` and `sagemaker:*` permissions. Enable the corresponding ACK controllers as EKS capabilities.

Enable capabilities via the EKS console or CLI:
```bash
aws eks update-cluster-config --name <cluster> \
  --compute-config enabled=true \
  --kubernetes-network-config '{"elasticLoadBalancing":{"enabled":true}}' \
  --storage-config '{"blockStorage":{"enabled":true}}'
```

---

## Deployment Options

### Option 1: Automated Bootstrap (Recommended)

```bash
cd bootstrap
./deploy-blueprints.sh
```

**What it does**:
1. Configures KRO RBAC
2. Deploys all blueprint templates
3. Ready for platform instances

**Time**: ~2 minutes

### Option 2: Manual Step-by-Step

```bash
# 1. KRO Setup (one-time)
kubectl apply -f kro-setup/rbac.yaml
kubectl rollout restart deployment -n kro-system kro

# 2. Deploy platform templates
kubectl apply -f platform/foundation/kro-resourcegroups/
kubectl apply -f platform/security/kro-resourcegroups/
kubectl apply -f team-services/team-namespace/kro-resourcegroups/

# 3. Deploy platform instances
kubectl apply -f platform/foundation/examples/full.yaml
kubectl apply -f platform/security/examples/restricted.yaml

# 4. Onboard teams
kubectl apply -f team-services/team-namespace/examples/backend-team.yaml
```

### Option 3: GitOps with ArgoCD

```bash
# Deploy root application (App of Apps pattern)
kubectl apply -f argocd/root-app.yaml

# ArgoCD automatically deploys:
# - Platform foundation
# - Platform security
# - Team namespaces
```

---

## Multi-Cluster Deployment

Deploy the same platform to multiple clusters:

```bash
# Production cluster
kubectl apply -f platform/foundation/examples/full.yaml
kubectl apply -f platform/security/examples/restricted.yaml

# Staging cluster
kubectl apply -f platform/foundation/examples/standard.yaml
kubectl apply -f platform/security/examples/standard.yaml

# Development cluster
kubectl apply -f platform/foundation/examples/minimal.yaml
kubectl apply -f platform/security/examples/permissive.yaml
```

All clusters automatically:
- Send metrics to same AMP workspace (unified visibility)
- Use consistent DNS management
- Have cost-optimized compute (spot instances)
- Follow security baselines

---

## Design Philosophy

### 1. Complement, Don't Duplicate

These blueprints **complement EKS add-ons** rather than replacing them.

**Use EKS Add-ons** (managed by AWS):
- AWS Load Balancer Controller
- Karpenter
- EBS/EFS CSI Drivers
- VPC CNI, CoreDNS, kube-proxy

**Use These Blueprints** (not available as add-ons):
- ✅ Platform orchestration (foundation + security)
- ✅ Observability configuration (AMP workspace, collectors, rules)
- ✅ DNS automation (ExternalDNS)
- ✅ Team onboarding (namespace templates with RBAC/quotas/secrets)
- ✅ Compute configuration (Karpenter NodePool templates)
- ✅ Security policies (pod security, image security, resource governance)

### 2. Layered Architecture

**Tier 1 (Foundation)**: Infrastructure that every cluster needs  
**Tier 2 (Security)**: Governance and compliance baseline  
**Tier 3 (Team Services)**: Self-service for development teams  

### 3. Smart Defaults with Flexibility

- **Production profile**: All modules enabled, high availability, strict security
- **Staging profile**: Standard modules, balanced settings
- **Development profile**: Essential modules, cost-optimized, permissive security

### 4. Kubernetes-Native

- Everything expressed as Kubernetes resources
- No Terraform, Helm, or Kustomize required
- ACK manages AWS resources through kubectl
- KRO orchestrates complex patterns

---

## Key Technologies

| Technology | Purpose | Documentation |
|------------|---------|---------------|
| **KRO** | Template engine for Kubernetes resources | https://kro.run/ |
| **ACK** | Kubernetes controllers for AWS services | https://aws-controllers-k8s.github.io/community/ |
| **EKS** | Managed Kubernetes with integrated capabilities | https://docs.aws.amazon.com/eks/latest/userguide/eks-add-ons.html |
| **ArgoCD** | GitOps continuous delivery | https://argo-cd.readthedocs.io/ |

---

## Contributing

This repository serves as a reference implementation. Feel free to:
- Fork and adapt to your organization's needs
- Submit issues for bugs or suggestions
- Share your own blueprint patterns
- Provide feedback on the approach

---

## Support

For questions, issues, or feedback:
- Open an issue in this repository
- Refer to individual blueprint README files
- Check AWS documentation links above

---

**Built with ❤️ for platform engineering teams who want to scale without operational overhead**
