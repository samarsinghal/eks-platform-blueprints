#!/bin/bash
set -e

echo "📋 Installing EKS Platform Prerequisites..."
echo ""

# cert-manager (required by certificate-manager module and OTel operator)
if ! kubectl get deployment cert-manager -n cert-manager &>/dev/null; then
  echo "   └─ Installing cert-manager v1.14.1..."
  kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.1/cert-manager.yaml
  sleep 5
  kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.1/cert-manager.yaml
  kubectl rollout status deployment cert-manager -n cert-manager --timeout=120s
else
  echo "   └─ cert-manager already installed"
fi

# OPA Gatekeeper (required by security blueprint)
if ! kubectl get deployment gatekeeper-controller-manager -n gatekeeper-system &>/dev/null; then
  echo "   └─ Installing OPA Gatekeeper v3.15.1..."
  kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/v3.15.1/deploy/gatekeeper.yaml
  kubectl rollout status deployment gatekeeper-controller-manager -n gatekeeper-system --timeout=120s
else
  echo "   └─ OPA Gatekeeper already installed"
fi

# OpenTelemetry Operator (required by observability module)
if ! kubectl get deployment -n opentelemetry-operator-system -l app.kubernetes.io/name=opentelemetry-operator &>/dev/null; then
  echo "   └─ Installing OpenTelemetry Operator..."
  kubectl apply -f https://github.com/open-telemetry/opentelemetry-operator/releases/download/v0.116.0/opentelemetry-operator.yaml
  sleep 5
  kubectl apply -f https://github.com/open-telemetry/opentelemetry-operator/releases/download/v0.116.0/opentelemetry-operator.yaml
  kubectl rollout status deployment -n opentelemetry-operator-system -l app.kubernetes.io/name=opentelemetry-operator --timeout=120s
  # Fix webhook service name to match cert SAN (upstream bug in v0.116.0)
  kubectl get mutatingwebhookconfiguration opentelemetry-operator-mutating-webhook-configuration -o json | \
    sed 's/opentelemetry-operator-webhook-service/opentelemetry-operator-webhook/g' | kubectl replace -f -
  kubectl get validatingwebhookconfiguration opentelemetry-operator-validating-webhook-configuration -o json | \
    sed 's/opentelemetry-operator-webhook-service/opentelemetry-operator-webhook/g' | kubectl replace -f -
else
  echo "   └─ OpenTelemetry Operator already installed"
fi

echo ""
echo "📋 Patching ESO CRDs..."
for crd in secretstores clustersecretstores externalsecrets clusterexternalsecrets; do
  kubectl patch crd ${crd}.external-secrets.io --type='json' \
    -p='[{"op":"replace","path":"/spec/versions/1/served","value":true}]' 2>/dev/null || true
done

echo ""
echo "✅ Prerequisites installed!"
echo ""
echo "Next: Deploy via ArgoCD or deploy-blueprints.sh"
