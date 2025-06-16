{{- define "drupal.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "drupal.release_selector_labels" -}}
app: {{ .Values.app | quote }}
release: {{ .Release.Name }}
{{- end }}

{{- define "drupal.release_labels" -}}
{{- include "drupal.release_selector_labels" . }}
app.kubernetes.io/name: {{ .Values.app | quote }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ template "drupal.chart" . }}
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
- name: config
  mountPath: /usr/local/etc/php/conf.d/silta.ini
  readOnly: true
  subPath: php_ini
- name: config
  mountPath: {{ .Values.webRoot }}/sites/default/settings.silta.php
  readOnly: true
  subPath: settings_silta_php
- name: config
  mountPath: {{ .Values.webRoot }}/sites/default/silta.services.yml
  readOnly: true
  subPath: silta_services_yml
- name: config
  mountPath: /tmp/zz-custom.conf
  readOnly: false
  subPath: php_fpm_d_custom
- name: config
  mountPath: /app/.ssh/config
  readOnly: true
  subPath: ssh_config
- name: config
  mountPath: /app/gdpr-dump.yaml
  readOnly: true
  subPath: gdpr-dump
{{- end }}

{{- define "drupal.volumes" -}}
{{- range $index, $mount := $.Values.mounts -}}
{{- if eq $mount.enabled true }}
- name: drupal-{{ $index }}
{{- if hasKey $mount "secretName" }}
  secret:
    secretName: {{ $mount.secretName }}
{{- else if hasKey $mount "configMapName" }}
  configMap:
    name: {{ $mount.configMapName }}
{{- else }}
  persistentVolumeClaim:
    {{- if and ( eq $mount.storageClassName "silta-shared" ) ( eq ( include "silta-cluster.rclone.has-provisioner" $ ) "true" ) }}
    claimName: {{ $.Release.Name }}-{{ $index }}2
    {{- else }}
    claimName: {{ $.Release.Name }}-{{ $index }}
    {{- end }}
{{- end }}
{{- end }}
{{- end }}
- name: config
  configMap:
    name: {{ .Release.Name }}-drupal
    defaultMode: 0755
{{- end }}

{{- define "drupal.imagePullSecrets" }}
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

{{- define "smtp.env" }}
- name: SMTP_ADDRESS
  {{- if .Values.mailpit.enabled }}
  value: "{{ .Release.Name }}-mailpit-smtp:25"
  {{ else if .Values.mailhog.enabled }}
  value: "{{ .Release.Name }}-mailhog:1025"
  {{ else }}
  value: {{ .Values.smtp.address | quote }}
  {{- end }}
- name: SMTP_TLS
  value: {{ .Values.smtp.tls | default false | quote }}
- name: SMTP_STARTTLS
  value: {{ .Values.smtp.starttls | default false | quote }}
- name: SMTP_USERNAME
  value: {{ .Values.smtp.username | quote }}
- name: SMTP_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-secrets-smtp
      key: password
# Duplicate SMTP env variables for ssmtp bundled with amazee php image
- name: SSMTP_MAILHUB
  {{- if .Values.mailpit.enabled }}
  value: "{{ .Release.Name }}-mailpit-smtp:25"
  {{ else if .Values.mailhog.enabled }}
  value: "{{ .Release.Name }}-mailhog:1025"
  {{ else }}
  value: {{ .Values.smtp.address | quote }}
  {{- end }}
- name: SSMTP_USETLS
  value: {{ .Values.smtp.tls | default false | quote }}
- name: SSMTP_USESTARTTLS
  value: {{ .Values.smtp.starttls | default false | quote }}
- name: SSMTP_AUTHUSER
  value: {{ .Values.smtp.username | quote }}
- name: SSMTP_AUTHPASS
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-secrets-smtp
      key: password
{{- end }}

{{- define "drupal.ref-data-env" }}
- name: REF_DATA_COPY_DB
  value: {{ .Values.referenceData.copyDatabase | quote }}
- name: REF_DATA_COPY_FILES
  value: {{ .Values.referenceData.copyFiles | quote }}
{{- end }}

{{- define "drupal.db-env" }}
{{- if .Values.mariadb.enabled }}
- name: MARIADB_DB_USER
  value: "{{ .Values.mariadb.db.user }}"
- name: MARIADB_DB_NAME
  value: "{{ .Values.mariadb.db.name }}"
- name: MARIADB_DB_HOST
  value: {{ .Release.Name }}-mariadb
- name: MARIADB_DB_PASS
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-mariadb
      key: mariadb-password
{{- end }}
{{- if index ( index .Values "pxc-db" ) "enabled" }}
- name: PXC_DB_USER
  value: "root"
- name: PXC_DB_NAME
  value: "drupal"
- name: PXC_DB_HOST
  value: {{ include "pxc-database.fullname" . }}-proxysql
- name: PXC_DB_PASS
  valueFrom:
    secretKeyRef:
      name: {{ include "pxc-database.fullname" . }}
      key: root
{{- end }}
{{- if and .Values.mariadb.enabled ( eq .Values.db.primary "mariadb" ) }}
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
{{- if and ( index ( index .Values "pxc-db" ) "enabled" ) ( eq .Values.db.primary "pxc-db" ) }}
- name: DB_USER
  value: "root"
- name: DB_NAME
  value: "drupal"
- name: DB_HOST
  value: {{ include "pxc-database.fullname" . }}-proxysql
- name: DB_PASS
  valueFrom:
    secretKeyRef:
      name: {{ include "pxc-database.fullname" . }}
      key: root
{{- end }}
{{- end }}

{{- define "drupal.env" }}
- name: SILTA_CLUSTER
  value: "1"
- name: PROJECT_NAME
  value: "{{ .Values.projectName | default .Release.Namespace }}"
- name: ENVIRONMENT_NAME
  value: "{{ .Values.environmentName }}"
- name: RELEASE_NAME
  value: "{{ .Release.Name }}"
{{- if not .Values.php.env.DRUSH_OPTIONS_URI }}
- name: DRUSH_OPTIONS_URI
  value: "http://{{- template "drupal.domain" . }}"
{{- end }}
{{- if .Values.timezone }}
- name: TZ
  value: {{ .Values.timezone | quote }}
{{- end }}
{{- include "drupal.db-env" . }}
- name: ERROR_LEVEL
  value: {{ .Values.php.errorLevel }}
{{- if .Values.memcached.enabled }}
{{- if contains "memcache" .Release.Name -}}
{{- fail "Do not use 'memcache' in release name or deployment will fail" -}}
{{- end }}
- name: MEMCACHED_HOST
  value: {{ .Release.Name }}-memcached
{{- end }}
{{- if .Values.redis.enabled }}
{{- if contains "redis" .Release.Name -}}
{{- fail "Do not use 'redis' in release name or deployment will fail" -}}
{{- end }}
{{- if eq .Values.redis.auth.password "" }}
{{- fail ".Values.redis.auth.password value required." }}
{{- end }}
- name: REDIS_HOST
  value: {{ .Release.Name }}-redis-master
- name: REDIS_PASS
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-redis
      key: redis-password
{{- end }}
{{- if .Values.elasticsearch.enabled }}
- name: ELASTICSEARCH_HOST
  value: {{ .Release.Name }}-es
{{- end }}
{{- if or .Values.mailhog.enabled .Values.mailpit.enabled .Values.smtp.enabled }}
{{- if .Values.mailhog.enabled }}
{{- if contains "mailhog" .Release.Name -}}
{{- fail "Do not use 'mailhog' in release name or deployment will fail" -}}
{{- end }}
{{- end }}
{{- if .Values.mailpit.enabled }}
{{- if contains "mailpit" .Release.Name -}}
{{- fail "Do not use 'mailpit' in release name or deployment will fail" -}}
{{- end }}
{{- end }}
{{ include "smtp.env" . }}
{{- end}}
{{- if .Values.referenceData.enabled }}
  {{ include "drupal.ref-data-env" . }}
{{- end }}
{{- if .Values.varnish.enabled }}
- name: VARNISH_ADMIN_HOST
  value: {{ .Release.Name }}-varnish
- name: VARNISH_ADMIN_PORT
  value: "6082"
- name: VARNISH_CONTROL_KEY
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-secrets-varnish
      key: control_key
{{- end }}
- name: HASH_SALT
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-secrets-drupal
      key: hashsalt
- name: DRUPAL_CONFIG_PATH
  value: {{ .Values.php.drupalConfigPath }}
- name: DRUPAL_CORE_VERSION
  value: {{ .Values.php.drupalCoreVersion | quote }}
{{- if .Values.solr.enabled }}
- name: SOLR_HOST
  value: {{ .Release.Name }}-solr
{{- end }}
{{- if .Values.clamav.enabled }}
- name: CLAMAV_HOST
  value: {{ .Release.Name }}-clamav
- name: CLAMAV_PORT
  value: "3310"
{{- end }}
# Environment overrides via values file
{{- range $key, $val := .Values.php.env }}
- name: {{ $key }}
{{- if or (kindIs "string" $val) (kindIs "int" $val) (kindIs "float64" $val) (kindIs "bool" $val) (kindIs "invalid" $val) }}
  value: {{ $val | quote }}
{{- else }}
  {{ $val | toYaml | indent 4 | trim }}
{{- end }}
{{- end }}
{{- range $index, $mount := $.Values.mounts }}
{{- if eq $mount.enabled true }}
- name: {{ regexReplaceAll "[^[:alnum:]]" $index "_" | upper }}_PATH
  value: {{ $mount.mountPath }}
{{- end }}
{{- end }}
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
  value: 127.0.0.1,localhost,.svc.cluster.local,{{ .Release.Name }}-memcached,{{ .Release.Name }}-redis,{{ .Release.Name }}-es,{{ .Release.Name }}-clamav,{{ .Release.Name }}-varnish,{{ .Release.Name }}-solr{{ if $proxy.no_proxy }},{{$proxy.no_proxy}}{{ end }}
- name: NO_PROXY
  value: 127.0.0.1,localhost,.svc.cluster.local,{{ .Release.Name }}-memcached,{{ .Release.Name }}-redis,{{ .Release.Name }}-es,{{ .Release.Name }}-clamav,{{ .Release.Name }}-varnish,{{ .Release.Name }}-solr{{ if $proxy.no_proxy }},{{$proxy.no_proxy}}{{ end }}
{{- end }}
{{- end }}

{{- define "drupal.tolerations" -}}
{{- range $key, $label := $ }}
- key: {{ $key }}
  operator: Equal
  value: {{ $label }}
{{- end }}
{{- end }}

{{- define "drupal.basicauth" }}
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

{{- define "drupal.wait-for-db-command" }}
TIME_WAITING=0
echo "Waiting for database.";
until mysqladmin status --connect-timeout=2 -u $DB_USER -p$DB_PASS -h $DB_HOST -P ${DB_PORT:-3306} --silent; do
  echo -n "."
  sleep 5
  TIME_WAITING=$((TIME_WAITING+5))

  if [ $TIME_WAITING -gt 300 ]; then
    echo "Database connection timeout"
    exit 1
  fi
done
{{- end }}

{{- define "drupal.create-db" }}
mysql -u $DB_USER -p$DB_PASS -h $DB_HOST -P ${DB_PORT:-3306} -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;"
{{- end }}

{{- define "drupal.wait-for-elasticsearch-command" }}
TIME_WAITING=0
echo -n "Waiting for Elasticsearch.";
until curl --silent --connect-timeout 2 "{{ .Values.elasticsearch.protocol }}://${ELASTICSEARCH_HOST}:9200" -k ; do
  echo -n "."
  sleep 5
  TIME_WAITING=$((TIME_WAITING+5))

  if [ $TIME_WAITING -gt 300 ]; then
    echo "Elasticsearch connection timeout"
    exit 1
  fi
done
{{- end }}

{{- define "drupal.installing-file" -}}
  {{ .Values.webRoot }}/sites/default/files/_installing
{{- end }}

{{- define "drupal.installation-in-progress-test" -}}
-f {{ include "drupal.installing-file" . }}
{{- end -}}

{{- define "drupal.data-push-command" }}
{{ include "drupal.extract-reference-data" . }}
{{- end }}

{{- define "drupal.data-pull-command" }}
set -e

INSTALLING_FILE="{{ include "drupal.installing-file" . }}"

# Attempt to remove the _installing file at the very beginning, ignoring errors if it doesn't exist.
# This cleans up state from a potential previous failed install run.
rm -f "$INSTALLING_FILE"

{{ include "drupal.import-reference-files" . }}

{{ include "drupal.wait-for-db-command" . }}
{{ include "drupal.create-db" . }}
touch "$INSTALLING_FILE"
{{ include "drupal.import-reference-db" . }}

{{ if .Values.elasticsearch.enabled }}
  {{ include "drupal.wait-for-elasticsearch-command" . }}
{{ end }}

{{ .Values.php.postinstall.command }}

rm -f "$INSTALLING_FILE"

{{ .Values.php.postupgrade.command }}
{{- if .Values.php.postupgrade.afterCommand }}
  {{ .Values.php.postupgrade.afterCommand }}
{{- end }}

# Wait for background imports to complete.
wait
{{- end }}

{{- define "drupal.post-release-command" -}}
  set -e

  INSTALLING_FILE="{{ include "drupal.installing-file" . }}"

  # Attempt to remove the _installing file at the very beginning, ignoring errors if it doesn't exist.
  # This cleans up state from a potential previous failed install run.
  rm -f "$INSTALLING_FILE" || true

  {{ if and .Release.IsInstall .Values.referenceData.enabled -}}
    {{ include "drupal.import-reference-files" . }}
  {{- end }}

  {{ include "drupal.wait-for-db-command" . }}
  {{ include "drupal.create-db" . }}

  {{ if .Release.IsInstall }}
    touch "$INSTALLING_FILE"
    {{- if .Values.referenceData.enabled }}
      {{ include "drupal.import-reference-db" . }}
    {{- end }}
  {{- end }}

  {{ if .Values.elasticsearch.enabled }}
    {{ include "drupal.wait-for-elasticsearch-command" . }}
  {{ end }}

  {{ if .Release.IsInstall }}
    {{ .Values.php.postinstall.command }}
    rm -f "$INSTALLING_FILE"
  {{ end }}
  {{ .Values.php.postupgrade.command }}
  {{- if .Values.php.postupgrade.afterCommand }}
    {{ .Values.php.postupgrade.afterCommand }}
  {{- end }}

  # Wait for background imports to complete.
  wait

  {{- if and .Values.referenceData.enabled .Values.referenceData.updateAfterDeployment }}
    {{- if eq .Values.referenceData.referenceEnvironment .Values.environmentName }}
      {{ include "drupal.extract-reference-data" . }}
    {{- end }}
  {{- end }}
{{- end }}

{{- define "drupal.extract-reference-data" -}}
set -e
if [[ "$(drush status --fields=bootstrap)" = *'Successful'* ]] ; then
  if [ "${REF_DATA_COPY_DB:-}" == "true" ]; then
    echo "Dump reference database."
    dump_dir=/tmp/reference-data-export/
    mkdir "${dump_dir}"

    echo "Dump reference database."
    gdpr-dump /app/gdpr-dump.yaml > /tmp/db.sql

    previous_wd=$(pwd)
    cd "${dump_dir}" || exit

    # Split the dump to one file per table. Use 4 digit suffix so that we don't run into sorting issues when there are over 100 or 1000 tables.
    csplit \
      --silent \
      --prefix='table-' \
      --suffix-format='%04d' \
      /tmp/db.sql \
      '/-- Table structure for table/-1' \
      '{*}'
    # First file is the mysqldump header, rename it to "header"
    mv table-0000 header
    # Find last table file
    last_table=$(find -type f -name 'table-*' | sort -n | tail -n1)
    # Split last table file to extract mysqldump footer, which starts with a line including "@OLD_"
    csplit \
      --silent \
      --prefix='last-' \
      "${last_table}" \
      '/@OLD_/'
    # Replace $last_table with the version of it that has footer extracted from it
    mv last-00 "${last_table}"
    # Rename the extracted footer to "footer"
    mv last-01 footer
    # Prepend header and append footer to all table files, save them as <table_name>.sql
    for file in table-*; do
      table_name=$(grep 'Table structure for table' ${file} | cut -d$'\x60' -f2)
      cat header "${file}" footer > "${table_name}.sql"
    done
    # Remove all non .sql files
    find . -type f ! -name '*.sql' -delete

    cd "${previous_wd}"

    # Compress the sql files into a single file and copy it into the backup folder.
    # We don't do this directly on the volume mount to avoid sending the uncompressed dump across the network.
    tar -cf /tmp/db.tar.gz -I 'gzip -1' -C "${dump_dir}" .
    cp /tmp/db.tar.gz /app/reference-data/db.tar.gz && echo "Saved db.tar.gz"

    # For backwards compability, we keep this older method of saving reference data. This way it will be easier to roll back if needed.
    # This will be removed once the new method has successfully been rolled out.
    gzip -1 /tmp/db.sql
    cp /tmp/db.sql.gz /app/reference-data/db.sql.gz && echo "Saved db.sql.gz"
  fi

  if [ "${REF_DATA_COPY_FILES:-}" == "true" ]; then
    {{ range $index, $mount := .Values.mounts -}}
    {{- if eq $mount.enabled true -}}
    # File backup for {{ $index }} volume.
    echo "Dump reference files for {{ $index }} volume."

    # Update reference data files.
    rsync -rvu "{{ $mount.mountPath }}/" \
      --max-size="{{ $.Values.referenceData.maxFileSize }}" \
      {{ range $folderIndex, $folderPattern := $.Values.referenceData.ignoreFolders -}}
      --exclude="{{ $folderPattern }}" \
      {{ end -}}
      --delete --delete-excluded \
      /app/reference-data/{{ $index }}
    {{ end -}}
    {{- end }}
  fi
else
  echo "Drupal bootstrap unsuccessful, skipping reference database dump."
fi
{{- end }}

{{- define  "drupal.import-reference-db" -}}
if [ "${REF_DATA_COPY_DB:-}" == "true" ]; then
  if [[ -f /app/reference-data/db.tar.gz || -f /app/reference-data/db.sql.gz ]]; then
    echo "Dropping old database"
    drush sql-drop -y

    app_ref_data=/app/reference-data
    tmp_ref_data=/tmp/reference-data
    import_method={{ .Values.referenceData.databaseImportMethod }}

    # New way of importing.
    if [[ -f "${app_ref_data}/db.tar.gz" ]]; then
      echo "Importing reference database dump from db.tar.gz"
      mkdir "${tmp_ref_data}"
      tar -xzf "${app_ref_data}/db.tar.gz" -C "${tmp_ref_data}/"

      if [[ "$import_method" == "parallel" ]]; then
        echo "Importing SQL files in parallel. This setting can be changed in silta.yml using the referenceData.databaseImportMethod key."
        find "${tmp_ref_data}/" -type f -name "*.sql" | xargs -P10 -I{} sh -c 'echo "Importing {}" && mysql -A --user="${DB_USER}" --password="${DB_PASS}" --host="${DB_HOST}" "${DB_NAME}" < {}'
        pipeline_exit_code=$? # Capture exit code of the pipeline (most likely influenced by xargs)

        # Check if xargs reported an error (any non-zero exit status)
        if [ "$pipeline_exit_code" -ne 0 ]; then
          echo "ERROR: One or more parallel imports failed. Check the logs above for specific mysql errors."
          exit 1
        fi

        echo "Parallel import command finished."

      elif [[ "$import_method" == "sequential" ]]; then
        echo "Importing SQL files sequentially. This setting can be changed in silta.yml using the referenceData.databaseImportMethod key."
        find "${tmp_ref_data}/" -type f -name "*.sql" | sort | while IFS= read -r sql_file; do
          echo "Importing ${sql_file}"
          if ! mysql -A --user="${DB_USER}" --password="${DB_PASS}" --host="${DB_HOST}" "${DB_NAME}" < "${sql_file}"; then
            echo "ERROR: Failed to import ${sql_file}. Check the logs above for specific mysql errors."
            exit 1
          fi
        done

        echo "Sequential import command finished."

      else
        echo "Incompatible import method. Please use either 'parallel' or 'sequential' in referenceData.databaseImportMethod."
        exit 1
      fi

    # Backwards compatibility for old way of importing.
    elif [[ -f "${app_ref_data}/db.sql.gz" ]]; then
      echo "Importing reference database dump from db.sql.gz"
      gunzip -c "${app_ref_data}/db.sql.gz" > "${tmp_ref_data}-db.sql"
      pv -f "${tmp_ref_data}-db.sql" | drush sql-cli
    fi

    # Clear caches before doing anything else.
    if [[ "${DRUPAL_CORE_VERSION}" -eq 7 ]] ; then
      drush cache-clear all;
    else
      drush cache-rebuild;
    fi
  else
    printf "\e[33mNo reference data found, please install Drupal or import a database dump. See release information for instructions.\e[0m\n"
  fi
fi
{{- end }}

{{- define "drupal.import-reference-files" }}
if [ "${REF_DATA_COPY_FILES:-}" == "true" ]; then
  {{ range $index, $mount := .Values.mounts -}}
  {{- if eq $mount.enabled true -}}
  if [ -d "/app/reference-data/{{ $index }}" ] && [ -n "$(ls /app/reference-data/{{ $index }})" ]; then
    echo "Importing {{ $index }} files"
    # skip subfolders
    rsync -r --delete --temp-dir=/tmp/ --filter "- */" "/app/reference-data/{{ $index }}/" "{{ $mount.mountPath }}" &
    # run rsync for each subfolder
    for f in /app/reference-data/{{ $index }}/*/; do
      subfolder="$(realpath -s $f)"
      rsync -r --delete --temp-dir=/tmp/ "${subfolder}" "{{ $mount.mountPath }}" &
    done
  fi
  {{ end -}}
  {{- end }}
fi
{{- end }}

{{- define "drupal.backup-command" -}}
  {{ include "drupal.backup-command.dump-database" . }}
  {{ include "drupal.backup-command.archive-store-backup" . }}
{{- end }}

{{- define "drupal.backup-command.dump-database" -}}
  set -e

  # Add initial delay to allow mariadb to fully initialize
  echo "Waiting 30 seconds for database to fully initialize..."
  sleep 30

  # Generate the id of the backup.
  BACKUP_ID=`date +%Y-%m-%d-%H-%M-%S`
  BACKUP_LOCATION="/backups/$BACKUP_ID"

  # Figure out which tables to skip.
  IGNORE_TABLES=""
  IGNORED_TABLES=""
  for TABLE in `drush sql-query "show tables;" | grep -E '{{ .Values.backup.ignoreTableContent }}'` ;
  do
    IGNORE_TABLES="$IGNORE_TABLES --ignore-table=$DB_NAME.$TABLE";
    IGNORED_TABLES="$IGNORED_TABLES $TABLE";
  done

  # Take a database dump.
  echo "Starting database backup."
  /usr/bin/mysqldump -u $DB_USER --password=$DB_PASS -h $DB_HOST --skip-lock-tables --single-transaction --max_allowed_packet=1G --quick $IGNORE_TABLES $DB_NAME > /tmp/db.sql
  /usr/bin/mysqldump -u $DB_USER --password=$DB_PASS -h $DB_HOST --skip-lock-tables --single-transaction --max_allowed_packet=1G --quick --force --no-data $DB_NAME $IGNORED_TABLES >> /tmp/db.sql
  echo "Database backup complete."
{{- end }}

{{- define "drupal.backup-command.archive-store-backup" -}}

  # Compress the database dump and copy it into the backup folder.
  # We don't do this directly on the volume mount to avoid sending the uncompressed dump across the network.
  echo "Compressing database backup."
  gzip -k1 /tmp/db.sql

  # Create a folder for the backup
  mkdir -p $BACKUP_LOCATION
  cp /tmp/db.sql.gz $BACKUP_LOCATION/db.sql.gz

  {{- if not .Values.backup.skipFiles }}
  {{ range $index, $mount := .Values.mounts -}}
  {{- if eq $mount.enabled true }}
  # File backup for {{ $index }} volume.
  # If files get changed while the tar command is running, tar will exit with code 1.
  # We ignore this as we want the rest of the job to still get run.
  echo "Starting {{ $index }} volume backup."
  tar -czP --exclude=css --exclude=js --exclude=styles -f $BACKUP_LOCATION/{{ $index }}.tar.gz {{ $mount.mountPath }} || ( export exitcode=$?; [[ $exitcode -eq 1 ]] || exit )
  {{- end -}}
  {{- end }}
  {{- end }}

  # Delete old backups
  echo "Removing backups older than {{ .Values.backup.retention }} days"
  # Can't locate directories based on mtime due to storage backend limitations,
  # Using folder name for time selection.
  retention_time=$(date -d "{{ .Values.backup.retention }} days ago" +%s)

  find /backups -type d -mindepth 1 -maxdepth 1 -print \
  | grep -E '/[0-9-]+$' \
  | while read -r dir
  do
    # convert dir name into timestamp
    stamp="$(echo "$dir" | sed -re 's%.+/(.+)-(.+)-(.+)-(.+)-(.+)-(.+)$%\1-\2-\3 \4:\5:\6%')"
    stamp="$(date -d "$stamp" '+%s')" || continue

    # jump out of the execution block if the directory more recent than retention time
    if [[ "$stamp" -gt "$retention_time" ]]; then
      continue
    fi
    # All checks have passed and we can remove the directory.
    echo "Removing directory: $dir"
    rm -rf "$dir"
  done

  # List content of backup folder
  echo "Current backups:"
  ls -lh /backups/*
{{- end }}

{{- define "mariadb.db-validation" -}}

  set -e

  echo "** DB validation"

  export DB_USER=root
  export DB_PASS={{ .db_password }}
  export DB_HOST=127.0.0.1
  export DB_NAME=drupal

  TIME_WAITING=0
  echo "Waiting for database.";

  until mysqladmin status --connect-timeout=2 -u $DB_USER -p$DB_PASS -h $DB_HOST --protocol=tcp --silent; do
    echo -n "."
    sleep 1s
    TIME_WAITING=$((TIME_WAITING+1))

    if [ $TIME_WAITING -gt 60 ]; then
      echo "Database connection timeout"
      exit 1
    fi
  done

  echo "Importing database dump for validation"
  mysql -u $DB_USER -p$DB_PASS $DB_NAME -h $DB_HOST --protocol=tcp --max_allowed_packet=1G < /tmp/db.sql
  drush status --fields=bootstrap

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

{{- define "cron.entrypoints" -}}

set -e
# Trigger lagoon entrypoint scripts if present.
if [ -f /lagoon/entrypoints.sh ] ; then /lagoon/entrypoints.sh ; fi
# Trigger silta entrypoint script if present.
if [ -f /silta/entrypoint.sh ] ; then /silta/entrypoint.sh ; fi

{{- end }}


{{- define "drupal.cron.api-version" }}
{{- if and ( ge $.Capabilities.KubeVersion.Major "1") ( ge $.Capabilities.KubeVersion.Minor "21" ) }}
batch/v1
{{- else }}
batch/v1beta1
{{- end }}
{{- end }}

{{- define "drupal.cron.timezone-support" }}
{{- if and ( ge $.Capabilities.KubeVersion.Major "1") ( ge $.Capabilities.KubeVersion.Minor "25" ) }}true
{{- else }}false
{{- end }}
{{- end }}

{{- define "drupal.autoscaling.api-version" }}
{{- if and ( ge $.Capabilities.KubeVersion.Major "1") ( ge $.Capabilities.KubeVersion.Minor "23" ) }}
autoscaling/v2
{{- else }}
autoscaling/v2beta1
{{- end }}
{{- end }}

{{- define "masking.prefix-alert" -}}
{{ if $.Values.domainPrefixes }}
{{ fail "Cannot use domain prefixes together with domain masking"}}
{{- end -}}
{{- end -}}

{{- define "silta-cluster.rclone.has-provisioner" }}
{{- if ( $.Capabilities.APIVersions.Has "silta.wdr.io/v1" ) }}true
{{- else }}false
{{- end }}
{{- end }}

{{- define "drupal.serviceAccountName" }}
{{- if .Values.serviceAccount.name }}
{{- .Values.serviceAccount.name }}
{{- else }}
{{- .Release.Name }}-sa
{{- end }}
{{- end }}
