#!/bin/bash
# PHP CodeSniffer pre-commit hook for git
#
# Adapted from the following authors.
#
# @author Soenke Ruempler <soenke@ruempler.eu>
# @author Sebastian Kaspari <s.kaspari@googlemail.com>
#
# Original here: https://github.com/s0enke/git-hooks/tree/master/phpcs-pre-commit
#
# Adapted for Open Social development.
# @author Alexander Varwijk <alexander@goalgorilla.com>
#
# This file should be the hooks folder of your git repo (.git/hooks/pre-commit).
# Ensure that an extension is not added to the file (e.g. no pre-commit.sh)

##
## Configuration
##
PHPCS_CODING_STANDARD=Drupal
PHPCS_IGNORE=
PHPCS_FILE_PATTERN="\.(php|module|inc|install|test|profile|theme)"
PHPCS_IGNORE_WARNINGS=0
PHPCS_ENCODING=utf-8
TMP_STAGING=".tmp_staging"

##
## Pre-Commit hook (don't edit below here)
##

# A global installation of phpcs in the user's root
PHPCS_GLOBAL=~/.composer/vendor/bin/phpcs
# A local installation of phpcs in the current project
PHPCS_LOCAL=./vendor/bin/phpcs
# The path of the phpcs installation in drupal_social from the open social project.
PHPCS_CI=../../../../vendor/bin/phpcs

# find out which PHPCS is installed
if [ -x $PHPCS_LOCAL ]; then
    PHPCS_BIN=$PHPCS_LOCAL
elif [ -x $PHPCS_CI ]; then
    PHPCS_BIN=$PHPCS_CI
elif [ -x $PHPCS_GLOBAL ]; then
    PHPCS_BIN=$PHPCS_GLOBAL
else
    echo "PHP CodeSniffer bin not found or executable in: \n$PHPCS_GLOBAL \n$PHPCS_LOCAL \n$PHPCS_CI"
    exit 1
fi

# stolen from template file
if git rev-parse --verify HEAD
then
    against=HEAD
else
    # Initial commit: diff against an empty tree object
    against=4b825dc642cb6eb9a060e54bf8d69288fbee4904
fi

# this is the magic: 
# retrieve all files in staging area that are added, modified or renamed
# but no deletions etc
FILES=$(git diff-index --name-only --cached --diff-filter=ACMR $against -- )

if [ "$FILES" == "" ]; then
    exit 0
fi

# create temporary copy of staging area
if [ -e $TMP_STAGING ]; then
    rm -rf $TMP_STAGING
fi
mkdir $TMP_STAGING

# match files against whitelist
FILES_TO_CHECK=""
for FILE in $FILES
do
    echo "$FILE" | egrep -q "$PHPCS_FILE_PATTERN"
    RETVAL=$?
    if [ "$RETVAL" -eq "0" ]
    then
        FILES_TO_CHECK="$FILES_TO_CHECK $FILE"
    fi
done

if [ "$FILES_TO_CHECK" == "" ]; then
    exit 0
fi

# execute the code sniffer
if [ "$PHPCS_IGNORE" != "" ]; then
    IGNORE="--ignore=$PHPCS_IGNORE"
else
    IGNORE=""
fi

if [ "$PHPCS_SNIFFS" != "" ]; then
    SNIFFS="--sniffs=$PHPCS_SNIFFS"
else
    SNIFFS=""
fi

if [ "$PHPCS_ENCODING" != "" ]; then
    ENCODING="--encoding=$PHPCS_ENCODING"
else
    ENCODING=""
fi

if [ "$PHPCS_IGNORE_WARNINGS" == "1" ]; then
    IGNORE_WARNINGS="-n"
else
    IGNORE_WARNINGS=""
fi

# Copy contents of staged version of files to temporary staging area
# because we only want the staged version that will be commited and not
# the version in the working directory
STAGED_FILES=""
for FILE in $FILES_TO_CHECK
do
  ID=$(git diff-index --cached $against $FILE | cut -d " " -f4)

  # create staged version of file in temporary staging area with the same
  # path as the original file so that the phpcs ignore filters can be applied
  mkdir -p "$TMP_STAGING/$(dirname $FILE)"
  git cat-file blob $ID > "$TMP_STAGING/$FILE"
  STAGED_FILES="$STAGED_FILES $TMP_STAGING/$FILE"
done

OUTPUT=$($PHPCS_BIN -s $IGNORE_WARNINGS --standard=$PHPCS_CODING_STANDARD $ENCODING $IGNORE $SNIFFS $STAGED_FILES)
RETVAL=$?

# delete temporary copy of staging area
rm -rf $TMP_STAGING

if [ $RETVAL -ne 0 ]; then
    echo -e "\nCommit aborted due to CodeSniffer errors\n"
    echo "$OUTPUT"
fi

exit $RETVAL
