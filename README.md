# EKS Platform Blueprints

Platform engineering blueprints for Amazon EKS using KRO ResourceGraphs and ACK. Build reusable infrastructure patterns for observability, security, multi-tenancy, and more.

## Overview

This repository provides **declarative platform blueprints** that transform complex AWS and Kubernetes infrastructure into simple, reusable templates. Each blueprint uses:

- **KRO (Kubernetes Resource Orchestrator)** - Define high-level patterns that expand into multiple resources
- **ACK (AWS Controllers for Kubernetes)** - Manage AWS resources natively through Kubernetes
- **GitOps (ArgoCD)** - Automated deployment and lifecycle management
- **EKS Capabilities** - Managed add-ons built directly into Amazon EKS

## What are Platform Blueprints?

Platform blueprints are **reusable infrastructure patterns** that:
- Hide complexity behind simple parameters (3-7 inputs)
- Expand into complete, properly-configured resource stacks (5-15 resources)
- Enable self-service for development teams
- Maintain central control for platform teams
- Scale from 1 to 100+ clusters without additional operational overhead

**Example**: Instead of manually configuring monitoring for each cluster (2-3 hours), apply a single YAML file with 5 parameters and get complete observability in 30 seconds.

## Available Blueprints

### 🔍 Observability
**Status**: ✅ Production-ready

Complete multi-cluster observability using Amazon Managed Prometheus (AMP) and Amazon Managed Grafana (AMG).

**What you get**:
- Centralized metrics storage (single AMP workspace for all clusters)
- ADOT collectors deployed automatically
- Pre-configured recording rules and alerts
- Grafana dashboards with unified visibility
- Pod Identity authentication (no IRSA complexity)

**Quick start**:
```bash
# Platform team deploys once (2 parameters)
kubectl apply -f observability/kro-resourcegroups/observability-platform.yaml
kubectl apply -f observability/examples/platform/company-observability.yaml

# Per cluster (5 parameters, ~30 seconds)
kubectl apply -f observability/examples/clusters/production/cluster.yaml
```

**Learn more**: [observability/README.md](observability/README.md)

---

## Coming Soon

Additional blueprints are planned for:
- 🔐 **Security** - Application security stacks (WAF, policies, IAM)
- 👥 **Team Onboarding** - Complete team workspaces with quotas and RBAC
- 🏢 **Multi-Tenancy** - Tenant isolation with dedicated resources
- 💾 **Database** - Production-ready database configurations
- 🚀 **CI/CD** - Complete pipeline setup

## Architecture Pattern

All blueprints follow this pattern:

```
Simple Instance YAML (3-7 parameters)
         ↓
KRO ResourceGraphDefinition (template)
         ↓
Multiple Kubernetes Resources (5-15)
         ↓
ACK Controllers call AWS APIs
         ↓
Complete AWS + Kubernetes Infrastructure
```

**Benefits**:
- **Consistency**: Same pattern deployed everywhere
- **Repeatability**: Adding cluster #20 takes same time as #2
- **Self-service**: Dev teams deploy without platform team
- **Central control**: Platform teams update templates once
- **GitOps-native**: All changes tracked in Git

## Prerequisites

- Amazon EKS cluster (version 1.28 or later)
- EKS add-ons installed:
  - ACK controllers (service-specific, e.g., Prometheus, IAM, EKS)
  - KRO (Kubernetes Resource Orchestrator)
  - ADOT (AWS Distro for OpenTelemetry)
  - ArgoCD (optional, for GitOps automation)
- kubectl configured to access your cluster
- AWS CLI with appropriate permissions

## Quick Start

1. **Choose a blueprint** from the directories above
2. **Deploy the ResourceGraphDefinition** (one-time setup):
   ```bash
   kubectl apply -f <blueprint>/kro-resourcegroups/
   ```
3. **Create an instance** by copying and customizing an example:
   ```bash
   kubectl apply -f <blueprint>/examples/
   ```
4. **Verify deployment**:
   ```bash
   kubectl get <ResourceType> -o wide
   ```

## Repository Structure

```
eks-platform-blueprints/
├── README.md                     # This file
├── CLAUDE.md                     # AI assistant guidance
├── observability/                # Multi-cluster observability blueprint
│   ├── kro-resourcegroups/      # KRO template definitions
│   ├── examples/                # Instance files (platform + clusters)
│   ├── argocd/                  # GitOps automation configs
│   ├── diagrams/                # Architecture diagrams
│   └── README.md                # Detailed observability guide
└── .gitignore
```

## How to Use This Repository

### For Platform Teams
1. Deploy ResourceGraphDefinitions to your management cluster
2. Customize templates for your organization's standards
3. Set up ArgoCD to watch this repository (optional)
4. Provide examples to development teams

### For Development Teams
1. Copy an example from the blueprint you need
2. Update parameters (cluster name, region, etc.)
3. Apply to your cluster: `kubectl apply -f your-config.yaml`
4. Verify resources are created correctly

### For GitOps Automation
1. Configure ArgoCD Applications/ApplicationSets
2. Commit instance files to Git
3. ArgoCD automatically deploys and syncs
4. All changes tracked with audit trail

## Key Technologies

| Technology | Purpose | Documentation |
|------------|---------|---------------|
| **KRO** | Template engine for Kubernetes resources | https://kro.run/ |
| **ACK** | Kubernetes controllers for AWS services | https://aws-controllers-k8s.github.io/community/ |
| **EKS** | Managed Kubernetes with integrated capabilities | https://docs.aws.amazon.com/eks/latest/userguide/eks-add-ons.html |
| **ADOT** | OpenTelemetry distribution for AWS | https://aws-otel.github.io/ |
| **ArgoCD** | GitOps continuous delivery | https://argo-cd.readthedocs.io/ |

## Design Philosophy

These blueprints are designed with these principles:

1. **Simplicity First**: Minimize required parameters (3-7 inputs)
2. **Sensible Defaults**: Production-ready configurations out of the box
3. **Declarative**: Everything expressed as Kubernetes resources
4. **Composable**: Blueprints can reference each other
5. **GitOps-Native**: Source of truth in Git, automated deployment
6. **Cloud-Native**: Leverage AWS managed services where possible
7. **Observable**: Built-in monitoring and logging
8. **Secure**: Least-privilege IAM, Pod Identity, encryption by default

## Contributing

This repository serves as a reference implementation. Feel free to:
- Fork and adapt to your organization's needs
- Submit issues for bugs or suggestions
- Share your own blueprint patterns
- Provide feedback on the approach

## Additional Resources

- **EKS Capabilities**: https://docs.aws.amazon.com/eks/latest/userguide/eks-add-ons.html
- **ACK Community**: https://aws-controllers-k8s.github.io/community/
- **KRO Documentation**: https://kro.run/
- **AWS Containers Blog**: https://aws.amazon.com/blogs/containers/

## Support

For questions, issues, or feedback:
- Open an issue in this repository
- Refer to individual blueprint README files for detailed guides
- Check AWS documentation links above

---

**Built with ❤️ for platform engineering teams who want to scale without operational overhead**
