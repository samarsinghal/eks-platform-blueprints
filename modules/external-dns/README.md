# ExternalDNS on EKS: The Kubernetes-Native Way

A comprehensive solution demonstrating how to manage ExternalDNS on EKS using a Kubernetes-Native/GitOps approach with AWS Controllers for Kubernetes (ACK), EKS Pod Identity, and ArgoCD.

## Overview

This repository showcases how platform teams can:
- **Manage ExternalDNS using kubectl** instead of manual Route53 configuration
- **Automatically create DNS records** for Kubernetes Services and Ingresses
- **Deploy and manage DNS infrastructure using GitOps** with ArgoCD
- **Scale DNS management across multiple clusters efficiently**
- **Use ACK for all AWS resource management** - no Terraform or CloudFormation needed

The solution implements automatic DNS record management where ExternalDNS watches Kubernetes resources and creates/updates DNS records in Route53.

### Architecture Approach

This solution uses ACK (AWS Controllers for Kubernetes) for all AWS resource management:
- **ACK IAM Controller** manages IAM roles and policies for Route53 access
- **ACK EKS Controller** manages Pod Identity associations
- **ExternalDNS** watches Services/Ingresses and manages Route53 records
- **EKS Pod Identity** provides secure AWS authentication without IRSA complexity
- **KRO** simplifies deployment with reusable templates

## How It Works: KRO ResourceGraphDefinitions

This project uses **KRO (Kubernetes Resource Orchestrator)** to define reusable templates that simplify ExternalDNS deployment.

### What is ExternalDNSCluster?

**ExternalDNSCluster** (`kro-resourcegroups/external-dns-cluster.yaml`)
- Creates per-cluster DNS management configuration
- **Input**: 9 parameters (clusterName, region, accountID, hostedZoneID, domainFilter, zoneType, policy, txtOwnerID, sources)
- **Output**: 7 resources (ServiceAccount, IAM Policy, IAM Role, PodIdentityAssociation, RBAC, Deployment)
- **Deployed**: Once per cluster

### Usage Pattern

**Step 1**: Deploy KRO ResourceGraphDefinition (one-time setup)
```bash
kubectl apply -f kro-resourcegroups/external-dns-cluster.yaml
```

**Step 2**: Add ExternalDNS to your cluster
```bash
# Edit examples/clusters/production/cluster.yaml with your values
kubectl apply -f examples/clusters/production/cluster.yaml
```

That's it! KRO automatically expands your simple YAML into all necessary resources.

## Architecture

```
┌────────────────────────────────────────────────────────────┐
│                    Git Repository                          │
│  ├── kro-resourcegroups/                                   │
│  │   └── external-dns-cluster.yaml                         │
│  └── examples/clusters/                                    │
│      ├── production/cluster.yaml                           │
│      ├── staging/cluster.yaml                              │
│      └── development/cluster.yaml                          │
└────────────────────────────────────────────────────────────┘
                          │
                          │ kubectl apply or ArgoCD watches
                          ↓
┌─────────────────────────────────────────────────────────────┐
│              Management EKS Cluster                         │
│  ┌──────────────────────────────────────────────────────-┐  │
│  │  ACK IAM Controller                                   │  │
│  │  └── Creates IAM roles and policies for Route53      │  │
│  └─────────────────────────────────────────────────────-─┘  │
│  ┌──────────────────────────────────────────────────────-┐  │
│  │  ACK EKS Controller                                   │  │
│  │  └── Creates Pod Identity associations                │  │
│  └─────────────────────────────────────────────────────-─┘  │
└─────────────────────────────────────────────────────────────┘
                          │
                          │ Creates AWS resources
                          ↓
┌─────────────────────────────────────────────────────────────┐
│                    AWS Resources                            │
│  ┌─────────────────────────────────────────────────────-─┐  │
│  │  IAM Resources                                        │  │
│  │  ├── IAM Policy (Route53 permissions)                │  │
│  │  ├── IAM Role (Pod Identity trust)                   │  │
│  │  └── Pod Identity Association                         │  │
│  └─────────────────────────────────────────────────────-─┘  │
│  ┌─────────────────────────────────────────────────────-─┐  │
│  │  Route53 Hosted Zones (Pre-existing)                 │  │
│  │  └── DNS Records (Managed by ExternalDNS)            │  │
│  └─────────────────────────────────────────────────────-─┘  │
└─────────────────────────────────────────────────────────────┘
                          ↑
                          │ DNS record changes
                          │
┌────────────────────────────────────────────────────────────┐
│              EKS Clusters with ExternalDNS                 │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  ExternalDNS Deployment                              │  │
│  │  ├── Watches Services with annotations              │  │
│  │  ├── Watches Ingresses with hostnames               │  │
│  │  └── Creates/Updates DNS records in Route53         │  │
│  └──────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Application Resources                               │  │
│  │  ├── LoadBalancer Services                           │  │
│  │  ├── Ingresses with hostnames                        │  │
│  │  └── Automatic DNS record creation                   │  │
│  └──────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────┘
```

## Key Features

### Simple Configuration

**Input (9 parameters)**:
```yaml
apiVersion: externaldns.company.com/v1alpha1
kind: ExternalDNSCluster
metadata:
  name: production
spec:
  clusterName: production
  region: <YOUR_AWS_REGION>
  accountID: "<YOUR_AWS_ACCOUNT_ID>"
  hostedZoneID: Z1234567890ABC
  domainFilter: prod.example.com
  zoneType: public
  policy: sync
  txtOwnerID: production
  sources: [service, ingress]
```

**Output (7 resources automatically created)**:
1. ServiceAccount (external-dns)
2. IAM Policy (Route53 permissions)
3. IAM Role (Pod Identity trust policy)
4. Pod Identity Association
5. ClusterRole (RBAC for watching K8s resources)
6. ClusterRoleBinding
7. Deployment (ExternalDNS controller)

### Flexible Source Configuration

Control which Kubernetes resources ExternalDNS watches:
- `service` - LoadBalancer Services
- `ingress` - Ingress resources
- `istio-gateway` - Istio Gateway resources
- `contour-httpproxy` - Contour HTTPProxy resources

### Policy Control

- `upsert-only` (default) - Only creates/updates records, never deletes (safe for shared zones)
- `sync` - Full synchronization, deletes records when resources are removed

### Zone Type Support

- `public` - Public hosted zones (default)
- `private` - Private hosted zones (requires VPC association)

## Quick Start

### Prerequisites

Before you begin, ensure you have:
- An EKS cluster (1.28 or later)
- kubectl configured to access your cluster
- AWS CLI configured with appropriate permissions
- A Route53 Hosted Zone
- ACK IAM Controller installed
- ACK EKS Controller installed
- KRO installed as EKS addon

### Installation Steps

#### 1. Install Prerequisites

```bash
# Install ACK IAM Controller
helm install ack-iam-controller \
  oci://public.ecr.aws/aws-controllers-k8s/iam-chart \
  --namespace ack-system \
  --create-namespace

# Install ACK EKS Controller
helm install ack-eks-controller \
  oci://public.ecr.aws/aws-controllers-k8s/eks-chart \
  --namespace ack-system

# Install KRO as EKS Add-on
aws eks create-addon \
  --cluster-name <your-cluster-name> \
  --addon-name kro
```

#### 2. Create Namespace

```bash
kubectl create namespace external-dns-system
```

#### 3. Deploy KRO ResourceGraphDefinition

```bash
kubectl apply -f kro-resourcegroups/external-dns-cluster.yaml
```

#### 4. Deploy ExternalDNS to Your Cluster

```bash
# Edit examples/clusters/production/cluster.yaml with your values:
# - region
# - accountID
# - hostedZoneID
# - domainFilter

kubectl apply -f examples/clusters/production/cluster.yaml
```

#### 5. Verify Deployment

```bash
# Check ExternalDNS is running
kubectl get pods -n external-dns-system

# Check logs
kubectl logs -n external-dns-system -l app=external-dns

# Verify IAM resources were created
kubectl get policy -n external-dns-system
kubectl get role -n external-dns-system
kubectl get podidentityassociation -n external-dns-system
```

## Usage Examples

### LoadBalancer Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-app
  annotations:
    external-dns.alpha.kubernetes.io/hostname: myapp.prod.example.com
spec:
  type: LoadBalancer
  ports:
    - port: 80
  selector:
    app: my-app
```

ExternalDNS will automatically create:
- A record: `myapp.prod.example.com` → `<LoadBalancer DNS>`
- TXT record: `external-dns-myapp.prod.example.com` → ownership info

### Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app-ingress
spec:
  rules:
    - host: myapp.prod.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-app
                port:
                  number: 80
```

ExternalDNS automatically creates DNS records from the `host` field.

## Repository Structure

```
.
├── kro-resourcegroups/          # KRO ResourceGroup definitions
│   └── external-dns-cluster.yaml
├── examples/                    # Example instance files
│   └── clusters/               # Per-cluster configurations
│       ├── production/
│       ├── staging/
│       └── development/
└── README.md
```

## Configuration Reference

### Required Parameters

- `clusterName` - EKS cluster name
- `region` - AWS region
- `accountID` - AWS account ID
- `hostedZoneID` - Route53 hosted zone ID
- `domainFilter` - Domain to manage (e.g., `prod.example.com`)

### Optional Parameters

- `zoneType` - `public` or `private` (default: `public`)
- `policy` - `upsert-only` or `sync` (default: `upsert-only`)
- `txtOwnerID` - Ownership identifier (default: clusterName)
- `sources` - Array of sources to watch (default: `[service, ingress]`)

## Validation

```bash
# Check ExternalDNS status
kubectl get externaldnscluster production -o yaml

# Check ExternalDNS logs
kubectl logs -n external-dns-system -l app=external-dns --tail=50

# Verify DNS records in Route53
aws route53 list-resource-record-sets \
  --hosted-zone-id <YOUR_ZONE_ID> \
  --query "ResourceRecordSets[?Type=='A' || Type=='TXT']"
```

## GitOps with ArgoCD

For GitOps deployment, see the centralized ArgoCD configuration in argocd/README.md at the repository root.

## Troubleshooting

### ExternalDNS not creating records

Check logs:
```bash
kubectl logs -n external-dns-system -l app=external-dns
```

Common issues:
- IAM permissions not correct
- Pod Identity not working
- Domain filter doesn't match
- Hosted zone ID incorrect

### Permission denied errors

Verify IAM resources:
```bash
kubectl get policy,role,podidentityassociation -n external-dns-system
```

Check Pod Identity association:
```bash
aws eks list-pod-identity-associations --cluster-name <cluster-name>
```

## Related Resources

- [ExternalDNS Documentation](https://github.com/kubernetes-sigs/external-dns)
- [AWS Controllers for Kubernetes (ACK)](https://aws-controllers-k8s.github.io/community/)
- [Kubernetes Resource Orchestrator (KRO)](https://kro.run/)
- [EKS Pod Identity](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html)
- [Route53 Documentation](https://docs.aws.amazon.com/route53/)
