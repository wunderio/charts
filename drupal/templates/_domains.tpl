

{{- define "drupal.domainSeparator" -}}
{{- if .Values.singleSubdomain -}}
-
{{- else -}}
.
{{- end -}}
{{- end -}}

{{- define "drupal.domain" -}}
{{- $projectName := regexReplaceAll "[^[:alnum:]]" (.Values.projectName | default .Release.Namespace) "-"  | trimSuffix "-" | lower }}
{{- $projectNameHash := sha256sum $projectName | trunc 3 }}
{{- $projectName := (ge (len $projectName) 30) | ternary (print ($projectName | trunc 27) $projectNameHash ) $projectName}}

{{- $environmentName := regexReplaceAll "[^[:alnum:]]" (.Values.environmentName | default .Release.Name) "-" | trimSuffix "-" | lower }}
{{- $environmentNameHash := sha256sum $environmentName | trunc 3 }}
{{- if .prefix -}}
{{- $maxEnvironmentNameLength := int (sub 61 (add (len .Values.clusterDomain) (len $projectName) (len .prefix))) }}
{{- $environmentName := (ge (len $environmentName) $maxEnvironmentNameLength) | ternary (print ($environmentName | trunc (int (sub $maxEnvironmentNameLength 3))) $environmentNameHash) $environmentName -}}
{{ .prefix }}{{ include "drupal.domainSeparator" . }}{{ $environmentName }}{{ include "drupal.domainSeparator" . }}{{ $projectName }}.{{ .Values.clusterDomain }}
{{- else -}}
{{- $maxEnvironmentNameLength := int (sub 62 (add (len .Values.clusterDomain) (len $projectName))) }}
{{- $environmentName := (ge (len $environmentName) $maxEnvironmentNameLength) | ternary (print ($environmentName | trunc (int (sub $maxEnvironmentNameLength 3))) $environmentNameHash) $environmentName -}}
{{- if eq $.Values.maskSubdomains "none" -}}
{{ $environmentName }}{{ include "drupal.domainSeparator" . }}{{ $projectName }}.{{ .Values.clusterDomain }}
{{- else if eq $.Values.maskSubdomains "both" -}}
{{- include "masking.prefix-alert" . -}}
{{- $environmentNameString := sha256sum (print $environmentName (include "drupal.domainSeparator" $ ) $projectName) | trunc 25 }}
{{- $environmentNameString -}}.{{ .Values.clusterDomain }}
{{- else if eq $.Values.maskSubdomains "projectName" -}}
{{- include "masking.prefix-alert" . -}}
{{ $environmentName }}{{ include "drupal.domainSeparator" . }}{{ sha256sum $projectName | trunc 10 }}.{{ .Values.clusterDomain }}
{{- else if eq $.Values.maskSubdomains "releaseName" -}}
{{- include "masking.prefix-alert" . -}}
{{ sha256sum $environmentName | trunc 10 }}{{ include "drupal.domainSeparator" . }}{{ $projectName }}.{{ .Values.clusterDomain }}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "drupal.referenceEnvironment" -}}
{{ regexReplaceAll "[^[:alnum:]]" .Values.referenceData.referenceEnvironment "-" | lower | trunc 50 | trimSuffix "-" }}
{{- end -}}

{{- define "drupal.environment.hostname" -}}
{{ regexReplaceAll "[^[:alnum:]]" .Release.Name "-" | lower | trunc 50 | trimSuffix "-" }}
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
