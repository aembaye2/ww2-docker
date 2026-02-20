# Readme2: Customizations for econwebwork deployment

This document lists edits made for:

- Domain: `ww2.econwebwork.com`
- Admin sender email: `abel.embaye@gmail.com`
- nginx + SSL with Let's Encrypt automation
- Temporary 2FA disable switch for admin login-loop recovery

## Files changed

### 1) `.env.def`

Updated defaults used when `docker_setup.pl` creates a fresh `.env`:

- `WEBWORK_HOSTNAME=ww2.econwebwork.com`
- `WEBWORK_HOST_IP=""` (blank bind; all interfaces)
- `WEBWORK_HOST_PORT="8080"` (kept exposed)
- `WEBWORK_ROOT_URL=https://${WEBWORK_HOSTNAME}`
- `WEBWORK_SMTP_SENDER=abel.embaye@gmail.com`
- `NGINX_HTTP_PORT="80"`
- `NGINX_HTTPS_PORT="443"`
- `LETSENCRYPT_EMAIL=abel.embaye@gmail.com`
- `LETSENCRYPT_RENEW_INTERVAL=12h`
- `WEBWORK_DISABLE_2FA=1` (temporary workaround)
- `RESTART="always"`

### 2) `docker-entrypoint.sh`

Added/updated generated config behavior:

- Applies `WEBWORK_SMTP_SENDER` to `mail{smtpSender}` in `site.conf`.
- If `WEBWORK_DISABLE_2FA=1`, appends `$twoFA{enabled} = 0;` to `localOverrides.conf`.
- Sets `$twoFA{email_sender}` from `WEBWORK_SMTP_SENDER` if not already present.

### 3) `compose.yaml`

Updated service topology:

- `app`: added `MOJO_REVERSE_PROXY=1` to better support headers/sessions behind nginx.
- `nginx`:
  - Proxies `80/443` to app.
  - Mounts:
    - `./config/nginx/default.conf.template`
    - `./config/nginx/start-nginx.sh`
    - `./config/ssl` to `/etc/ssl/local`
    - shared ACME webroot volume `letsencrypt_www`
- Added `certbot` service:
  - Runs `config/nginx/certbot-loop.sh`
  - Issues/renews certificates for `${WEBWORK_HOSTNAME}`
  - Copies active cert/key to `/etc/ssl/local/fullchain.pem` and `/etc/ssl/local/privkey.pem`

### 4) `config/nginx/default.conf.template`

- Serves `/.well-known/acme-challenge/` from `/var/www/certbot`.
- Redirects other HTTP traffic to HTTPS.
- Uses certificate files:
  - `/etc/ssl/local/fullchain.pem`
  - `/etc/ssl/local/privkey.pem`
- Proxies HTTPS traffic to `app:8080`.

### 5) `config/nginx/start-nginx.sh` (new)

- Bootstraps a short-lived self-signed cert if LE cert does not exist yet.
- Starts nginx and periodically reloads to pick up updated certs.

### 6) `config/nginx/certbot-loop.sh` (new)

- Uses webroot challenge for Let's Encrypt.
- Obtains initial cert if missing, then renews on interval.
- Persists certbot state under `config/ssl/letsencrypt`, `config/ssl/work`, `config/ssl/log`.

### 7) `config/ssl/Readme`

- Updated to describe automated cert management and fallback behavior.

### 8) `.gitignore`

Added ignores for generated TLS files/state:

- `config/ssl/fullchain.pem`
- `config/ssl/privkey.pem`
- `config/ssl/letsencrypt/`
- `config/ssl/work/`
- `config/ssl/log/`

### 9) `Dockerfile`

- `WEBWORK_ROOT_URL=https://ww2.econwebwork.com`
- Added `WEBWORK_SMTP_SENDER=abel.embaye@gmail.com`

### 10) `README.md`

- Updated example URL to `https://ww2.econwebwork.com/webwork2/`

### 11) `docker_setup.pl`

- If `.env.def` is missing, fallback now writes `WEBWORK_HOST_IP=""` (blank) instead of `127.0.0.1:`.

## SMTP relay host recommendation

For production email delivery, set `WEBWORK_SMTP_SERVER` in `.env` to a transactional relay host, for example:

- `smtp.mailgun.org`
- `email-smtp.<region>.amazonaws.com` (Amazon SES)
- `smtp.postmarkapp.com`

## 2FA recovery note

Current default sets `WEBWORK_DISABLE_2FA=1` to stop the admin login loop.

After confirming stable login + correct VPS clock sync, set:

- `WEBWORK_DISABLE_2FA=0`

Then restart/recreate containers so the setting is applied.
