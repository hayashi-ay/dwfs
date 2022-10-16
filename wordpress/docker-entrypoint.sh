#!/bin/bash

# exit immediately if a command fails or unset variables are used.
# https://sipb.mit.edu/doc/safe-shell/
# https://www.gnu.org/savannah-checkouts/gnu/bash/manual/bash.html#The-Set-Builtin
set -eu -o pipefail

# logging functions
log_base() {
	local type="$1"; shift
	printf '%s [%s] [Entrypoint]: %s\n' "$(date --rfc-3339=seconds)" "$type" "$*"
}

log_info() {
	log_base Info "$@"
}

log_error() {
  log_base ERROR "$@" >&2
  exit 1
}

wait_until_db_start() {
  log_info "Waiting for MariaDB to start."
  local i
  for i in {10..0}; do
    if [ "$i" = 0 ]; then
      log_error "Could not connect to MariaDB."
    fi
    if mysql -h mariadb -u "${DB_USER}" -p"${DB_PASS}" <<<'SELECT 1;' &> /dev/null; then
      break
    fi
    sleep 1
  done
  log_info "MariaDB is started."
}

# check whether WP is installed.
is_wp_installed() {
  # consider WP is installed, if the wp-config.php file exists.
  [ -e "${WP_PATH}/wp-config.php" ]
}

install_wp() {
  log_info "Installing WordPress."
  # generates a wp-config.php file.
  # https://developer.wordpress.org/cli/commands/config/create/
  wp config create \
    --dbname="${DB_NAME}" \
    --dbuser="${DB_USER}" \
    --dbpass="${DB_PASS}" \
    --dbhost=mariadb:3306 \
    --path="${WP_PATH}" \
    --allow-root

  # runs the standard WordPress installation process.
  # https://developer.wordpress.org/cli/commands/core/install/
  wp core install \
    --url="${WP_URL}" \
    --title="${WP_TITLE}" \
    --admin_user="${WP_ADMIN_USER}" \
    --admin_password="${WP_ADMIN_PASS}" \
    --admin_email="${WP_ADMIN_EMAIL}" \
    --path="${WP_PATH}" \
    --allow-root

  # create a new user with an editor role.
  # editor can publish and manage posts including the posts of other users.
  # https://developer.wordpress.org/cli/commands/user/create/
  wp user create \
    "${WP_EDITOR_USER}" \
    "${WP_EDITOR_EMAIL}" \
    --user_pass="${WP_EDITOR_PASS}" \
    --role=editor \
    --path="${WP_PATH}" \
    --allow-root

  log_info "WordPress is successfully installed."
}

wait_until_db_start
if ! is_wp_installed; then
  install_wp
fi
exec "$@"
