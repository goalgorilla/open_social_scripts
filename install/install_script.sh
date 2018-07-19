#!/bin/bash

LOCAL=$1
NFS=$2
DEV=$3

fn_sleep() {
  if [[ ${LOCAL} != "nopause" ]]
  then
     sleep 5
  fi
}

for i in "$@"
do
case ${i} in
    -d|--dev)
      DEV='dev'
      shift # past argument with no value
      ;;
    -p|--nopause)
      LOCAL=nopause
      shift # past argument with no value
      ;;
    -n|--nfs)
      NFS=nfs
      shift # past argument with no value
      ;;
    -s|--skip-content)
      SKIP=skip
      shift # past argument with no value
      ;;
    *)
          # unknown option
    ;;
esac
done

# Install script for in the docker container.
cd /var/www/html/;

# Set the correct settings.php requires scripts folder to be mounted in /var/www/scripts/social.
chmod 777 /var/www/html/sites/default

if [ -f /var/www/html/sites/default/settings.php ]; then
  chmod 777 /var/www/html/sites/default/settings.php
  rm /var/www/html/sites/default/settings.php
fi

if [ -f /var/www/html/sites/default/default.settings.php ]; then
  chmod 777 /var/www/html/sites/default/default.settings.php
  rm /var/www/html/sites/default/default.settings.php
fi

# Do something similar for drushrc.php. This will make drush know the uri of your dev site.
if [ -f /var/www/html/sites/default/drushrc.php ]; then
  chmod 777 /var/www/html/sites/default/drushrc.php
  rm /var/www/html/sites/default/drushrc.php
fi

cp /var/www/scripts/social/install/default.settings.php /var/www/html/sites/default/default.settings.php

# Only add the drushrc file when the VIRTUAL HOST is set.
if [[ "$VIRTUAL_HOST" != "" ]]; then
  # Copy the default drushrc.php file and try to replace VIRTUAL_HOST var.
  sed "s/VHOST/$VIRTUAL_HOST/g" /var/www/scripts/social/install/default.drushrc.php > /var/www/html/sites/default/drushrc.php
fi

drush -y site-install social --db-url=mysql://root:root@db:3306/social --account-pass=admin install_configure_form.update_status_module='array(FALSE,FALSE)' --site-name='Open Social';
fn_sleep
echo "installed drupal"
if [[ ${NFS} != "nfs" ]]
  then
    chown -R www-data:www-data /var/www/html/
    fn_sleep
    echo "set the correct owner"
  fi

php -r 'opcache_reset();';
fn_sleep
echo "opcache reset"
chmod 444 sites/default/settings.php

# Create private files directory.
if [ ! -d /var/www/files_private ]; then
  mkdir /var/www/files_private;
else
  # Empty existing directory
  rm -rf /var/www/files_private/*
fi
chmod 777 -R /var/www/files_private;
chmod 777 -R sites/default/files

# Create swiftmailer-spool directory for behat tests
if [ ! -d /var/www/html/profiles/contrib/social/tests/behat/features/swiftmailer-spool ]; then
  mkdir /var/www/html/profiles/contrib/social/tests/behat/features/swiftmailer-spool;
fi
chmod 777 -R /var/www/html/profiles/contrib/social/tests/behat/features/swiftmailer-spool;
chown -R www-data:www-data /var/www/html/profiles/contrib/social/tests/behat/features/swiftmailer-spool

fn_sleep
echo "settings.php and files directory permissions"

if [[ ${SKIP} == "skip" ]]
then
  echo "skipping demo content"
else
  drush pm-enable social_demo -y
  fn_sleep
  drush cc drush
  echo "creating demo content"
  drush sda file user group topic event eventenrollment post comment like # Add the demo content
  #drush sdr like eventenrollment topic event post comment group user file # Remove the demo content
  drush pm-uninstall social_demo -y
  fn_sleep
  echo "flush image caches"
  drush cc drush
  drush image-flush --all
  fn_sleep
  echo "run activity queues"
  drush queue-run activity_logger_message
  drush queue-run activity_creator_logger
  drush queue-run activity_creator_activities
  fn_sleep
  echo "rebuild node access"
  drush php-eval 'node_access_rebuild()';
  echo "trigger a search api re-index"
  drush php-eval 'drush_search_api_reset_tracker();';
fi

# Add 'dev; to your install script as third argument to enable
# development modules e.g. pause nfs dev.
if [[ ${DEV} == "dev" ]]
then
  echo "enabling devel modules"
  drush en social_devel -y
fi
