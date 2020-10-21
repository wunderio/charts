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
  'port' => '3306',
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
  // Elasticsearch Helper 6.x compatible configuration override.
  $config['elasticsearch_helper.settings']['elasticsearch_helper']['host'] = $elasticsearch_host;
  $config['elasticsearch_helper.settings']['elasticsearch_helper']['port'] = 9200;

  // Elasticsearch Helper 7.x compatible configuration override.
  $config['elasticsearch_helper.settings']['hosts'] = [
    [
      'host' => $elasticsearch_host,
      'port' => 9200,
    ],
  ];
}

/**
 * Set the memcache server hostname when a memcached server is available.
 */
if (getenv('MEMCACHED_HOST')) {
  $settings['memcache']['servers'] = [getenv('MEMCACHED_HOST') . ':11211' => 'default'];

  // Set the memcache backend if class is defined.
  if (class_exists('\Drupal\memcache\MemcacheBackend')) {
    $settings['cache']['default'] = 'cache.backend.memcache';
  }
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
 * Use our own services override.
 *
 * We don't include this when running on cli, for example when using drush,
 * because the output from monolog to stdout interferes with drush batch
 * processing, causing the process to die when drush tries to start a new batch.
 */
if (PHP_SAPI !== 'cli') {
  $settings['container_yamls'][] = 'sites/default/silta.services.yml';
}
