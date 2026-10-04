#!/usr/bin/env bash
set -euo pipefail
SITE=/var/www/meal-order-preview
CONF=/etc/nginx/conf.d/meal-order-preview.conf
PACKAGE=/root/meal-order-preview.tar.gz
if [ "$(id -u)" -ne 0 ]; then echo '请使用 root 或 sudo bash 执行'; exit 1; fi
if [ -e "$SITE" ] || [ -e "$CONF" ]; then echo '订餐目录或配置已存在，停止以避免覆盖。'; exit 1; fi
if ss -lntH | awk '{print $4}' | grep -Eq ':8081$'; then echo '8081 已占用，停止。'; exit 1; fi
if ! nginx -T 2>/dev/null | grep -Eq '^[[:space:]]*include[[:space:]]+/etc/nginx/conf.d/\*\.conf[[:space:]]*;'; then echo '未找到标准 conf.d 加载配置，请先提供 Nginx include 配置。'; exit 1; fi
test -f "$PACKAGE" || { echo '请先上传部署包到 /root'; exit 1; }
mkdir -p "$SITE"
tar -xzf "$PACKAGE" -C "$SITE"
chmod -R a+rX "$SITE"
cat > "$CONF" <<'NGINX'
server {
    listen 8081;
    listen [::]:8081;
    server_name _;
    root /var/www/meal-order-preview;
    index index.html;
    charset utf-8;
    location / { try_files $uri $uri/ =404; }
    location ~ \.sh$ { deny all; }
}
NGINX
if ! nginx -t; then rm -f "$CONF"; echo '配置检查失败，已撤销新增配置，未重载。'; exit 1; fi
if ! systemctl reload nginx; then rm -f "$CONF"; echo '重载失败，已撤销新增配置。'; exit 1; fi
curl --fail --silent --show-error http://127.0.0.1:8081/ -o /tmp/meal-preview-check.html
grep -q '好好吃饭' /tmp/meal-preview-check.html
echo '网页原型本机检查通过：http://14.103.28.143:8081/'
echo '请在云服务器安全组放行 TCP 8081；如 UFW 已启用，也需要放行此端口。'
echo '当前为网页原型，订单只存在访客浏览器中，尚未接入真实收单。'
