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

# do a temporary startup of the MariaDB server, for init purposes.
docker_temp_server_start() {
  log_info "Starting temporary server."
  mysqld --skip-networking -uroot &
  # Wait until mariadb starts.
  local i
  for i in {10..0}; do
    if [ "$i" = 0 ]; then
      log_error "Failed to start server."
    fi
    if mysql <<<'SELECT 1;' &> /dev/null; then
      break
    fi
    sleep 1
  done
  log_info "Temporary server started."
}

docker_temp_server_stop() {
  log_info "Stopping temporary server."
  mysqladmin shutdown
  log_info "Temporary server stopped."
}

# usage: docker_process_init_files [file...]
#   ie: docker_process_init_files /docker-entrypoint-initdb.d/*
# process initializer files.
docker_process_init_files() {
  local f
  for f; do
    case "$f" in
      *.sh)
        log_info "running $f";
        # ShellCheck can't follow non-constant source. Use a directive to specify location.
        # shellcheck disable=SC1090
        . "$f"
        ;;
      *.sql)
        log_info "running $f";
        mysql < "$f"
        ;;
      *) log_info "ignoring $f"; ;;
    esac
  done
}

# check whether DB init scripts are executed.
is_initialized() {
  # Consider DB is initialized, if wordpress database exists.
  [ -e /var/lib/mysql/"${DB_NAME}" ]
}

initialize_db() {
  docker_temp_server_start
  docker_process_init_files /docker-entrypoint-initdb.d/*
  docker_temp_server_stop
}

if ! is_initialized; then
  initialize_db
fi
exec "$@"
