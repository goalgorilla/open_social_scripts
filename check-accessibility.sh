#!/usr/bin/env bash

COMMAND_OR_URL=$1

if [ "$COMMAND_OR_URL" == "install" ]; then
  apt-get install -y npm libfontconfig1
  ln -s /usr/bin/nodejs /usr/bin/node
  npm cache clean -f
  npm install -g n
  n stable
  npm i -g phantomjs grunt-cli

  cd /var/www/vendor/squizlabs/html_codesniffer
  npm i
  grunt build
  cd -

  COMMAND_OR_URL="/"
fi

FILE="/tmp/accessibility.html"

if [ -z $COMMAND_OR_URL ]; then
  COMMAND_OR_URL="/"
fi

curl -L http://localhost$COMMAND_OR_URL > $FILE
phantomjs /var/www/vendor/squizlabs/html_codesniffer/Contrib/PhantomJS/HTMLCS_Run.js $FILE WCAG2AAA table
