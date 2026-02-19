#!/bin/bash

echo "=========================================="
echo "EKS Platform Blueprints - Health Check"
echo "=========================================="
echo ""

ERRORS=0
WARNINGS=0

# Check cluster connectivity
echo "🔍 Checking cluster connectivity..."
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot connect to cluster"
    ERRORS=$((ERRORS + 1))
else
    CLUSTER_NAME=$(kubectl config current-context)
    echo "✓ Connected to: $CLUSTER_NAME"
fi
echo ""

# Check EKS add-ons
echo "🔍 Checking EKS add-ons..."
REQUIRED_ADDONS=("kro" "argo-cd" "ack-iam" "ack-eks" "ack-prometheusservice")

for addon in "${REQUIRED_ADDONS[@]}"; do
    if kubectl get namespace "${addon}-system" &> /dev/null 2>&1 || \
       kubectl get namespace "argocd" &> /dev/null 2>&1 || \
       kubectl get namespace "kro-system" &> /dev/null 2>&1; then
        echo "  ✓ $addon"
    else
        echo "  ❌ $addon (not found)"
        ERRORS=$((ERRORS + 1))
    fi
done
echo ""

# Check KRO RBAC
echo "🔍 Checking KRO RBAC configuration..."
if kubectl get clusterrole eks-capabilities-kro-access &> /dev/null; then
    echo "  ✓ ClusterRole exists"
    
    # Check for required API groups
    REQUIRED_GROUPS=("observability.company.com" "metrics.company.com" "externaldns.company.com" "secrets.company.com" "karpenter.company.com" "security.company.com")
    MISSING_GROUPS=()
    
    for group in "${REQUIRED_GROUPS[@]}"; do
        if ! kubectl get clusterrole eks-capabilities-kro-access -o yaml | grep -q "$group"; then
            MISSING_GROUPS+=("$group")
        fi
    done
    
    if [ ${#MISSING_GROUPS[@]} -eq 0 ]; then
        echo "  ✓ All required API groups configured"
    else
        echo "  ⚠️  Missing API groups: ${MISSING_GROUPS[*]}"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo "  ❌ ClusterRole not found"
    ERRORS=$((ERRORS + 1))
fi

if kubectl get clusterrolebinding kro-controller-access &> /dev/null; then
    echo "  ✓ Controller binding exists"
else
    echo "  ❌ Controller binding not found"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Check KRO controller health
echo "🔍 Checking KRO controller..."
if kubectl get deployment -n kro-system kro &> /dev/null; then
    READY=$(kubectl get deployment -n kro-system kro -o jsonpath='{.status.readyReplicas}')
    DESIRED=$(kubectl get deployment -n kro-system kro -o jsonpath='{.spec.replicas}')
    
    if [ "$READY" == "$DESIRED" ]; then
        echo "  ✓ Controller healthy ($READY/$DESIRED)"
    else
        echo "  ❌ Controller not ready ($READY/$DESIRED)"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "  ❌ Controller deployment not found"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Check ResourceGraphDefinitions
echo "🔍 Checking deployed blueprints..."
RGD_COUNT=$(kubectl get resourcegraphdefinitions --no-headers 2>/dev/null | wc -l | tr -d ' ')

if [ "$RGD_COUNT" -gt 0 ]; then
    echo "  ✓ $RGD_COUNT blueprints deployed"
    kubectl get resourcegraphdefinitions -o custom-columns=NAME:.metadata.name,AGE:.metadata.creationTimestamp --no-headers | sed 's/^/    /'
else
    echo "  ⚠️  No blueprints deployed yet"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# Check for common issues
echo "🔍 Checking for common issues..."

# Check if capability is degraded
if kubectl get events -A --field-selector reason=AccessDenied 2>/dev/null | grep -q "capabilities.eks.amazonaws.com"; then
    echo "  ⚠️  Found AccessDenied events for EKS capability"
    echo "     Run: kubectl get events -A --field-selector reason=AccessDenied"
    WARNINGS=$((WARNINGS + 1))
else
    echo "  ✓ No AccessDenied events"
fi
echo ""

# Summary
echo "=========================================="
echo "Summary"
echo "=========================================="
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "✅ All checks passed! Platform is healthy."
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo "⚠️  $WARNINGS warning(s) found"
    echo ""
    echo "Platform is functional but has minor issues."
    exit 0
else
    echo "❌ $ERRORS error(s) and $WARNINGS warning(s) found"
    echo ""
    echo "Platform has critical issues that need attention."
    echo ""
    echo "Common fixes:"
    echo "  1. Deploy RBAC: kubectl apply -f bootstrap/kro-rbac.yaml"
    echo "  2. Restart KRO: kubectl rollout restart deployment -n kro-system kro"
    echo "  3. Check logs: kubectl logs -n kro-system deployment/kro"
    echo ""
    exit 1
fi
