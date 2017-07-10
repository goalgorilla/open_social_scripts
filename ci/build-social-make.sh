#!/usr/bin/env bash

set -ev

pwd

# Restore permissions and do the make install.
mkdir html/sites/default/files
bash scripts/ci/restore-permissions.sh
bash scripts/ci/drush-make-install.sh
docker exec -i social_ci_web bash /var/www/scripts/install/install_script.sh
