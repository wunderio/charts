{{/*
Override templates from subcharts.
*/}}

{{/*
The elasticsearch chart uses an incompatible naming scheme,
we make it compatible by overriding the following templates.
*/}}
{{- define "elasticsearch.uname" -}}
{{ .Release.Name }}-es
{{- end }}

{{- define "elasticsearch.masterService" -}}
{{ .Release.Name }}-es
{{- end }}

{{- define "elasticsearch.endpoints" -}}
{{ .Release.Name }}-es-0
{{- end -}}