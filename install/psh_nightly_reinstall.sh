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
echo "GENERATING ADDITIONAL DEMO CONTENT"
drush --root=/app/web -y sdg user:5000 topic:1500 event:1000 group:100 post:7500 comment:5000

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
