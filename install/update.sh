#!/bin/bash
set -e

# Script to update Drupal in the docker container.
cd /var/www/html/;

drush -y cr
drush -y updatedb

