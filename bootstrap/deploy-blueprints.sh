#!/bin/bash
set -e

echo "🚀 Deploying EKS Platform Blueprints (3-Tier Architecture)..."

# Deploy KRO RBAC
echo "📋 Configuring KRO RBAC..."
kubectl apply -f ../kro-setup/rbac.yaml
kubectl apply -f ../kro-setup/custom-resource-rbac.yaml

# Ensure KRO has permissions to manage all CRDs
kubectl get clusterrolebinding kro-admin-binding &>/dev/null || \
  kubectl create clusterrolebinding kro-admin-binding \
    --clusterrole=cluster-admin \
    --serviceaccount=kro-system:kro

# Restart KRO controller to pick up new permissions
echo "🔄 Restarting KRO controller..."
kubectl rollout restart deployment -n kro-system kro
kubectl rollout status deployment -n kro-system kro --timeout=120s

echo ""
echo "📦 Deploying blueprint templates..."
echo ""

# Tier 1: Platform Foundation
echo "🏗️  Tier 1: Platform Foundation"
kubectl apply -f ../platform/foundation/kro-resourcegroups/

# Deploy individual module templates (for advanced users)
echo "   └─ Individual modules..."
kubectl apply -f ../modules/observability/kro-resourcegroups/
kubectl apply -f ../modules/external-dns/kro-resourcegroups/
kubectl apply -f ../modules/karpenter/kro-resourcegroups/
kubectl apply -f ../modules/metrics-server/kro-resourcegroups/
kubectl apply -f ../modules/external-secrets/kro-resourcegroups/
kubectl apply -f ../modules/centralized-logging/kro-resourcegroups/
kubectl apply -f ../modules/certificate-manager/kro-resourcegroups/
kubectl apply -f ../modules/cost-visibility/kro-resourcegroups/

echo ""

# Tier 2: Platform Security
echo "🔒 Tier 2: Platform Security"
kubectl apply -f ../platform/security/kro-resourcegroups/

echo ""

# Tier 3: Team Services
echo "👥 Tier 3: Team Services"
kubectl apply -f ../team-services/team-namespace/kro-resourcegroups/
kubectl apply -f ../team-services/backup-strategy/kro-resourcegroups/
echo ""

# Wait for blueprints to register
echo "⏳ Waiting for blueprints to register..."
sleep 15

echo ""
echo "✅ All blueprint templates deployed!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Blueprint Status:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
kubectl get resourcegraphdefinition -o custom-columns=NAME:.metadata.name,KIND:.spec.schema.kind,READY:.status.conditions[-1:].status
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Next Steps - Deploy Platform Instances:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Step 1: Deploy Platform Foundation (2 minutes)"
echo "  kubectl apply -f ../platform/foundation/examples/full.yaml"
echo ""
echo "Step 2: Deploy Security Baseline (30 seconds)"
echo "  kubectl apply -f ../platform/security/examples/restricted.yaml"
echo ""
echo "Step 3: Onboard Teams (10 seconds per team)"
echo "  kubectl apply -f ../team-services/team-namespace/examples/backend-team.yaml"
echo ""
