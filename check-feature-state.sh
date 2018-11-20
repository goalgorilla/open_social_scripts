#!/usr/bin/env bash

# Script which checks for feature state in Drupal.
# Usage: bash check-feature-state.sh bundle
# E.g. for checking features in bundle social:
# bash check-feature-state.sh social

# Set bundle var.
BUNDLE=$1

# When the feature is marked as Changed it will exit with an error.
function error_exit
{
	echo -e "\033[0;31m$1\033[0m" 1>&2
	exit 1
}

# Now retrieve the feature state and error_exit/echo accordingly.
FEATURE_STATE=`drush fl --bundle=$BUNDLE --fields=machine_name,state`

if [[ $FEATURE_STATE =~ "Changed" ]]
then
    # Print the difference for each changed feature.
    echo "$FEATURE_STATE" | grep "Changed" | awk '{ print $1 }' | while read -r feature; do
        echo -e "Showing difference for \033[34m${feature}\033[0m...\n"
        drush features-diff "$feature"
	echo -e "\n"
    done
    error_exit "The feature state is not default!"
else
    echo -e "\033[0;32mThe feature state is default.\033[0m"
fi
