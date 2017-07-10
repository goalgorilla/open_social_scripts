#!/usr/bin/env bash
pwd
# First build the site with the make file.
vendor/bin/drush make scripts/ci/build-social-dev.make make_build
ls -lah
cd make_build;
ls -lah
composer config repositories.drupal composer https://packages.drupal.org/8
composer require "drupal/address ~1.0" "drupal/social_auth ^1.0" "facebook/graph-sdk ^5.4" "google/apiclient ^2.1" "php-http/curl-client ^1.6" "guzzlehttp/psr7 ^1.3" "php-http/message ^1.4" "happyr/linkedin-api-client ^1.0" "abraham/twitteroauth ^0.7.2" "swiftmailer/swiftmailer 5.4.8"

# Now cleanup the old stuff.
cd ../
ls -lah

rm -rf html
mv make_build html
