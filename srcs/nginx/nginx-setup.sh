#!/bin/sh

log()  { echo "[nginx] $*"; }

DOMAIN_NAME="bde-mada.42.fr"
COUNTRY="ES"
STATE="Bizkaia"
LOCATION="Bilbao"
ORGANIZATION="42Urduliz"

# ── TLS certificate & DH params ───────────────────────────────────────────
SSL_DIR="/etc/nginx/ssl"
CERT="${SSL_DIR}/server.crt"
KEY="${SSL_DIR}/server.key"
DH="${SSL_DIR}/dhparam.pem"

mkdir -p "${SSL_DIR}"

if [ ! -f "${CERT}" ] || [ ! -f "${KEY}" ]; then
    log "Generating self-signed TLS certificate for ${DOMAIN_NAME}..."
    openssl req -x509 -nodes -days 365 \
        -newkey rsa:2048 \
        -keyout "${KEY}" \
        -out    "${CERT}" \
        -subj   "/C=${COUNTRY}/ST=${STATE}/L=${LOCATION}/0=${ORGANIZATION}/CN=${DOMAIN_NAME}" \
        -addext "subjectAltName=DNS:${DOMAIN_NAME},DNS:www.${DOMAIN_NAME}"
    chmod 600 "${KEY}" "${CERT}"
    log "Certificate generated."
fi

if [ ! -f "${DH}" ]; then
    log "Generating DH parameters (this may take a moment)..."
    openssl dhparam -out "${DH}" 2048 2>/dev/null
    chmod 600 "${DH}"
    log "DH parameters generated."
fi

log "Starting Nginx..."
exec "$@"