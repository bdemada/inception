#!/bin/sh

echo "Starting WordPress setup..."

# ── Helpers ────────────────────────────────────────────────────────────────
log()  { echo "[WordPress] $*"; }
fail() { echo "[WordPress] ERROR: $*" >&2; exit 1; }

read_secret() {
    [ -f "$1" ] || fail "Secret file not found: $1"
    tr -d '\r\n' < "$1"
}

# ── Load secrets ───────────────────────────────────────────────────────────
###

DB_ROOT_PASSWORD=$(read_secret /run/secrets/db_root_password)
DB_NAME=$(read_secret         /run/secrets/db_name)
DB_USER=$(read_secret         /run/secrets/db_user)
DB_PASSWORD=$(read_secret     /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(read_secret /run/secrets/wp_admin_password)
WP_ADMIN_EMAIL=$(read_secret /run/secrets/wp_admin_email)
WP_USER_PASSWORD=$(read_secret /run/secrets/wp_user_password)
WP_USER_EMAIL=$(read_secret /run/secrets/wp_user_email)

# Check environment variables from .env
[ -z "$WP_ADMIN_USER" ] && fail "WP_ADMIN_USER not set in environment"
[ -z "$WP_USER" ] && fail "WP_USER not set in environment"

# ── Wait for mariadb container ───────────────────────────────────────────
while ! mariadb-admin ping -h"mariadb" -u"$DB_USER" -p"$DB_PASSWORD" --connect-timeout=5; do
    log "Waiting for MariaDB..."
    ping -c 1 mariadb | head -n 2
    sleep 2
done

cd /var/www/html

# Use wp with increased memory limit
WP="php -d memory_limit=512M /usr/local/bin/wp --allow-root"

if [ ! -f "wp-config.php" ]; then
    log "Downloading WordPress..."
    $WP core download

    log "Configuring WordPress..."
    $WP config create \
        --dbname=${DB_NAME} \
        --dbuser=${DB_USER} \
        --dbpass=${DB_PASSWORD} \
        --dbhost=mariadb

    log "Installing WordPress..."
    $WP core install \
        --url=https://${DOMAIN_NAME} \
        --title="Bde-mada's Inception" \
        --admin_user=${WP_ADMIN_USER} \
        --admin_password=${WP_ADMIN_PASSWORD} \
        --admin_email=${WP_ADMIN_EMAIL}

    log "Creating extra user..."
    $WP user create \
        ${WP_USER} \
        ${WP_USER_EMAIL} \
        --role=author \
        --user_pass=${WP_USER_PASSWORD}
fi

log "WordPress setup complete!"

# Search in /usr/sbin (standard Alpine location for sbin daemons)
PHP_FPM=$(find /usr/sbin -name 'php-fpm*' | head -n 1)

if [ -z "$PHP_FPM" ]; then
    fail "PHP-FPM binary not found in /usr/sbin"
fi

log "Starting FastCGI server ($PHP_FPM)..."

exec $PHP_FPM -F