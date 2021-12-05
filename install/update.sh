#!/bin/bash
set -e

# Script to update Drupal in the docker container.
cd /var/www/html/;

drush -y cr
## Needed for updates from rc-5 -> 1.4.0 of Group see: #3134690
## It is fired in an update hook, however we can't know which order it's run or which version updates are coming from
## so we need to enable it first otherwise we are running in to errors.
drush -y variationcache
drush -y updatedb
