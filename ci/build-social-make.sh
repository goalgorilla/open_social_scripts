#!/usr/bin/env bash

set -ev

# Restore permissions and do the make install.
mkdir html/sites/default/files
bash scripts/social/ci/restore-permissions.sh
bash scripts/social/ci/drush-make-install.sh
docker exec -i social_ci_web bash /var/www/scripts/social/install/install_script.sh
