#!/bin/bash
# Verifies HPA auto-scaling occurred during load test
# Usage: ./hpa-verify.sh <namespace> [expected-replicas]

set -euo pipefail

NAMESPACE="${1:-dev}"
MIN_EXPECTED="${2:-2}"
FAILURES=0

echo "=== HPA Status in namespace: $NAMESPACE ==="
kubectl get hpa -n "$NAMESPACE" -o wide

echo ""
echo "=== Checking for scale-up events ==="
for hpa in $(kubectl get hpa -n "$NAMESPACE" -o name); do
  name=$(echo "$hpa" | cut -d/ -f2)
  current=$(kubectl get "$hpa" -n "$NAMESPACE" -o jsonpath='{.status.currentReplicas}')
  desired=$(kubectl get "$hpa" -n "$NAMESPACE" -o jsonpath='{.status.desiredReplicas}')
  
  echo "$name: current=$current desired=$desired"
  
  if [ "$desired" -ge "$MIN_EXPECTED" ] 2>/dev/null; then
    echo "  PASS: $name scaled to $desired replicas"
  else
    echo "  FAIL: $name did not scale (desired=$desired, expected >= $MIN_EXPECTED)"
    FAILURES=$((FAILURES + 1))
  fi
done

echo ""
echo "Scale-up failures: $FAILURES"
exit "$FAILURES"
