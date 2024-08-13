<?php

/**
 * @file
 * Automatically injected settings for the Silta environment.
 */

// Database settings.
$databases['default']['default'] = [
  'database' => getenv('DB_NAME'),
  'username' => getenv('DB_USER'),
  'password' => getenv('DB_PASS'),
  'host' => getenv('DB_HOST'),
  'port' => empty(getenv('DB_PORT')) ? '3306' : getenv('DB_PORT'),
  'driver' => 'mysql',
  'prefix' => '',
];

// Salt for one-time login links, cancel links, form tokens, etc.
$settings['hash_salt'] = getenv('HASH_SALT');

/**
 * If a volume has been set for private files, tell Drupal about it.
 */
if (getenv('PRIVATE_FILES_PATH')) {
  $settings['file_private_path'] = getenv('PRIVATE_FILES_PATH');
}

/**
 * Set Elasticsearch Helper module configuration if needed.
 */
if ($elasticsearch_host = getenv('ELASTICSEARCH_HOST')) {

  $elasticsearch_port = 9200;

  // Elasticsearch Helper 6.x compatible configuration override.
  $config['elasticsearch_helper.settings']['elasticsearch_helper']['host'] = $elasticsearch_host;
  $config['elasticsearch_helper.settings']['elasticsearch_helper']['port'] = $elasticsearch_port;

  // Elasticsearch Helper 7.x compatible configuration override.
  $config['elasticsearch_helper.settings']['hosts'] = [
    [
      'host' => $elasticsearch_host,
      'port' => $elasticsearch_port,
    ],
  ];

  // Enable Drupal Ping to survey the Elasticsearch connection
  // https://github.com/wunderio/drupal-ping#elasticsearch
  $settings['ping_elasticsearch_connections'] = [
    [
      'severity' => 'warning',
      'proto' => 'http',
      'host' => $elasticsearch_host,
      'port' => $elasticsearch_port,
    ],
  ];
}

/**
 * Generated twig files should not be on shared storage.
 */
$settings['php_storage']['twig']['directory'] = '../generated-php';

/**
 * Make sure the dynamic environments are not blocked out as untrusted.
 *
 * Other hostnames wouldn't reach the pod in silta anyway.
 */
$settings['trusted_host_patterns'][] = '^.*$';

/**
 * Show all error messages, with backtrace information.
 *
 * In case the error level could not be fetched from the database, as for
 * example the database connection failed, we rely only on this value.
 */
$config['system.logging']['error_level'] = getenv('ERROR_LEVEL');

/**
 * Enable reverse proxy.
 */
$settings['reverse_proxy'] = TRUE;
$settings['reverse_proxy_addresses'] = [];

/**
 * Override varnish config when varnish environment variables are defined.
 */
if (getenv('VARNISH_ADMIN_HOST')) {
  $config['varnish.settings']['varnish_version'] = 4;
  $config['varnish.settings']['varnish_control_terminal'] = getenv('VARNISH_ADMIN_HOST') . ':' . getenv('VARNISH_ADMIN_PORT');
  $config['varnish.settings']['varnish_control_key'] = trim(getenv('VARNISH_CONTROL_KEY'));
}

/**
 * Override clamav config when clamav environment variables are defined.
 */
if (getenv('CLAMAV_HOST')) {
  $config['clamav.settings']['scan_mode'] = 0;
  $config['clamav.settings']['mode_daemon_tcpip']['hostname'] = getenv('CLAMAV_HOST');
  $config['clamav.settings']['mode_daemon_tcpip']['port'] = getenv('CLAMAV_PORT');
}

/**
 * Use our own services override.
 *
 * Add monolog config
 * because the output from monolog to stdout interferes with drush batch
 * processing we avoid it by logging to STDERR.
 */
$settings['container_yamls'][] = 'sites/default/silta.services.yml';
