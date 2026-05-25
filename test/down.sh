#!/usr/bin/env bash
# Delete the local k3d test cluster.
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-bmlt-test}"

command -v k3d >/dev/null 2>&1 || { echo "error: k3d not found in PATH" >&2; exit 1; }

if k3d cluster list "$CLUSTER_NAME" >/dev/null 2>&1; then
  echo "==> Deleting k3d cluster '$CLUSTER_NAME'"
  k3d cluster delete "$CLUSTER_NAME"
else
  echo "cluster '$CLUSTER_NAME' not found; nothing to do"
fi
