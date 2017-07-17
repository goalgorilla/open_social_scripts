#!/usr/bin/env bash

# Take optional arguments for this script.
#
# To run all stability tests except for DS-2082 and DS-816:
# /behatstability.sh
# To run specified tags except for DS-2082 and DS-816:
# /behatstability.sh stability-1 stability-2 stability-5
if [ -z "$1" ];
then
  TAGS="stability&&~DS-2082&&~DS-816"
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
  TAGS="$TAGS&&~DS-2082&&~DS-816"
fi

PROJECT_FOLDER=/var/www/html/profiles/contrib/social/tests/behat

/var/www/vendor/bin/behat --version

/var/www/vendor/bin/behat $PROJECT_FOLDER --config $PROJECT_FOLDER/config/behat.yml --tags $TAGS
