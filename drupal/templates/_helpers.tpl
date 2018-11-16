{{- define "drupal.release_labels" }}
app: {{ .Values.app | quote }}
release: {{ .Release.Name }}
{{- end }}

{{- define "shell.release_labels" }}
app: shell
release: {{ .Release.Name }}
{{- end }}

{{- define "drupal.domain" -}}
{{ include "drupal.environmentName" . }}.{{ .Release.Namespace }}.{{ .Values.clusterDomain }}
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

{{- define "drupal.php-container" }}
image: {{ .Values.php.image | quote }}
env: {{ include "drupal.env" . }}
ports:
  - containerPort: 9000
    name: drupal
volumeMounts:
  {{ include "drupal.volumeMounts" . | indent 8 }}
{{- end }}

{{- define "shell.ssh-container" }}
image: {{ .Values.shell.image | quote }}
env:
  {{ include "drupal.env" . | indent 2 }}
  - name: GITAUTH_API_TOKEN
    value: "{{ .Values.shell.gitAuth.apiToken }}"
  - name: GITAUTH_REPOSITORY_URL
    value: "{{ .Values.shell.gitAuth.repositoryUrl }}"
ports:
  - containerPort: 22
volumeMounts:
  {{ include "drupal.volumeMounts" . | indent 8 }}
{{- end }}

{{- define "drupal.volumeMounts" }}
  - name: drupal-public-files
    mountPath: /var/www/html/web/sites/default/files
  {{- if .Values.privateFiles.enabled }}
  - name: drupal-private-files
    mountPath: /var/www/html/private
  {{- end }}
  {{- if .Values.referenceData.enabled }}  
  - name: reference-data-volume
    mountPath: /var/www/html/reference-data
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
{{- end }}

{{- define "drupal.volumes" }}
- name: drupal-public-files
  persistentVolumeClaim:
    claimName: {{ .Release.Name }}-public-files
{{- if .Values.privateFiles.enabled }}
- name: drupal-private-files
  persistentVolumeClaim:
    claimName: {{ .Release.Name }}-private-files
{{- end }}
- name: php-conf
  configMap:
    name: {{ .Release.Name }}-php-conf
    items:
      - key: php_ini
        path: php_ini
      - key: php-fpm_conf
        path: php-fpm_conf
      - key: www_conf
        path: www_conf
{{- if .Values.referenceData.enabled }}        
- name: reference-data-volume
  persistentVolumeClaim:
    claimName: {{ include "drupal.referenceEnvironment" . }}-reference-data
{{- end }}
{{- end }}

{{- define "drupal.imagePullSecrets" }}
{{- if .Values.imagePullSecrets }}
imagePullSecrets:
{{ .Values.imagePullSecrets | toYaml }}
{{- end }}
{{- end }}

{{- define "drupal.env" }}
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
- name: HASH_SALT
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-secrets-drupal
      key: hashsalt
{{- range $key, $val := .Values.php.env }}
- name: {{ $key }}
  value: {{ $val | quote }}
{{- end }}
{{- if .Values.privateFiles.enabled }}
- name: PRIVATE_FILES_PATH
  value: '/var/www/html/private'
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