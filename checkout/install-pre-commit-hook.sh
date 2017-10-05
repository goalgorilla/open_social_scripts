#!/bin/bash
# Installs the PHP CodeSniffer pre-commit hook into the current git repository.
#
# @author Alexander Varwijk <alexander@goalgorilla.com>
GIT_ROOT=`git rev-parse --git-dir`

# Exit if we're not in a git repository
if [ -z "$GIT_ROOT" ]; then
  exit 1
fi

echo "Installing pre-commit hook into $GIT_ROOT/hooks/"

cp -v ${BASH_SOURCE%/*}/pre-commit-sniffer.sh $GIT_ROOT/hooks/pre-commit
chmod -vv ug+x $GIT_ROOT/hooks/pre-commit

echo "Done."
