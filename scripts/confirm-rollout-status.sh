#!/bin/bash

set -e

release_name=${1:-sysdig-agent}
namespace=${2:-ibm-observe}

# Determine the fullname based on Helm chart naming logic
# If release_name contains "agent", use it as-is; otherwise append "-agent"
if [[ "$release_name" == *"agent"* ]]; then
  fullname="$release_name"
else
  fullname="${release_name}-agent"
fi

echo "Checking rollout status for monitoring agent components (release: ${release_name}, namespace: ${namespace})..."
echo ""

# Check agent daemonset (always deployed)
echo "Checking ${fullname} daemonset..."
kubectl rollout status ds/"${fullname}" -n "${namespace}" --timeout 30m
echo "✓ ${fullname} daemonset rolled out successfully"
echo ""

# Check host-scanner daemonset (if deployed)
if kubectl get ds "${fullname}-host-scanner" -n "${namespace}" &>/dev/null; then
  echo "Checking ${fullname}-host-scanner daemonset..."
  kubectl rollout status ds/"${fullname}-host-scanner" -n "${namespace}" --timeout 30m
  echo "✓ ${fullname}-host-scanner daemonset rolled out successfully"
  echo ""
fi

# Check kspm-analyzer daemonset (if deployed)
if kubectl get ds "${fullname}-kspm-analyzer" -n "${namespace}" &>/dev/null; then
  echo "Checking ${fullname}-kspm-analyzer daemonset..."
  kubectl rollout status ds/"${fullname}-kspm-analyzer" -n "${namespace}" --timeout 30m
  echo "✓ ${fullname}-kspm-analyzer daemonset rolled out successfully"
  echo ""
fi

# Check cluster-shield deployment (if deployed)
if kubectl get deployment "${fullname}-clustershield" -n "${namespace}" &>/dev/null; then
  echo "Checking ${fullname}-clustershield deployment..."
  kubectl rollout status deployment/"${fullname}-clustershield" -n "${namespace}" --timeout 30m
  echo "✓ ${fullname}-clustershield deployment rolled out successfully"
  echo ""
fi

echo "✓ All monitoring agent components successfully rolled out"
