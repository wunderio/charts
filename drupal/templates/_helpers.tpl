{{- define "drupal.release_labels" -}}
app: {{ .Values.app | quote }}
release: {{ .Release.Name }}
{{- end }}

{{- define "drupal.php-container" -}}
image: {{ .Values.php.image | quote }}
env: {{ include "drupal.env" . }}
ports:
  - containerPort: 9000
    name: drupal
{{- end }}

{{- define "drupal.volumeMounts" -}}
{{- range $index, $mount := $.Values.mounts }}
{{- if eq $mount.enabled true }}
- name: drupal-{{ $index }}
  mountPath: {{ $mount.mountPath }}
{{- end }}
{{- end }}
- name: php-conf
  mountPath: /etc/php7/php.ini
  readOnly: true
  subPath: php_ini
- name: php-conf
  mountPath: /etc/php7/php-fpm.conf
  readOnly: true
  subPath: php-fpm_conf
- name: php-conf
  mountPath: /etc/php7/php-fpm.d/www.conf
  readOnly: true
  subPath: www_conf
{{ if ne $.Template.Name "drupal/templates/backup-cron.yaml" -}}
- name: gdpr-dump
  mountPath: /etc/my.cnf.d/gdpr-dump.cnf
  readOnly: true
  subPath: gdpr-dump
{{- end }}
- name: settings
  mountPath: /app/web/sites/default/settings.silta.php
  readOnly: true
  subPath: settings_silta_php
{{- end }}

{{- define "drupal.volumes" -}}
{{- range $index, $mount := $.Values.mounts }}
{{- if eq $mount.enabled true }}
- name: drupal-{{ $index }}
  persistentVolumeClaim:
    claimName: {{ $.Release.Name }}-{{ $index }}
{{- end }}
{{- end }}
- name: php-conf
  configMap:
    name: {{ .Release.Name }}-php-conf
{{ if ne $.Template.Name "drupal/templates/backup-cron.yaml" -}}
- name: gdpr-dump
  configMap:
    name: {{ .Release.Name }}-gdpr-dump
{{- end }}
- name: settings
  configMap:
    name: {{ .Release.Name }}-settings
{{- end }}

{{- define "drupal.imagePullSecrets" }}
{{- if .Values.imagePullSecrets }}
imagePullSecrets:
{{ .Values.imagePullSecrets | toYaml }}
{{- end }}
{{- end }}

{{- define "drupal.env" }}
- name: SILTA_CLUSTER
  value: "1"
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
- name: ERROR_LEVEL
  value: {{ .Values.php.errorLevel }}
{{- if .Values.memcached.enabled }}
- name: MEMCACHED_HOST
  value: {{ .Release.Name }}-memcached
{{- end }}
{{- if .Values.elasticsearch.enabled }}
- name: ELASTICSEARCH_HOST
  value: {{ .Release.Name }}-elastic
{{- end }}
- name: HASH_SALT
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-secrets-drupal
      key: hashsalt
- name: DRUPAL_CONFIG_PATH
  value: {{ .Values.php.drupalConfigPath }}
{{- range $key, $val := .Values.php.env }}
- name: {{ $key }}
  value: {{ $val | quote }}
{{- end }}
{{- range $index, $mount := $.Values.mounts }}
- name: {{ regexReplaceAll "[^[:alnum:]]" $index "_" | upper }}_PATH
  value: {{ $mount.mountPath }}
{{- end }}
{{- end }}

{{- define "drupal.basicauth" }}
  {{- if .Values.nginx.basicauth.enabled }}
  satisfy any;
  allow 127.0.0.1;
  {{- range .Values.nginx.basicauth.noauthips }}
  allow {{ . }};
  {{- end }}
  deny all;

  auth_basic "Restricted";
  auth_basic_user_file /etc/nginx/.htaccess;
  {{- end }}
{{- end }}

{{- define "drupal.wait-for-db-command" }}
TIME_WAITING=0
  until mysqladmin status --connect_timeout=2 -u $DB_USER -p$DB_PASS -h $DB_HOST --silent; do
  echo "Waiting for database..."; sleep 5
  TIME_WAITING=$((TIME_WAITING+5))

  if [ $TIME_WAITING -gt 90 ]; then
    echo "Database connection timeout"
    exit 1
  fi
done
{{- end }}

{{- define "drupal.installation-in-progress-test" -}}
-f /app/web/sites/default/files/_installing
{{- end -}}

{{- define "drupal.post-release-command" -}}
set -e

{{ include "drupal.wait-for-db-command" . }}

{{ if .Release.IsInstall }}
touch /app/web/sites/default/files/_installing
{{ .Values.php.postinstall.command}}
rm /app/web/sites/default/files/_installing
{{ else }}
{{ .Values.php.postupgrade.command}}
{{ end }}

{{- if and .Values.referenceData.enabled .Values.referenceData.updateAfterDeployment }}
{{- if eq .Values.referenceData.referenceEnvironment .Values.environmentName }}
{{ .Values.referenceData.command }}
{{- end }}
{{- end }}
{{- end }}
