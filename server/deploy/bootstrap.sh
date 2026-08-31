#!/usr/bin/env bash
set -euo pipefail

app_root="/opt/study-manager"
service_user="study-manager"

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends python3-venv

if ! id "$service_user" >/dev/null 2>&1; then
  useradd --system --home "$app_root" --shell /usr/sbin/nologin "$service_user"
fi

install -d -m 0755 "$app_root"
install -d -m 0750 -o "$service_user" -g "$service_user" /var/lib/study-manager
install -d -m 0750 -o root -g "$service_user" /etc/study-manager

python3 -m venv "$app_root/server/.venv"
"$app_root/server/.venv/bin/pip" install --disable-pip-version-check -r "$app_root/server/requirements.txt"

if [ ! -f /etc/study-manager/api.env ]; then
  umask 077
  secret="$(openssl rand -hex 32)"
  printf '%s\n' \
    "STUDY_MANAGER_ENV=production" \
    "STUDY_MANAGER_JWT_SECRET=$secret" \
    "STUDY_MANAGER_DB_PATH=/var/lib/study-manager/study_manager.db" \
    "STUDY_MANAGER_CORS_ORIGINS=http://101.37.24.186" \
    >/etc/study-manager/api.env
fi

chown -R "$service_user:$service_user" "$app_root/server/app" /var/lib/study-manager
install -m 0644 "$app_root/server/deploy/study-manager-api.service" /etc/systemd/system/study-manager-api.service
install -m 0644 "$app_root/server/deploy/nginx-study-manager.conf" /etc/nginx/sites-available/study-manager
ln -sfn /etc/nginx/sites-available/study-manager /etc/nginx/sites-enabled/study-manager

nginx -t
systemctl daemon-reload
systemctl enable --now study-manager-api
systemctl reload nginx
curl --fail --silent http://127.0.0.1:8000/health >/dev/null
curl --fail --silent http://127.0.0.1/api/health >/dev/null
printf 'Study Manager API deployment complete.\n'
