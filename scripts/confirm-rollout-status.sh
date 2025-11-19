#!/bin/bash

set -e

daemonset=$1
namespace=$2

# Wait for daemonset to roll out
echo "Waiting for daemonset ${daemonset} to roll out in namespace ${namespace}..."
kubectl rollout status ds "${daemonset}" -n "${namespace}" --timeout 30m

# Get the label selector from the daemonset to ensure we check the right pods
label_selector=$(kubectl get ds "${daemonset}" -n "${namespace}" -o jsonpath='{.spec.selector.matchLabels}' | jq -r 'to_entries | map("\(.key)=\(.value)") | join(",")')

if [ -z "$label_selector" ]; then
  echo "ERROR: Could not determine label selector for daemonset ${daemonset}"
  exit 1
fi

# Validate that all pods are actually running and healthy (not CrashLoopBackOff, ImagePullBackOff, etc.)
echo "Validating pod health status..."
not_ready=$(kubectl get pods -n "${namespace}" -l "${label_selector}" \
  --field-selector=status.phase!=Running -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)

if [ -n "$not_ready" ]; then
  echo "ERROR: The following pods are not in Running phase: $not_ready"
  echo "Pod status details:"
  kubectl get pods -n "${namespace}" -l "${label_selector}" -o wide
  echo ""
  echo "Pod event logs:"
  for pod in $not_ready; do
    echo "=== Events for pod $pod ==="
    kubectl describe pod "$pod" -n "${namespace}" | grep -A 20 "Events:" || true
  done
  exit 1
fi

# Validate that all containers are ready
echo "Validating container readiness..."
not_ready_containers=$(kubectl get pods -n "${namespace}" -l "${label_selector}" \
  -o jsonpath='{.items[*].status.containerStatuses[?(@.ready==false)].name}' 2>/dev/null)

if [ -n "$not_ready_containers" ]; then
  echo "ERROR: The following containers are not ready: $not_ready_containers"
  kubectl get pods -n "${namespace}" -l "${label_selector}" -o wide
  exit 1
fi

# Validate that init containers have completed successfully (if any exist)
echo "Validating init container completion..."
init_container_failures=$(kubectl get pods -n "${namespace}" -l "${label_selector}" \
  -o jsonpath='{.items[*].status.initContainerStatuses[?(@.ready==false)].name}' 2>/dev/null)

if [ -n "$init_container_failures" ]; then
  echo "ERROR: The following init containers failed or are not ready: $init_container_failures"
  echo "Init container status details:"
  kubectl get pods -n "${namespace}" -l "${label_selector}" -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{range .status.initContainerStatuses[*]}{"\t"}{.name}: ready={.ready}, restartCount={.restartCount}, state={.state}{"\n"}{end}{"\n"}{end}'
  echo ""
  echo "Pod events:"
  for pod in $(kubectl get pods -n "${namespace}" -l "${label_selector}" -o jsonpath='{.items[*].metadata.name}'); do
    echo "=== Events for pod $pod ==="
    kubectl describe pod "$pod" -n "${namespace}" | grep -A 20 "Events:" || true
  done
  exit 1
fi

echo "✓ All pods are healthy and running"
echo "✓ All init containers completed successfully"
