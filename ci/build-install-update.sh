#!/usr/bin/env bash

set -ev

# Install the site in version X.
docker exec -i social_ci_web bash /var/www/scripts/ci/install/install_script.sh
bash scripts/ci/restore-permissions.sh
# Update composer to version Y.
rm -f composer.lock && composer require goalgorilla/open_social:"dev-8.x-1.x"
bash scripts/ci/restore-permissions.sh
docker exec -i social_ci_web bash /var/www/scripts/social/install/update.sh
