#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Run this script as root on the Aliyun ECS host." >&2
  exit 1
fi

SOURCE_CONF="/etc/nginx/conf.d/mindevo.conf"
BACKUP_DIR="/etc/nginx/backups"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_FILE="${BACKUP_DIR}/mindevo.conf.${STAMP}.bak"

mkdir -p "$BACKUP_DIR"
cp -a "$SOURCE_CONF" "$BACKUP_FILE"
echo "Backed up existing config to ${BACKUP_FILE}"

cat > "$SOURCE_CONF" <<'NGINX'
# Canonical HTTPS server: www.mindevo.club only
server {
    server_name www.mindevo.club;
    root /var/www/mindevo;
    index index.html;

    gzip on;
    gzip_vary on;
    gzip_min_length 256;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml text/javascript image/svg+xml;

    location ~* \.(css|js)$ {
        expires 7d;
        add_header Cache-Control "public, immutable";
    }

    location ~* \.(jpg|jpeg|png|webp|svg|ico|woff2|woff)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    include /etc/nginx/snippets/mindevo-wechat-share.conf;

    location / {
        try_files $uri $uri/ =404;
    }

    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/mindevo.club/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/mindevo.club/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
}

# Redirect non-www HTTPS to www
server {
    server_name mindevo.club;
    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/mindevo.club/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/mindevo.club/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
    return 301 https://www.mindevo.club$request_uri;
}

# Redirect HTTP (any host) to HTTPS www
server {
    listen 80;
    server_name mindevo.club www.mindevo.club 121.40.130.19;
    return 301 https://www.mindevo.club$request_uri;
}
NGINX

if nginx -t; then
  systemctl reload nginx
  echo "Nginx canonical redirect installed and reloaded successfully."
else
  echo "nginx -t failed; restoring backup." >&2
  cp -a "$BACKUP_FILE" "$SOURCE_CONF"
  nginx -t
  systemctl reload nginx
  echo "Restored previous config." >&2
  exit 1
fi
