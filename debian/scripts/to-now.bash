#!/usr/bin/env bash
set -euo pipefail

NAME="${1:-"default"}"

mkdir -p "/tmp/changed-${NAME}"

tar -c --newer "/tmp/mark-${NAME}" \
  --exclude /FROM_NOW/script \
  --exclude /TO_NOW/script \
  --exclude /boot \
  --exclude /dev \
  --exclude /etc/hosts \
  --exclude /etc/resolv.conf \
  --exclude /etc/ld.so.cache \
  --exclude /media \
  --exclude /mnt \
  --exclude /proc \
  --exclude /run \
  --exclude /srv \
  --exclude /sys \
  --exclude /tmp \
  --exclude /usr/share/man \
  --exclude /usr/share/doc \
  --exclude /var \
  -f - / | tar -xf - -C "/tmp/changed-${NAME}"

find "/tmp/changed-${NAME}" -type d -empty -delete
