{{/* Specification for a generic drupal container */}}
{{- define "drupal.drupal-container" }}
image: {{ .Values.drupal.image | quote }}
env:
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
- name: HASH_SALT
  valueFrom:
	secretKeyRef:
	  name: {{ .Release.Name }}-secrets-drupal
	  key: hashsalt
{{- range $key, $val := .Values.drupal.env }}
- name: {{ $key }}
  value: {{ $val | quote }}
{{- end }} 
volumeMounts:
- name: drupal-files-volume
  mountPath: /var/www/html/web/sites/default/files
{{- end -}}

{{/* The drupal files volume */}}
{{- define "drupal.drupal-files-volume" }}
- name: drupal-files-volume
  persistentVolumeClaim:
    claimName: {{ .Release.Name }}-public-files
{{- end -}}
