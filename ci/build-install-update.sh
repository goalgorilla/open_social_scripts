#!/usr/bin/env bash

set -ev

# Install the site in version X.
docker exec -i social_ci_web bash /var/www/scripts/social/install/install_script.sh
bash scripts/social/ci/restore-permissions.sh
# Update composer to version Y.
composer require ${1} --update-with-all-dependencies
# ALso we install from 8.x with search autocomplete enabled, so we need to composer require it to make sure it doesn't break travis.
composer require drupal/social_search_autocomplete
# do this anyway
composer update
bash scripts/social/ci/restore-permissions.sh
docker exec -i social_ci_web bash /var/www/scripts/social/install/update.sh
