# Airflow Custom Helm Chart v3

Custom Helm chart for Apache Airflow with flexible DAG storage options.

**Repository:** [github.com/dkatta26/airflow_kubernetes](https://github.com/dkatta26/airflow_kubernetes)

```bash
git clone https://github.com/dkatta26/airflow_kubernetes.git
cd airflow_kubernetes
```

### Push this chart to your new repository (first time)

From your **local** project folder (e.g. `airflow-custom-chart-v3`):

```bash
cd /path/to/airflow-custom-chart-v3

git init   # skip if .git already exists
git add .
git commit -m "Initial commit: Airflow Helm chart"

git branch -M main
git remote add origin https://github.com/dkatta26/airflow_kubernetes.git
git push -u origin main
```

If GitHub shows an empty repo with different default branch (`master`), use `git push -u origin main` or match their default. If the remote already has a README from the GitHub UI, use `git pull origin main --allow-unrelated-histories` once, then push.

## Features

✅ **Fixed Issues:**
- Database initialization runs automatically
- NodePort service by default (accessible immediately)
- CSRF protection with auto-generated secret key

✅ **DAG Storage Options:**
- **Git-Sync** - Sync DAGs from Git repository (recommended)
- **NFS** - Use NFS shared storage for multi-node clusters
- **HostPath** - Direct host directory mount (single-node only)
- Easy switching between methods

✅ **Production Ready:**
- Multi-node cluster support
- Separated components (scheduler, webserver, workers)
- CeleryExecutor for distributed tasks
- Configurable resources and scaling

## Prerequisites

- Kubernetes cluster (v1.20+)
- kubectl configured
- Helm 3.x
- PostgreSQL running (external to Kubernetes)

## Quick Start

### 1. Extract Chart

```bash
tar -xzf airflow-custom-chart-v3-final.tar.gz
cd airflow-custom-chart-v3
```

### 2. Configure PostgreSQL

Edit `values.yaml`:

```yaml
postgresql:
  host: "YOUR_POSTGRESQL_IP"  # Change this!
  port: 5432
  username: airflow
  password: airflow123
  database: airflow
```

### 3. Choose DAG Storage Method

#### Option A: Git-Sync (Recommended)

```yaml
dags:
  gitSync:
    enabled: true
    repo: "https://github.com/your-org/airflow-dags.git"
    branch: "main"
  nfs:
    enabled: false
```

#### Option B: NFS

```yaml
dags:
  gitSync:
    enabled: false
  nfs:
    enabled: true
    server: "nfs-server.example.com"
    path: "/exports/airflow/dags"
```

### 4. Install

```bash
helm install my-airflow . \
  --namespace airflow \
  --create-namespace \
  --timeout 10m
```

### 5. Access Airflow

```bash
# Fixed NodePort is 30080 (configured in values.yaml)

# Get server IP
SERVER_IP=$(hostname -I | awk '{print $1}')

# Open firewall (one-time)
sudo firewall-cmd --permanent --add-port=30080/tcp
sudo firewall-cmd --reload

# Access
echo "http://$SERVER_IP:30080"
# Login: admin / admin
```

## Configuration

### Key Values

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | Airflow image | `dkatta26/diveshkattaregistry` |
| `image.tag` | Image tag | `2.8.3` |
| `postgresql.host` | PostgreSQL host | `192.168.1.100` |
| `dags.gitSync.enabled` | Enable Git-Sync | `false` |
| `dags.gitSync.repo` | Git repository URL | - |
| `dags.nfs.enabled` | Enable NFS | `false` |
| `dags.nfs.server` | NFS server | - |
| `scheduler.replicas` | Scheduler replicas | `1` |
| `webserver.replicas` | Webserver replicas | `2` |
| `webserver.service.type` | Service type | `NodePort` |
| `webserver.service.nodePort` | Fixed NodePort | `30080` |
| `workers.replicas` | Worker replicas | `3` |

See `values.yaml` for all configuration options.

## DAG Management

### Git-Sync

1. Create Git repository with DAGs
2. Enable in values.yaml
3. Push changes to Git
4. DAGs sync automatically every 60 seconds

```bash
# Example
cd ~/airflow-dags
vi my_dag.py
git add . && git commit -m "New DAG" && git push
# Wait 60 seconds - appears in Airflow
```

### NFS

1. Set up NFS server
2. Enable in values.yaml
3. Edit files on NFS server
4. DAGs appear in Airflow within 60 seconds

```bash
# Example
vi /exports/airflow/dags/my_dag.py
# Save - appears in Airflow
```

### Switching Methods

```bash
# Edit values.yaml - flip enabled flags
# Then upgrade
helm upgrade my-airflow . -n airflow
```

## Operations

### Scale Workers

```bash
helm upgrade my-airflow . -n airflow --set workers.replicas=5
```

### View Logs

```bash
# Scheduler
kubectl logs deployment/my-airflow-airflow-custom-scheduler -n airflow

# Webserver
kubectl logs deployment/my-airflow-airflow-custom-webserver -n airflow

# Worker
kubectl logs my-airflow-airflow-custom-worker-0 -n airflow

# Git-sync (if using Git-Sync)
kubectl logs deployment/my-airflow-airflow-custom-scheduler -n airflow -c git-sync
```

### Restart Components

```bash
kubectl rollout restart deployment/my-airflow-airflow-custom-scheduler -n airflow
kubectl rollout restart deployment/my-airflow-airflow-custom-webserver -n airflow
kubectl rollout restart statefulset/my-airflow-airflow-custom-worker -n airflow
```

## Troubleshooting

### Check Pods

```bash
kubectl get pods -n airflow
kubectl describe pod <pod-name> -n airflow
```

### Check DAG Storage

```bash
# View DAGs directory
kubectl exec deployment/my-airflow-airflow-custom-scheduler -n airflow -- \
  ls -la /opt/airflow/dags/

# List parsed DAGs
kubectl exec deployment/my-airflow-airflow-custom-scheduler -n airflow -- \
  airflow dags list
```

### Git-Sync Issues

```bash
# Check git-sync logs
kubectl logs deployment/my-airflow-airflow-custom-scheduler -n airflow -c git-sync

# Verify repo URL and credentials
```

### NFS Issues

```bash
# Test NFS mount on nodes
sudo mount -t nfs NFS_SERVER:/path /mnt
ls /mnt
sudo umount /mnt

# Check NFS exports
showmount -e NFS_SERVER
```

## Upgrade

```bash
helm upgrade my-airflow . -n airflow
```

## Uninstall

```bash
helm uninstall my-airflow -n airflow
kubectl delete namespace airflow
```

## Documentation

- **COMPLETE_DAG_GUIDE.md** - Detailed setup for Git-Sync and NFS
- **VALUES_EXAMPLES.md** - Configuration examples for different scenarios
- **values.yaml** - All configuration options with inline comments

## Support

For issues or questions, refer to:
- Airflow docs: https://airflow.apache.org/docs/
- Helm docs: https://helm.sh/docs/

## License

Apache 2.0
