# Metrics Server Blueprint

Deploy Kubernetes Metrics Server to enable Horizontal Pod Autoscaler (HPA) and `kubectl top` commands.

## Overview

This blueprint deploys Metrics Server with:
- **Resource metrics collection** from kubelets
- **HPA enablement** (Horizontal Pod Autoscaler)
- **kubectl top** support (view pod/node resource usage)
- **High availability** (2 replicas with anti-affinity)
- **Secure configuration** (TLS, read-only filesystem, non-root)

## Why Metrics Server?

**Critical for**:
- ✅ **Horizontal Pod Autoscaler (HPA)** - Cannot function without Metrics Server
- ✅ **kubectl top pods/nodes** - View current CPU/memory usage
- ✅ **VPA (Vertical Pod Autoscaler)** - Requires metrics for recommendations
- ✅ **Right-sizing workloads** - Visibility into actual resource consumption

**Without Metrics Server**:
- ❌ HPA doesn't work
- ❌ `kubectl top` returns errors
- ❌ No visibility into real-time resource usage
- ❌ VPA cannot make recommendations

## Architecture

```
Kubelet (node metrics) → Metrics Server → Metrics API
                                              ↓
                         HPA / kubectl top / VPA
```

**Resources Created** (9):
1. ServiceAccount
2. ClusterRole (metrics reader)
3. ClusterRoleBinding
4. ClusterRole (aggregated metrics)
5. RoleBinding (auth reader)
6. APIService (v1beta1.metrics.k8s.io)
7. Service
8. Deployment (2 replicas)
9. PodDisruptionBudget

## Quick Start

### 1. Deploy Metrics Server

```bash
# Deploy ResourceGraphDefinition
kubectl apply -f metrics-server/kro-resourcegroups/metrics-server.yaml

# Deploy Metrics Server instance
kubectl apply -f metrics-server/examples/metrics-server.yaml
```

### 2. Verify Installation

```bash
# Check pods
kubectl get pods -n kube-system -l app.kubernetes.io/name=metrics-server

# Check APIService
kubectl get apiservice v1beta1.metrics.k8s.io

# Test kubectl top
kubectl top nodes
kubectl top pods -A
```

### 3. Create HPA

```bash
# Example: Auto-scale deployment based on CPU
kubectl autoscale deployment nginx --cpu-percent=70 --min=2 --max=10
```

## Configuration Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `namespace` | `kube-system` | Namespace for Metrics Server |
| `replicas` | `2` | Number of replicas (HA) |
| `cpuRequest` | `100m` | CPU request |
| `memoryRequest` | `200Mi` | Memory request |
| `cpuLimit` | `500m` | CPU limit |
| `memoryLimit` | `1Gi` | Memory limit |
| `enablePDB` | `true` | Enable PodDisruptionBudget |

## Examples

### Use with Horizontal Pod Autoscaler

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: backend-api-hpa
  namespace: backend-team
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: backend-api
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
```

**Result**: Deployment automatically scales between 2-10 replicas based on CPU/memory usage!

### View Resource Usage

```bash
# Node resource usage
kubectl top nodes

# Pod resource usage (all namespaces)
kubectl top pods -A

# Pod resource usage (specific namespace)
kubectl top pods -n backend-team

# Sort by CPU/memory
kubectl top pods -A --sort-by=cpu
kubectl top pods -A --sort-by=memory
```

## Monitoring

Check Metrics Server health:
```bash
kubectl get pods -n kube-system -l app.kubernetes.io/name=metrics-server
kubectl logs -n kube-system -l app.kubernetes.io/name=metrics-server
```

Check APIService status:
```bash
kubectl get apiservice v1beta1.metrics.k8s.io
kubectl describe apiservice v1beta1.metrics.k8s.io
```

Test metrics collection:
```bash
# Raw metrics API
kubectl get --raw /apis/metrics.k8s.io/v1beta1/nodes
kubectl get --raw /apis/metrics.k8s.io/v1beta1/pods
```

## Troubleshooting

### kubectl top returns "Metrics API not available"

```bash
# Check Metrics Server pods
kubectl get pods -n kube-system -l app.kubernetes.io/name=metrics-server

# Check APIService
kubectl get apiservice v1beta1.metrics.k8s.io -o yaml

# Check logs
kubectl logs -n kube-system -l app.kubernetes.io/name=metrics-server
```

### HPA shows "<unknown>" for metrics

```bash
# Check HPA status
kubectl describe hpa backend-api-hpa -n backend-team

# Verify Metrics Server is running
kubectl top nodes

# Check if deployment has resource requests (required for HPA)
kubectl get deployment backend-api -n backend-team -o yaml | grep -A 4 resources
```

### Metrics Server cannot connect to kubelets

```bash
# Check Metrics Server logs for errors
kubectl logs -n kube-system -l app.kubernetes.io/name=metrics-server

# Common issues:
# - Network policies blocking kubelet access
# - SecurityGroups not allowing metrics-server → kubelet communication
```

## Resource Sizing

**Small clusters** (< 10 nodes):
- CPU: 100m request, 500m limit
- Memory: 200Mi request, 1Gi limit

**Medium clusters** (10-50 nodes):
- CPU: 200m request, 1000m limit
- Memory: 400Mi request, 2Gi limit

**Large clusters** (50+ nodes):
- CPU: 500m request, 2000m limit
- Memory: 1Gi request, 4Gi limit

## Integration with Other Blueprints

**Works with**:
- VPA (Vertical Pod Autoscaler) - Uses metrics for recommendations
- HPA (built into Kubernetes) - Requires Metrics Server
- Observability blueprint - Metrics Server metrics scraped by ADOT

**Required by**:
- Any workload using HPA
- VPA blueprint (coming soon)
- Right-sizing tools

## Security

Metrics Server is configured with security best practices:
- ✅ Non-root user (UID 1000)
- ✅ Read-only root filesystem
- ✅ Drop all capabilities
- ✅ Secure communication with kubelets
- ✅ TLS for API communication
- ✅ PriorityClass: system-cluster-critical

## For GitOps deployment

See [argocd/README.md](../argocd/README.md) at the repository root.
