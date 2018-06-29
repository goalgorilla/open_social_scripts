#!/usr/bin/env bash

set -ev

CONTAINER=`docker ps --format '{{.Names}}' | grep "\w[social]\w[web]"`

# Install the site in version X.
docker exec -i $CONTAINER bash /var/www/scripts/social/install/install_script.sh
bash scripts/social/ci/restore-permissions.sh
# Update composer to version Y.
rm -f composer.lock && composer require goalgorilla/open_social:dev-${2}#${3} --no-update
# do this anyway
composer update
bash scripts/social/ci/restore-permissions.sh
docker exec -i $CONTAINER bash /var/www/scripts/social/install/update.sh
