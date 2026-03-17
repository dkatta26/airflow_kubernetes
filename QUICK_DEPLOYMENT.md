# Quick Deployment Guide - Airflow v3

## ⚡ 15-Minute Deployment

### Prerequisites Check (2 min)

```bash
# Check Kubernetes
kubectl get nodes
# Must show: 2+ nodes in Ready state

# Check Helm
helm version
# Must show: v3.x.x

# Check PostgreSQL
ssh postgresql-host
sudo systemctl status postgresql
# Must show: active (running)
```

### Choose Your Method

**Option A:** Git-Sync (Recommended) → Go to [Git-Sync Deployment](#git-sync-deployment)  
**Option B:** NFS → Go to [NFS Deployment](#nfs-deployment)

---

## 🔥 Git-Sync Deployment

### Step 1: Create Git Repo (3 min)

```bash
# Create DAGs repo
mkdir ~/airflow-dags && cd ~/airflow-dags
git init

# Add sample DAG
cat > hello.py <<'EOF'
from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime

with DAG('hello', start_date=datetime(2024,1,1), schedule_interval='@daily', catchup=False) as dag:
    BashOperator(task_id='hi', bash_command='echo "Hello Airflow!"')
EOF

# Push to GitHub
git add . && git commit -m "init"
git remote add origin https://github.com/YOUR_USERNAME/airflow-dags.git
git push -u origin main
```

### Step 2: Configure Chart (2 min)

```bash
cd ~
tar -xzf airflow-custom-chart-v3-complete.tar.gz
cd airflow-custom-chart-v3

# Edit values.yaml - change ONLY these 3 lines:
vi values.yaml

# Line 23: PostgreSQL IP
postgresql:
  host: "YOUR_POSTGRESQL_IP"  # ← CHANGE THIS!

# Line 58: Enable Git-Sync  
  gitSync:
    enabled: true  # ← Change to true

# Line 60: Your Git repo
    repo: "https://github.com/YOUR_USERNAME/airflow-dags.git"  # ← CHANGE THIS!
```

### Step 3: Deploy (5 min)

```bash
# Deploy
helm install my-airflow . -n airflow --create-namespace --timeout 10m

# Wait for pods
kubectl get pods -n airflow -w
# Wait until all show Running/Completed (3-5 min)

# Get server IP
SERVER_IP=$(hostname -I | awk '{print $1}')

# Open firewall (fixed port 30080)
sudo firewall-cmd --permanent --add-port=30080/tcp && sudo firewall-cmd --reload

# Access
echo "Airflow: http://$SERVER_IP:30080"
echo "Login: admin / admin"
```

### Step 4: Verify (2 min)

```bash
# Check DAG appeared
kubectl exec deployment/my-airflow-airflow-custom-scheduler -n airflow -- airflow dags list | grep hello

# Open browser → http://YOUR_IP:30080
# You should see "hello" DAG!
```

**✅ Done! Total: ~12 minutes**

---

## 🌐 NFS Deployment

### Step 1: Setup NFS Server (5 min)

```bash
# On one node (choose as NFS server)
sudo dnf install -y nfs-utils
sudo mkdir -p /exports/airflow/dags
sudo chmod 777 /exports/airflow/dags
echo "/exports/airflow/dags *(rw,sync,no_root_squash)" | sudo tee -a /etc/exports
sudo exportfs -ra
sudo systemctl start nfs-server
sudo firewall-cmd --permanent --add-service=nfs && sudo firewall-cmd --reload

# Note NFS server IP
hostname -I  # e.g., 192.168.1.50

# Create sample DAG
cat > /exports/airflow/dags/hello.py <<'EOF'
from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime

with DAG('hello', start_date=datetime(2024,1,1), schedule_interval='@daily', catchup=False) as dag:
    BashOperator(task_id='hi', bash_command='echo "Hello from NFS!"')
EOF
```

### Step 2: Install NFS Client on All K8s Nodes (3 min)

```bash
# On EACH Kubernetes node
sudo dnf install -y nfs-utils

# Test mount
sudo mount -t nfs NFS_SERVER_IP:/exports/airflow/dags /mnt && ls /mnt && sudo umount /mnt
```

### Step 3: Configure Chart (2 min)

```bash
cd ~
tar -xzf airflow-custom-chart-v3-complete.tar.gz
cd airflow-custom-chart-v3

# Edit values.yaml - change ONLY these 4 lines:
vi values.yaml

# Line 23: PostgreSQL IP
postgresql:
  host: "YOUR_POSTGRESQL_IP"  # ← CHANGE THIS!

# Line 70: Enable NFS
  nfs:
    enabled: true  # ← Change to true

# Line 71: NFS server IP
    server: "YOUR_NFS_IP"  # ← CHANGE THIS!
```

### Step 4: Deploy (5 min)

```bash
# Deploy
helm install my-airflow . -n airflow --create-namespace --timeout 10m

# Wait for pods
kubectl get pods -n airflow -w

# Get server IP
SERVER_IP=$(hostname -I | awk '{print $1}')

# Open firewall (fixed port 30080)
sudo firewall-cmd --permanent --add-port=30080/tcp && sudo firewall-cmd --reload

# Access
echo "Airflow: http://$SERVER_IP:30080"
echo "Login: admin / admin"
```

### Step 5: Verify (2 min)

```bash
# Check DAG
kubectl exec deployment/my-airflow-airflow-custom-scheduler -n airflow -- airflow dags list | grep hello

# Open browser → http://YOUR_IP:30080
```

**✅ Done! Total: ~17 minutes**

---

## 🔍 Quick Verification Checklist

```bash
# 1. All pods running?
kubectl get pods -n airflow
# Expected: 8 Running + 1 Completed

# 2. Can access UI?
# Open: http://YOUR_IP:30080 (fixed port)
# Login: admin / admin

# 3. DAG visible?
# Check: DAGs page shows your DAG

# 4. Git-sync working? (if using Git)
kubectl logs deployment/my-airflow-airflow-custom-scheduler -n airflow -c git-sync | tail -5
# Expected: "synced" message

# 5. NFS mounted? (if using NFS)
kubectl exec deployment/my-airflow-airflow-custom-scheduler -n airflow -- df -h | grep dags
# Expected: shows NFS mount
```

---

## 🎯 What You Get

After deployment:
- ✅ 1 Scheduler (parses DAGs)
- ✅ 2 Webservers (UI access)
- ✅ 3 Workers (execute tasks)
- ✅ 1 Triggerer (deferrable operators)
- ✅ 1 Redis (Celery broker)
- ✅ PostgreSQL on host (metadata database)
- ✅ Auto database initialization
- ✅ Fixed NodePort access (port 30080)
- ✅ CSRF protection (auto-configured)
- ✅ DAG sync (Git or NFS)

---

## 📝 Common Post-Install Tasks

### Add More DAGs

**Git-Sync:**
```bash
cd ~/airflow-dags
vi new_dag.py
git add . && git commit -m "new dag" && git push
# Wait 60 seconds - appears in UI!
```

**NFS:**
```bash
# On NFS server
vi /exports/airflow/dags/new_dag.py
# Save - appears in UI within 60 seconds!
```

### Change Password

```bash
kubectl exec deployment/my-airflow-airflow-custom-scheduler -n airflow -- \
  airflow users create --username youradmin --password SECURE_PASS --role Admin \
    --firstname Your --lastname Name --email you@example.com
```

### Scale Workers

```bash
helm upgrade my-airflow ~/airflow-custom-chart-v3 -n airflow --set workers.replicas=5
```

---

## ❌ If Something Goes Wrong

### Pods not starting?

```bash
kubectl describe pod POD_NAME -n airflow
kubectl logs POD_NAME -n airflow
```

### Can't reach database?

```bash
# On PostgreSQL host
sudo systemctl status postgresql
sudo ss -tlnp | grep 5432
sudo firewall-cmd --list-ports | grep 5432
```

### DAG not appearing?

```bash
# Check Git-sync
kubectl logs deployment/my-airflow-airflow-custom-scheduler -n airflow -c git-sync

# Check NFS
kubectl exec deployment/my-airflow-airflow-custom-scheduler -n airflow -- ls /opt/airflow/dags/

# Check parsing errors
kubectl exec deployment/my-airflow-airflow-custom-scheduler -n airflow -- \
  airflow dags list-import-errors
```

---

## 📚 Full Documentation

For detailed guides, see:
- `DEPLOYMENT_GUIDE.md` - Step-by-step deployment
- `USER_GUIDE.md` - Daily operations
- `COMPLETE_DAG_GUIDE.md` - Git-Sync & NFS details
- `VALUES_EXAMPLES.md` - Configuration examples

---

## 🎉 That's It!

You now have a production-ready Airflow deployment with:
- ✅ Multi-node support
- ✅ Flexible DAG management (Git or NFS)
- ✅ Auto database setup
- ✅ Immediate web access
- ✅ Easy scaling

**Start building workflows! 🚀**
