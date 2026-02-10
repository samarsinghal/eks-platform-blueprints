# Managing Amazon Managed Prometheus and Grafana on EKS: The Kubernetes-Native Way

A comprehensive solution demonstrating how to manage Amazon Managed Prometheus (AMP) and Amazon Managed Grafana (AMG) on EKS using a Kubernetes-Native/GitOps approach with AWS Controllers for Kubernetes (ACK), AWS Distro for OpenTelemetry (ADOT), and ArgoCD.

## ✅ Solution Validation

This solution has been successfully deployed and tested in production environments.

All components work together to provide complete observability via ACK-managed resources:
- ✅ AMP Workspace: Created and managed via ACK Prometheus controller
- ✅ Recording Rules: 6 pre-aggregation rules deployed via ACK
- ✅ Alert Rules: 4 critical platform alerts deployed via ACK
- ✅ ADOT Collectors: Running as DaemonSet on all nodes
- ✅ IAM Roles & Policies: Created via ACK IAM controller
- ✅ EKS Pod Identity: Configured for secure AWS access without IRSA
- ✅ Metrics Collection: Scraping 4 job types (API server, nodes, pods, cAdvisor)

**Deployment Approach**: 100% Kubernetes-native (no Terraform, no CloudFormation, no AWS CLI)

## Overview

This repository showcases how platform teams can:
- **Manage AWS observability infrastructure using kubectl** instead of AWS Console or CloudFormation
- **Collect metrics using ADOT** running as pods in your EKS clusters
- **Deploy and manage observability infrastructure using GitOps** with ArgoCD
- **Scale observability across multiple clusters efficiently**
- **Use ACK for all AWS resource management** - no Terraform or CloudFormation needed

The solution implements a centralized observability pattern where multiple EKS clusters send metrics to a single AMP workspace and visualize through a single AMG workspace, demonstrating the power and simplicity of the Kubernetes-Native approach.

### Architecture Approach

This solution uses ACK (AWS Controllers for Kubernetes) for all AWS resource management:
- **ACK Prometheus Service Controller** manages AMP workspaces, recording rules, and alert rules
- **ACK IAM Controller** manages IAM roles and policies
- **ACK EKS Controller** manages EKS addons (ADOT operator)
- **ADOT Collectors** collect and send metrics from EKS clusters to AMP
- **EKS Pod Identity** provides secure AWS authentication without IRSA complexity
- **AMG** is created manually as a prerequisite (ACK Grafana controller not yet available)
- **Dashboards** are imported manually into AMG

## Architecture

### Architecture Overview

```
┌────────────────────────────────────────────────────────────┐
│                    Git Repository                          │
│  ├── kro-resourcegroups/                                   │
│  │   ├── observability-platform.yaml                       │
│  │   └── observability-cluster.yaml                        │
│  ├── examples/                                             │
│  │   ├── platform/company-observability.yaml               │
│  │   └── clusters/production/cluster.yaml                  │
│  └── argocd/                                               │
└────────────────────────────────────────────────────────────┘
                          │
                          │ kubectl apply or ArgoCD watches
                          ↓
┌─────────────────────────────────────────────────────────────┐
│              Management EKS Cluster                         │
│  ┌─────────────────────────────────────────────────────-─┐  │
│  │  ACK Prometheus Controller                            │  │
│  │  └── Creates AMP workspaces, rules, alerts            │  │
│  └──────────────────────────────────────────────────────-┘  │
│  ┌──────────────────────────────────────────────────────-┐  │
│  │  ACK IAM Controller                                   │  │
│  │  └── Creates IAM roles and policies                   │  │
│  └─────────────────────────────────────────────────────-─┘  │
│  ┌──────────────────────────────────────────────────────-┐  │
│  │  ACK EKS Controller                                   │  │
│  │  └── Creates Pod Identity associations & addons       │  │
│  └─────────────────────────────────────────────────────-─┘  │
└─────────────────────────────────────────────────────────────┘
                          │
                          │ Creates AWS resources
                          ↓
┌─────────────────────────────────────────────────────────────┐
│                    AWS Resources                            │
│  ┌─────────────────────────────────────────────────────-─┐  │
│  │  AMP Workspace (Shared)                               │  │
│  │  ├── Recording Rules (6 rules)                        │  │
│  │  └── Alert Rules (4 alerts)                           │  │
│  └─────────────────────────────────────────────────────-─┘  │
│  ┌─────────────────────────────────────────────────────-─┐  │
│  │  IAM Resources                                        │  │
│  │  ├── IAM Policy (ADOT permissions)                    │  │
│  │  ├── IAM Role (Pod Identity trust)                    │  │
│  │  └── Pod Identity Association                         │  │
│  └─────────────────────────────────────────────────────-─┘  │
│  ┌─────────────────────────────────────────────────────-─┐  │
│  │  AMG Workspace (Manually Created)                     │  │
│  │  ├── Prometheus Data Source (AMP)                     │  │
│  │  ├── Dashboards (Manually Imported)                   │  │
│  │  └── IAM Identity Center Authentication               │  │
│  └─────────────────────────────────────────────────────-─┘  │
└─────────────────────────────────────────────────────────────┘
                          ↑
                          │ Metrics flow
                          │
┌────────────────────────────────────────────────────────────┐
│              Monitored EKS Clusters                        │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  ADOT Operator (EKS Addon)                           │  │
│  │  └── Manages OpenTelemetryCollector resources        │  │
│  └──────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  ADOT Collector (DaemonSet)                          │  │
│  │  ├── Scrapes Kubernetes API server                   │  │
│  │  ├── Scrapes kubelet/cAdvisor                        │  │
│  │  ├── Scrapes pod metrics                             │  │
│  │  └── Remote writes to AMP via Pod Identity           │  │
│  └──────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Cluster Resources                                   │  │
│  │  ├── Nodes (kubelet metrics)                         │  │
│  │  ├── Pods (container metrics)                        │  │
│  │  └── API Server (control plane metrics)              │  │
│  └──────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────┘
```


## How It Works: KRO ResourceGraphDefinitions

This project uses **KRO (Kubernetes Resource Orchestrator)** to define reusable templates that simplify multi-cluster observability deployment.

### What are ResourceGraphDefinitions?

KRO ResourceGraphDefinitions are high-level abstractions that:
- Accept a small number of input parameters
- Expand into multiple related Kubernetes resources
- Enable platform teams to create self-service patterns

### Two-Tier Resource Model

**1. ObservabilityPlatform** (`kro-resourcegroups/observability-platform.yaml`)
- Creates shared observability infrastructure
- **Input**: 2 parameters (workspaceName, region)
- **Output**: 3 ACK resources (AMP Workspace + Recording Rules + Alert Rules)
- **Deployed**: Once by platform team

**2. ObservabilityCluster** (`kro-resourcegroups/observability-cluster.yaml`)
- Creates per-cluster monitoring configuration
- **Input**: 5 parameters (clusterName, region, ampWorkspaceID, ampRemoteWriteEndpoint, accountID)
- **Output**: 8 resources (ServiceAccount, IAM Policy, IAM Role, PodIdentityAssociation, ADOT Addon, RBAC, OpenTelemetryCollector)
- **Deployed**: Once per cluster

### Usage Pattern

**Step 1**: Deploy KRO ResourceGraphDefinitions (one-time setup)
```bash
kubectl apply -f kro-resourcegroups/observability-platform.yaml
kubectl apply -f kro-resourcegroups/observability-cluster.yaml
```

**Step 2**: Create platform instance
```bash
# Edit examples/platform/company-observability.yaml with your values
kubectl apply -f examples/platform/company-observability.yaml
```

**Step 3**: Add clusters
```bash
# Edit examples/clusters/production/cluster.yaml with your values
kubectl apply -f examples/clusters/production/cluster.yaml
```

That's it! KRO automatically expands your simple YAML into all necessary resources.

## Key Components

### 1. ObservabilityPlatform ResourceGroup
Creates shared observability infrastructure (AMP workspace, cross-cluster recording rules, critical platform alerts). Deployed once by the platform team.

### 2. ObservabilityCluster ResourceGroup
Creates per-cluster observability configuration (ADOT Collector with Prometheus scrape configs, IAM roles/policies, Pod Identity associations, and RBAC permissions). Deployed for each cluster that needs monitoring.

### 3. ADOT Collectors
AWS Distro for OpenTelemetry collectors run as pods in each EKS cluster, scraping metrics from Kubernetes components and sending them to the shared AMP workspace.

### 4. Grafana Dashboards
Pre-configured dashboards can be created in AMG to visualize metrics from the shared AMP workspace, including:
- Multi-cluster overview
- Cluster-level resource usage
- Node and pod metrics
- Control plane health
- Workload monitoring

### 5. ArgoCD GitOps
Automated deployment using ArgoCD Application and ApplicationSet for continuous delivery.

## Quick Start

### Prerequisites

Before you begin, ensure you have:
- An EKS cluster (1.28 or later)
- kubectl configured to access your cluster
- AWS CLI configured with appropriate permissions
- Helm 3.x installed

**Important Notes**:
- This reference implementation does not specify exact version numbers. Use the latest compatible versions available in your AWS region. The installation commands show how to check for available versions.
- If you plan to use ArgoCD GitOps (optional), update the `repoURL` values in `argocd/platform-app.yaml` and `argocd/clusters-appset.yaml` with your actual GitHub repository URL.

### Installation Steps

#### 1. Create AMG Workspace (Manual)

```bash
# AMG must be created manually as ACK Grafana controller is not yet available
aws grafana create-workspace \
  --account-access-type CURRENT_ACCOUNT \
  --authentication-providers AWS_SSO \
  --permission-type SERVICE_MANAGED \
  --workspace-name company-observability-grafana \
  --region us-west-2
```

#### 2. Install ACK Prometheus Controller

```bash
# Install ACK Prometheus Controller
# Check for latest version at: https://gallery.ecr.aws/aws-controllers-k8s/prometheusservice-chart
helm install ack-prometheusservice-controller \
  oci://public.ecr.aws/aws-controllers-k8s/prometheusservice-chart \
  --namespace ack-system \
  --create-namespace
```

#### 3. Install ADOT as EKS Add-on

```bash
# Install ADOT for metrics collection
# To check available versions: aws eks describe-addon-versions --addon-name adot
aws eks create-addon \
  --cluster-name <your-cluster-name> \
  --addon-name adot
  # Optionally specify --addon-version (defaults to latest)
```

#### 4. Install KRO as EKS Add-on

```bash
# To check available versions: aws eks describe-addon-versions --addon-name kro
aws eks create-addon \
  --cluster-name <your-cluster-name> \
  --addon-name kro
  # Optionally specify --addon-version (defaults to latest)
```

#### 5. Install ArgoCD as EKS Add-on

```bash
# To check available versions: aws eks describe-addon-versions --addon-name argo-cd
aws eks create-addon \
  --cluster-name <your-cluster-name> \
  --addon-name argo-cd
  # Optionally specify --addon-version (defaults to latest)
```

#### 6. Deploy KRO ResourceGroups

```bash
# Deploy the ResourceGroup definitions
kubectl apply -f kro-resourcegroups/observability-platform.yaml
kubectl apply -f kro-resourcegroups/observability-cluster.yaml
```

#### 7. Deploy ObservabilityPlatform

```bash
# Deploy the shared observability infrastructure
kubectl apply -f examples/platform/company-observability.yaml

# Wait for platform to be ready
kubectl wait --for=condition=Ready observabilityplatform/company-observability --timeout=5m
```

#### 8. Deploy Your First Cluster

```bash
# Update examples/clusters/production/cluster.yaml with your AMP workspace endpoint
# Then deploy
kubectl apply -f examples/clusters/production/cluster.yaml

# Wait for ADOT collector to be running
kubectl wait --for=condition=Ready observabilitycluster/production --timeout=5m
```

#### 9. Configure Grafana and Import Dashboards

```bash
# Get the AMG workspace URL
aws grafana describe-workspace \
  --workspace-id <workspace-id> \
  --query 'workspace.endpoint' \
  --output text

# Access Grafana and configure Prometheus data source
```

## Repository Structure

```
.
├── kro-resourcegroups/          # KRO ResourceGroup definitions (production-ready)
│   ├── observability-platform.yaml
│   └── observability-cluster.yaml
├── examples/                    # Example instance files
│   ├── platform/               # Platform configuration
│   │   └── company-observability.yaml
│   └── clusters/               # Per-cluster configurations
│       ├── production/
│       ├── staging/
│       └── development/
├── argocd/                      # ArgoCD configurations
│   ├── platform-app.yaml
│   └── clusters-appset.yaml
├── diagrams/                    # Architecture diagrams
│   ├── architecture.drawio
│   ├── deployment-flow.drawio
│   └── image/
├── blog.md                      # Implementation guide and blog post
└── CLAUDE.md                    # AI guidance for Claude Code
```

## Documentation

- [Implementation Guide](blog.md) - Complete guide with prerequisites, architecture, and step-by-step deployment
- [Architecture Diagrams](diagrams/) - Visual representations of the architecture and deployment flow

## Key Benefits

### Traditional Approach vs Kubernetes-Native Approach

**Traditional (Per-Cluster)**:
- Create AMP workspace for each cluster
- Create AMG workspace for each cluster
- Configure data sources manually
- Import dashboards manually
- Set up alert rules manually
- Deploy metrics collectors manually
- Result: N workspaces for N clusters

**Kubernetes-Native (Centralized)**:
- Create shared AMP/AMG workspaces once
- Add clusters by deploying ADOT collectors
- Dashboards imported once into AMG
- Alerts automatically configured
- Collectors deployed via Kubernetes manifests
- Result: 1 workspace for N clusters

### Why This Matters

1. **Single Pane of Glass**: View all clusters in one Grafana instance
2. **Consistent Configuration**: Same dashboards and alerts across all clusters
3. **Cost Efficiency**: Shared infrastructure reduces AWS costs
4. **GitOps Workflow**: All changes tracked in Git with automated deployment
5. **Kubernetes-Native**: Manage AWS resources using kubectl and standard Kubernetes patterns

## Validation

Validate your deployment using kubectl commands:

```bash
# Check ACK controllers are running
kubectl get pods -n ack-system

# Check KRO ResourceGroups are registered
kubectl get resourcegraphdefinitions

# Check platform is deployed
kubectl get observabilityplatform company-observability -o yaml

# Check specific cluster
kubectl get observabilitycluster production -o yaml

# Verify ADOT collectors are running
kubectl get pods -n observability-system -l app=adot-collector

# Check AMP workspace status
kubectl get workspace company-observability -n observability-system -o yaml
```

## Contributing

This repository is designed to be a reference implementation. Feel free to fork and adapt to your organization's needs.

## Related Resources

- [AWS Controllers for Kubernetes (ACK)](https://aws-controllers-k8s.github.io/community/)
- [Kubernetes Resource Orchestrator (KRO)](https://kro.run/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Amazon Managed Prometheus](https://aws.amazon.com/prometheus/)
- [Amazon Managed Grafana](https://aws.amazon.com/grafana/)
