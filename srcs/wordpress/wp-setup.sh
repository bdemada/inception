#!/bin/sh

echo "Starting WordPress setup..."

read_secret() {
    [ -f "$1" ] || fail "Secret file not found: $1"
    cat "$1"
}

DB_ROOT_PASSWORD=$(read_secret /run/secrets/db_root_password)
DB_NAME=$(read_secret         /run/secrets/db_name)
DB_USER=$(read_secret         /run/secrets/db_user)
DB_PASSWORD=$(read_secret     /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(read_secret /run/secrets/wp_admin_password)
WP_ADMIN_EMAIL=$(read_secret /run/secrets/wp_admin_email)
WP_USER_PASSWORD=$(read_secret /run/secrets/wp_user_password)
WP_USER_EMAIL=$(read_secret /run/secrets/wp_user_email)

#Wait for mariadb container
while ! /usr/bin/mariadb-admin ping -h"mariadb" -u"$DB_USER" -p"$DB_PASSWORD" --silent; do
    echo "Waiting for MariaDB..."
    sleep 2
done

if [ ! -f "wp-config.php" ]; then
    echo "Downloading WordPress..."
    wp core download --allow-root

    echo "Configuring WordPress..."
    wp config create \
        --dbname=${DB_NAME} \
        --dbuser=${DB_USER} \
        --dbpass=${DB_PASSWORD} \
        --dbhost=mariadb \
        --allow-root

    echo "Installing WordPress"
    wp core install \
        --url=https://bde-mada.42.fr \
        --title="Bde-mada's Inception" \
        --admin_user=${WP_ADMIN_USER} \
        --admin_password=${WP_ADMIN_PASSWORD} \
        --admin_email=${WP_ADMIN_EMAIL} \
        --allow-root

    echo "Creating extra user"
    wp user create \
        ${WP_USER} \
        ${WP_USER_EMAIL} \
        --role=author \
        --user_pass=${WP_USER_PASSWORD} \
        --allow-root
fi

echo "WordPress setup complete!"

PHP_FPM=$(find /usr/bin -name 'php-fpm*' | head -n 1)

echo "Starting FastCGI server ($PHP_FPM)..."

exec $PHP_FPM -F