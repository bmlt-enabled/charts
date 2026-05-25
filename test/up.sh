#!/usr/bin/env bash
# Stand up a local k3d cluster, deploy MariaDB, and install the bmlt-server chart.
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-bmlt-test}"
NAMESPACE="${NAMESPACE:-bmlt}"
RELEASE="${RELEASE:-bmlt}"

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHART_DIR="$(cd "$HERE/.." && pwd)/charts/bmlt-server"

for bin in k3d kubectl helm; do
  command -v "$bin" >/dev/null 2>&1 || { echo "error: $bin not found in PATH" >&2; exit 1; }
done

echo "==> Ensuring k3d cluster '$CLUSTER_NAME'"
if ! k3d cluster list "$CLUSTER_NAME" >/dev/null 2>&1; then
  k3d cluster create "$CLUSTER_NAME" --wait
else
  echo "    cluster already exists"
fi
kubectl config use-context "k3d-$CLUSTER_NAME" >/dev/null

echo "==> Namespace '$NAMESPACE'"
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

echo "==> Deploying MariaDB"
kubectl apply -n "$NAMESPACE" -f "$HERE/mariadb.yaml"
kubectl rollout status -n "$NAMESPACE" deployment/mariadb --timeout=180s

echo "==> Installing chart '$RELEASE'"
helm upgrade --install "$RELEASE" "$CHART_DIR" \
  -n "$NAMESPACE" \
  -f "$HERE/values-local.yaml" \
  --wait --timeout 300s

echo "==> Done. Pods:"
kubectl get pods -n "$NAMESPACE"
echo
echo "Run ./test/smoke-test.sh to verify the app responds, ./test/down.sh to tear down."
