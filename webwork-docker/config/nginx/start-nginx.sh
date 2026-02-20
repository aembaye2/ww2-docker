#!/bin/sh
set -eu

if [ ! -f /etc/ssl/local/fullchain.pem ] || [ ! -f /etc/ssl/local/privkey.pem ]; then
  if ! command -v openssl >/dev/null 2>&1; then
    apk add --no-cache openssl >/dev/null 2>&1
  fi

  mkdir -p /etc/ssl/local
  openssl req -x509 -nodes -newkey rsa:2048 -days 3 \
    -keyout /etc/ssl/local/privkey.pem \
    -out /etc/ssl/local/fullchain.pem \
    -subj "/CN=${WEBWORK_HOSTNAME}" >/dev/null 2>&1
fi

nginx -g 'daemon off;' &
NGINX_PID=$!

while true; do
  sleep "${LETSENCRYPT_RENEW_INTERVAL:-12h}" || true
  nginx -s reload || true
done &

wait "$NGINX_PID"
