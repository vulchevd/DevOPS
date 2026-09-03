{{- define "tasks-api.name" -}}
tasks-api
{{- end -}}

{{- define "tasks-api.labels" -}}
app.kubernetes.io/name: {{ include "tasks-api.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "tasks-api.selectorLabels" -}}
app.kubernetes.io/name: {{ include "tasks-api.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
