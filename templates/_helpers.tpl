{{/*
Chart name truncated to 63 chars.
*/}}
{{- define "mcp.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Fully qualified app name.
If fullnameOverride is set, use it directly.
Otherwise combine release name with chart name (deduplicating when they match).
Truncated to 63 chars per Kubernetes naming constraints.
*/}}
{{- define "mcp.fullname" -}}
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
Chart label value: <name>-<version>
*/}}
{{- define "mcp.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels applied to every resource.
*/}}
{{- define "mcp.labels" -}}
{{ include "mcp.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels used in Deployment matchLabels and Service selectors.
*/}}
{{- define "mcp.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mcp.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Vault annotations for the Banzai Cloud mutating webhook.
Rendered only when vault.enabled is true and both vault.role and vault.path are provided.
*/}}
{{- define "mcp.vault" -}}
{{- if and .Values.vault.enabled .Values.vault.role .Values.vault.path -}}
vault.security.banzaicloud.io/vault-role: {{ .Values.vault.role | quote }}
vault.security.banzaicloud.io/vault-path: {{ .Values.vault.path | quote }}
{{- end }}
{{- end }}

{{/*
ServiceAccount name — uses the override, or falls back to fullname when create=true,
otherwise uses the default ServiceAccount.
*/}}
{{- define "mcp.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "mcp.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
