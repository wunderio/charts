{{- define "simple.release_labels" }}
app: {{ .Values.app | quote }}
release: {{ .Release.Name }}
{{- end }}

{{- define "simple.domainSeparator" -}}
{{- if .Values.singleSubdomain -}}
-
{{- else -}}
.
{{- end -}}
{{- end -}}

{{- define "simple.domain" -}}
{{- $projectName := regexReplaceAll "[^[:alnum:]]" (.Values.projectName | default .Release.Namespace) "-"  | trimSuffix "-" | lower }}
{{- $projectNameHash := sha256sum $projectName | trunc 3 }}
{{- $projectName := (ge (len $projectName) 30) | ternary (print ($projectName | trunc 27) $projectNameHash ) $projectName}}

{{- $environmentName := regexReplaceAll "[^[:alnum:]]" (.Values.environmentName | default .Release.Name) "-" | trimSuffix "-" | lower }}
{{- $environmentNameHash := sha256sum $environmentName | trunc 3 }}
{{- $maxEnvironmentNameLength := int (sub 62 (add (len .Values.clusterDomain) (len $projectName))) }}
{{- $environmentName := (ge (len $environmentName) $maxEnvironmentNameLength) | ternary (print ($environmentName | trunc (int (sub $maxEnvironmentNameLength 3))) $environmentNameHash) $environmentName -}}

{{ $environmentName }}{{ include "simple.domainSeparator" . }}{{ $projectName }}.{{ .Values.clusterDomain }}
{{- end -}} 

{{- define "simple.referenceEnvironment" -}}
{{ regexReplaceAll "[^[:alnum:]]" .Values.referenceData.referenceEnvironment "-" | lower }}
{{- end -}}

{{- define "simple.basicauth" }}
  {{- if .Values.nginx.basicauth.enabled }}
  satisfy any;
  allow 127.0.0.1;
  {{- if .Values.nginx.noauthips }}
  {{- range .Values.nginx.noauthips }}
  allow {{ . }};
  {{- end }}
  {{- end }}
  deny all;

  auth_basic "Restricted";
  auth_basic_user_file /etc/nginx/.htaccess;
  {{- end }}
{{- end }}

{{- define "cert-manager.api-version" }}
{{- if ( .Capabilities.APIVersions.Has "cert-manager.io/v1" ) }}
cert-manager.io/v1
{{- else }}
certmanager.k8s.io/v1alpha1
{{- end }}
{{- end }}

{{- define "ingress.api-version" }}
{{- if and ( ge $.Capabilities.KubeVersion.Major "1") ( ge $.Capabilities.KubeVersion.Minor "18" ) }}
networking.k8s.io/v1
{{- else }}
networking.k8s.io/v1beta1
{{- end }}
{{- end }}

{{- define "simple.autoscaling.api-version" }}
{{- if and ( ge $.Capabilities.KubeVersion.Major "1") ( ge $.Capabilities.KubeVersion.Minor "23" ) }}
autoscaling/v2
{{- else }}
autoscaling/v2beta1
{{- end }}
{{- end }}

{{- define "simple.imagePullSecrets" }}
{{- if or .Values.imagePullSecrets .Values.imagePullSecret }}
imagePullSecrets:
{{- if .Values.imagePullSecrets }}
{{ .Values.imagePullSecrets | toYaml }}
{{- end }}
{{- if .Values.imagePullSecret }}
- name: {{ .Release.Name }}-registry
{{- end }}
{{- end }}
{{- end }}

{{- define "simple.serviceAccountName" }}
{{- if .Values.serviceAccount.name }}
{{- .Values.serviceAccount.name }}
{{- else }}
{{- .Release.Name }}-sa
{{- end }}
{{- end }}
