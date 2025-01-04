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
  if grep -q "${key}" ${file}; then
    gsed -i "s|^${key} \+=.*|${key} = ${value}|g" ${file}
  else
    echo "${key} = ${value}" >> ${file}
  fi
}

log "Create database if not exists"
if [[ ! -d /var/mysql/kumquat ]]; then
  KUMQUAT_INIT="CREATE DATABASE IF NOT EXISTS kumquat;
        CREATE USER 'kumquat'@'localhost' IDENTIFIED BY '${MYSQL_KUMQUAT_PW}';
        CREATE USER 'kumquat'@'127.0.0.1' IDENTIFIED BY '${MYSQL_KUMQUAT_PW}';
        GRANT ALL PRIVILEGES ON kumquat.* TO 'kumquat'@'localhost';
        GRANT ALL PRIVILEGES ON kumquat.* TO 'kumquat'@'127.0.0.1';
        FLUSH PRIVILEGES;"

  mysql --user=root --password=${MYSQL_ROOT_PW} -e "${KUMQUAT_INIT}" > /dev/null \
    || (log "ERROR MySQL query failed to execute." && exit 31)
  DB_CREATED=true
fi

log "Initial setup .env file"
if [[ ! -f "${PIXELFED_HOME}/.env" ]]; then
  cp "${PIXELFED_HOME}/.env.example" "${PIXELFED_HOME}/.env"

  PIXELFED_KEY=${PIXELFED_KEY:-$(mdata-get pixelfed_key 2> /dev/null)} \
    || PIXELFED_KEY=$(php artisan key:generate --show)
  mdata-put pixelfed_key "${PIXELFED_KEY}"
fi

_insertreplace ${PIXELFED_ENV} APP_NAME
_insertreplace ${PIXELFED_ENV} APP_URL "https://${HOSTNAME}"
_insertreplace ${PIXELFED_ENV} APP_DOMAIN ${HOSTNAME}
_insertreplace ${PIXELFED_ENV} ADMIN_DOMAIN ${HOSTNAME}
_insertreplace ${PIXELFED_ENV} SESSION_DOMAIN ${HOSTNAME}

_insertreplace ${PIXELFED_ENV} DB_PASSWORD "TODO"

_insertreplace ${PIXELFED_ENV} MAIL_DRIVER sendmail

_insertreplace ${PIXELFED_ENV} ACTIVITY_PUB true
_insertreplace ${PIXELFED_ENV} AP_REMOTE_FOLLOW true
