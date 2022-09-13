#!/bin/bash
# Ensure we exit with an error on drush errors.
set -e

LOCAL=$1
NFS=$2
DEV=$3
OPTIONAL=$4
SETTINGS=$5

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
    -ls|--localsettings)
      SETTINGS='local'
      shift # past argument with no value
      ;;
    -wo|--with-optional)
      OPTIONAL='optional'
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

cp /var/www/scripts/social/install/default.settings.php /var/www/html/sites/default/default.settings.php
cp /var/www/scripts/social/install/settings.local.php /var/www/html/sites/default/settings.local.php

if [[ ${OPTIONAL} == "optional" ]]; then
  # Install with the optional modules declaring having a module.installer_options.yml
  # See #3110127
  drush -y si social --db-url=mysql://root:root@db:3306/social --account-pass=admin social_module_configure_form.select_all='TRUE' install_configure_form.update_status_module='array(FALSE,FALSE)' --site-name='Open Social';
  echo "installed drupal including optional modules"
else
  # Use the normal installer without optional modules
  drush -y si social --db-url=mysql://root:root@db:3306/social --account-pass=admin install_configure_form.update_status_module='array(FALSE,FALSE)' --site-name='Open Social';
  echo "installed drupal"
fi

fn_sleep
if [[ ${NFS} != "nfs" ]]
  then
    chown -R www-data:www-data /var/www/html/
    fn_sleep
    echo "set the correct owner"
  fi

php -r 'opcache_reset();';
fn_sleep
echo "opcache reset"
chmod 644 sites/default/settings.php

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

# Make sure we add swiftmailer default settings if the environment is development
if drush ev "echo getenv('DRUPAL_SETTINGS');" | grep -q 'development'; then
  drush cset swiftmailer.transport transport 'smtp' -y
  drush cset swiftmailer.transport smtp_host 'mailcatcher' -y
  drush cset swiftmailer.transport smtp_port 1025 -y
  echo "updated swiftmailer settings"
fi

# Make sure we add swiftmailer default settings if the environment is set to local.
if [[ ${SETTINGS} == "local" ]]
then
  drush cset swiftmailer.transport transport 'smtp' -y
  drush cset swiftmailer.transport smtp_host 'mailcatcher' -y
  drush cset swiftmailer.transport smtp_port 1025 -y
  echo "updated swiftmailer settings"
fi

fn_sleep
echo "settings.php and files directory permissions"

if [[ ${SKIP} == "skip" ]]
then
  echo "skipping demo content"
else
  drush en social_demo -y
  fn_sleep
  drush cc drush
  echo "creating demo content"
  drush sda file user group topic event event_enrollment post comment like # Add the demo content
  #drush sdr like event_enrollment topic event post comment group user file # Remove the demo content
  drush pmu social_demo -y
  fn_sleep
  echo "flush image caches"
  drush cc drush
  drush if --all
  fn_sleep
  echo "run activity queues"
  # Since we are now having ultimate cron and advance queue, we need to run drush cron separately as drush queue:run doesn't works.
  drush cron
  fn_sleep
  echo "trigger a search api re-index"
  drush sapi-rt
fi

echo "rebuild node access"
drush ev 'node_access_rebuild()';

# Add 'dev; to your install script as third argument to enable
# development modules e.g. pause nfs dev.
if [[ ${DEV} == "dev" ]]
then
  echo "enabling devel modules"
  drush en -y config_update config_update_ui devel devel_generate dblog views_ui field_ui contextual
fi
