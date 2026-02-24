# EKS Platform Config — Example Private Repository

This directory contains a complete reference implementation for your private configuration repository. Copy this entire directory to create your own private config repo.

## What This Is

This is a **starter template** for your private configuration repository that works with the public [eks-platform-blueprints](https://github.com/your-org/eks-platform-blueprints) repository.

**Two-Repo Architecture**:
- **Public repo** (`eks-platform-blueprints`): Reusable KRO templates and blueprints
- **Private repo** (this directory): Your actual configurations with sensitive values

## Quick Start

### 1. Copy to Your Private Repository

```bash
# Create a new private Git repository
git init eks-platform-config
cd eks-platform-config

# Copy this examples directory
cp -r /path/to/eks-platform-blueprints/examples/* .

# Initialize Git
git add .
git commit -m "Initial platform configuration"
git remote add origin <YOUR_PRIVATE_REPO_URL>
git push -u origin main
```

### 2. Replace All Placeholders

Search and replace the following placeholders with your actual values:

| Placeholder | Description | Example |
|-------------|-------------|---------|
| `<YOUR_CLUSTER_NAME>` | EKS cluster name | `production-cluster` |
| `<YOUR_AWS_REGION>` | AWS region | `us-east-1` |
| `<YOUR_AWS_ACCOUNT_ID>` | AWS account ID | `123456789012` |
| `<YOUR_AMP_WORKSPACE_ID>` | Amazon Managed Prometheus workspace ID | `ws-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `<YOUR_AMP_REMOTE_WRITE_ENDPOINT>` | AMP remote write endpoint | `https://aps-workspaces.us-east-1.amazonaws.com/workspaces/ws-xxx/api/v1/remote_write` |
| `<YOUR_HOSTED_ZONE_ID>` | Route53 hosted zone ID | `Z0123456789ABCDEF` |
| `<YOUR_DOMAIN>` | Domain name for DNS | `platform.example.com` |
| `<ADMIN_USER_EMAIL>` | Admin user email | `admin@example.com` |
| `<DEV_USER_1_EMAIL>` | Developer user email | `dev1@example.com` |
| `<YOUR_S3_BUCKET_URI>` | S3 bucket URI | `s3://my-bucket/path/` |
| `<YOUR_BLUEPRINTS_REPO_URL>` | Public blueprints repo URL | `https://github.com/your-org/eks-platform-blueprints` |
| `<YOUR_CONFIG_REPO_URL>` | Private config repo URL | `https://git-codecommit.us-east-1.amazonaws.com/v1/repos/eks-platform-config` |
| `<YOUR_CLUSTER_ARN>` | EKS cluster ARN | `arn:aws:eks:us-east-1:123456789012:cluster/my-cluster` |

**Automated replacement** (use with caution):
```bash
# Example: Replace cluster name
find . -type f -name "*.yaml" -exec sed -i '' 's/<YOUR_CLUSTER_NAME>/production-cluster/g' {} \;

# Replace AWS account ID
find . -type f -name "*.yaml" -exec sed -i '' 's/<YOUR_AWS_ACCOUNT_ID>/123456789012/g' {} \;

# Replace region
find . -type f -name "*.yaml" -exec sed -i '' 's/<YOUR_AWS_REGION>/us-east-1/g' {} \;
```

### 3. Deploy with ArgoCD

```bash
# Step 1: Deploy blueprint templates from public repo (sync-wave: 0)
kubectl apply -f argocd/blueprints-app.yaml

# Step 2: Deploy your configurations from private repo (sync-wave: 1)
kubectl apply -f argocd/root-app.yaml

# ArgoCD will automatically sync and deploy everything
```

## Directory Structure

```
eks-platform-config/
├── README.md                    # This file
│
├── argocd/                      # ArgoCD GitOps setup
│   ├── blueprints-app.yaml     # Deploys templates from public repo
│   └── root-app.yaml           # Deploys configs from this private repo
│
├── platform/                    # Platform-level configurations
│   ├── foundation.yaml         # Infrastructure (observability, DNS, compute, etc.)
│   └── security.yaml           # Security baseline (pod security, RBAC, policies)
│
├── teams/                       # Team namespace configurations
│   ├── backend-team.yaml       # Backend team namespace with RBAC
│   └── ml-team.yaml            # ML team namespace with RBAC
│
├── data-services/               # AWS managed data services
│   ├── backend-db.yaml         # Aurora PostgreSQL database
│   └── backend-cache-queue.yaml # ElastiCache Redis + SQS queue
│
└── ai-ml/                       # AI/ML platform configurations
    └── ml-platform.yaml        # GPU nodepool + Bedrock access + Knowledge base
```

## Configuration Files Explained

### Platform Foundation (`platform/foundation.yaml`)

Deploys complete infrastructure in ~2 minutes:
- **Observability**: Amazon Managed Prometheus + Grafana + ADOT collectors
- **DNS**: ExternalDNS with Route53 integration
- **Compute**: Karpenter NodePools with spot instances
- **Metrics**: Metrics Server for HPA
- **Secrets**: External Secrets Operator with AWS Secrets Manager
- **Logging**: Centralized logging to CloudWatch/OpenSearch

### Platform Security (`platform/security.yaml`)

Security baseline and governance:
- **Pod Security Standards**: Restricted profile enforcement
- **Image Security**: Registry allowlist, block latest tags
- **Resource Governance**: Required labels, resource limits
- **Network Policies**: Default deny ingress
- **RBAC**: Cluster viewer role, audit cluster admin

### Team Namespaces (`teams/*.yaml`)

Self-service team onboarding:
- Namespace with RBAC (admin/developer roles)
- Resource quotas (CPU, memory)
- Network policies
- Secrets access (AWS Secrets Manager)
- AWS service access (S3, DynamoDB, SQS)

### Data Services (`data-services/*.yaml`)

AWS managed data services via ACK:
- **Database**: Aurora PostgreSQL/MySQL
- **Cache**: ElastiCache Serverless Redis
- **Queue**: SQS with encryption
- **Storage**: S3 buckets (not shown, add as needed)

### AI/ML Platform (`ai-ml/*.yaml`)

AI/ML infrastructure:
- **GPU NodePool**: Karpenter GPU nodes for inference
- **Bedrock Access**: Foundation model access with guardrails
- **Knowledge Base**: RAG with S3 data source

## Customization Guide

### Adding a New Team

1. Copy an existing team file:
```bash
cp teams/backend-team.yaml teams/new-team.yaml
```

2. Update the team name and settings:
```yaml
metadata:
  name: new-team
spec:
  teamName: new-team
  adminUsers: "admin@example.com"
  developerUsers: "dev1@example.com,dev2@example.com"
  cpuQuota: "10"
  memoryQuota: "20Gi"
```

3. Commit and push:
```bash
git add teams/new-team.yaml
git commit -m "Add new-team namespace"
git push
```

ArgoCD automatically creates the namespace within seconds!

### Adding a Database for a Team

1. Create a database configuration:
```bash
cat > data-services/new-team-db.yaml << 'EOF'
apiVersion: data.company.com/v1alpha1
kind: TeamDatabase
metadata:
  name: new-team-db
spec:
  teamName: new-team
  clusterName: <YOUR_CLUSTER_NAME>
  region: <YOUR_AWS_REGION>
  accountID: "<YOUR_AWS_ACCOUNT_ID>"
  engine: aurora-postgresql
  engineVersion: "16.1"
  instanceClass: db.r6g.large
  databaseName: appdb
  backupRetentionPeriod: 7
  deletionProtection: true
EOF
```

2. Commit and push - ArgoCD deploys automatically!

### Changing Security Profile

Edit `platform/security.yaml`:

```yaml
spec:
  securityProfile: standard  # Change from 'restricted' to 'standard'
  policyEnforcement:
    mode: warn  # Change from 'deny' to 'warn' for testing
```

## Multi-Environment Setup

Create separate directories for each environment:

```
eks-platform-config/
├── production/
│   ├── platform/
│   ├── teams/
│   └── argocd/
├── staging/
│   ├── platform/
│   ├── teams/
│   └── argocd/
└── development/
    ├── platform/
    ├── teams/
    └── argocd/
```

Or use branches:
- `main` → production
- `staging` → staging environment
- `dev` → development environment

## Security Best Practices

1. **Never commit sensitive values**:
   - Use AWS Secrets Manager for secrets
   - Reference secrets in manifests, don't embed them

2. **Use private Git repository**:
   - GitHub private repo
   - AWS CodeCommit
   - GitLab private repo

3. **Enable branch protection**:
   - Require pull request reviews
   - Require status checks
   - Restrict who can push

4. **Audit access**:
   - Review who has access to this repo
   - Use least privilege IAM roles
   - Enable CloudTrail for Git operations

## Troubleshooting

### ArgoCD Not Syncing

```bash
# Check ArgoCD application status
kubectl get applications -n argocd

# View application details
kubectl describe application platform-config -n argocd

# Check ArgoCD logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller
```

### Platform Foundation Not Deploying

```bash
# Check if KRO templates are registered
kubectl get resourcegraphdefinitions

# Check platform foundation status
kubectl get eksplatformfoundation production -o yaml

# Check KRO controller logs
kubectl logs -n kro-system -l app=kro
```

### Team Namespace Not Created

```bash
# Check if TeamNamespace resource exists
kubectl get teamnamespace

# Check status
kubectl describe teamnamespace backend-team

# Verify RBAC
kubectl get rolebinding -n backend
```

## Support

For issues with:
- **Blueprint templates**: Open issue in public `eks-platform-blueprints` repo
- **Your configurations**: Check this private repo's documentation
- **ArgoCD**: Check ArgoCD logs and application status
- **KRO**: Check KRO controller logs

## Next Steps

1. ✅ Copy this directory to your private repo
2. ✅ Replace all placeholders with actual values
3. ✅ Deploy ArgoCD applications
4. ✅ Verify platform is running
5. ✅ Onboard your first team
6. ✅ Add data services as needed
7. ✅ Set up CI/CD pipelines

---

**Remember**: This is YOUR private configuration repository. Customize it to match your organization's needs!
