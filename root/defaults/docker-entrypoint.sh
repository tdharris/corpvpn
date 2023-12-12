#!/usr/bin/env bash

set -e

trap 'kill ${!}; stop' SIGTERM SIGINT SIGQUIT SIGHUP ERR
log_prefix="[$(basename "${BASH_SOURCE[0]}")]"
# shellcheck source=../app/common.sh
# shellcheck disable=SC1091
source /app/common.sh

start() {
  log info "$log_prefix Starting services..."
  if [[ "$ENABLE_VPN" == "true" ]]; then
    log info "$log_prefix VPN is enabled."
    /app/openconnect.sh start
    /app/routes.sh
  fi
  /app/privoxy.sh start
  /app/microsocks.sh start
  if [[ "$ENABLE_DNS" == "true" ]]; then
    /app/dnsmasq.sh start
  fi
  log info "$log_prefix ✔ Successfully started all services."
}

stop() {
  log info "$log_prefix Stopping services..."
  if [[ "$ENABLE_VPN" == "true" ]]; then
    /app/openconnect.sh stop
  fi
  /app/privoxy.sh stop
  /app/microsocks.sh stop
  if [[ "$ENABLE_DNS" == "true" ]]; then
    /app/dnsmasq.sh stop
  fi
  log info "$log_prefix ✔ Successfully stoped all services."

  exit 143; # SIGTERM
}

start

# wait forever
while true; do
  tail -f /dev/null & wait ${!}
done
