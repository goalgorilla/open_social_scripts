<?php
/**
 * Drush configuration file for OS local development.
 */
if (PHP_SAPI === 'cli' && isset($_ENV['VIRTUAL_HOST'])) {
  $options['uri'] = $_ENV['VIRTUAL_HOST'];
}
