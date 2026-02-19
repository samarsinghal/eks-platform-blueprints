# External Secrets Operator Blueprint

Automatically sync secrets from AWS Secrets Manager and SSM Parameter Store into Kubernetes Secrets with continuous updates.

## Overview

This blueprint deploys External Secrets Operator with:
- **Continuous secret sync** from AWS → Kubernetes
- **Automatic rotation** when secrets change in AWS
- **Multiple backends** (Secrets Manager, Parameter Store)
- **ClusterSecretStore** for organization-wide configuration
- **Pod Identity authentication** for AWS access
- **GitOps-friendly** (ExternalSecret CRDs in Git, actual secrets in AWS)

## Why External Secrets Operator?

**vs. Secrets CSI Driver**:
- ✅ **Continuous sync** (CSI = one-time mount at pod start)
- ✅ **GitOps-friendly** (ExternalSecret CRD can be in Git)
- ✅ **Automatic rotation** (no pod restart needed)
- ✅ **Multi-namespace** (ClusterSecretStore shared across namespaces)

**Benefits**:
- Secrets never stored in Git (only paths/references)
- Centralized secret management in AWS
- Automatic propagation of secret updates
- Audit trail in AWS CloudTrail

## Architecture

```
AWS Secrets Manager → External Secrets Operator → Kubernetes Secret
                              ↓ (sync every 1h)
                          Pod Identity
```

**Resources Created** (11):
1. Namespace
2. IAM Policy (Secrets Manager + SSM access)
3. IAM Role (Pod Identity)
4. Pod Identity Association
5. ServiceAccount
6. Deployment (operator controller, 2 replicas)
7. ClusterSecretStore (AWS Secrets Manager)
8. ClusterSecretStore (AWS Parameter Store, optional)
9. Service (metrics)
10. PodDisruptionBudget
11. Status outputs

## Prerequisites

**External Secrets CRDs** must be installed:
```bash
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets \
  --namespace external-secrets-system \
  --create-namespace \
  --set installCRDs=true
```

Or use kubectl:
```bash
kubectl apply -f https://raw.githubusercontent.com/external-secrets/external-secrets/main/deploy/crds/bundle.yaml
```

## Quick Start

### 1. Create Secret in AWS Secrets Manager

```bash
aws secretsmanager create-secret \
  --name eks/production/database/credentials \
  --description "Database credentials for backend team" \
  --secret-string '{
    "username": "dbuser",
    "password": "supersecret",
    "host": "db.example.com",
    "port": "5432"
  }' \
  --region us-west-2
```

### 2. Deploy External Secrets Operator

```bash
# Deploy blueprint
kubectl apply -f external-secrets/kro-resourcegroups/external-secrets-operator.yaml

# Deploy operator instance
kubectl apply -f external-secrets/examples/clusters/production-eso.yaml
```

### 3. Create ExternalSecret to Sync

```bash
kubectl apply -f external-secrets/examples/secrets/database-secret.yaml
```

### 4. Verify Secret Created

```bash
# Check ExternalSecret status
kubectl get externalsecret database-credentials -n backend-team

# Check synced Kubernetes Secret
kubectl get secret database-credentials -n backend-team

# View secret data (base64 decoded)
kubectl get secret database-credentials -n backend-team -o jsonpath='{.data.username}' | base64 -d
```

## Configuration Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `clusterName` | - | EKS cluster name |
| `region` | - | AWS region |
| `accountID` | - | AWS account ID |
| `operatorNamespace` | `external-secrets-system` | Operator namespace |
| `syncInterval` | `1h` | Secret refresh interval |
| `secretsPrefix` | `eks` | AWS secrets path prefix |
| `enableSecretsManager` | `true` | Enable Secrets Manager backend |
| `enableParameterStore` | `false` | Enable SSM Parameter Store |
| `cpuRequest/Limit` | `100m/500m` | CPU resources |
| `memoryRequest/Limit` | `128Mi/512Mi` | Memory resources |

## Examples

### Sync Database Credentials

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: database-credentials
  namespace: backend-team
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets-manager
    kind: ClusterSecretStore
  target:
    name: database-credentials
  data:
    - secretKey: username
      remoteRef:
        key: eks/production/database/credentials
        property: username
    - secretKey: password
      remoteRef:
        key: eks/production/database/credentials
        property: password
```

### Sync Entire Secret (All Fields)

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: api-keys
  namespace: backend-team
spec:
  refreshInterval: 15m
  secretStoreRef:
    name: aws-secrets-manager
    kind: ClusterSecretStore
  target:
    name: api-keys
  dataFrom:
    - extract:
        key: eks/production/api-keys
```

### Use in Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-api
spec:
  template:
    spec:
      containers:
        - name: api
          image: backend:latest
          env:
            - name: DB_USERNAME
              valueFrom:
                secretKeyRef:
                  name: database-credentials
                  key: username
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: database-credentials
                  key: password
```

## Secret Rotation

When you update a secret in AWS Secrets Manager:

1. **ESO detects change** (within `refreshInterval`)
2. **Updates Kubernetes Secret** automatically
3. **Pods see new value** (env vars require pod restart, volume mounts are immediate)

**Force immediate sync**:
```bash
kubectl annotate externalsecret database-credentials \
  force-sync=$(date +%s) \
  -n backend-team
```

## Namespace-Scoped SecretStore

For namespace-specific access:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: team-secrets
  namespace: backend-team
spec:
  provider:
    aws:
      service: SecretsManager
      region: us-west-2
      auth:
        jwt:
          serviceAccountRef:
            name: backend-team-sa
```

## Security Best Practices

1. **Use specific IAM paths**: `eks/production/*` not `*`
2. **Enable KMS encryption**: Secrets Manager with customer-managed keys
3. **Rotate secrets regularly**: Set up AWS Secrets Manager rotation
4. **Use short refresh intervals**: For sensitive secrets (15m)
5. **Audit access**: Monitor CloudTrail for secret access
6. **Never commit secrets**: Only commit ExternalSecret CRDs

## Monitoring

Check operator health:
```bash
kubectl get pods -n external-secrets-system
kubectl logs -n external-secrets-system -l app.kubernetes.io/name=external-secrets
```

Check sync status:
```bash
kubectl get externalsecret --all-namespaces
kubectl describe externalsecret database-credentials -n backend-team
```

Metrics endpoint:
```bash
kubectl port-forward -n external-secrets-system svc/external-secrets-operator-metrics 8080:8080
curl localhost:8080/metrics
```

## Troubleshooting

### ExternalSecret stuck in "SecretSyncedError"

```bash
# Check operator logs
kubectl logs -n external-secrets-system -l app.kubernetes.io/component=controller

# Check IAM permissions
kubectl exec -n external-secrets-system <pod> -- \
  aws secretsmanager get-secret-value --secret-id eks/production/test

# Check ClusterSecretStore
kubectl describe clustersecretstore aws-secrets-manager
```

### Secret not updating

```bash
# Check refresh interval
kubectl get externalsecret -n backend-team -o yaml | grep refreshInterval

# Force sync
kubectl annotate externalsecret database-credentials force-sync=$(date +%s) -n backend-team

# Check secret modification time in AWS
aws secretsmanager describe-secret --secret-id eks/production/database/credentials
```

## Integration with Team Onboarding

Replace CSI driver with External Secrets in team-onboarding blueprint:

1. Deploy External Secrets Operator (this blueprint)
2. Teams create `ExternalSecret` CRDs in their namespace
3. Secrets automatically synced from AWS

## For GitOps deployment

See [argocd/README.md](../argocd/README.md) at the repository root.
