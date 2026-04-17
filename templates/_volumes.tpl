{{/*
DAG Volume Configuration
This template defines the volume for DAGs based on the selected method
*/}}

{{- define "airflow.dagsVolume" -}}
{{- if .Values.dags.hostPath.enabled }}
- name: dags
  hostPath:
    path: {{ .Values.dags.hostPath.path }}
    type: DirectoryOrCreate
{{- else if .Values.dags.nfs.enabled }}
- name: dags
  nfs:
    server: {{ .Values.dags.nfs.server }}
    path: {{ .Values.dags.nfs.path }}
{{- else if .Values.dags.persistentVolumeClaim.enabled }}
- name: dags
  persistentVolumeClaim:
    claimName: {{ .Values.dags.persistentVolumeClaim.existingClaim }}
{{- else }}
- name: dags
  emptyDir: {}
{{- end }}
{{- end }}

{{/*
DAG Volume Mount
*/}}
{{- define "airflow.dagsVolumeMount" -}}
- name: dags
  mountPath: /opt/airflow/dags
  {{- if and .Values.dags.persistentVolumeClaim.enabled .Values.dags.persistentVolumeClaim.subPath }}
  subPath: {{ .Values.dags.persistentVolumeClaim.subPath }}
  {{- end }}
{{- end }}

{{/*
Logs Volume Configuration
*/}}
{{- define "airflow.logsVolume" -}}
{{- if .Values.logs.hostPath.enabled }}
- name: logs
  hostPath:
    path: {{ .Values.logs.hostPath.path }}
    type: DirectoryOrCreate
{{- else if .Values.logs.nfs.enabled }}
- name: logs
  nfs:
    server: {{ .Values.logs.nfs.server }}
    path: {{ .Values.logs.nfs.path }}
{{- else if .Values.logs.persistentVolumeClaim.enabled }}
- name: logs
  persistentVolumeClaim:
    claimName: {{ .Values.logs.persistentVolumeClaim.existingClaim | required "logs.persistentVolumeClaim.existingClaim is required when logs.persistentVolumeClaim.enabled is true" }}
{{- else }}
- name: logs
  emptyDir: {}
{{- end }}
{{- end }}

{{/*
Logs Volume Mount
*/}}
{{- define "airflow.logsVolumeMount" -}}
- name: logs
  mountPath: /opt/airflow/logs
  {{- if and .Values.logs.persistentVolumeClaim.enabled .Values.logs.persistentVolumeClaim.subPath }}
  subPath: {{ .Values.logs.persistentVolumeClaim.subPath }}
  {{- end }}
{{- end }}

{{/*
Git-Sync Container
*/}}
{{- define "airflow.gitSyncContainer" -}}
{{- if .Values.dags.gitSync.enabled }}
- name: git-sync
  image: registry.k8s.io/git-sync/git-sync:v4.2.1
  env:
  - name: GITSYNC_REPO
    value: {{ .Values.dags.gitSync.repo | quote }}
  - name: GITSYNC_BRANCH
    value: {{ .Values.dags.gitSync.branch | quote }}
  - name: GITSYNC_ROOT
    value: /git
  - name: GITSYNC_DEST
    value: dags
  - name: GITSYNC_WAIT
    value: {{ .Values.dags.gitSync.wait | quote }}
  - name: GITSYNC_MAX_FAILURES
    value: "3"
  {{- if .Values.dags.gitSync.sshKeySecret }}
  - name: GITSYNC_SSH_KEY_FILE
    value: /etc/git-secret/ssh
  volumeMounts:
  - name: git-secret
    mountPath: /etc/git-secret
    readOnly: true
  {{- end }}
  volumeMounts:
  - name: dags
    mountPath: /git
  resources:
    limits:
      cpu: 100m
      memory: 128Mi
    requests:
      cpu: 50m
      memory: 64Mi
{{- end }}
{{- end }}

{{/*
Git-Sync Volume for SSH key
*/}}
{{- define "airflow.gitSyncVolume" -}}
{{- if and .Values.dags.gitSync.enabled .Values.dags.gitSync.sshKeySecret }}
- name: git-secret
  secret:
    secretName: {{ .Values.dags.gitSync.sshKeySecret }}
    defaultMode: 0400
{{- end }}
{{- end }}

{{/*
NAS / PVC: pre-uploaded airflow.cfg (use with airflow.useConfigMapForEnv: false for cfg-only)
*/}}
{{- define "airflow.externalAirflowCfgVolume" -}}
{{- if .Values.airflow.externalAirflowCfg.enabled }}
- name: external-airflow-cfg
  persistentVolumeClaim:
    claimName: {{ .Values.airflow.externalAirflowCfg.existingClaim | required "airflow.externalAirflowCfg.existingClaim is required when externalAirflowCfg.enabled is true" }}
{{- end }}
{{- end }}

{{- define "airflow.externalAirflowCfgVolumeMount" -}}
{{- if .Values.airflow.externalAirflowCfg.enabled }}
- name: external-airflow-cfg
  mountPath: {{ .Values.airflow.externalAirflowCfg.mountPath | default "/opt/airflow/airflow.cfg" | quote }}
  subPath: {{ .Values.airflow.externalAirflowCfg.subPath | default "airflow.cfg" | quote }}
  readOnly: true
{{- end }}
{{- end }}

{{/*
NAS custom scripts PVC
*/}}
{{- define "airflow.nasScriptsVolume" -}}
{{- if .Values.nasScripts.enabled }}
- name: nas-scripts
  persistentVolumeClaim:
    claimName: {{ .Values.nasScripts.existingClaim | required "nasScripts.existingClaim is required when nasScripts.enabled is true" }}
{{- end }}
{{- end }}

{{- define "airflow.nasScriptsVolumeMount" -}}
{{- if .Values.nasScripts.enabled }}
- name: nas-scripts
  mountPath: {{ .Values.nasScripts.mountPath | default "/opt/data" | quote }}
  readOnly: {{ .Values.nasScripts.readOnly | default true }}
{{- end }}
{{- end }}
