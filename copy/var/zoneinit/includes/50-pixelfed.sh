#!/usr/bin/env bash

HOSTNAME=$(hostname)
PIXELFED_HOME=/opt/pixelfed
PIXELFED_ENV=${PIXELFED_HOME}/.env

MYSQL_ROOT_PW=$(mdata-get mysql_pw)
MYSQL_PIXELFED_PW=$(/opt/core/bin/mdata-create-password.sh -m mysql_pixelfed_pw)

# _insertreplace FILE KEY VALUE
_insertreplace() {
  local file="${1}"
  shift
  local key="${1}"
  shift
  local value="${@}"
  if [[ "${value}" != "True" &&
    "${value}" != "False" &&
    "${value:0:1}" != "[" ]]; then
    value="\"${value}\""
  fi
  if grep -q "${key}" "${file}"; then
    gsed -i "s|^${key}\s*=.*|${key}=${value}|g" "${file}"
  else
    echo "${key} = ${value}" >>"${file}"
  fi
}
# _pixelfed_php command
_pixelfed_php() {
  cd "${PIXELFED_HOME}" && su pixelfed -c "php ${*}"
}

log "Initial setup if first setup"
if [[ ! -d /var/mysql/pixelfed ]]; then
  log "Install database"
  PIXELFED_INIT="CREATE DATABASE IF NOT EXISTS pixelfed;
        CREATE USER 'pixelfed'@'localhost' IDENTIFIED BY '${MYSQL_PIXELFED_PW}';
        CREATE USER 'pixelfed'@'127.0.0.1' IDENTIFIED BY '${MYSQL_PIXELFED_PW}';
        GRANT ALL PRIVILEGES ON pixelfed.* TO 'pixelfed'@'localhost';
        GRANT ALL PRIVILEGES ON pixelfed.* TO 'pixelfed'@'127.0.0.1';
        FLUSH PRIVILEGES;"

  mysql --user=root --password=${MYSQL_ROOT_PW} -e "${PIXELFED_INIT}" >/dev/null ||
    (log "ERROR MySQL query failed to execute." && exit 31)

  log "Copy storage skel files"
  cp -r ${PIXELFED_HOME}/storage.skel/* ${PIXELFED_HOME}/storage/
fi

log "Fix permissions for storage data"
chown -R pixelfed:www ${PIXELFED_HOME}/storage || true

log "Initial setup .env file"
if [[ ! -f "${PIXELFED_HOME}/.env" ]]; then
  cp "${PIXELFED_HOME}/.env.example" "${PIXELFED_HOME}/.env"
fi
PIXELFED_KEY=${PIXELFED_KEY:-$(mdata-get pixelfed_key 2>/dev/null)} ||
  PIXELFED_KEY=$(_pixelfed_php artisan key:generate --show)
mdata-put pixelfed_key "${PIXELFED_KEY}"

if PIXELFED_APP_NAME=$(mdata-get pixelfed_app_name 2>/dev/null); then
  _insertreplace ${PIXELFED_ENV} APP_NAME "${PIXELFED_APP_NAME}"
fi
_insertreplace ${PIXELFED_ENV} APP_KEY "$(mdata-get pixelfed_key)"
_insertreplace ${PIXELFED_ENV} APP_URL "https://${HOSTNAME}"
_insertreplace ${PIXELFED_ENV} APP_DOMAIN "${HOSTNAME}"
_insertreplace ${PIXELFED_ENV} ADMIN_DOMAIN "${HOSTNAME}"
_insertreplace ${PIXELFED_ENV} SESSION_DOMAIN "${HOSTNAME}"

_insertreplace ${PIXELFED_ENV} DB_PASSWORD "${MYSQL_PIXELFED_PW}"

_insertreplace ${PIXELFED_ENV} MAIL_DRIVER "sendmail"

_insertreplace ${PIXELFED_ENV} OAUTH_ENABLED "false"

_insertreplace ${PIXELFED_ENV} ACTIVITY_PUB "true"
_insertreplace ${PIXELFED_ENV} AP_REMOTE_FOLLOW "true"

log "Initial commands for setup"
_pixelfed_php artisan storage:link
_pixelfed_php artisan migrate --force
_pixelfed_php artisan import:cities
_pixelfed_php artisan instance:actor
_pixelfed_php artisan route:cache
_pixelfed_php artisan view:cache

log "Install Laravel Horizon"
_pixelfed_php artisan horizon:install
_pixelfed_php artisan horizon:publish

log "Create admin account"
PIXELFED_ADMIN_INITIAL_PW=$(/opt/core/bin/mdata-create-password.sh -m pixelfed_initial_pw)
PIXELFED_ADMIN_MAIL=$(mdata-get pixelfed_admin_mail 2>/dev/null || mdata-get mail_adminaddr 2>/dev/null || echo 'admin@localhost')

if ! _pixelfed_php artisan user:table | grep -q " admin "; then
  _pixelfed_php artisan user:create \
    --name=admin --username=admin --email=${PIXELFED_ADMIN_MAIL} \
    --password=${PIXELFED_ADMIN_INITIAL_PW} --is_admin=1 --no-interaction
fi

log "Enable pixelfed horizon service"
svcadm enable svc:/application/pixelfed:horizon
