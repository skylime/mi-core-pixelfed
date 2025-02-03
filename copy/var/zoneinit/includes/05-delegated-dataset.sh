#!/bin/bash

if DDS=$(/opt/core/bin/dds); then
  zfs create "${DDS}/pixelfed_storage" || true
  zfs create "${DDS}/mysql" || true

  if ! zfs get -o value -H mountpoint "${DDS}/pixelfed_storage" | grep -q /opt/pixelfed/storage; then
    zfs set mountpoint=/opt/pixelfed/storage "${DDS}/pixelfed_storage"
  fi
  if ! zfs get -o value -H mountpoint "${DDS}/mysql" | grep -q /var/mysql; then
    zfs set mountpoint=/var/mysql "${DDS}/mysql"
  fi
fi

# Always try to set the correct permissions for /var/mysql
chown -R mariadb:mariadb /var/mysql || true
chown -R pixelfed:www /opt/pixelfed/storage || true
