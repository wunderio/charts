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
We don't use roles for elasticsearch 6 and having them set in later 
chart versions, breaks deployment. So we add conditional on it.
*/}}
{{- define "elasticsearch.roles" -}}
{{- if gt (int (include "elasticsearch.esMajorVersion" .)) 6 }}
{{- range $.Values.roles -}}
{{ . }},
{{- end -}}
{{- end -}}
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
