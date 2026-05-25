{{/*
Expand the name of the chart.
*/}}
{{- define "bmlt-server.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "bmlt-server.fullname" -}}
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
{{- define "bmlt-server.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "bmlt-server.labels" -}}
helm.sh/chart: {{ include "bmlt-server.chart" . }}
{{ include "bmlt-server.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "bmlt-server.selectorLabels" -}}
app.kubernetes.io/name: {{ include "bmlt-server.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Container environment shared by the Deployment and the aggregator CronJob.
The bmlt-server app reads DB_USERNAME/DB_PASSWORD/etc. and GOOGLE_API_KEY
(see App\ConfigBase::fromEnv). Each value can come from a referenced Secret
({name,key}) or an inline plaintext value.
*/}}
{{- define "bmlt-server.env" -}}
- name: AGGREGATOR_MODE_ENABLED
  value: {{ .Values.bmlt.aggregatorMode.enabled | quote }}
- name: DB_DATABASE
  value: {{ .Values.database.name | quote }}
- name: DB_HOST
  value: {{ .Values.database.host | quote }}
- name: DB_PORT
  value: {{ .Values.database.port | quote }}
- name: DB_USERNAME
{{- if .Values.database.secrets.username }}
  valueFrom:
    secretKeyRef:
      name: {{ tpl .Values.database.secrets.username.name . }}
      key: {{ tpl .Values.database.secrets.username.key . }}
{{- else if .Values.database.username }}
  value: {{ .Values.database.username | quote }}
{{- end }}
- name: DB_PASSWORD
{{- if .Values.database.secrets.password }}
  valueFrom:
    secretKeyRef:
      name: {{ tpl .Values.database.secrets.password.name . }}
      key: {{ tpl .Values.database.secrets.password.key . }}
{{- else if .Values.database.password }}
  value: {{ .Values.database.password | quote }}
{{- end }}
- name: DB_PREFIX
  value: {{ .Values.database.dbprefix | default "na" | quote }}
{{- if or .Values.bmlt.secrets.googleApiKey .Values.bmlt.googleApiKey }}
- name: GOOGLE_API_KEY
{{- if .Values.bmlt.secrets.googleApiKey }}
  valueFrom:
    secretKeyRef:
      name: {{ tpl .Values.bmlt.secrets.googleApiKey.name . }}
      key: {{ tpl .Values.bmlt.secrets.googleApiKey.key . }}
{{- else }}
  value: {{ .Values.bmlt.googleApiKey | quote }}
{{- end }}
{{- end }}
{{- with .Values.extraEnv }}
{{ toYaml . }}
{{- end }}
{{- end }}
