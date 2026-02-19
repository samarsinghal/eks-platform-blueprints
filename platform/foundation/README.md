# Platform Foundation: Complete EKS Infrastructure in One Resource

Deploy a complete, production-ready EKS platform infrastructure with a single Kubernetes resource.

## What Gets Deployed

One `EKSPlatformFoundation` resource orchestrates:

| Module | Resources | Purpose |
|--------|-----------|---------|
| **Observability** | 12+ | AMP workspace, ADOT collectors, recording/alert rules |
| **DNS** | 10+ | ExternalDNS automation for Route53 |
| **Compute** | 4-16 | Karpenter NodePools (general, compute, memory, ARM) |
| **Metrics** | 3 | Metrics Server for HPA |
| **Secrets** | 8+ | External Secrets Operator for AWS Secrets Manager |
| **Ingress** | 10+ | ALB/NLB Ingress Controller |
| **Logging** | 8+ | Centralized logging to CloudWatch/OpenSearch |

**Total**: 50+ resources from 8-10 parameters

## Quick Start

```bash
# 1. Deploy blueprint template (one-time)
kubectl apply -f kro-resourcegroups/eks-platform-foundation.yaml

# 2. Deploy platform instance
kubectl apply -f examples/full.yaml

# 3. Verify
kubectl get eksplatformfoundation production
kubectl get observabilitycluster,externaldnscluster,karpenternodepool
```

## Configuration Profiles

### Production (Full Platform)

```yaml
apiVersion: platform.company.com/v1alpha1
kind: EKSPlatformFoundation
metadata:
  name: production
spec:
  clusterName: production
  region: <YOUR_AWS_REGION>
  accountID: "<YOUR_AWS_ACCOUNT_ID>"
  profile: production
  
  modules:
    observability: true
    dns: true
    compute: true
    metrics: true
    secrets: true
    ingress: true
    logging: true
  
  observability:
    ampWorkspaceID: ws-prod-abc123
    ampRemoteWriteEndpoint: https://...
  
  dns:
    hostedZoneID: Z123ABC
    domainFilter: prod.example.com
  
  compute:
    subnetSelector: "*private*"
    securityGroupSelector: "*node*"
    spotEnabled: true
    computeOptimized: true
    memoryOptimized: true
```

### Staging (Standard Setup)

```yaml
spec:
  profile: staging
  
  compute:
    computeOptimized: false  # Cost-optimized
    memoryOptimized: false
  
  ingress:
    enableWAF: false  # Reduce costs
  
  logging:
    retentionDays: 7  # Shorter retention
```

### Development (Minimal)

```yaml
spec:
  profile: development
  
  modules:
    ingress: false  # Not needed
    logging: false  # Not needed
  
  compute:
    armGraviton: true  # Cost savings
  
  metrics:
    highAvailability: false  # Single replica
```

## Module Details

### Observability
- AMP workspace for metrics storage
- ADOT collectors (DaemonSet on all nodes)
- Recording rules for pre-aggregation
- Alert rules for platform health
- IAM roles with Pod Identity

### DNS
- ExternalDNS for automatic DNS records
- Route53 integration
- Support for public/private zones
- Sync or upsert-only policies

### Compute
- **General Purpose**: t3/t3a instances, spot
- **Compute Optimized**: c5/c6i instances (optional)
- **Memory Optimized**: r5/r6i instances (optional)
- **ARM Graviton**: t4g/m6g/c6g instances (optional)

### Metrics
- Metrics Server for HPA
- High availability (2 replicas) in production
- Resource limits configured

### Secrets
- External Secrets Operator
- AWS Secrets Manager integration
- Parameter Store support (optional)
- Automatic sync with configurable interval

### Ingress
- AWS Load Balancer Controller
- ALB or NLB support
- WAF integration (optional)
- TLS 1.3 by default

### Logging
- CloudWatch Logs or OpenSearch
- Application, dataplane, audit logs
- Configurable retention
- Automatic log group creation

## Parameter Reference

### Core (Required)
- `clusterName`: EKS cluster name
- `region`: AWS region
- `accountID`: AWS account ID

### Profile
- `profile`: production|staging|development (smart defaults)

### Module Toggles
- `modules.observability`: Enable observability stack
- `modules.dns`: Enable DNS automation
- `modules.compute`: Enable Karpenter NodePools
- `modules.metrics`: Enable Metrics Server
- `modules.secrets`: Enable External Secrets
- `modules.ingress`: Enable Ingress Controller
- `modules.logging`: Enable centralized logging

### Module Configurations
See [examples/](examples/) for complete configurations.

## Multi-Cluster Deployment

Deploy to multiple clusters with consistent configuration:

```bash
# Production
kubectl apply -f examples/full.yaml

# Staging (same AMP workspace)
kubectl apply -f examples/standard.yaml

# Development
kubectl apply -f examples/minimal.yaml
```

All clusters send metrics to the same AMP workspace for unified observability.

## Validation

```bash
# Check platform status
kubectl get eksplatformfoundation production -o yaml

# Verify modules
kubectl get observabilitycluster
kubectl get externaldnscluster
kubectl get karpenternodepool
kubectl get metricsserver
kubectl get externalsecretsoperator
kubectl get ingresscontroller
kubectl get centralizedlogging

# Check pods
kubectl get pods -n observability-system
kubectl get pods -n external-dns-system
kubectl get pods -n kube-system | grep metrics-server
kubectl get pods -n external-secrets-system
kubectl get pods -n ingress-system
kubectl get pods -n logging-system
```

## Troubleshooting

### Platform not creating modules

```bash
kubectl describe eksplatformfoundation production
kubectl get resourcegraphdefinition eks-platform-foundation
kubectl logs -n kro-system -l app=kro-controller
```

### Module not ready

```bash
kubectl describe <module-type> <module-name>
kubectl get pods -A | grep <module>
```

## Next Steps

After deploying platform foundation:

1. **Deploy security baseline**: `kubectl apply -f ../../security/examples/restricted.yaml`
2. **Onboard teams**: `kubectl apply -f ../../team-services/team-namespace/examples/`
3. **Configure GitOps**: `kubectl apply -f ../../argocd/root-app.yaml`

## Related Resources

- [Platform Security](../security/README.md)
- [Team Services](../../team-services/team-namespace/README.md)
- [Individual Modules](../../modules/)
