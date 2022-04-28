{{- define "frontend.release_labels" }}
app: {{ .Values.app | quote }}
release: {{ .Release.Name }}
{{- end }}

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

{{- define "frontend.security_headers" }}
  ## https://www.owasp.org/index.php/List_of_useful_HTTP_headers.
  {{- range $header, $value := .Values.nginx.security_headers }}
  add_header                  {{ $header }} {{ $value }};
  {{- end }}
  add_header                  Strict-Transport-Security "max-age=31536000; {{ .Values.nginx.hsts_include_subdomains }} preload" always;
  {{- if .Values.nginx.content_security_policy }}
  add_header                  Content-Security-Policy "{{ .Values.nginx.content_security_policy }}" always;
  {{- end }}
{{- end }}

{{- define "frontend.tolerations" -}}
{{- range $key, $label := $ }}
- key: {{ $key }}
  operator: Equal
  value: {{ $label }}
{{- end }}
{{- end }}

{{- define "frontend.backup.create-destination-path" -}}
set -ex

# Generate the id of the backup.
BACKUP_ID=`date +%Y-%m-%d-%H-%M-%S`
BACKUP_LOCATION="/backup_archive"

# Related issue: https://github.com/rclone/rclone/issues/3453
mkdir -p "${BACKUP_LOCATION}/${BACKUP_ID}"; touch "${BACKUP_LOCATION}/${BACKUP_ID}/.anchor"

ln -s "${BACKUP_LOCATION}/${BACKUP_ID}" /backups/current
{{- end }}

{{- define "frontend.backup.copy-mounts" -}}
set -e

rsync -az /values_mounts/ /backups/current/
{{- end }}

{{- define "services.env" }}
{{- $service := .service -}}
- name: 'PORT'
  value: {{ default .Values.serviceDefaults.port $service.port | quote }}
- name: PROJECT_NAME
  value: "{{ .Values.projectName | default .Release.Namespace }}"
- name: 'ENVIRONMENT_DOMAIN'
  value: {{ template "frontend.domain" . }}
- name: 'RELEASE_NAME'
  value: {{ .Release.Name | quote }}
{{- range $index, $service := .Values.services }}
- name: "{{ $index }}_HOST"
  value: "{{ $.Release.Name }}-{{ $index }}:{{ default $.Values.serviceDefaults.port $service.port }}"
{{- end }}
# Elasticsearch
{{- if .Values.elasticsearch.enabled }}
- name: ELASTICSEARCH_HOST
  value: {{ .Release.Name }}-es
{{- end }}
# RabbitMQ
{{- if .Values.rabbitmq.enabled }}
- name: RABBITMQ_HOST
  value: {{ .Release.Name }}-rabbitmq
{{- end }}
# MariaDB
{{- if .Values.mariadb.enabled }}
- name: DB_USER
  value: "{{ .Values.mariadb.db.user }}"
- name: DB_NAME
  value: "{{ .Values.mariadb.db.name }}"
- name: DB_HOST
  value: {{ .Release.Name }}-mariadb
- name: DB_PASS
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-mariadb
      key: mariadb-password
{{- end }}
# MongoDB
{{- if .Values.mongodb.enabled }}
- name: MONGODB_HOST
  value: {{ .Release.Name }}-mongodb
{{- end }}
# Shell / Gitauth
{{ if .Values.shell.enabled -}}
- name: GITAUTH_URL
  value: {{ .Values.shell.gitAuth.keyserver.url | default (printf "https://keys.%s/api/1/git-ssh-keys" .Values.clusterDomain) | quote }}
- name: GITAUTH_USERNAME
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-secrets-shell
      key: keyserver.username
- name: GITAUTH_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-secrets-shell
      key: keyserver.password
- name: GITAUTH_SCOPE
  value: {{ .Values.shell.gitAuth.repositoryUrl }}
- name: OUTSIDE_COLLABORATORS
  value: {{ .Values.shell.gitAuth.outsideCollaborators | default true | quote }}
{{- end }}
# Proxy
{{ $proxy := ( index .Values "silta-release" ).proxy }}
{{ if $proxy.enabled }}
# The http_proxy needs to be defined in lowercase.
# The HTTPS_PROXY needs to be defined in uppercase.
# It is recommended to define both in both cases.
- name: http_proxy
  value: "{{ $proxy.url }}:{{ $proxy.port }}"
- name: HTTP_PROXY
  value: "{{ $proxy.url }}:{{ $proxy.port }}"
- name: https_proxy
  value: "{{ $proxy.url }}:{{ $proxy.port }}"
- name: HTTPS_PROXY
  value: "{{ $proxy.url }}:{{ $proxy.port }}"
- name: no_proxy
  value: .svc.cluster.local,{{ .Release.Name }}-mongodb,{{ .Release.Name }}-es{{ if $proxy.no_proxy }},{{$proxy.no_proxy}}{{ end }}
- name: NO_PROXY
  value: .svc.cluster.local,{{ .Release.Name }}-mongodb,{{ .Release.Name }}-es{{ if $proxy.no_proxy }},{{$proxy.no_proxy}}{{ end }}
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
{{- if ( .Capabilities.APIVersions.Has "networking.k8s.io/v1" ) }}
networking.k8s.io/v1
{{- else }}
networking.k8s.io/v1beta1
{{- end }}
{{- end }}

{{- define "frontend.cron.api-version" }}
{{- if ( .Capabilities.APIVersions.Has "batch/v1" ) }}
batch/v1
{{- else }}
batch/v1beta1
{{- end }}
{{- end }}

{{- define "frontend.autoscaling.api-version" }}
{{- if ( .Capabilities.APIVersions.Has "autoscaling/v2" ) }}
autoscaling/v2
{{- else }}
autoscaling/v2beta1
{{- end }}
{{- end }}
