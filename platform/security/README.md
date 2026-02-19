# Platform Security: Governance and Compliance Baseline

Deploy a comprehensive security baseline for your EKS cluster with a single Kubernetes resource.

## What Gets Deployed

One `EKSPlatformSecurity` resource creates:

- **Pod Security Standards**: Enforce restricted/baseline/privileged policies
- **OPA Gatekeeper**: Policy enforcement with audit logging
- **Image Security**: Registry allowlists, block :latest tags
- **Resource Governance**: Enforce resource limits and required labels
- **Network Policies**: Default deny ingress, DNS egress
- **RBAC Baseline**: Cluster-wide RBAC policies and audit

## Security Profiles

### Restricted (Production)

Strictest security for production workloads:

```yaml
apiVersion: platform.company.com/v1alpha1
kind: EKSPlatformSecurity
metadata:
  name: restricted
spec:
  clusterName: production
  securityProfile: restricted
  
  policyEnforcement:
    mode: deny  # Block non-compliant resources
  
  podSecurity:
    defaultLevel: restricted  # No privileged containers
  
  imageSecurity:
    enableAllowlist: true
    allowedRegistries:
      - "<YOUR_AWS_ACCOUNT_ID>.dkr.ecr.<YOUR_AWS_REGION>.amazonaws.com"
    blockLatestTag: true
  
  resourceGovernance:
    enforceResourceLimits: true
    requiredLabels: [team, environment, cost-center]
  
  networkPolicies:
    defaultDenyIngress: true
```

### Standard (Staging)

Balanced security for non-production:

```yaml
spec:
  securityProfile: standard
  
  podSecurity:
    defaultLevel: baseline  # Some privileged features allowed
  
  imageSecurity:
    enableAllowlist: false  # Any registry
    blockLatestTag: true    # Still block :latest
  
  resourceGovernance:
    enforceResourceLimits: true
    requiredLabels: [team, environment]
```

### Permissive (Development)

Minimal restrictions for development:

```yaml
spec:
  securityProfile: permissive
  
  policyEnforcement:
    mode: warn  # Don't block, just warn
  
  podSecurity:
    defaultLevel: baseline
  
  imageSecurity:
    enableAllowlist: false
    blockLatestTag: false  # Allow :latest in dev
  
  resourceGovernance:
    enforceResourceLimits: false
```

## Quick Start

```bash
# 1. Deploy blueprint template (one-time)
kubectl apply -f kro-resourcegroups/eks-platform-security.yaml

# 2. Deploy security baseline
kubectl apply -f examples/restricted.yaml

# 3. Verify
kubectl get eksplatformsecurity restricted
kubectl get securityprofile,rbacprofile
```

## Policy Enforcement Modes

### Deny Mode (Production)
- **Blocks** non-compliant resources
- Resources fail to create if they violate policies
- Use for production environments

### Dryrun Mode (Testing)
- **Logs** violations but allows creation
- Use for testing policies before enforcement
- Review audit logs for violations

### Warn Mode (Development)
- **Warns** about violations
- Allows all resources to be created
- Use for development environments

## Pod Security Standards

### Restricted
- No privileged containers
- No host namespaces (network, PID, IPC)
- No host ports
- No host paths
- Limited capabilities
- Required: runAsNonRoot, seccompProfile, drop ALL capabilities

### Baseline
- No privileged containers
- No host namespaces
- Limited host ports
- Some capabilities allowed

### Privileged
- No restrictions
- Use only for system namespaces

## Image Security

### Registry Allowlist

Only allow images from approved registries:

```yaml
imageSecurity:
  enableAllowlist: true
  allowedRegistries:
    - "<YOUR_AWS_ACCOUNT_ID>.dkr.ecr.<YOUR_AWS_REGION>.amazonaws.com"
    - "public.ecr.aws"
    - "docker.io/library"  # Official Docker images
```

### Block :latest Tag

Prevent use of :latest tag (non-deterministic):

```yaml
imageSecurity:
  blockLatestTag: true
```

## Resource Governance

### Enforce Resource Limits

Require all containers to have resource limits:

```yaml
resourceGovernance:
  enforceResourceLimits: true
```

Blocks pods without:
- `resources.requests.cpu`
- `resources.requests.memory`
- `resources.limits.cpu`
- `resources.limits.memory`

### Required Labels

Enforce labeling standards:

```yaml
resourceGovernance:
  enforceRequiredLabels: true
  requiredLabels:
    - team
    - environment
    - cost-center
    - application
```

## Network Policies

### Default Deny Ingress

Block all ingress traffic by default:

```yaml
networkPolicies:
  defaultDenyIngress: true
```

Teams must explicitly allow ingress in their namespaces.

### Default Deny Egress

Block all egress traffic by default (strict):

```yaml
networkPolicies:
  defaultDenyEgress: true
```

⚠️ **Warning**: This blocks DNS and external traffic. Teams must explicitly allow egress.

## RBAC Baseline

### Cluster-Wide Policies

```yaml
rbac:
  enabled: true
  defaultViewerAccess: false  # No default read access
  auditClusterAdmin: true     # Log cluster-admin usage
```

### Audit Cluster Admin

Logs all actions by cluster-admin users for security auditing.

## Excluded Namespaces

Security policies don't apply to system namespaces:

- `kube-system`
- `kube-public`
- `kube-node-lease`
- `karpenter`
- `external-secrets-system`
- `observability-system`
- `external-dns-system`
- `ingress-system`
- `logging-system`

## Validation

```bash
# Check security baseline
kubectl get eksplatformsecurity restricted -o yaml

# Verify policies
kubectl get securityprofile
kubectl get constraints  # OPA Gatekeeper constraints

# Check violations (audit logs)
kubectl get constraint -o yaml | grep violations

# Test policy (should fail in deny mode)
kubectl run test --image=nginx:latest  # Blocked if blockLatestTag=true
```

## Troubleshooting

### Policy blocking legitimate workloads

1. Check constraint violations:
```bash
kubectl get constraint <constraint-name> -o yaml
```

2. Switch to dryrun mode temporarily:
```bash
kubectl patch eksplatformsecurity restricted --type=merge -p '{"spec":{"policyEnforcement":{"mode":"dryrun"}}}'
```

3. Review audit logs, adjust policies, switch back to deny mode

### Namespace not excluded

Add to excluded namespaces in the blueprint template.

## Best Practices

1. **Start with dryrun**: Test policies before enforcing
2. **Gradual rollout**: Start with permissive, move to standard, then restricted
3. **Monitor violations**: Review audit logs regularly
4. **Document exceptions**: Use annotations for policy exceptions
5. **Team training**: Educate teams on security requirements

## Next Steps

After deploying security baseline:

1. **Review violations**: `kubectl get constraints -o yaml`
2. **Adjust policies**: Update security profile as needed
3. **Onboard teams**: Teams inherit security policies automatically
4. **Monitor compliance**: Set up alerts for policy violations

## Related Resources

- [Platform Foundation](../foundation/README.md)
- [Team Services](../../team-services/team-namespace/README.md)
- [OPA Gatekeeper](https://open-policy-agent.github.io/gatekeeper/)
- [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
