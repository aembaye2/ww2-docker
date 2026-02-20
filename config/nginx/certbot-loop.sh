#!/bin/sh
set -eu

CERTBOT_CONFIG_DIR=/etc/ssl/local/letsencrypt
CERTBOT_WORK_DIR=/etc/ssl/local/work
CERTBOT_LOGS_DIR=/etc/ssl/local/log
LIVE_DIR="$CERTBOT_CONFIG_DIR/live/${WEBWORK_HOSTNAME}"

mkdir -p "$CERTBOT_CONFIG_DIR" "$CERTBOT_WORK_DIR" "$CERTBOT_LOGS_DIR" /var/www/certbot

while true; do
  if [ ! -f "$LIVE_DIR/fullchain.pem" ] || [ ! -f "$LIVE_DIR/privkey.pem" ]; then
    certbot certonly \
      --webroot -w /var/www/certbot \
      --config-dir "$CERTBOT_CONFIG_DIR" \
      --work-dir "$CERTBOT_WORK_DIR" \
      --logs-dir "$CERTBOT_LOGS_DIR" \
      --non-interactive --agree-tos --no-eff-email \
      -m "$LETSENCRYPT_EMAIL" \
      -d "$WEBWORK_HOSTNAME"
  else
    certbot renew \
      --webroot -w /var/www/certbot \
      --config-dir "$CERTBOT_CONFIG_DIR" \
      --work-dir "$CERTBOT_WORK_DIR" \
      --logs-dir "$CERTBOT_LOGS_DIR" \
      --quiet
  fi

  if [ -f "$LIVE_DIR/fullchain.pem" ] && [ -f "$LIVE_DIR/privkey.pem" ]; then
    cp "$LIVE_DIR/fullchain.pem" /etc/ssl/local/fullchain.pem
    cp "$LIVE_DIR/privkey.pem" /etc/ssl/local/privkey.pem
    chmod 644 /etc/ssl/local/fullchain.pem
    chmod 600 /etc/ssl/local/privkey.pem
  fi

  sleep "${LETSENCRYPT_RENEW_INTERVAL:-12h}"
done
