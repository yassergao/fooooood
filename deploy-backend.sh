#!/usr/bin/env bash
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo '请以 root 执行'; exit 1; }
command -v node >/dev/null
CONF=/etc/nginx/conf.d/meal-order-preview.conf
[ -f "$CONF" ] || { echo '未找到原订餐配置，停止'; exit 1; }
if [ ! -e /etc/systemd/system/meal-order.service ] && ss -lntH | awk '{print $4}' | grep -q ':3101$'; then echo '3101 被其他服务占用'; exit 1; fi
BACKUP=/root/meal-order-backup-$(date +%Y%m%d-%H%M%S)
mkdir -p "$BACKUP"
cp "$CONF" "$BACKUP/nginx.conf"
if [ -d /opt/meal-order ]; then cp -a /opt/meal-order "$BACKUP/app"; fi
if [ -f /etc/meal-order.env ]; then cp /etc/meal-order.env "$BACKUP/env"; fi
if [ -f /etc/systemd/system/meal-order.service ]; then cp /etc/systemd/system/meal-order.service "$BACKUP/service"; fi
id mealorder >/dev/null 2>&1 || useradd --system --home /var/lib/meal-order --shell /usr/sbin/nologin mealorder
mkdir -p /opt/meal-order /var/lib/meal-order
chown mealorder:mealorder /var/lib/meal-order
chmod 700 /var/lib/meal-order
tar -xzf /root/meal-order-backend.tar.gz -C /opt/meal-order
chmod -R a+rX /opt/meal-order
if [ ! -f /etc/meal-order.env ]; then
 PASSWORD=$(node -e "console.log(require('node:crypto').randomInt(100000,1000000))")
 printf 'ADMIN_PASSWORD=%s\nDATA_DIR=/var/lib/meal-order\nPORT=3101\n' "$PASSWORD" > /etc/meal-order.env
 chmod 600 /etc/meal-order.env
fi
NODE=$(command -v node)
cat > /etc/systemd/system/meal-order.service <<UNIT
[Unit]
Description=Meal order service
After=network.target
[Service]
User=mealorder
Group=mealorder
WorkingDirectory=/opt/meal-order
EnvironmentFile=/etc/meal-order.env
ExecStart=$NODE /opt/meal-order/server.cjs
Restart=on-failure
RestartSec=3
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
PrivateTmp=true
ReadWritePaths=/var/lib/meal-order
[Install]
WantedBy=multi-user.target
UNIT
cat > "$BACKUP/rollback.sh" <<ROLLBACK
#!/usr/bin/env bash
set -e
systemctl stop meal-order
cp '$BACKUP/nginx.conf' '$CONF'
if [ -f '$BACKUP/service' ]; then
 cp '$BACKUP/service' /etc/systemd/system/meal-order.service
 cp '$BACKUP/env' /etc/meal-order.env
 cp -a '$BACKUP/app/.' /opt/meal-order/
 systemctl daemon-reload
 systemctl start meal-order
else
 systemctl disable meal-order || true
 rm -f /etc/systemd/system/meal-order.service
 systemctl daemon-reload
fi
nginx -t && systemctl reload nginx
ROLLBACK
chmod 700 "$BACKUP/rollback.sh"
trap 'echo "更新未完成，执行回滚"; bash "$BACKUP/rollback.sh"' ERR
systemctl daemon-reload
systemctl enable meal-order
systemctl restart meal-order
for n in $(seq 1 15); do if curl -fsS http://127.0.0.1:3101/api/health >/dev/null; then break; fi; sleep 1; done
curl -fsS http://127.0.0.1:3101/api/health
cat > "$CONF" <<'NGINX'
server {
 listen 8081;
 listen [::]:8081;
 server_name _;
 client_max_body_size 32k;
 location / {
  proxy_pass http://127.0.0.1:3101;
  proxy_set_header Host $http_host;
  proxy_set_header X-Forwarded-Proto $scheme;
  proxy_set_header X-Real-IP $remote_addr;
 }
}
NGINX
nginx -t
systemctl reload nginx
curl --retry 10 --retry-all-errors --retry-delay 1 -fsS http://127.0.0.1:8081/api/health
trap - ERR
echo
echo '更新成功。后台：http://14.103.28.143:8081/admin'
echo '管理员密码（请保存）：'
sed -n 's/^ADMIN_PASSWORD=//p' /etc/meal-order.env
echo "撤销本次更新：bash $BACKUP/rollback.sh"
