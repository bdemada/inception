#!/bin/sh
set -e

log()  { echo "[nginx] $*"; }

# ── Validate required variable ────────────────────────────────────────────
: "${DOMAIN_NAME:?DOMAIN_NAME must be set in .env}"

# ── Inject DOMAIN_NAME into the nginx config template ────────────────────
# Only ${DOMAIN_NAME} is substituted; all nginx $variables are left intact
# because envsubst is given an explicit variable list.
log "Generating nginx config for domain: ${DOMAIN_NAME}..."
envsubst '${DOMAIN_NAME}' \
    < /etc/nginx/http.d/wordpress.conf.template \
    > /etc/nginx/http.d/default.conf

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
        -subj   "/C=ES/ST=Bizkaia/L=Bilbao/0=42Urduliz/CN=${DOMAIN_NAME}" \
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