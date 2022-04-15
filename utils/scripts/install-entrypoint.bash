#!/usr/bin/env bash
set -euo pipefail

cat <<EOF >/entrypoint.bash
#!/usr/bin/env bash
# Script inspired by: https://bit.ly/3kNFIuh
set -euo pipefail

USERNAME="${USERNAME:-"code"}"
SOURCE_SOCKET="${SOURCE_SOCKET:-"/var/run/docker-host.sock"}"
TARGET_SOCKET="${TARGET_SOCKET:-"/var/run/docker.sock"}"
ENTRYPOINT_LOGS="${ENTRYPOINT_LOGS:-"/tmp/entrypoint-logs"}"
EOF

cat <<-"EOF" >>/entrypoint.bash
mkdir -p "${ENTRYPOINT_LOGS}"
ENTRYPOINT_LOG_FILE="${ENTRYPOINT_LOGS}/entrypoint.log"
SOCAT_LOG="${ENTRYPOINT_LOGS}/socat.log"
SOCAT_PID="${ENTRYPOINT_LOGS}/socat.pid"

function log {
  echo -e "[$(date)]" "$@" | tee -a "${ENTRYPOINT_LOG_FILE}" >/dev/null
}

# If the docker socket has not been mounted we have nothing to do
if [ -S "${SOURCE_SOCKET}" ]; then
  SOCKET_GID="$(stat -c '%g' "${SOURCE_SOCKET}")"
  if [ "${SOCKET_GID}" != "0" ]; then
    # If we can we will just use the host socket directly by
    # modifying the permissions of the contaienr user.
    if [ "$(grep :"${SOCKET_GID}": </etc/group)" = "" ]; then
      log "groupadd --gid ${SOCKET_GID} docker-host"
      groupadd --gid "${SOCKET_GID}" docker-host
    fi
    if [ "$(id "${USERNAME}" | grep -E "groups.*(=|,)${SOCKET_GID}\(")" = "" ]; then
      log "usermod -aG ${SOCKET_GID} ${USERNAME}"
      usermod -aG "${SOCKET_GID}" "${USERNAME}"
    fi
    if [ ! -S "${TARGET_SOCKET}" ]; then
      log "ln -s ${SOURCE_SOCKET} ${TARGET_SOCKET}"
      ln -s "${SOURCE_SOCKET}" "${TARGET_SOCKET}"
    fi
  else
    # If the group is root, fall back on using socat to forward the docker
    # socket to another unix socket so that we can set permissions on it
    # without affecting the host.
    if [ ! -f "${SOCAT_PID}" ] || ! ps -p "$(cat ${SOCAT_PID})" >/dev/null; then
      log "Enabling socket proxy."
      log "Proxying ${SOURCE_SOCKET} to ${TARGET_SOCKET}"
      (
        socat \
          "UNIX-LISTEN:${TARGET_SOCKET},fork,mode=660,user=${USERNAME}" \
          "UNIX-CONNECT:${SOURCE_SOCKET}" 2>&1 |
          tee -a "${SOCAT_LOG}" >/dev/null &
        echo "$!" | tee "${SOCAT_PID}" >/dev/null
      )
      sleep 1
    else
      log "Socket proxy already running."
    fi
  fi
  log "chown -h ${USERNAME}:root ${TARGET_SOCKET}"
  chown -h "${USERNAME}:root" "${TARGET_SOCKET}"
else
  log "${SOURCE_SOCKET} does not exist, thus docker will not work inside this container"
fi

# Make sure we can read/write some other volume mounts
function chown_vol {
  if [ -d "${1}" ]; then
    chown -R "${USERNAME}:root" "${1}"
  fi
}
chown_vol "/home/${USERNAME}/go"
chown_vol "/home/${USERNAME}/.config/gh"

# Execute whatever commands were passed in (if any) as the unprivilaged user.
exec gosu "${USERNAME}" "$@"
EOF

cat /entrypoint.bash
chmod +x /entrypoint.bash
chown "${USERNAME}:root" /entrypoint.bash