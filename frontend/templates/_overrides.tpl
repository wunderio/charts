{{/*
Override templates from subcharts.
*/}}

{{/*
The elasticsearch chart uses an incompatible naming scheme,
we make it compatible by overriding the following templates.
*/}}
{{- define "uname" -}}
{{ .Release.Name }}-es
{{- end }}

{{- define "masterService" -}}
{{ .Release.Name }}-es
{{- end }}

{{- define "endpoints" -}}
{{ .Release.Name }}-es-0
{{- end -}}