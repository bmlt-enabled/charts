# BMLT Helm Charts

Helm chart repository for the [Basic Meeting List Toolbox (BMLT)](https://bmlt.app)
server, published at **https://charts.bmlt.app**.

```bash
helm repo add bmlt https://charts.bmlt.app
helm repo update
helm search repo bmlt
helm install <release> bmlt/bmlt-server -n <namespace>
```

The chart is also published as an OCI artifact on Docker Hub:

```bash
helm pull oci://registry-1.docker.io/bmltenabled/bmlt-server
```

## What it deploys

`bmlt-server` runs the [`bmltenabled/bmlt-server`](https://hub.docker.com/r/bmltenabled/bmlt-server)
image (Apache + PHP/Laravel, serving on port 8000). The chart provides:

- a **Deployment** for the long-lived server,
- a **Service** and optional **Ingress**,
- an optional **HorizontalPodAutoscaler**, and
- an optional **CronJob** that runs the aggregator import (`php artisan
  aggregator:InitializeDatabase` + `aggregator:ImportRootServers`) on a schedule.

You bring your own MySQL/MariaDB — the chart only points the app at it.

## Database

The server needs a MySQL/MariaDB database. A quick way to stand one up is the
Bitnami chart:

```yaml
# mysql-values.yaml
auth:
  rootPassword: rootserver
  database: rootserver
  username: rootserver
  password: rootserver
```

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install mysql bitnami/mysql -f mysql-values.yaml -n <namespace>
```

Then point the chart at it via the `database.*` values below.

## Configuration

Common values (see [`charts/bmlt-server/values.yaml`](charts/bmlt-server/values.yaml)
for the full list):

| Key | Default | Description |
| --- | --- | --- |
| `image.tag` | `""` (chart `appVersion`) | Image tag; set `"latest"` to track newest. |
| `database.host` | `mysql.bmlt.svc.cluster.local` | DB host. |
| `database.port` | `3306` | DB port (`DB_PORT`). |
| `database.name` | `rootserver` | DB name. |
| `database.username` / `database.password` | `rootserver` | DB credentials (inline). |
| `database.dbprefix` | `na` | Table prefix (`DB_PREFIX`). |
| `database.secrets.username` / `.password` | _unset_ | Source credentials from a Secret instead (see below). |
| `bmlt.aggregatorMode.enabled` | `true` | Enable aggregator mode + the import CronJob. |
| `bmlt.aggregatorMode.schedule` | `0 */2 * * *` | CronJob schedule. |
| `bmlt.googleApiKey` | `""` | Google Maps API key (`GOOGLE_API_KEY`). |
| `bmlt.secrets.googleApiKey` | _unset_ | Source the API key from a Secret instead. |
| `extraEnv` | `[]` | Extra env vars passed to server + aggregator. |
| `ingress.enabled` | `true` | Create an Ingress (defaults to AWS ALB). |
| `service.type` | `NodePort` | Service type. |

### Sourcing credentials from Secrets

Any of the DB credentials and the Google API key can come from an existing
Secret instead of plaintext values:

```yaml
database:
  secrets:
    username:
      name: database-creds
      key: db-admin-user
    password:
      name: database-creds
      key: db-admin-password
bmlt:
  secrets:
    googleApiKey:
      name: google-creds
      key: google-key
```

### Extra environment variables

```yaml
extraEnv:
  - name: ENABLE_LANGUAGE_SELECTOR
    value: "true"
  - name: MEETING_STATES_AND_PROVINCES
    value: "CT,MA,NH,NJ,NY,PA,VT"
```

### Ingress

The default ingress targets the AWS Load Balancer Controller (`className: alb`).
If you use ALB, make sure the controller is installed on the cluster and adjust
the `ingress.annotations` (subnets, certificate ARN, etc.). For other ingress
controllers, change `ingress.className` and the annotations accordingly, or set
`ingress.enabled: false`.

## Contributing & local testing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the repo layout, the `make` targets,
how to spin up a local k3d cluster to test the chart, and the release process.
