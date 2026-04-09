#!/bin/sh
set -e

log()  { echo "[wordpress] $*"; }
fail() { echo "[wordpress] ERROR: $*" >&2; exit 1; }

read_secret() {
    [ -f "$1" ] || fail "Secret file not found: $1"
    cat "$1"
}

# ── Credentials from secrets (sensitive) ─────────────────────────────────
DB_NAME=$(read_secret           /run/secrets/db_name)
DB_USER=$(read_secret           /run/secrets/db_user)
DB_PASSWORD=$(read_secret       /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(read_secret /run/secrets/wp_admin_password)
WP_ADMIN_EMAIL=$(read_secret    /run/secrets/wp_admin_email)
WP_USER_PASSWORD=$(read_secret  /run/secrets/wp_user_password)
WP_USER_EMAIL=$(read_secret     /run/secrets/wp_user_email)

# ── Usernames and domain from environment (.env) ──────────────────────────
: "${WP_ADMIN_USER:?WP_ADMIN_USER must be set in .env}"
: "${WP_USER:?WP_USER must be set in .env}"
: "${DOMAIN_NAME:?DOMAIN_NAME must be set in .env}"

DB_HOST="${WORDPRESS_DB_HOST:-mariadb:3306}"
WP_URL="https://${DOMAIN_NAME}"
WP_TITLE="${WORDPRESS_TITLE:-My WordPress Site}"
WP_PATH="/var/www/html"

# ── Copy WordPress source to shared volume (first run only) ──────────────
if [ ! -f "${WP_PATH}/wp-login.php" ]; then
    log "Copying WordPress files to ${WP_PATH}..."
    cp -r /usr/src/wordpress/. "${WP_PATH}/"
    chown -R nobody:nobody "${WP_PATH}"
fi

# ── Generate wp-config.php (first run only) ───────────────────────────────
if [ ! -f "${WP_PATH}/wp-config.php" ]; then
    log "Generating wp-config.php..."

    SALT=$(wget -qO- https://api.wordpress.org/secret-key/1.1/salt/ 2>/dev/null \
           || echo "// Could not fetch salts — replace these manually")

    cat > "${WP_PATH}/wp-config.php" << PHP
<?php
define( 'DB_NAME',     '${DB_NAME}' );
define( 'DB_USER',     '${DB_USER}' );
define( 'DB_PASSWORD', '${DB_PASSWORD}' );
define( 'DB_HOST',     '${DB_HOST}' );
define( 'DB_CHARSET',  'utf8mb4' );
define( 'DB_COLLATE',  'utf8mb4_unicode_ci' );

\$table_prefix = 'wp_';

${SALT}

define( 'WP_DEBUG',           false );
define( 'DISALLOW_FILE_EDIT', true );
define( 'WP_HOME',            '${WP_URL}' );
define( 'WP_SITEURL',         '${WP_URL}' );

if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', __DIR__ . '/' );
}
require_once ABSPATH . 'wp-settings.php';
PHP
    chown nobody:nobody "${WP_PATH}/wp-config.php"
    chmod 640 "${WP_PATH}/wp-config.php"
fi

# ── Wait for MariaDB ───────────────────────────────────────────────────────
log "Waiting for database at ${DB_HOST}..."
DB_HOST_ONLY="${DB_HOST%%:*}"
DB_PORT="${DB_HOST##*:}"
[ "${DB_PORT}" = "${DB_HOST_ONLY}" ] && DB_PORT=3306

until php -r "
    \$c = @new mysqli('${DB_HOST_ONLY}','${DB_USER}','${DB_PASSWORD}','${DB_NAME}',${DB_PORT});
    exit(\$c->connect_error ? 1 : 0);
" 2>/dev/null; do
    sleep 2
done
log "Database is ready."

# ── WordPress core install (first run only) ────────────────────────────────
if ! wp --path="${WP_PATH}" --allow-root core is-installed 2>/dev/null; then
    log "Installing WordPress core..."
    wp --path="${WP_PATH}" --allow-root core install \
        --url="${WP_URL}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email
    log "WordPress installed. Admin: ${WP_ADMIN_USER}"
fi

# ── Create regular user (first run only) ──────────────────────────────────
if ! wp --path="${WP_PATH}" --allow-root user get "${WP_USER}" \
        --field=login 2>/dev/null | grep -q "^${WP_USER}$"; then
    log "Creating regular user: ${WP_USER} (role: subscriber)..."
    wp --path="${WP_PATH}" --allow-root user create \
        "${WP_USER}" \
        "${WP_USER_EMAIL}" \
        --role=subscriber \
        --user_pass="${WP_USER_PASSWORD}" \
        --display_name="${WP_USER}"
    log "User ${WP_USER} created."
else
    log "User ${WP_USER} already exists, skipping."
fi

log "Starting PHP-FPM..."
exec "$@"
