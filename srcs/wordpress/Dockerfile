FROM alpine:3.22.3

# ── PHP 8.3 + all extensions required by WordPress ────────────────────────
RUN apk update && apk upgrade && \
        apk add --no-cache \
        php \
        php-fpm \
        php-mysqli \
        php-json \
        php-curl \
        php-dom \
        php-exif \
        php-fileinfo \
        php-mbstring \
        php-opcache \
        php-openssl \
        php-xml \
        php-zip \
        php-phar \
        curl \
        mariadb-client

# ── Download WP-CLI ────────────────────────────────────────────────────────
RUN curl -fsSL -o /usr/local/bin/wp \
        https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
        && chmod +x /usr/local/bin/wp

# ── PHP-FPM pool config (listen on TCP so nginx can reach it) ─────────────
RUN find /etc -name www.conf -exec sed -i 's/listen = 127.0.0.1:9000/listen = 9000/g' {} \;

RUN mkdir -p /var/www/html \
        && chown -R nobody:nobody /var/www/html \
        && chmod -R 755 /var/www/html

COPY wp-setup.sh        /usr/local/bin/wp-setup.sh
RUN  chmod +x           /usr/local/bin/wp-setup.sh

ENTRYPOINT ["/usr/local/bin/wp-setup.sh"]