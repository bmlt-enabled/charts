#!/usr/bin/env bash
# Verify the installed bmlt-server responds over HTTP via port-forward.
set -euo pipefail

NAMESPACE="${NAMESPACE:-bmlt}"
RELEASE="${RELEASE:-bmlt}"
LOCAL_PORT="${LOCAL_PORT:-8000}"

command -v kubectl >/dev/null 2>&1 || { echo "error: kubectl not found in PATH" >&2; exit 1; }

echo "==> Waiting for deployment rollout"
kubectl rollout status -n "$NAMESPACE" "deployment/${RELEASE}-bmlt-server" --timeout=300s

echo "==> Port-forwarding svc/${RELEASE}-bmlt-server :${LOCAL_PORT} -> 8000"
kubectl port-forward -n "$NAMESPACE" "svc/${RELEASE}-bmlt-server" "${LOCAL_PORT}:8000" >/dev/null 2>&1 &
PF_PID=$!
trap 'kill "$PF_PID" 2>/dev/null || true' EXIT

# Give the forward a moment to establish.
for _ in $(seq 1 10); do
  kill -0 "$PF_PID" 2>/dev/null || { echo "error: port-forward died" >&2; exit 1; }
  curl -sf -o /dev/null "http://127.0.0.1:${LOCAL_PORT}/" && break
  sleep 2
done

echo "==> GET / (following redirect to main_server/)"
CODE="$(curl -s -L -o /dev/null -w '%{http_code}' "http://127.0.0.1:${LOCAL_PORT}/")"
echo "    HTTP $CODE"
if [ "$CODE" = "200" ]; then
  echo "PASS: app is serving."
else
  echo "FAIL: unexpected status $CODE" >&2
  kubectl logs -n "$NAMESPACE" "deployment/${RELEASE}-bmlt-server" --tail=30 || true
  exit 1
fi
