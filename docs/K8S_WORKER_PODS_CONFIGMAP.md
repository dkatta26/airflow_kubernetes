# KubernetesExecutor “worker” task pods + ConfigMap

**Worker pods** here means **task pods** created by KubernetesExecutor (not Celery workers).

They do **not** automatically inherit the scheduler’s `envFrom`. You must use a **pod template** that includes `envFrom` → the same ConfigMap as the rest of the deployment.

---

## Steps (checklist)

### 1. Executor and pod template in `values.yaml`

```yaml
airflow:
  executor: KubernetesExecutor
  kubernetesExecutor:
    podTemplate:
      enabled: true   # must be true for ConfigMap injection into task pods
```

### 2. What the chart creates

| Resource | Purpose |
|----------|---------|
| ConfigMap **`<release>-config`** | All `AIRFLOW__…` keys (Postgres, executor, k8s executor settings, etc.) |
| ConfigMap **`<release>-pod-template`** | Contains `pod_template.yaml` with **`envFrom` → `<release>-config`** |
| Scheduler | Mounts `pod_template.yaml` at **`/opt/airflow/config/pod_template.yaml`** |
| Env on scheduler | **`AIRFLOW__KUBERNETES_EXECUTOR__POD_TEMPLATE_FILE=/opt/airflow/config/pod_template.yaml`** |

### 3. Deploy / upgrade

```bash
helm upgrade <release> . -n <namespace> -f values.yaml
oc rollout restart deployment/<release>-scheduler -n <namespace>   # if needed
```

### 4. Verify task pods see Postgres (while a task runs)

```bash
oc exec <task-pod-name> -n <namespace> -- printenv 'AIRFLOW__DATABASE__SQL_ALCHEMY_CONN'
```

Expect a **`postgresql://`** URL, not empty / SQLite.

### 5. If you use NAS-mounted `airflow.cfg` instead of ConfigMap env

Set **`airflow.useConfigMapForEnv: false`** and **`airflow.externalAirflowCfg.enabled: true`** (PVC + `subPath` to your file). Task pods still get the **same NAS mount** via the pod template; they do **not** use `envFrom` in that mode. See **`docs/EXTERNAL_AIRFLOW_CFG.md`**.

For **ConfigMap + env** injection into task pods, keep **`useConfigMapForEnv: true`** (default).

---

## Optional: `podTemplate.enabled: false`

Use only if you provide **`AIRFLOW__KUBERNETES_EXECUTOR__POD_TEMPLATE_FILE`** yourself (custom ConfigMap/mount) and a template that still **`envFrom`**’s your config.

---

## Git-Sync note

With **git-sync** for DAGs, the default pod template uses **emptyDir** for DAGs on task pods; use **PVC/NFS** for DAGs in production or customize the template.
