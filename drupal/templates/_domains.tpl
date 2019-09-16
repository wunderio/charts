{{- define "drupal.domain" -}}
{{ include "drupal.environmentName" . }}.{{ regexReplaceAll "[^[:alnum:]]" (.Values.projectName | default .Release.Namespace) "-" | trunc 30 | trimSuffix "-" | lower }}.{{ .Values.clusterDomain }}
{{- end -}}

{{- define "drupal.environmentName" -}}
{{ regexReplaceAll "[^[:alnum:]]" (.Values.environmentName | default .Release.Name) "-" | lower | trunc 50 | trimSuffix "-" }}
{{- end -}}

{{- define "drupal.referenceEnvironment" -}}
{{ regexReplaceAll "[^[:alnum:]]" .Values.referenceData.referenceEnvironment "-" | lower | trunc 50 | trimSuffix "-" }}
{{- end -}}

{{- define "drupal.environment.hostname" -}}
{{ regexReplaceAll "[^[:alnum:]]" (.Values.environmentName | default .Release.Name) "-" | lower | trunc 50 | trimSuffix "-" }}
{{- end -}}

# SSH-related hosts
{{- define "drupal.jumphost" -}}
www-admin@ssh.{{ .Values.clusterDomain }}
{{- end -}}

{{- define "drupal.shellHost" -}}
www-admin@{{ template "drupal.environment.hostname" . }}-shell.{{ .Release.Namespace }}
{{- end -}}

{{- define "drupal.endpoint" -}}
{{- if .Values.varnish.enabled -}}
{{ .Release.Name }}-varnish.{{ .Release.Namespace }}.svc.cluster.local:80
{{- else -}}
{{ .Release.Name }}-drupal.{{ .Release.Namespace }}.svc.cluster.local:80
{{- end -}}
{{- end -}}

{{- define "drupal.servicename" -}}
{{- if .Values.varnish.enabled -}}
{{ .Release.Name }}-varnish
{{- else -}}
{{ .Release.Name }}-drupal
{{- end -}}
{{- end -}}
