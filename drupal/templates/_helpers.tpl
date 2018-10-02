{{- define "drupal.release_labels" }}
app: {{ printf "%s-%s" .Release.Name .Chart.Name | trunc 63 }}
version: {{ .Chart.Version }}
release: {{ .Release.Name }}
{{- end }}
{{- define "drupal.full_name" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 -}}
{{- end -}}
{{- define "drupal.domain" -}}
{{ regexReplaceAll "[^[:alnum:]]" .Values.branchname "-" | lower }}.{{ .Release.Namespace }}.{{ .Values.clusterDomain }}
{{- end -}}