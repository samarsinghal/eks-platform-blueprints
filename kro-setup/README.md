# KRO Additional Permissions

Extends KRO controller permissions for custom API groups used by platform blueprints.

## Overview

The EKS KRO capability uses **RBAC aggregation**. Any ClusterRole with label `rbac.kro.run/aggregate-to-controller: "true"` automatically aggregates into the KRO controller's permissions.

This is the **official extension mechanism** provided by the EKS capability.

## Usage

**Apply once per cluster:**
```bash
kubectl apply -f rbac.yaml
```

No restart needed - aggregation happens automatically within seconds.

## What's Included

Permissions for:
- **Custom API groups**: All `*.company.com` groups used by blueprints
- **Core Kubernetes**: Namespaces, Services, ConfigMaps, Secrets, etc.
- **ACK Controllers**: IAM, EKS, Prometheus, CloudWatch, ELBv2
- **Third-party operators**: Karpenter, ExternalDNS, External Secrets, Gatekeeper, Velero

## Adding New API Groups

When creating a new blueprint with a custom API group:

1. Add the API group to `rbac.yaml` under the first rule
2. Apply: `kubectl apply -f rbac.yaml`
3. KRO automatically picks it up (no restart needed)

## Verification

```bash
# Check the ClusterRole exists
kubectl get clusterrole kro:controller:additional-permissions

# Verify aggregation label
kubectl get clusterrole kro:controller:additional-permissions -o jsonpath='{.metadata.labels}'
```

## Why This File Exists

While KRO provides the aggregation mechanism, you must **declare which API groups** your blueprints use. This file is that declaration.

**Think of it as**: EKS provides the capability → You configure which APIs to manage
