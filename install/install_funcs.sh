#!/bin/bash

os_fn_sleep() {
    if [ ${LOCAL} != "nopause" ]; then
        sleep 5
    fi
}

os_prepare_settings() {
    local default_dir="${ROOT_DIR}html/sites/default"

    chmod 777 ${default_dir}

    if [ -f "${default_dir}/settings.php" ]; then
        chmod 777 "${default_dir}/settings.php"
        rm "${default_dir}/settings.php"
    fi

    if [ -f "${default_dir}/default.settings.php" ]; then
        chmod 777 "${default_dir}/default.settings.php"
        rm "${default_dir}/default.settings.php"
    fi

    cp "${ROOT_DIR}scripts/social/install/default.settings.php" "${ROOT_DIR}html/sites/default/default.settings.php"
}

os_install() {
    local db_user=${1}
    local db_pass=${2}
    local db_host=${3}
    local admin_pass=${4}
    drush -y site-install social --db-url=mysql://${db_user}:${db_pass}@${db_host}:${db_port}/social --account-pass=${admin_pass} install_configure_form.update_status_module='array(FALSE,FALSE)';
    os_fn_sleep
    echo "Drupal installed"
}

os_nfs() {
    if [ ${NFS} != "nfs" ]; then
        chown -R www-data:www-data "${ROOT_DIR}html/"
        echo "Set the correct owner"
    fi
}

os_opcache_reset() {
    php -r "if (function_exists('opcache_reset')) opcache_reset();"
    os_fn_sleep
    echo "opcache reset"
}

os_files_perms() {
    chmod 444 "${ROOT_DIR}html/sites/default/settings.php"

    # Create private files directory.
    if [ ! -d "${ROOT_DIR}html/sites/default/files_private" ]; then
      mkdir "${ROOT_DIR}html/sites/default/files_private"
    fi

    chmod 777 -R "${ROOT_DIR}html/sites/default/files_private"
    chmod 777 -R "${ROOT_DIR}html/sites/default/files"
    os_fn_sleep
    echo "settings.php and files directory permissions"
}

os_demo() {
    drush pm-enable social_demo -y
    os_fn_sleep
    echo "Enabled social_demo module"

    drush cache-clear drush

    if [ ${DEFAULT_DEMO} ]; then
        drush sda file user group topic event event_enrollment post comment like
    fi

    if [ ${EXTRA_DEMO} ]; then
        drush sda ${EXTRA_DEMO}
    fi

    drush pm-uninstall social_demo -y
    os_fn_sleep
}

os_flush_image_cache() {
    echo "Flush image caches"
    drush cc drush
    drush image-flush --all
    os_fn_sleep
}

os_run_queues() {
    echo "Run activity queues"
    drush queue-run activity_logger_message
    drush queue-run activity_creator_logger
    drush queue-run activity_creator_activities
    os_fn_sleep
}

os_rebuild_node_access() {
    echo "Rebuild node access"
    drush php-eval "node_access_rebuild();"
}

os_reindex() {
    echo "Trigger a search api re-index"
    drush php-eval "drush_search_api_reset_tracker();"
}

os_devel() {
    if [ ${DEV} = "dev" ]; then
      drush en social_devel -y
    fi
}
