#!/bin/bash

set -e

daemonset=$1
namespace=$2

echo "Waiting for daemonset ${daemonset} to roll out in namespace ${namespace}..."
kubectl rollout status ds "${daemonset}" -n "${namespace}" --timeout 30m
echo "Daemonset ${daemonset} successfully rolled out"
