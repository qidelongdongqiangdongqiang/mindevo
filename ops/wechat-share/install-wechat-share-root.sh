#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Run this script as root on the Aliyun ECS host." >&2
  exit 1
fi

APP_DIR="/var/www/mindevo-services/wechat-share"
ENV_FILE="/etc/mindevo/wechat-share.env"
SERVICE_FILE="/etc/systemd/system/mindevo-wechat-share.service"
NGINX_SNIPPET="/etc/nginx/snippets/mindevo-wechat-share.conf"
NGINX_CONF="/etc/nginx/conf.d/mindevo.conf"

mkdir -p "$APP_DIR" /etc/mindevo /etc/nginx/snippets
chown -R deploy:deploy "$(dirname "$APP_DIR")"
chown deploy:deploy /etc/mindevo
chmod 700 /etc/mindevo

if [ ! -f "$ENV_FILE" ]; then
  cat > "$ENV_FILE" <<'ENV'
WECHAT_APP_ID=replace-with-wechat-app-id
WECHAT_APP_SECRET=replace-with-wechat-app-secret
WECHAT_ALLOWED_HOSTS=www.mindevo.club,mindevo.club
WECHAT_SHARE_PORT=8710
ENV
  chmod 600 "$ENV_FILE"
  chown deploy:deploy "$ENV_FILE"
  echo "Created $ENV_FILE. Fill in WECHAT_APP_ID and WECHAT_APP_SECRET before enabling production sharing."
fi

install -m 0644 ./mindevo-wechat-share.service "$SERVICE_FILE"
install -m 0644 ./mindevo-wechat-share-nginx.conf "$NGINX_SNIPPET"

if ! grep -q "mindevo-wechat-share.conf" "$NGINX_CONF"; then
  python3 - "$NGINX_CONF" <<'PY'
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
text = path.read_text()
needle = "    location / {\n"
include = "    include /etc/nginx/snippets/mindevo-wechat-share.conf;\n\n"
if include not in text:
    text = text.replace(needle, include + needle, 1)
path.write_text(text)
PY
fi

systemctl daemon-reload
systemctl enable mindevo-wechat-share.service

nginx -t
systemctl reload nginx
echo "WeChat share root setup complete. After deploying service code, run: systemctl restart mindevo-wechat-share.service"
