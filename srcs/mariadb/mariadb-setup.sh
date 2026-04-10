#!/bin/sh
set -e

# ── Helpers ────────────────────────────────────────────────────────────────
log()  { echo "[mariadb] $*"; }
fail() { echo "[mariadb] ERROR: $*" >&2; exit 1; }

read_secret() {
    [ -f "$1" ] || fail "Secret file not found: $1"
    cat "$1"
}

# ── Load secrets ───────────────────────────────────────────────────────────
###
DB_ROOT_PASSWORD=$(read_secret /run/secrets/db_root_password)
DB_NAME=$(read_secret         /run/secrets/db_name)
DB_USER=$(read_secret         /run/secrets/db_user)
DB_PASSWORD=$(read_secret     /run/secrets/db_password)

DATA_DIR="/var/lib/mysql"
###

# ── First-run initialisation ───────────────────────────────────────────────
if [ ! -d "${DATA_DIR}/mysql" ]; then
    log "Initialising data directory..."
    mysql_install_db --user=mysql --datadir="${DATA_DIR}" --skip-test-db \
        > /dev/null 2>&1

    log "Starting temporary server for bootstrapping..."
    mysqld --user=mysql --skip-networking \
           --socket=/run/mysqld/mysqld.sock &
    TEMP_PID=$!

    # Wait until the socket is up. Using mariadb-admin instead of mysqladmin to avoid deprecation warning
    i=0
    while ! ./usr/bin/mariadb-admin --socket=/run/mysqld/mysqld.sock ping --silent 2>/dev/null; do
        i=$((i+1))
        [ $i -lt 30 ] || fail "Temporary server did not start in time."
        sleep 1
    done

    log "Bootstrapping users and database..."
    mysql --socket=/run/mysqld/mysqld.sock -u root << SQL
-- Secure root
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost','127.0.0.1','::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';

-- Application database & user
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`
    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'%';
FLUSH PRIVILEGES;
SQL

    log "Shutting down temporary server..."
    ./usr/bin/mariadb-admin --socket=/run/mysqld/mysqld.sock \
               -u root -p"${DB_ROOT_PASSWORD}" shutdown
    wait "${TEMP_PID}"
    log "Initialisation complete."
fi

# ── Hand off to mysqld ─────────────────────────────────────────────────────
log "Starting MariaDB..."
exec "$@"