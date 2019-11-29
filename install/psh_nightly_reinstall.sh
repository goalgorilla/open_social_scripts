#!/bin/bash

echo "INSTALLING OPEN SOCIAL"
drush --root=/app/web -y sql-drop
drush --root=/app/web -y site-install social --account-pass=admin install_configure_form.update_status_module='array(FALSE,FALSE)';

echo "RESETTING OPCACHE"
php -r 'opcache_reset();';

drush --root=/app/web -y cr

drush --root=/app/web -y sql-dump > /tmp/clean.sql

drush --root=/app/web -y pm-enable redis
echo "ENABLING MULTIPLE SOCIAL EXTENSIONS"
drush --root=/app/web -y pm-enable social_book social_comment_upload social_event_an_enroll social_event_type social_gdpr social_group_quickjoin social_landing_page social_sharing social_tagging social_user_export social_embed social_private_message social_profile_fields social_profile_organization_tag social_profile_privacy

drush --root=/app/web -y sql-dump > /tmp/clean-with-optional-modules.sql

drush --root=/app/web -y pm-enable social_lazy_loading social_lazy_loading_images

drush --root=/app/web -y sql-dump > /tmp/clean-with-all-modules.sql

echo "ENABLING DEMO CONTENT MODULE"
drush --root=/app/web -y pm-enable social_demo

echo "IMPORTING DEMO CONTENT"
drush --root=/app/web -y cc drush
drush --root=/app/web -y sda file user group topic event eventenrollment page post comment like link # Add the demo content
echo "GENERATING ADDITIONAL DEMO CONTENT, THIS MAY TAKE A WHILE" # NOTE: Run each content type separately to prevent the memory to be exhausted.
# Create users.
drush --root=/app/web -y sdg user:2500
drush --root=/app/web -y sdg user:2500
# Create topics.
drush --root=/app/web -y sdg topic:1500
# Create events.
drush --root=/app/web -y sdg event:1000
# Create groups.
drush --root=/app/web -y sdg group:100
# Create pages.
drush --root=/app/web -y sdg page:500
# Create posts.
drush --root=/app/web -y sdg post:3000
drush --root=/app/web -y sdg post:3000
# Create comments.
drush --root=/app/web -y sdg comment:2500
drush --root=/app/web -y sdg comment:2500
# Create likes.
drush --root=/app/web -y sdg like:1000
drush --root=/app/web -y sdg like:1000


echo "DISABLING DEMO CONTENT MODULE"
drush --root=/app/web -y pm-uninstall social_demo

echo "FLUSHING IMAGE CACHES"
drush --root=/app/web -y image-flush --all

echo "EMPTY ACTIVITY QUEUES"
drush --root=/app/web -y queue-run activity_logger_message
drush --root=/app/web -y queue-run activity_creator_logger
drush --root=/app/web -y queue-run activity_creator_activities

echo "REBUILDING NODE ACCESS"
drush --root=/app/web -y php-eval 'node_access_rebuild()';

echo "RE-INDEXING ALL SEARCH INDEXES"
drush --root=/app/web php-eval 'drush_search_api_reset_tracker()';

echo "RUNNING ENTITY UPDATES"
drush --root=/app/web -y entity-updates;

drush --root=/app/web -y cr

drush --root=/app/web -y sql-dump > /tmp/clean-with-all-modules-demo-content.sql
