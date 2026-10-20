#!/usr/bin/env bash
# install-nginx-security-hardening-root.sh
#
# 在阿里云 ECS（121.40.130.19）上以 root 执行一次：
#   1. 安装 /etc/nginx/snippets/mindevo-security-hardening.conf
#   2. 在 mindevo.conf / mindevo-staging.conf 的站点 server 块内插入 include
#   3. nginx -t 校验通过后 reload
#
# 使用方法（在服务器上，root 身份）：
#   bash install-nginx-security-hardening-root.sh
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Run this script as root on the Aliyun ECS host." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SNIPPET_SRC="${SCRIPT_DIR}/mindevo-security-hardening.conf"
SNIPPET_DST="/etc/nginx/snippets/mindevo-security-hardening.conf"
INCLUDE_LINE="include /etc/nginx/snippets/mindevo-security-hardening.conf;"
BACKUP_DIR="/etc/nginx/backups"
STAMP="$(date +%Y%m%d-%H%M%S)"

if [ ! -f "$SNIPPET_SRC" ]; then
  echo "Snippet not found next to this script: $SNIPPET_SRC" >&2
  exit 1
fi

mkdir -p /etc/nginx/snippets "$BACKUP_DIR"
cp -a "$SNIPPET_SRC" "$SNIPPET_DST"
echo "Installed snippet: $SNIPPET_DST"

for CONF in /etc/nginx/conf.d/mindevo.conf /etc/nginx/conf.d/mindevo-staging.conf; do
  if [ ! -f "$CONF" ]; then
    echo "Skip (not found): $CONF"
    continue
  fi
  cp -a "$CONF" "${BACKUP_DIR}/$(basename "$CONF").${STAMP}.bak"
  echo "Backed up $CONF"
  if grep -qF "$INCLUDE_LINE" "$CONF"; then
    echo "Already included in $CONF"
    continue
  fi
  # 在站点 server 块的 root 指令后插入 include（每个站点配置只有含 root 的
  # server 块提供静态文件，重定向 server 块不含 root，不受影响）
  sed -i "/^[[:space:]]*root[[:space:]]\+\/var\/www\/mindevo/a\\    ${INCLUDE_LINE}" "$CONF"
  echo "Inserted include into $CONF"
done

nginx -t
systemctl reload nginx
echo "nginx reloaded with security hardening rules."

echo
echo "验证（应全部返回 404）："
for p in /README.md /.git/config /.git/HEAD /.env /composer.lock; do
  code="$(curl -o /dev/null -sS -w '%{http_code}' "https://www.mindevo.club${p}")"
  echo "${code}  https://www.mindevo.club${p}"
done
