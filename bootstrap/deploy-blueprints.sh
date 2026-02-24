#!/bin/bash
set -e

echo "🚀 Deploying EKS Platform Blueprints (Manual Path)..."
echo ""
echo "Use this script if NOT using ArgoCD."
echo "For ArgoCD: run prerequisites.sh then deploy ArgoCD apps."
echo ""

# Install prerequisites
source "$(dirname "$0")/prerequisites.sh"

# Restart KRO to pick up new RBAC
echo "🔄 Restarting KRO controller..."
kubectl rollout restart deployment -n kro-system kro
kubectl rollout status deployment -n kro-system kro --timeout=120s

echo ""
echo "📦 Deploying blueprint templates..."
echo ""

# Tier 1: Platform Foundation
echo "🏗️  Tier 1: Platform Foundation"
kubectl apply -f ../platform/foundation/kro-resourcegroups/
echo "   └─ Individual modules..."
kubectl apply -f ../modules/observability/kro-resourcegroups/
kubectl apply -f ../modules/external-dns/kro-resourcegroups/
kubectl apply -f ../modules/karpenter/kro-resourcegroups/
kubectl apply -f ../modules/metrics-server/kro-resourcegroups/
kubectl apply -f ../modules/external-secrets/kro-resourcegroups/
kubectl apply -f ../modules/centralized-logging/kro-resourcegroups/
kubectl apply -f ../modules/certificate-manager/kro-resourcegroups/
kubectl apply -f ../modules/cost-visibility/kro-resourcegroups/
kubectl apply -f ../modules/ingress-controller/kro-resourcegroups/

echo ""

# Tier 2: Platform Security
echo "🔒 Tier 2: Platform Security"
kubectl apply -f ../platform/security/kro-resourcegroups/

echo ""

# Tier 3: Team Services
echo "👥 Tier 3: Team Services"
kubectl apply -f ../team-services/team-namespace/kro-resourcegroups/
kubectl apply -f ../team-services/ecr-repository/kro-resourcegroups/
kubectl apply -f ../team-services/ingress/kro-resourcegroups/
kubectl apply -f ../team-services/backup-strategy/kro-resourcegroups/

echo ""

# Tier 4: Data Services
echo "💾 Tier 4: Data Services"
kubectl apply -f ../data-services/database/kro-resourcegroups/
kubectl apply -f ../data-services/cache/kro-resourcegroups/
kubectl apply -f ../data-services/queue/kro-resourcegroups/
kubectl apply -f ../data-services/storage/kro-resourcegroups/

echo ""

# Tier 5: AI/ML
echo "🤖 Tier 5: AI/ML"
kubectl apply -f ../ai-ml/gpu-nodepool/kro-resourcegroups/
kubectl apply -f ../ai-ml/bedrock-access/kro-resourcegroups/
kubectl apply -f ../ai-ml/bedrock-agent/kro-resourcegroups/
kubectl apply -f ../ai-ml/bedrock-knowledge-base/kro-resourcegroups/
kubectl apply -f ../ai-ml/notebook/kro-resourcegroups/
kubectl apply -f ../ai-ml/sagemaker-endpoint/kro-resourcegroups/
kubectl apply -f ../ai-ml/training-job/kro-resourcegroups/

echo ""
echo "⏳ Waiting for blueprints to register..."
sleep 15

echo ""
echo "✅ All blueprint templates deployed!"
echo ""
kubectl get resourcegraphdefinition -o custom-columns=NAME:.metadata.name,KIND:.spec.schema.kind,READY:.status.conditions[-1:].status
echo ""
echo "Next: Deploy instances from examples/ directories"
