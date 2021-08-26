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
$conf['hash_salt'] = getenv('HASH_SALT');

/**
 * If a volume has been set for private files, tell Drupal about it.
 */
if (getenv('PRIVATE_FILES_PATH')) {
  $conf['file_private_path'] = getenv('PRIVATE_FILES_PATH');
}


/**
 * Show all error messages, with backtrace information.
 *
 * In case the error level could not be fetched from the database, as for
 * example the database connection failed, we rely only on this value.
 */
$conf['error_level'] = getenv('ERROR_LEVEL');

/**
 * Override varnish config when varnish environment variables are defined.
 */
if (getenv('VARNISH_ADMIN_HOST')) {
  $conf['varnish_control_terminal'] = getenv('VARNISH_ADMIN_HOST') . ':' . getenv('VARNISH_ADMIN_PORT');
  $conf['varnish_control_key'] = trim(getenv('VARNISH_CONTROL_KEY'));
}
