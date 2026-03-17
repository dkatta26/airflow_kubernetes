{{/*
Expand the name of the chart.
*/}}
{{- define "airflow.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "airflow.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "airflow.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "airflow.labels" -}}
helm.sh/chart: {{ include "airflow.chart" . }}
{{ include "airflow.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "airflow.selectorLabels" -}}
app.kubernetes.io/name: {{ include "airflow.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
PostgreSQL connection string
*/}}
{{- define "airflow.postgresql.connection" -}}
{{- printf "postgresql://%s:%s@%s:%d/%s" .Values.postgresql.username .Values.postgresql.password .Values.postgresql.host (.Values.postgresql.port | int) .Values.postgresql.database }}
{{- end }}

{{/*
Redis connection string
*/}}
{{- define "airflow.redis.connection" -}}
{{- printf "redis://:%s@%s-redis:6379/0" .Values.redis.password (include "airflow.fullname" .) }}
{{- end }}

{{/*
Service account name
*/}}
{{- define "airflow.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "airflow.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Generate webserver secret key - 64 character random string
✅ FIXED: This generates a secure random key for CSRF protection
*/}}
{{- define "airflow.webserverSecretKey" -}}
{{- randAlphaNum 64 }}
{{- end }}
