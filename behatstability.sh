#!/usr/bin/env bash

# Take optional arguments for this script.
#
# To run all stability tests:
# /behatstability.sh
# To run specified tags:
# /behatstability.sh stability-1 stability-2 stability-5
if [ -z "$1" ];
then
  TAGS="stability"
else
  for var in "$@"
  do
    if [ -z "$TAGS" ];
    then
      TAGS="$var"
    else
      TAGS="$TAGS,$var"
    fi
  done
  TAGS="$TAGS"
fi

PROJECT_FOLDER=/var/www/html/profiles/contrib/social/tests/behat

/var/www/vendor/bin/behat --version

/var/www/vendor/bin/behat -vv $PROJECT_FOLDER --config $PROJECT_FOLDER/behat.yml --tags $TAGS
