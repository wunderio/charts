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

{{/*
The mariadb chart switched to an incompatible naming scheme,
we make it compatible by overriding the following templates.
*/}}
{{- define "mariadb.fullname" -}}
{{ .Release.Name }}-mariadb
{{- end }}

{{/*
The way pxc chart trims resource names can cause resource collisions so we add hash to it.
https://github.com/percona/percona-helm-charts/blob/main/charts/pxc-db/templates/_helpers.tpl
*/}}
{{- define "pxc-database.fullname" -}}
{{- $releaseNameHash := sha256sum .Release.Name | trunc 3 -}}
{{- (gt (len .Release.Name) 22) | ternary ( print (.Release.Name | trunc 18) print $releaseNameHash ) .Release.Name }}
{{- end -}}
