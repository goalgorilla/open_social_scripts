<?php
/**
 * Drush configuration file for OS local development.
 */
if (PHP_SAPI === 'cli' && !empty('VHOST') && strpos('VHOST', '.') > 0) {
  $options['uri'] = 'VHOST';
}
