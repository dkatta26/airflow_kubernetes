# `airflow.cfg` on NAS (PVC mount)

Use this when you want the **main Airflow config file** on **NAS/NFS**, mounted into pods as **`airflow.cfg`**, instead of (or in addition to) **`AIRFLOW__…` variables** from the Helm ConfigMap.

## How Airflow resolves config

1. Reads **`airflow.cfg`** (default: `/opt/airflow/airflow.cfg`).
2. Applies **`AIRFLOW__SECTION__KEY` environment variables**, which **override** the file for the same setting.

So:

| Mode | `useConfigMapForEnv` | `externalAirflowCfg.enabled` | Behavior |
|------|----------------------|------------------------------|----------|
| **Default (Helm only)** | `true` | `false` | ConfigMap → env; no file mount. |
| **File only** | `false` | `true` + PVC | Only `airflow.cfg` from NAS; **you** maintain all settings in the file. |
| **Both** | `true` | `true` | ConfigMap env **wins** over duplicate keys in `airflow.cfg`. |

Helm **fails** if `useConfigMapForEnv: false` and `externalAirflowCfg.enabled: false` (no config source).

---

## Steps: NAS / PVC–backed `airflow.cfg`

### 1. Prepare the file on the volume

- Create a **PVC** (or use an existing one) whose volume is your **NAS export**.
- Place **`airflow.cfg`** at the path you will reference with **`subPath`** (e.g. file `airflow.cfg` at the volume root, or `config/airflow.cfg`).

### 2. Set `values.yaml`

**Cfg-only (recommended for full NAS-driven config):**

```yaml
airflow:
  useConfigMapForEnv: false
  externalAirflowCfg:
    enabled: true
    existingClaim: my-airflow-config-pvc   # PVC name in the release namespace
    subPath: airflow.cfg                 # filename/path inside the volume
    mountPath: /opt/airflow/airflow.cfg  # where Airflow reads the file
```

**Optional: keep Helm ConfigMap for some settings and add the file:**

```yaml
airflow:
  useConfigMapForEnv: true
  externalAirflowCfg:
    enabled: true
    existingClaim: my-airflow-config-pvc
    subPath: airflow.cfg
```

Remember: **env overrides** the file for the same option.

### 3. Required content in `airflow.cfg` (cfg-only mode)

You must define at least:

| Area | Examples |
|------|----------|
| Metadata DB | `[database]` → `sql_alchemy_conn` (Postgres) |
| Executor | `[core]` → `executor` |
| Webserver | `[webserver]` → `secret_key`, etc. |
| KubernetesExecutor | `[kubernetes_executor]` → `namespace`, `worker_container_repository`, `worker_container_tag`, **`pod_template_file`** |

If you use the chart’s **pod template** mount on the scheduler, set:

```ini
[kubernetes_executor]
pod_template_file = /opt/airflow/config/pod_template.yaml
```

(match the path used by the chart when `kubernetesExecutor.podTemplate.enabled` is true).

### 4. Deploy

```bash
helm upgrade <release> . -n <namespace> -f values.yaml
```

Restart workloads after changing the file on NAS or the PVC.

### 5. Security

- Avoid plain-text DB passwords on shared NAS if possible; prefer **Secrets** + small patches, or strict file permissions.
- For Postgres TLS, set `postgresql.sslmode` in `values.yaml` when using ConfigMap mode; in cfg-only mode, add `?sslmode=require` (or as supported) to `sql_alchemy_conn` in **`airflow.cfg`**.

---

## What the chart mounts

When **`externalAirflowCfg.enabled`** is true, these components get the **same** PVC `subPath` → **`mountPath`**:

- Scheduler, Webserver, Triggerer  
- db-init Job  
- Celery workers (if CeleryExecutor + workers enabled)  
- **KubernetesExecutor task pods** (via the pod template helper)

---

## See also

- `docs/K8S_WORKER_PODS_CONFIGMAP.md` — task pods + ConfigMap / pod template.
- `VERIFY_POSTGRES_ENV.md` — checking `AIRFLOW__DATABASE__SQL_ALCHEMY_CONN` in pods.
