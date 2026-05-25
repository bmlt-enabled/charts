# Contributing

This repo is **two things at once**:

1. The **Helm chart** source under [`charts/bmlt-server/`](charts/bmlt-server/).
2. The **published chart repository** — the static site under [`site/`](site/)
   that is served at https://charts.bmlt.app via GitHub Pages.

```
charts/bmlt-server/    chart source (templates, values.yaml, Chart.yaml)
site/                  published Pages site: index.yaml, *.tgz, index.html, CNAME
test/                  local k3d test harness (scripts + manifests)
Makefile               lint / package / index / local-cluster targets
```

Pushing to `main` triggers `.github/workflows/static.yml`, which uploads the
`site/` directory to GitHub Pages. **The chart is only published once the
packaged `.tgz` and regenerated `index.yaml` are committed under `site/`.**

## Prerequisites

| Tool | Used for |
| --- | --- |
| [helm](https://helm.sh) (v3+) | lint, template, package, index |
| [kubectl](https://kubernetes.io/docs/tasks/tools/) | talking to the test cluster |
| [k3d](https://k3d.io) | running a local cluster in Docker |
| [Docker](https://www.docker.com) | k3d + pulling images |

Run `make help` to see all targets.

## Developing the chart

```bash
make lint        # helm lint
make template    # render with default values
```

When editing container environment, change the shared `bmlt-server.env` helper
in `charts/bmlt-server/templates/_helpers.tpl` — it is `include`d by both the
Deployment and the aggregator CronJob, so they stay in sync. The app reads
`DB_USERNAME` / `DB_PASSWORD` / `DB_HOST` / `DB_PORT` / `DB_PREFIX` and
`GOOGLE_API_KEY` (the names come from `App\ConfigBase::fromEnv` in the
bmlt-server repo).

## Testing on a local k3d cluster

The [`test/`](test/) directory contains a self-contained harness that creates a
throwaway cluster, deploys a MariaDB, installs the chart, and smoke-tests it.

```bash
make e2e            # cluster-up + smoke test in one shot
# ...or step by step:
make cluster-up     # create k3d cluster, deploy MariaDB, install the chart
make cluster-test   # wait for rollout, port-forward, assert GET / returns 200
make cluster-down   # delete the cluster
```

What each piece does:

- **`test/mariadb.yaml`** — a minimal MariaDB Deployment + Service whose
  credentials match the chart defaults.
- **`test/values-local.yaml`** — local overrides: ingress disabled, `ClusterIP`
  service (reached via `kubectl port-forward`), aggregator off for a fast smoke
  test, and `database.host` pointed at the in-cluster `mariadb` service.
- **`test/up.sh` / `smoke-test.sh` / `down.sh`** — the scripts behind the make
  targets. They are idempotent, so re-running `cluster-up` after a chart change
  just re-applies the release.

Override defaults with environment variables, e.g.:

```bash
CLUSTER_NAME=bmlt-dev NAMESPACE=bmlt make cluster-up
```

To exercise the aggregator CronJob, flip `bmlt.aggregatorMode.enabled: true` in
`test/values-local.yaml` (note: the import reaches the public root-server list
and takes a while).

Inspect the running release:

```bash
kubectl get pods -n bmlt
kubectl logs -n bmlt deployment/bmlt-bmlt-server
```

Always tear the cluster down when finished: `make cluster-down`.

## Releasing

1. Bump `version` (and `appVersion` if the image changed) in
   `charts/bmlt-server/Chart.yaml`. `version` is the **chart** version;
   `appVersion` is the **bmlt-server** image version.
2. Build the release artifacts:

   ```bash
   make release      # lint, package into site/, regenerate site/index.yaml
   ```

3. Commit the new `site/*.tgz` and `site/index.yaml`, then push to `main`. The
   Pages workflow publishes the updated repository.
