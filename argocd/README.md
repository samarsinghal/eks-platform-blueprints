# ArgoCD GitOps Integration

Manage the entire platform through Git using the App of Apps pattern.

## Architecture

```
root-app.yaml                    → Deploys everything below
├── platform/blueprints.yaml     → Registers KRO blueprint templates (sync-wave: 0)
├── platform/example-full.yaml     → Deploys foundation + security instances (sync-wave: 1)
└── teams/team-namespaces.yaml   → Auto-onboards teams from Git (sync-wave: 2)
```

## How It Works

1. **Platform engineers** push changes to Git
2. **ArgoCD** detects changes and syncs to cluster
3. **KRO** reconciles blueprint instances into Kubernetes resources
4. **Teams** self-service by adding a YAML file to `team-services/team-namespace/examples/`

## Setup

```bash
# 1. Update repoURL in all ArgoCD files
find argocd -name "*.yaml" -exec sed -i 's|<YOUR_GIT_REPO_URL>|https://github.com/your-org/eks-platform-blueprints|g' {} \;

# 2. Deploy the root app (everything else is automatic)
kubectl apply -f argocd/root-app.yaml
```

## Onboarding a New Team (GitOps)

```bash
# 1. Create a team YAML file
cat > team-services/team-namespace/examples/my-team.yaml << 'EOF'
apiVersion: platform.company.com/v1alpha1
kind: TeamNamespace
metadata:
  name: my-team
spec:
  teamName: my-team
  clusterName: <YOUR_CLUSTER_NAME>
  region: <YOUR_AWS_REGION>
  accountID: "<YOUR_AWS_ACCOUNT_ID>"
  environment: production
  adminUsers: "admin@company.com"
  developerUsers: "dev1@company.com,dev2@company.com"
  cpuQuota: "10"
  memoryQuota: "20Gi"
EOF

# 2. Commit and push
git add . && git commit -m "Onboard my-team" && git push

# 3. ArgoCD automatically creates the namespace with all resources
```

## Adding a New Environment

Copy `argocd/platform/example-full.yaml`, change the file includes to point to your environment's examples (e.g., `standard.yaml` and `standard.yaml`).

## Sync Waves

| Wave | What | Purpose |
|------|------|---------|
| 0 | Blueprint templates | Register KRO ResourceGraphDefinitions |
| 1 | Platform instances | Deploy foundation + security |
| 2 | Team namespaces | Onboard teams |
