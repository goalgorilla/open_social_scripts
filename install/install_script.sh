#!/bin/bash

ROOT_DIR="/var/www/"
LOCAL=${1}
NFS=${2}
DEV=${3}

DEFAULT_DEMO=1
EXTRA_DEMO=""

. "${ROOT_DIR}/scripts/social/install/install_funcs.sh"

cd "${ROOT_DIR}html"

os_prepare_settings
os_install "root" "root" "db" "3306" "admin"
os_nfs
os_opcache_reset
os_files_perms
os_demo
os_flush_image_cache
os_run_queues
os_rebuild_node_access
os_reindex
os_devel
