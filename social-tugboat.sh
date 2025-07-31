#!/bin/bash

# Prompt for GitHub PR ID
read -p "Enter the GitHub PR ID number (e.g., 3959): " GH_PR

# Hardcoded repo ID
REPO_ID="630373f56d9ec36a0f50b5d5"

echo "🔍 Searching for preview matching: $GH_PR"

# Get all previews
PREVIEWS=$(tugboat ls previews repo="$REPO_ID")

# Find line number of match (URL line)
MATCH_LINE_NUM=$(echo "$PREVIEWS" | grep -in "$GH_PR" | cut -d: -f1)

if [ -z "$MATCH_LINE_NUM" ]; then
  echo "❌ No Tugboat preview found matching: $GH_PR"
  exit 1
fi

# Get the line above the matched line
ID_LINE=$(echo "$PREVIEWS" | sed -n "$((MATCH_LINE_NUM - 1))p")

# Extract the first column (should be preview ID)
POTENTIAL_ID=$(echo "$ID_LINE" | awk '{print $1}')

# Validate preview ID format (24 hex chars)
if [[ "$POTENTIAL_ID" =~ ^[a-f0-9]{24}$ ]]; then
  PREVIEW_ID="$POTENTIAL_ID"
  echo "✅ Found Preview ID: $PREVIEW_ID"
else
  echo "❌ Invalid preview ID extracted: $POTENTIAL_ID"
  exit 1
fi

# Get the webserver service ID
SERVICE_ID=$(tugboat ls services preview="$PREVIEW_ID" --json \
  | jq -r '.[] | select(.name=="webserver") | .id')

if [ -z "$SERVICE_ID" ]; then
  echo "❌ No webserver service found for preview: $PREVIEW_ID"
  exit 1
fi

echo "✅ Webserver Service ID: $SERVICE_ID"

# Show options
while true; do
  echo
  echo "What would you like to do next?"
  echo "1) Enable Drupal module(s)"
  echo "2) Run a custom Drush command"
  echo "3) Download database (drush sql-dump)"
  echo "4) Exit"
  read -p "Choose an option (1/2/3/4): " NEXT_ACTION

  if [ "$NEXT_ACTION" == "2" ]; then
    read -p "Enter the Drush command to run (without 'drush'): " DRUSH_COMMAND
    echo "🚀 Running: drush $DRUSH_COMMAND"
    tugboat shell "$SERVICE_ID" command="/var/www/vendor/drush/drush/drush $DRUSH_COMMAND"

  elif [ "$NEXT_ACTION" == "1" ]; then
    while true; do
      read -p "Enter the module name to enable: " MODULE_NAME
      echo "🚀 Enabling module: $MODULE_NAME"
      tugboat shell "$SERVICE_ID" command="/var/www/vendor/drush/drush/drush en $MODULE_NAME -y"

      echo
      read -p "Do you want to enable another module? (y/n): " ENABLE_ANOTHER
      if [[ "$ENABLE_ANOTHER" != "y" && "$ENABLE_ANOTHER" != "Y" ]]; then
        echo "👋 Done enabling modules."
        break
      fi
    done

  elif [ "$NEXT_ACTION" == "3" ]; then
    echo "💾 Downloading database dump to local file: database.sql"
    tugboat shell "$SERVICE_ID" command="/var/www/vendor/drush/drush/drush sql-dump" > database.sql
    echo "✅ Dump saved as database.sql"

  elif [ "$NEXT_ACTION" == "4" ]; then
    echo "👋 Exiting."
    break

  else
    echo "❌ Invalid option selected."
  fi
done