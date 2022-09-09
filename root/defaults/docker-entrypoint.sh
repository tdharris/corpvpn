#!/usr/bin/env bash

set -e

trap 'kill ${!}; stop' SIGTERM SIGINT SIGQUIT SIGHUP ERR
log_prefix="[$(basename "${BASH_SOURCE[0]}")]"
# shellcheck source=../app/common.sh
# shellcheck disable=SC1091
source /app/common.sh

start() {
  log info "$log_prefix Starting services..."
  /app/openconnect.sh start
  /app/routes.sh
  /app/privoxy.sh start
  /app/microsocks.sh start
  /app/dnsmasq.sh start
  log info "$log_prefix ✔ Successfully started all services."
}

stop() {
  log info "$log_prefix Stopping services..."
  /app/openconnect.sh stop
  /app/privoxy.sh stop
  /app/microsocks.sh stop
  /app/dnsmasq.sh stop
  log info "$log_prefix ✔ Successfully stoped all services."

  exit 143; # SIGTERM
}

start

# wait forever
while true; do
  tail -f /dev/null & wait ${!}
done
