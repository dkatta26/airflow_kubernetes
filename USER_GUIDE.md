# User Guide - Airflow Custom Chart v3

## 📚 Quick Reference

### Daily Operations

```bash
# Check Airflow status
kubectl get pods -n airflow

# Access Web UI (fixed port 30080)
http://YOUR_SERVER_IP:30080
Username: admin
Password: admin

# View logs
kubectl logs deployment/my-airflow-airflow-custom-scheduler -n airflow

# Scale workers
helm upgrade my-airflow ~/airflow-custom-chart-v3 -n airflow --set workers.replicas=5
```

---

## 🚀 Adding DAGs

### Method 1: Git-Sync (If using Git)

```bash
# 1. Navigate to your DAGs repository
cd ~/airflow-dags

# 2. Create new DAG
cat > my_new_dag.py <<'EOF'
from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime

with DAG(
    'my_new_dag',
    start_date=datetime(2024, 1, 1),
    schedule_interval='@daily',
    catchup=False
) as dag:
    BashOperator(
        task_id='task1',
        bash_command='echo "My new task!"'
    )
EOF

# 3. Commit and push
git add my_new_dag.py
git commit -m "Add my new DAG"
git push

# 4. Wait 60 seconds - DAG appears in Airflow UI automatically!
```

### Method 2: NFS (If using NFS)

```bash
# On NFS server machine
vi /exports/airflow/dags/my_new_dag.py

# Save file - appears in Airflow within 60 seconds!
```

### Method 3: kubectl cp (Emergency/Testing)

```bash
# Get scheduler pod name
SCHEDULER_POD=$(kubectl get pod -n airflow -l component=scheduler -o jsonpath='{.items[0].metadata.name}')

# Copy DAG
kubectl cp my_dag.py airflow/$SCHEDULER_POD:/opt/airflow/dags/

# Verify
kubectl exec $SCHEDULER_POD -n airflow -- ls /opt/airflow/dags/
```

---

## 🔧 Common Operations

### Trigger a DAG

```bash
# Via CLI
kubectl exec deployment/my-airflow-airflow-custom-scheduler -n airflow -- \
  airflow dags trigger my_dag_id

# Via Web UI
# Go to DAGs page → Click play button → Trigger DAG
```

### List All DAGs

```bash
kubectl exec deployment/my-airflow-airflow-custom-scheduler -n airflow -- \
  airflow dags list
```

### View DAG Details

```bash
kubectl exec deployment/my-airflow-airflow-custom-scheduler -n airflow -- \
  airflow dags show my_dag_id
```

### Pause/Unpause DAG

```bash
# Pause
kubectl exec deployment/my-airflow-airflow-custom-scheduler -n airflow -- \
  airflow dags pause my_dag_id

# Unpause
kubectl exec deployment/my-airflow-airflow-custom-scheduler -n airflow -- \
  airflow dags unpause my_dag_id
```

### Test a Task

```bash
kubectl exec deployment/my-airflow-airflow-custom-scheduler -n airflow -- \
  airflow tasks test my_dag_id my_task_id 2024-01-01
```

---

## 📊 Monitoring

### Check Pod Status

```bash
# All pods
kubectl get pods -n airflow

# With resource usage
kubectl top pods -n airflow

# Watch in real-time
kubectl get pods -n airflow -w
```

### View Logs

```bash
# Scheduler logs
kubectl logs deployment/my-airflow-airflow-custom-scheduler -n airflow -f

# Webserver logs
kubectl logs deployment/my-airflow-airflow-custom-webserver -n airflow -f

# Worker logs
kubectl logs my-airflow-airflow-custom-worker-0 -n airflow -f

# Git-sync logs (if using Git-Sync)
kubectl logs deployment/my-airflow-airflow-custom-scheduler -n airflow -c git-sync -f

# Last 100 lines
kubectl logs deployment/my-airflow-airflow-custom-scheduler -n airflow --tail=100
```

### Check Celery Workers

```bash
# List active workers
kubectl exec deployment/my-airflow-airflow-custom-scheduler -n airflow -- \
  airflow celery inspect active

# Check worker stats
kubectl exec deployment/my-airflow-airflow-custom-scheduler -n airflow -- \
  airflow celery inspect stats
```

### Database Health

```bash
# Check database connection
kubectl exec deployment/my-airflow-airflow-custom-scheduler -n airflow -- \
  airflow db check

# List tables
kubectl exec deployment/my-airflow-airflow-custom-scheduler -n airflow -- \
  airflow db shell -c "\dt"
```

---

## ⚙️ Configuration Changes

### Scale Workers

```bash
# Scale to 5 workers
helm upgrade my-airflow ~/airflow-custom-chart-v3 -n airflow --set workers.replicas=5

# Or edit values.yaml and upgrade
vi ~/airflow-custom-chart-v3/values.yaml
# Change: workers.replicas = 5
helm upgrade my-airflow ~/airflow-custom-chart-v3 -n airflow
```

### Change Service Type or NodePort

```bash
# Change to LoadBalancer (cloud/MetalLB)
helm upgrade my-airflow ~/airflow-custom-chart-v3 -n airflow \
  --set webserver.service.type=LoadBalancer

# Change fixed NodePort (default: 30080)
helm upgrade my-airflow ~/airflow-custom-chart-v3 -n airflow \
  --set webserver.service.nodePort=31080
```

### Update Image Version

```bash
helm upgrade my-airflow ~/airflow-custom-chart-v3 -n airflow \
  --set image.tag=2.8.4
```

### Switch from Git-Sync to NFS

```bash
# 1. Set up NFS server first
# 2. Edit values.yaml
vi ~/airflow-custom-chart-v3/values.yaml

# Change:
# dags:
#   gitSync:
#     enabled: false
#   nfs:
#     enabled: true
#     server: "NFS_IP"
#     path: "/exports/airflow/dags"

# 3. Upgrade
helm upgrade my-airflow ~/airflow-custom-chart-v3 -n airflow

# 4. Pods will restart with NFS mount
```

---

## 👥 User Management

### Create New User

```bash
kubectl exec deployment/my-airflow-airflow-custom-scheduler -n airflow -- \
  airflow users create \
    --username john \
    --firstname John \
    --lastname Doe \
    --role Viewer \
    --email john@example.com \
    --password secure_password
```

### List Users

```bash
kubectl exec deployment/my-airflow-airflow-custom-scheduler -n airflow -- \
  airflow users list
```

### Delete User

```bash
kubectl exec deployment/my-airflow-airflow-custom-scheduler -n airflow -- \
  airflow users delete --username john
```

### Available Roles

- **Admin** - Full access
- **User** - Can view and edit DAGs
- **Op** - Can view and trigger DAGs
- **Viewer** - Read-only access
- **Public** - Limited public access

---

## 🔐 Connections & Variables

### Add Connection (via CLI)

```bash
# PostgreSQL connection example
kubectl exec deployment/my-airflow-airflow-custom-scheduler -n airflow -- \
  airflow connections add 'my_postgres' \
    --conn-type 'postgres' \
    --conn-host 'postgres.example.com' \
    --conn-login 'user' \
    --conn-password 'password' \
    --conn-port '5432' \
    --conn-schema 'mydb'

# HTTP connection example
kubectl exec deployment/my-airflow-airflow-custom-scheduler -n airflow -- \
  airflow connections add 'my_api' \
    --conn-type 'http' \
    --conn-host 'api.example.com' \
    --conn-extra '{"timeout": 30}'
```

### List Connections

```bash
kubectl exec deployment/my-airflow-airflow-custom-scheduler -n airflow -- \
  airflow connections list
```

### Add Variable

```bash
kubectl exec deployment/my-airflow-airflow-custom-scheduler -n airflow -- \
  airflow variables set my_variable "my_value"

# From JSON file
kubectl exec deployment/my-airflow-airflow-custom-scheduler -n airflow -- \
  airflow variables import /path/to/variables.json
```

### Get Variable

```bash
kubectl exec deployment/my-airflow-airflow-custom-scheduler -n airflow -- \
  airflow variables get my_variable
```

---

## 🔄 Backup & Restore

### Backup PostgreSQL Database

```bash
# On PostgreSQL host machine
sudo -u postgres pg_dump airflow > airflow_backup_$(date +%Y%m%d).sql

# Or with compression
sudo -u postgres pg_dump airflow | gzip > airflow_backup_$(date +%Y%m%d).sql.gz
```

### Restore PostgreSQL Database

```bash
# On PostgreSQL host machine
sudo -u postgres psql airflow < airflow_backup_20240128.sql

# Or from compressed
gunzip < airflow_backup_20240128.sql.gz | sudo -u postgres psql airflow
```

### Backup DAGs (Git-Sync)

```bash
# DAGs are in Git - just ensure you've pushed
cd ~/airflow-dags
git status
git push
```

### Backup DAGs (NFS)

```bash
# On NFS server
tar -czf airflow_dags_backup_$(date +%Y%m%d).tar.gz /exports/airflow/dags/
```

---

## 🐛 Troubleshooting

### DAG Not Appearing

```bash
# 1. Check DAG file exists
kubectl exec deployment/my-airflow-airflow-custom-scheduler -n airflow -- \
  ls -la /opt/airflow/dags/

# 2. Check for parsing errors
kubectl exec deployment/my-airflow-airflow-custom-scheduler -n airflow -- \
  airflow dags list-import-errors

# 3. Check scheduler logs
kubectl logs deployment/my-airflow-airflow-custom-scheduler -n airflow | grep -i error

# 4. Manually test DAG
kubectl exec deployment/my-airflow-airflow-custom-scheduler -n airflow -- \
  python /opt/airflow/dags/my_dag.py
```

### Task Failing

```bash
# View task logs in Web UI
# Or via CLI:
kubectl exec deployment/my-airflow-airflow-custom-scheduler -n airflow -- \
  airflow tasks logs my_dag_id my_task_id 2024-01-28

# View worker logs
kubectl logs my-airflow-airflow-custom-worker-0 -n airflow | grep my_task_id
```

### Slow Performance

```bash
# Check resource usage
kubectl top pods -n airflow
kubectl top nodes

# Scale workers
helm upgrade my-airflow ~/airflow-custom-chart-v3 -n airflow --set workers.replicas=5

# Increase worker concurrency
helm upgrade my-airflow ~/airflow-custom-chart-v3 -n airflow --set workers.concurrency=32
```

### Pod Crashes

```bash
# Check pod status
kubectl get pods -n airflow

# Describe pod
kubectl describe pod POD_NAME -n airflow

# Check logs
kubectl logs POD_NAME -n airflow

# Check previous logs (if pod restarted)
kubectl logs POD_NAME -n airflow --previous
```

---

## 🔧 Maintenance

### Restart Components

```bash
# Restart scheduler
kubectl rollout restart deployment/my-airflow-airflow-custom-scheduler -n airflow

# Restart webserver
kubectl rollout restart deployment/my-airflow-airflow-custom-webserver -n airflow

# Restart all workers
kubectl rollout restart statefulset/my-airflow-airflow-custom-worker -n airflow

# Restart everything
kubectl delete pods -l app.kubernetes.io/instance=my-airflow -n airflow
```

### Clean Up Old DAG Runs

```bash
# Clean DAG runs older than 30 days
kubectl exec deployment/my-airflow-airflow-custom-scheduler -n airflow -- \
  airflow db clean --clean-before-timestamp $(date -d '30 days ago' +%Y-%m-%d) --yes
```

### Upgrade Airflow

```bash
# 1. Update image tag in values.yaml
vi ~/airflow-custom-chart-v3/values.yaml
# Change: image.tag = "2.8.4"

# 2. Upgrade
helm upgrade my-airflow ~/airflow-custom-chart-v3 -n airflow

# 3. Run database migration (if needed)
kubectl exec deployment/my-airflow-airflow-custom-scheduler -n airflow -- \
  airflow db migrate
```

---

## 📈 Best Practices

### DAG Development

1. **Test locally** before deploying
2. **Use meaningful names** for DAGs and tasks
3. **Add tags** for organization
4. **Set `catchup=False`** to avoid backfilling
5. **Use appropriate `schedule_interval`**
6. **Add documentation** in DAG docstring
7. **Handle failures** with retries and alerts

### Example Well-Structured DAG

```python
from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime, timedelta

default_args = {
    'owner': 'data-team',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email': ['alerts@company.com'],
    'email_on_failure': True,
    'email_on_retry': False,
    'retries': 2,
    'retry_delay': timedelta(minutes=5),
}

with DAG(
    'etl_customer_data',
    default_args=default_args,
    description='Daily ETL for customer data',
    schedule_interval='0 2 * * *',  # 2 AM daily
    catchup=False,
    tags=['etl', 'customer', 'production'],
    doc_md="""
    # Customer Data ETL
    
    This DAG processes daily customer data:
    1. Extract from source DB
    2. Transform data
    3. Load to warehouse
    """
) as dag:
    
    extract = BashOperator(
        task_id='extract_data',
        bash_command='python /opt/scripts/extract.py',
    )
    
    transform = BashOperator(
        task_id='transform_data',
        bash_command='python /opt/scripts/transform.py',
    )
    
    load = BashOperator(
        task_id='load_data',
        bash_command='python /opt/scripts/load.py',
    )
    
    extract >> transform >> load
```

### Resource Management

- Monitor pod resource usage
- Scale workers based on workload
- Set appropriate resource limits
- Use node affinity for resource-intensive tasks

### Security

- Change default passwords immediately
- Use RBAC for user permissions
- Secure connections with encryption
- Rotate credentials regularly
- Use Kubernetes secrets for sensitive data

---

## 📞 Getting Help

### Check Status

```bash
# Helm release status
helm status my-airflow -n airflow

# Release history
helm history my-airflow -n airflow

# Kubernetes events
kubectl get events -n airflow --sort-by='.lastTimestamp'
```

### Common Commands Reference

```bash
# Quick status check
kubectl get pods -n airflow && kubectl get svc -n airflow

# Quick logs
kubectl logs -l component=scheduler -n airflow --tail=50

# Quick DAG list
kubectl exec deployment/my-airflow-airflow-custom-scheduler -n airflow -- airflow dags list

# Quick trigger
kubectl exec deployment/my-airflow-airflow-custom-scheduler -n airflow -- airflow dags trigger DAG_ID
```

---

## 🎉 Summary

You now know how to:
- ✅ Add and manage DAGs
- ✅ Monitor Airflow components
- ✅ Scale and configure resources
- ✅ Manage users and permissions
- ✅ Backup and restore
- ✅ Troubleshoot issues
- ✅ Follow best practices

**Happy Airflowing! 🚀**
