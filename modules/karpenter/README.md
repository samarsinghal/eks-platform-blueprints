# Karpenter Configuration on EKS: The Cost-Optimization Way

A comprehensive solution for configuring Karpenter NodePools with spot instances, right-sizing, and workload-specific compute using KRO and ACK.

## Overview

This blueprint enables platform teams to create optimized NodePool configurations for Karpenter with cost savings and right-sizing built-in.

**What you get**:
- Pre-configured NodePools for different workload types
- Spot instance support (30-50% cost savings)
- IAM roles and instance profiles via ACK
- Right-sized instance type selections
- Automatic node consolidation
- Workload isolation via taints/labels

## Quick Start

```bash
# Deploy ResourceGraphDefinition (once)
kubectl apply -f kro-resourcegroups/karpenter-nodepool.yaml

# Create a NodePool
kubectl apply -f examples/nodepools/general-purpose-spot.yaml

# Verify
kubectl get nodepool
kubectl get ec2nodeclass
```

## Prerequisites

**Karpenter must be installed** (available as EKS add-on in Auto Mode):
```bash
aws eks create-addon \
  --cluster-name production \
  --addon-name karpenter
```

This blueprint **configures** Karpenter (doesn't install it).

## Configuration

**Input Parameters** (11 parameters):
- `nodePoolName` - Name for this NodePool (required)
- `clusterName` - EKS cluster name (required)
- `accountID` - AWS account ID (required)
- `subnetSelector` - Subnet tag selector (required, e.g., "*private*")
- `securityGroupSelector` - Security group tag selector (required, e.g., "*node*")
- `instanceTypes` - Array of instance types (default: t3.medium, t3.large, t3.xlarge)
- `capacityType` - spot, on-demand, or mixed (default: "spot")
- `spotToOnDemandRatio` - Percentage of spot (default: "80")
- `architecture` - amd64 or arm64 (default: "amd64")
- `cpuLimit` - Max CPU across all nodes (default: "1000")
- `memoryLimit` - Max memory across all nodes (default: "1000Gi")

**Output Resources** (4 resources):
1. IAM Role (for EC2 nodes via ACK)
2. IAM Instance Profile (via ACK)
3. EC2NodeClass (infrastructure config)
4. NodePool (scheduling constraints)

## Cost Savings

### Spot Instances

**Spot vs On-Demand pricing:**
- t3.medium: $0.0416/hr → $0.0125/hr (70% savings)
- c5.xlarge: $0.17/hr → $0.051/hr (70% savings)
- r5.2xlarge: $0.504/hr → $0.151/hr (70% savings)

**Annual savings example (100 nodes):**
- On-Demand: $36,480
- Spot: $10,950
- **Savings: $25,530/year** (70%)

### Right-Sizing

Karpenter automatically:
- Provisions nodes that exactly fit workloads
- Consolidates underutilized nodes
- Removes empty nodes within minutes
- Prevents over-provisioning

**Result**: 10-20% additional savings from right-sizing

### Total Savings: 40-60%

## Pre-Configured NodePools

### 1. General Purpose (Spot)

```yaml
# Use for: Most workloads, development, testing
instanceTypes: [t3.medium, t3.large, t3.xlarge]
capacityType: spot
savings: ~70%
```

**When to use:**
- Web applications
- API services
- Background jobs
- Non-critical workloads

### 2. Compute Optimized

```yaml
# Use for: CPU-intensive workloads
instanceTypes: [c5.large, c5.xlarge, c6i.large]
capacityType: mixed  # 80% spot, 20% on-demand
savings: ~50-60%
```

**When to use:**
- Machine learning inference
- Video encoding
- Batch processing
- Scientific computing

### 3. Memory Optimized

```yaml
# Use for: Memory-intensive workloads
instanceTypes: [r5.large, r5.xlarge, r6i.large]
capacityType: mixed  # 70% spot, 30% on-demand
savings: ~40-50%
```

**When to use:**
- Redis/Memcached
- Elasticsearch
- Data analytics
- In-memory databases

### 4. ARM Graviton

```yaml
# Use for: Cost-optimized ARM workloads
instanceTypes: [t4g.medium, m6g.large, c6g.large]
capacityType: spot
architecture: arm64
savings: ~80% (spot + graviton)
```

**When to use:**
- Container workloads (multi-arch images)
- Additional cost savings
- Better price/performance ratio

## Usage Examples

### Deploy General Purpose NodePool

```bash
kubectl apply -f examples/nodepools/general-purpose-spot.yaml
```

### Application Deploys to Spot Instances Automatically

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    spec:
      # No nodeSelector needed - Karpenter handles it
      containers:
        - name: app
          image: my-app:latest
          resources:
            requests:
              cpu: "500m"
              memory: "512Mi"
```

Karpenter automatically:
1. Sees pending pod
2. Selects cheapest instance from NodePool
3. Provisions spot instance
4. Schedules pod
5. Consolidates nodes when workload decreases

### Target Specific NodePool

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ml-inference
spec:
  template:
    spec:
      nodeSelector:
        nodepool: compute-optimized  # Use compute-optimized nodes
      containers:
        - name: inference
          image: ml-model:latest
          resources:
            requests:
              cpu: "4"
              memory: "8Gi"
```

### Handle Spot Interruptions

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 3  # Multiple replicas for resilience
  template:
    spec:
      tolerations:
        - key: karpenter.sh/disruption
          operator: Exists
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: topology.kubernetes.io/zone
          whenUnsatisfiable: DoNotSchedule
```

## Node Consolidation

Karpenter automatically consolidates nodes to reduce costs:

**Scenario:**
- 10 pods running on 5 nodes
- 5 pods terminate
- Remaining 5 pods can fit on 2 nodes

**Karpenter action:**
1. Cordons 3 underutilized nodes
2. Drains pods gracefully
3. Terminates empty nodes
4. Saves ~60% of compute cost

**Configuration:**
```yaml
disruption:
  consolidationPolicy: WhenUnderutilized
  expireAfter: 720h  # 30 days
```

## Multiple NodePools Strategy

**Recommended setup:**

```bash
# 1. General purpose for most workloads (spot)
kubectl apply -f examples/nodepools/general-purpose-spot.yaml

# 2. Compute optimized for CPU-heavy (mixed)
kubectl apply -f examples/nodepools/compute-optimized.yaml

# 3. Memory optimized for data workloads (mixed)
kubectl apply -f examples/nodepools/memory-optimized.yaml

# 4. ARM Graviton for additional savings (spot)
kubectl apply -f examples/nodepools/arm-graviton.yaml
```

**Result**: Karpenter automatically selects the cheapest option for each workload

## Spot Instance Best Practices

### 1. Multiple Instance Types

```yaml
instanceTypes:
  - t3.medium
  - t3.large
  - t3a.medium  # AMD variant
  - t3a.large
```

**Why**: More instance types = higher spot availability

### 2. Multiple Availability Zones

Karpenter automatically spreads across AZs based on subnet selector.

### 3. Graceful Shutdown

```yaml
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    spec:
      terminationGracePeriodSeconds: 120  # Allow time for graceful shutdown
      containers:
        - name: app
          lifecycle:
            preStop:
              exec:
                command: ["/bin/sh", "-c", "sleep 15"]
```

### 4. Pod Disruption Budgets

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: my-app-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: my-app
```

## Monitoring and Observability

### Check NodePool Status

```bash
# View NodePools
kubectl get nodepool

# View nodes provisioned
kubectl get nodes -L karpenter.sh/capacity-type,node.kubernetes.io/instance-type

# View node utilization
kubectl top nodes
```

### Karpenter Metrics

Karpenter exposes Prometheus metrics:
- `karpenter_nodes_created` - Nodes created
- `karpenter_nodes_terminated` - Nodes terminated
- `karpenter_consolidation_savings` - Cost savings from consolidation

### Cost Tracking

Tag nodes for cost allocation:
```yaml
tags:
  CostCenter: "engineering"
  Team: "platform"
  Environment: "production"
```

View costs in AWS Cost Explorer filtered by tags.

## Validation

```bash
# Check KarpenterNodePool resource
kubectl get karpenternodepool general-purpose-spot -o yaml

# Check EC2NodeClass
kubectl get ec2nodeclass general-purpose-spot -o yaml

# Check IAM resources
kubectl get role,instanceprofile -n karpenter

# Verify nodes are provisioned
kubectl get nodes -l nodepool=general-purpose-spot
```

## Troubleshooting

### Pods not scheduling

```bash
# Check NodePool constraints
kubectl describe nodepool general-purpose-spot

# Check pod requirements
kubectl describe pod <pod-name>

# Check Karpenter logs
kubectl logs -n karpenter -l app.kubernetes.io/name=karpenter
```

Common issues:
- Instance type not available in AZ
- Insufficient spot capacity
- Resource limits exceeded
- Taints not tolerated

### Spot interruptions

```bash
# Check for spot interruption warnings (2 minutes before termination)
kubectl get events --field-selector reason=SpotInterruption

# Handle in application
curl http://169.254.169.254/latest/meta-data/spot/instance-action
```

### Costs higher than expected

```bash
# Check for node under-utilization
kubectl top nodes

# Check consolidation is enabled
kubectl get nodepool -o yaml | grep consolidationPolicy

# Review instance type selection
kubectl get nodes -L node.kubernetes.io/instance-type
```

## GitOps with ArgoCD

For GitOps deployment, see the centralized ArgoCD configuration in argocd/README.md at the repository root.

## Related Resources

- [Karpenter Documentation](https://karpenter.sh/)
- [AWS Spot Instances Best Practices](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/spot-best-practices.html)
- [EC2 Spot Instance Advisor](https://aws.amazon.com/ec2/spot/instance-advisor/)
- [ACK Documentation](https://aws-controllers-k8s.github.io/community/)
