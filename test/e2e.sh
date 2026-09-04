#!/usr/bin/env bash
# End-to-end smoke test: stand up a throwaway k3d cluster + MariaDB, install the
# chart, verify the app serves HTTP, then always tear the cluster back down.
#
# Meant to be the one command you (or CI) run to prove the chart still deploys
# and boots. Wraps up.sh -> smoke-test.sh -> down.sh with guaranteed cleanup.
#
# Env knobs:
#   CLUSTER_NAME (default bmlt-test)  k3d cluster name
#   NAMESPACE    (default bmlt)       namespace to install into
#   RELEASE      (default bmlt)       helm release name
#   KEEP         (default 0)          set to 1 to leave the cluster up after the
#                                     run (skips teardown) for debugging
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-bmlt-test}"
NAMESPACE="${NAMESPACE:-bmlt}"
RELEASE="${RELEASE:-bmlt}"
KEEP="${KEEP:-0}"
export CLUSTER_NAME NAMESPACE RELEASE

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for bin in k3d kubectl helm curl; do
  command -v "$bin" >/dev/null 2>&1 || { echo "error: $bin not found in PATH" >&2; exit 1; }
done

cleanup() {
  local rc=$?
  if [ "$rc" -ne 0 ]; then
    echo
    echo "==> FAILED (exit $rc) — dumping diagnostics"
    kubectl get pods,svc,secret,serviceaccount,hpa -n "$NAMESPACE" 2>/dev/null || true
    kubectl describe pods -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE" 2>/dev/null | tail -40 || true
    kubectl logs -n "$NAMESPACE" "deployment/${RELEASE}-bmlt-server" --tail=50 2>/dev/null || true
  fi
  if [ "$KEEP" = "1" ]; then
    echo "==> KEEP=1 set — leaving cluster '$CLUSTER_NAME' up (tear down with ./test/down.sh)"
  else
    echo "==> Tearing down"
    "$HERE/down.sh" || true
  fi
  exit "$rc"
}
trap cleanup EXIT

echo "########## bmlt-server chart e2e smoke test ##########"
"$HERE/up.sh"
"$HERE/smoke-test.sh"

echo
echo "########## PASS: chart deployed and app served HTTP 200 ##########"
