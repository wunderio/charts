{{- define "frontend.release_labels" }}
app: {{ .Values.app | quote }}
release: {{ .Release.Name }}
{{- end }}

{{- define "frontend.domain" -}}
{{ include "frontend.environmentName" . }}.{{ .Release.Namespace }}.{{ .Values.clusterDomain }}
{{- end -}}

{{- define "frontend.environmentName" -}}
{{ regexReplaceAll "[^[:alnum:]]" (.Values.environmentName | default .Release.Name) "-" | lower }}
{{- end -}}

{{- define "frontend.referenceEnvironment" -}}
{{ regexReplaceAll "[^[:alnum:]]" .Values.referenceData.referenceEnvironment "-" | lower }}
{{- end -}}


{{- define "frontend.basicauth" }}
  {{- if .Values.nginx.basicauth.enabled }}
  satisfy any;
  allow 127.0.0.1;
  {{- range .Values.nginx.noauthips }}
  allow {{ . }};
  {{- end }}
  deny all;

  auth_basic "Restricted";
  auth_basic_user_file /etc/nginx/.htaccess;
  {{- end }}
{{- end }}